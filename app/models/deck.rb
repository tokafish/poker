require File.join(File.dirname(__FILE__), 'card')

class Deck
  attr_accessor :cards

  def initialize
    @cards = []
    %w{h d c s}.each do |suit|
      %w{2 3 4 5 6 7 8 9 T J Q K A}.each do |rank|
        @cards << Card.new(rank + suit)
      end
    end
    shuffle!
  end

  def shuffle!
    cards.shuffle!
  end

  def deal!
    cards.pop
  end
end
