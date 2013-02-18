require 'state_machine'

require File.join(File.dirname(__FILE__), 'player')
require File.join(File.dirname(__FILE__), 'deck')
require File.join(File.dirname(__FILE__), 'hand')

class Table
  attr_accessor :players, :deck, :pot, :to_call, :board, :messages

  state_machine :state, :initial => :waiting do
    event :start_hand do
      transition :waiting => :preflop, :if => :sufficient_players?
    end

    event :player_acted do
      transition all - :waiting => :waiting, :if => lambda { |table| table.players_in_hand.length == 1 }
      transition :preflop => :flop, :flop => :fourth_street, :fourth_street => :river, :river => :waiting,
        :if => :bets_called?
      transition :preflop => :preflop, :flop => :flop, :fourth_street => :fourth_street, :river => :river
    end

    event :abort! do
      transition any => :waiting
    end

    before_transition :waiting => :preflop, :do => :deal_hands
    before_transition :preflop => :flop, :do => :deal_flop
    before_transition :flop => :fourth_street, :fourth_street => :river, :do => :deal_card
    before_transition all - :waiting => :waiting, :do => :finalize_pot, :on => :player_acted
    before_transition all - :waiting => :waiting, :do => :reset, :on => :abort!
  end

  VALID_COMMANDS = ["start_hand", "choose_seat", "unseat_player", "bet", "fold"].freeze
  NUM_PLAYERS = 6
  def initialize
    @players = NUM_PLAYERS.times.map { nil }
    @board = []
    @messages = []
    super # for state_machine gem
  end

  def choose_seat(player, seat)
    return if players.include?(player)
    @messages << "#{player.name} sat at seat #{seat + 1}"
    players[seat] ||= player
  end

  def unseat_player(player, data = nil)
    if seat = players.index(player)
      @messages << "#{player.name} got up from seat #{seat + 1}"
      player.fold!
      players[seat] = nil
    end
  end

  def bet(player, bet)
    bet = bet.to_i
    return unless player.active?
    return if player.chips < bet
    return if to_call.first > bet

    player.chips -= bet
    @pot += bet

    raised_amount = bet - to_call.pop

    if raised_amount > 0
      @messages << "#{player.name} raised to #{bet}"

      # other players might need to see this raise. They're not on the stack if they've previous called,
      # so check how many are in the hand that are not on the stack, ignoring the current player, and add
      # them back
      previously_called_players = players_in_hand.length - to_call.length - 1

      previously_called_players.times { to_call << 0 }
      to_call.map! { |bet| bet + raised_amount }
    else
      if bet > 0
        @messages << "#{player.name} bet #{bet}"
      else
        @messages << "#{player.name} checked"
      end
    end

    player_after(player).active!
    player.resign_active!
    player_acted
  end

  def fold(player, arg = nil)
    return unless player.active?
    @messages << "#{player.name} folded"

    to_call.pop
    player_after(player).active!
    player.fold!
    player_acted
  end

  def handle_command(command, player, data)
    return unless VALID_COMMANDS.include?(command)

    send(command, player, data)
  end

  def deal_hands
    @deck = Deck.new
    @pot = 0
    @board = []

    seated_players = @players.compact
    seated_players.each(&:play!)

    2.times do
      seated_players.each do |player|
        player.cards << @deck.deal!
      end
    end

    @messages << "Starting a new hand"

    setup_round
  end

  def deal_flop
    3.times do
      @board << @deck.deal!
    end

    @messages << "The flop is #{@board.map(&:to_s).join(' ')}"

    setup_round
  end

  def deal_card
    @board << @deck.deal!

    round = @board.length == 4 ? "turn" : "river"

    @messages << "The #{round} is #{@board.last.to_s}"
    setup_round
  end

  def setup_round
    @to_call = players_in_hand.map { 0 }

    players_in_hand.each(&:resign_active!)
    players_in_hand.first.active!
  end

  def finalize_pot
    players_in_hand.each(&:resign_active!)

    if players_in_hand.length > 1
      chips_per_winner = pot / winning_hands.length
      #remainder = pot % winners.length

      winning_hands.each do |winner, hand|
        winner.chips += chips_per_winner
        @messages << "#{winner.name} won #{chips_per_winner} chips with #{hand}"
      end
    else
      winner = players_in_hand.first
      winner.chips += pot
      @messages << "#{winner.name} won #{pot} chips"
    end
  end

  def winning_players
    winning_hands.map { |hand| best_hands[hand] }
  end

  def winning_hands
    winners = {}

    best_hands.each do |player, hand|
      if winners.empty? || hand > winners.values.first
        winners = { player => hand }
      elsif hand == winners.values.first
        winners[player] = hand
      end
    end
    winners
  end

  def best_hands
    players_in_hand.inject({}) do |hands, player|
      available_cards = player.cards + board

      hands[player] = available_cards.combination(5).map { |cards| Hand.new(cards) }.sort.last

      hands
    end
  end

  def bets_called?
    to_call.empty?
  end

  def sufficient_players?
    @players.compact.length > 1
  end

  def reset
    @deck = nil
    @pot = 0
    @to_call = nil
    @board = []
    @players.compact.each(&:fold!)
  end

  def playing?
    !waiting?
  end

  def active_player
    players_in_hand.detect(&:active?)
  end

  def players_in_hand
    players.compact.select(&:playing?)
  end

  def player_after(player)
    next_index = players_in_hand.index(player) + 1

    if next_index < players_in_hand.length
      players_in_hand[next_index]
    else
      players_in_hand[0]
    end
  end

  def as_json(viewer)
    {
      :state => state,
      :players => players.map { |p| p && p.as_json(viewer) },
      :to_call => to_call && to_call.first,
      :board => board.map(&:as_json),
      :pot => pot
    }
  end
end