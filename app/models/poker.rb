require File.join(File.dirname(__FILE__), 'deck')
require File.join(File.dirname(__FILE__), 'hand')

class Poker
  class << self

    def play!(players = 2)
      raise "Can't deal to more than 10 players!" if players > 10
      raise "Need at least two players!" if players < 2
      deck = Deck.new

      hands = players.times.map { Hand.new }

      5.times do
        hands.each do |hand|
          hand.cards << deck.deal!
        end
      end

      hands.sort!.reverse!

      winners = [hands.shift]
      losers = []

      hands.each do |hand|
        if winners.first == hand
          winners << hand
        else
          losers << hand
        end
      end

      winners.each do |hand|
        puts "#{hand} - #{hand.rank} (winner)"
      end
      losers.each do |hand|
        puts "#{hand} - #{hand.rank} (loser)"
      end

      winners
    end

  end
end

