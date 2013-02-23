require File.join(File.dirname(__FILE__), '..', 'models', 'table')
require 'rspec'

describe Table do
  subject(:table) { Table.new }
  let(:negranu) { Player.new(:name => "Daniel Negranu") }
  let(:hellmuth) { Player.new(:name => "Phil Hellmuth") }
  let(:ivey) { Player.new(:name => "Phil Ivey") }
  let(:men) { Player.new(:name => "Men Nguyen") }

  describe "upon initialization" do
    it { should_not be_sufficient_players }
    its(:state) { should == 'waiting' }
    its(:deck) { should be_nil }
    its(:board) { should be_empty }
    its(:messages) { should be_empty }
    its(:active_player) { should be_nil }
    its(:players_in_hand) { should be_empty }

    it "has no seated players" do
      table.players.all? { |player| player.should be_nil }
    end
  end

  describe "with one player seated" do
    before do
      table.seat_player(negranu, 0)
    end

    it { should_not be_sufficient_players }
    its(:messages) { should_not be_empty }
    its(:active_player) { should be_nil }
    its(:players_in_hand) { should be_empty }
    its(:seated_players) { should == [negranu] }

    it "does not allow another player to sit in the same position" do
      table.seat_player(hellmuth, 0)
      table.seated_players.should == [negranu]
    end

    it "allows another player to sit in a different position" do
      table.seat_player(hellmuth, 1)
      table.seated_players.should == [negranu, hellmuth]
    end

    it "does not allow a seated player to sit in a different position" do
      table.seat_player(negranu, 1)
      table.seated_players.should == [negranu]
    end
  end

  describe "with two players seated" do
    before do
      table.seat_player(negranu, 0)
      table.seat_player(hellmuth, 1)
    end

    it { should be_sufficient_players }
    its(:seated_players) { should == [negranu, hellmuth] }

    it "allows a player to get up" do
      table.unseat_player(negranu)
      table.seated_players.should == [hellmuth]
    end
  end

  describe "starting a hand" do
    before do
      table.seat_player(negranu, 0)
      table.seat_player(hellmuth, 1)
      table.seat_player(ivey, 2)
      table.start_hand
    end

    its(:state) { should == 'preflop' }
    its(:deck) { should be_kind_of(Deck) }
    its(:board) { should be_empty }
    its(:messages) { should_not be_empty }
    its(:active_player) { should == negranu }
    its(:players_in_hand) { should == [negranu, hellmuth, ivey] }
    its(:pot) { should == 0 }
    its(:to_call) { should == [0,0,0] }

    it "has dealt hole cards to both players" do
      [negranu, hellmuth, ivey].each do |player|
        player.cards.length.should == 2
      end
      table.deck.cards.length.should == 46
    end

    context "and the first player bets 50" do
      before do
        table.bet(negranu, 50)
      end

      its(:pot) { should == 50 }
      its(:active_player) { should == hellmuth }
      its(:to_call) { should == [50, 50] }
      it "deducts chips from the bettor" do
        negranu.chips.should == 950
      end

      context "and the second player calls" do
        before do
          table.bet(hellmuth, 50)
        end

        its(:pot) { should == 100 }
        its(:state) { should == 'preflop' }
        its(:active_player) { should == ivey }
        its(:players_in_hand) { should == [negranu, hellmuth, ivey] }
        its(:to_call) { should == [50] }

        context "and the final player calls" do
          before do
            table.bet(ivey, 50)
          end

          its(:pot) { should == 150 }
          its(:state) { should == 'flop' }
          its(:active_player) { should == negranu }
          its(:to_call) { should == [0,0,0] }

          it "should have dealt 3 cards to the board" do
            table.board.length.should == 3
            table.deck.cards.length.should == 43
          end
        end
      end

      context "and the second player folds" do
        before do
          table.fold(hellmuth)
        end

        its(:pot) { should == 50 }
        its(:state) { should == "preflop" }
        its(:active_player) { should == ivey }
        its(:players_in_hand) { should == [negranu, ivey] }
        its(:to_call) { should == [50] }
      end
    end

    context "and a new player sits down" do
      before do
        table.seat_player(men, 3)
      end

      its(:seated_players) { should == [negranu, hellmuth, ivey, men] }
      its(:players_in_hand) { should == [negranu, hellmuth, ivey] }
    end
  end

end