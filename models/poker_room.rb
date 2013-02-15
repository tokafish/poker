require File.join(File.dirname(__FILE__), 'player')
require File.join(File.dirname(__FILE__), 'deck')
require File.join(File.dirname(__FILE__), 'hand')

class PokerRoom
  attr_accessor :players, :state, :deck, :active_player_id

  VALID_COMMANDS = ["start_hand", "cancel_hand"].freeze

  def initialize
    @players = []
    @state = "waiting"
  end

  def add_player(name)
    Player.new(:name => name).tap { |player| @players << player }
  end

  def remove_player(player)
    @players.delete(player)
  end

  def handle_command(command, data)
    return unless VALID_COMMANDS.include?(command)

    send(command, data)
  end

  def start_hand(*args)
    return unless waiting?
    deal!

    @active_player_id = @players.first.id

    @state = "draw"
  end

  def cancel_hand(*args)
    @deck = nil
    @active_player_id = nil
    @state = "waiting"

    @players.each { |p| p.hand = nil }
  end

  def deal!
    @deck = Deck.new

    @players.each { |player| player.hand = Hand.new }
    5.times do
      @players.each do |player|
        player.hand.cards << @deck.deal!
      end
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
      :players => players.map { |p| p.as_json(viewer) },
      :active_player_id => active_player_id,
      :current_player_id => viewer.id
    }
  end
end