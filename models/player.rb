require 'uuid'

class Player
  attr_accessor :id, :name, :hand

  def initialize(opts = {})
    @name = opts[:name]
    @id = UUID.generate :compact
  end

  def as_json(viewer)
    attributes = { :id => id, :name => name }
    attributes[:hand] = @hand && @hand.as_json if viewer.id == id
    attributes
  end
end
