require 'uuid'

class Player
  attr_accessor :id, :name, :cards, :state, :chips

  def initialize(opts = {})
    @name = opts[:name]
    @id = UUID.generate :compact
    @state = "waiting"
    @cards = []
    @chips = 1000
  end

  def playing?
    !cards.empty?
  end

  def active?
    @state == "active"
  end

  def active!
    @state = "active"
  end

  def resign_active!
    @state = "playing"
  end

  def fold!
    @cards = []
    @state = "waiting"
  end

  def play!
    @cards = []
    @state = "playing"
  end

  def to_s
    name
  end

  def as_json(viewer)
    attributes = { :id => id, :name => name, :state => state, :chips => chips }

    if playing?
      attributes[:cards] = if viewer.id == id
        cards && cards.map(&:as_json)
      else
        cards && cards.map { nil }
      end
    end

    attributes
  end
end
