require File.join(File.dirname(__FILE__), '..', 'models', 'player')
require File.join(File.dirname(__FILE__), '..', 'models', 'deck')
require 'rspec'

describe Player do
  let(:player) { Player.new :name => "Joe" }
  let(:json) { player.as_json }

  describe "json representation" do

    it "includes the player's id, state, chips, and name" do
      [:id, :state, :chips, :name].each do |field|
        json[field].should == player.send(field)
      end
    end

    it "does not include the player's cards when there are none" do
      json[:cards].should be_nil
    end

    context "when the player has been dealt a hand" do
      before do
        deck = Deck.new
        4.times { player.cards << deck.deal! }
      end

      it "includes a nil (hidden) card for each card in the player's hand" do
        json[:cards].should == [nil, nil, nil, nil]
      end

      it "includes actual cards when requested" do
        player.as_json(true)[:cards].should == player.cards.map(&:as_json)
      end

    end
  end
end