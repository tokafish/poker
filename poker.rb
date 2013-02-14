class Card
  attr_accessor :suit, :rank

  RANKS = {
    "A" => 14,
    "K" => 13,
    "Q" => 12,
    "J" => 11,
    "T" => 10
  }

  def initialize(str)
    rank, suit = str.split("")

    @suit = suit
    @rank = RANKS[rank] || rank.to_i
  end

  def <=>(card)
    card.rank <=> rank
  end

  def as_low_ace
    if rank == 14
      c = self.dup
      c.rank = 1
      c
    else
      self
    end
  end

  def to_s
    (RANKS.invert[rank] || rank.to_s) + suit
  end
end

class Hand
  include Comparable

  attr_reader :cards

  RANKINGS = [:royal_flush, :straight_flush, :four_of_a_kind,
             :full_house, :flush, :straight, :three_of_a_kind,
             :two_pair, :one_pair, :high_card]

  def initialize(str = "")
    @cards = str.split(" ").map { |s| Card.new(s) }
  end

  def royal_flush?
    flush? && straight? && kickers.first.rank == 14
  end

  def straight_flush?
    flush? && straight?
  end

  def flush?
    cards.map(&:suit).uniq.length == 1
  end

  def straight?
    high_ace_straight? || low_ace_straight?
  end

  def four_of_a_kind?
    num_groups == 1 && group_lengths == [4]
  end

  def full_house?
    num_groups == 2 && group_lengths == [3,2]
  end

  def three_of_a_kind?
    num_groups == 1 && group_lengths == [3]
  end

  def two_pair?
    num_groups == 2 && group_lengths == [2,2]
  end

  def one_pair?
    num_groups == 1 && group_lengths == [2]
  end

  def paired_hand?
    num_groups > 0
  end

  def high_card?
    true
  end

  def kickers
    if low_ace_straight?
      cards.map(&:as_low_ace).sort
    elsif full_house?
      rank_grouped.flatten
    elsif paired_hand?
      sorted_pairs = rank_grouped.flatten.sort
      sorted_pairs << (cards - sorted_pairs)
    else
      cards.sort
    end
  end

  def <=>(hand)
    # lower indexes are better, so the comparison is swapped
    comparison = RANKINGS.index(hand.rank) <=> RANKINGS.index(self.rank)
    comparison = hand.kickers <=> self.kickers if comparison == 0
    comparison
  end

  def rank
    RANKINGS.detect do |rank|
      self.send("#{rank}?")
    end
  end

  def to_s
    cards.sort.map(&:to_s).join(" ")
  end

  private

  def high_ace_straight?
    cards.sort.map(&:rank).each_cons(2).all? { |first, second| first - second == 1 }
  end

  def low_ace_straight?
    cards.map(&:as_low_ace).sort.map(&:rank).each_cons(2).all? { |first, second| first - second == 1 }
  end

  def num_groups
    rank_grouped.length
  end

  def group_lengths
    rank_grouped.map(&:length)
  end

  def rank_grouped
    cards.group_by(&:rank).reject { |rank, cards| cards.length == 1 }.values.sort do |group1, group2|
      group2.length <=> group1.length
    end
  end
end

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

