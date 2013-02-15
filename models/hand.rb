require File.join(File.dirname(__FILE__), 'card')

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

  def as_json
    cards.map(&:as_json)
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