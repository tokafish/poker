require 'uuid'

class Player
  attr_accessor :id, :name, :hand, :state

  def initialize(opts = {})
    @name = opts[:name]
    @id = UUID.generate :compact
    @state = "waiting"
  end

  def as_json(viewer)
    attributes = { :id => id, :name => name, :state => state }
    attributes[:hand] = @hand && @hand.as_json if viewer.id == id
    attributes
  end
end
