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

  def as_json
    { :rank => rank, :suit => suit }
  end
end