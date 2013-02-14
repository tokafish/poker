require './poker'
require 'rspec'

describe Hand do
  subject { Hand.new(cards) }

  RANKED_HANDS = {
    :royal_flush => "Th Qh Jh Kh Ah",
    :straight_flush => "Th 9h Jh Qh 8h",
    :flush => "Th 9h Jh Qh 7h",
    :straight => "Jh Td Qs Ks 9h",
    :four_of_a_kind => "Th Ts Td Tc 8h",
    :full_house => "Th Ts Tc Qh Qd",
    :three_of_a_kind => "Th Ts Td 7c 8h",
    :two_pair => "Th Ts Jd 8c 8h",
    :one_pair => "Th Ts Jd 6c 8h"
  }

  RANKED_HANDS.each do |name, cards|
    let(name) { Hand.new(cards) }
  end

  describe "royal flushes" do
    subject { royal_flush }

    it { should be_royal_flush }
    it { should be_straight_flush }
    it { should be_straight }
    it { should be_flush }
    it { should_not be_four_of_a_kind }
    it { should_not be_full_house }
    it { should_not be_three_of_a_kind }
    it { should_not be_two_pair }
    it { should_not be_one_pair }

    its(:rank) { should == :royal_flush }

    [:straight_flush, :flush, :straight, :four_of_a_kind, :full_house, :three_of_a_kind, :two_pair, :one_pair].each do |hand|
      it "beat a #{hand}" do
        subject.should be > send(hand)
      end
    end
  end

  describe "straight flushes" do
    subject { straight_flush }

    it { should_not be_royal_flush }
    it { should be_straight_flush }
    it { should be_straight }
    it { should be_flush }
    it { should_not be_four_of_a_kind }
    it { should_not be_full_house }
    it { should_not be_three_of_a_kind }
    it { should_not be_two_pair }
    it { should_not be_one_pair }

    its(:rank) { should == :straight_flush }

    it "loses to a royal flush" do
      subject.should be < royal_flush
    end
    [:flush, :straight, :four_of_a_kind, :full_house, :three_of_a_kind, :two_pair, :one_pair].each do |hand|
      it "beat a #{hand}" do
        subject.should be > send(hand)
      end
    end
  end

  other_hands = [:four_of_a_kind, :full_house, :flush, :straight, :three_of_a_kind, :two_pair, :one_pair]

  other_hands.each do |hand|
    describe hand.to_s do
      subject { send(hand) }

      RANKED_HANDS.each do |hand_name, cards|
        if hand == hand_name
          it { should send("be_#{hand_name}") }
        else
          it { should_not send("be_#{hand_name}") }
        end
      end

      it "loses to a royal flush" do
        subject.should be < royal_flush
      end

      it "loses to a straight flush" do
        subject.should be < straight_flush
      end

      hand_index = other_hands.index(hand)

      other_hands.slice(0, hand_index).each do |winning_hand|
        it "loses to a #{winning_hand}" do
          subject.should be < send(winning_hand)
        end
      end

      other_hands.slice(hand_index + 1, other_hands.length - hand_index).each do |losing_hand|
        it "beats a #{losing_hand}" do
          subject.should be > send(losing_hand)
        end
      end
    end
  end

  describe "straights with ace low" do
    subject { Hand.new("Ah 3c 4d 5s 2c") }

    it { should be_straight }
    its(:rank) { should == :straight }
  end

  describe "tie breaking" do
    describe "for straights" do
      it "is done by highest card" do
        Hand.new("2s 3d 4s 5c 6h").should be < Hand.new("3c 4d 5s 6d 7h")
      end

      it "counts aces as low when the straight is a wheel" do
        Hand.new("2s 3d 4s 5c Ah").should be < Hand.new("3c 4d 5s 6d 7h")
      end

      describe "for flushes" do
        it "is done by the highest card" do
          Hand.new("As Ks 4s 5s 6s").should be < Hand.new("Ac Kc Qc 6c 7c")
        end
      end

      describe "for four of a kind" do
        it "is done by the rank of the quads" do
          Hand.new("Ks Kd Kc Kh 6s").should be > Hand.new("Qs Qd Qc Qh Ad")
        end

        it "is done secondarily by the kicker" do
          Hand.new("Ks Kd Kc Kh 6s").should be > Hand.new("Ks Kd Kc Kh 4s")
        end
      end

      describe "for full houses" do
        it "is done by the rank of the trips primarily" do
          Hand.new("Ks Kd Kc Qh Qs").should be > Hand.new("Js Jd Jc Ah Ad")
        end

        it "is done secondarily by the rank of the pair" do
          Hand.new("Ks Kd Kc Qh Qs").should be > Hand.new("Ks Kd Kc Jh Js")
        end
      end

      describe "for trips" do
        it "is done by the rank of the trips primarily" do
          Hand.new("Ks Kd Kc Qh Js").should be > Hand.new("Js Jd Jc Ah Kd")
        end

        it "is done secondarily by the rank of the kickers" do
          Hand.new("Ks Kd Kc Qh Js").should be > Hand.new("Ks Kd Kc Qh Ts")
        end

      end

    end

  end
end
