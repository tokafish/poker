require File.join(File.dirname(__FILE__), '..', 'models', 'table')
require 'rspec'

describe Table do
  let(:table) { Table.new }
  let(:negranu) { Player.new(:name => "Daniel Negranu") }
  let(:hellmuth) { Player.new(:name => "Phil Hellmuth") }
  let(:ivey) { Player.new(:name => "Phil Ivey") }

  describe "upon initialization" do
    subject { table }

    it { should_not be_sufficient_players }
    its(:state) { should == 'waiting' }
    its(:deck) { should be_nil }
    its(:board) { should be_empty }
    its(:messages) { should be_empty }
    its(:active_player) { should be_nil }
    its(:players_in_hand) { should be_empty }

    it "has no seated players" do
      subject.players.all? { |player| player.should be_nil }
    end
  end

  describe "with Daniel Negranu seated" do
    subject do
      table.seat_player(negranu, 0)
      table
    end

    it { should_not be_sufficient_players }
    its(:messages) { should_not be_empty }
    its(:active_player) { should be_nil }
    its(:players_in_hand) { should be_empty }
    its(:seated_players) { should == [negranu] }

    it "does not allow another player to sit in the same position" do
      subject.seat_player(hellmuth, 0)
      subject.seated_players.should == [negranu]
    end

    it "allows another player to sit in a different position" do
      subject.seat_player(hellmuth, 1)
      subject.seated_players.should == [negranu, hellmuth]
    end

    it "does not allow a seated player to sit in a different position" do
      subject.seat_player(negranu, 1)
      subject.seated_players.should == [negranu]
    end
  end

  describe "with Daniel Negranu and Phil Hellmuth seated" do
    subject do
      table.seat_player(negranu, 0)
      table.seat_player(hellmuth, 1)
      table
    end

    it { should be_sufficient_players }
    its(:seated_players) { should == [negranu, hellmuth] }

    it "allows a player to get up" do
      subject.unseat_player(negranu)
      subject.seated_players.should == [hellmuth]
    end

    context "and a hand starts" do
      before do
        subject.start_hand
      end

      its(:state) { should == 'preflop' }
      its(:deck) { should be_kind_of(Deck) }
      its(:board) { should be_empty }
      its(:messages) { should_not be_empty }
      its(:active_player) { should == negranu }
      its(:players_in_hand) { should == [negranu, hellmuth] }
      its(:pot) { should == 0 }

      it "has dealt hole cards to both players" do
        [negranu, hellmuth].each do |player|
          player.cards.length.should == 2
        end
        subject.deck.cards.length.should == 48
      end

      context "and Daniel Negranu bets 50" do
        before do
          subject.bet(negranu, 50)
        end

        its(:pot) { should == 50 }
        its(:active_player) { should == hellmuth }

        it "deducts chips from the bettor" do
          negranu.chips.should == 950
        end

        context "and Phil Hellmuth calls" do
          before do
            subject.bet(hellmuth, 50)
          end

          its(:pot) { should == 100 }
          its(:state) { should == 'flop' }
          its(:active_player) { should == negranu }
          its(:players_in_hand) { should == [negranu, hellmuth] }

          it "should have dealt 3 cards to the board" do
            table.board.length.should == 3
            subject.deck.cards.length.should == 45
          end
        end

        context "and Phil Hellmuth folds" do
          before do
            subject.fold(hellmuth)
          end

          its(:pot) { should == 0 }
          its(:state) { should == "waiting" }
          it "awards the pot to the winner" do
            negranu.chips.should == 1000
          end
        end
      end

      context "and Phil Ivey sits down" do
        before do
          subject.seat_player(ivey, 2)
        end

        its(:seated_players) { should == [negranu, hellmuth, ivey] }
        its(:players_in_hand) { should == [negranu, hellmuth] }
      end
    end
  end
end