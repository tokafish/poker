require File.join(File.dirname(__FILE__), 'player')
require File.join(File.dirname(__FILE__), 'deck')
require File.join(File.dirname(__FILE__), 'hand')

class Table
  attr_accessor :players, :state, :deck

  VALID_COMMANDS = ["start_hand", "choose_seat", "unseat_player"].freeze

  def initialize
    @players = (1..6).map { nil }
    @state = "waiting"
  end

  def choose_seat(player, seat)
    return if @players.include?(player)

    @players[seat] ||= player
  end

  def unseat_player(player, data = nil)
    if seat = @players.index(player)
      @players[seat] = nil
    end
  end

  def handle_command(command, player, data)
    return unless VALID_COMMANDS.include?(command)

    send(command, player, data)
  end

  def start_hand(player, data = nil)
    return unless waiting?
    @state = "draw"
    @deck = Deck.new

    players = @players.compact

    players.each do |player|
      player.hand = Hand.new
      player.state = "playing"
    end

    5.times do
      players.each do |player|
        player.hand.cards << @deck.deal!
      end
    end

    players.first.state = "active"
  end

  def cancel_hand
    @deck = nil
    @state = "waiting"

    @players.compact.each do |player|
      player.hand = nil
      player.state = "waiting"
    end
  end

  def waiting?
    @state == "waiting"
  end

  def playing?
    !waiting?
  end

  def as_json(viewer)
    {
      :state => state,
      :players => players.map { |p| p && p.as_json(viewer) }
    }
  end
end