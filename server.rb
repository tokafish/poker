$stdout.sync = true

require 'em-websocket'
require 'yajl'
require 'yajl/json_gem'
require File.join(File.dirname(__FILE__), 'models', 'table')

class PokerConnection
  attr_accessor :player, :websocket

  def initialize(player, websocket)
    @player = player
    @websocket = websocket
  end

  def send_message(msg)
    @websocket.send(msg.to_json)
  end
end

class PokerRoom
  def initialize
    @connections = {}
    @table = Table.new
  end

  def start
    EM::WebSocket.run(:host => "0.0.0.0", :port => 9293) do |ws|
      ws.onopen { |handshake| player_connected!(ws, handshake) }
      ws.onclose { player_disconnected!(ws) }
      ws.onmessage { |msg| message_received!(ws, msg) }
    end
  end

  def player_connected!(ws, handshake)
    player = Player.new(:name => handshake.query["name"])
    connection = PokerConnection.new(player, ws)
    @connections[ws] = connection

    update_poker_room
  end

  def player_disconnected!(ws)
    connection = @connections.delete(ws)
    @table.unseat_player(connection.player)

    if @table.playing?
      @table.abort!
    end

    update_poker_room
  end

  def message_received!(ws, json)
    msg  = JSON.parse(json)

    player = @connections[ws].player

    @table.handle_command msg["command"], player, msg["data"]

    update_poker_room
  end

  def update_poker_room
    @connections.values.each do |connection|
      connection.send_message :command => :update_poker_room, :data => as_json(connection.player)
    end
    broadcast_messages
  end

  def broadcast_messages
    @connections.values.each do |connection|
      @table.messages.each do |message|
        connection.send_message :command => :broadcast_message, :data => message
      end
    end
    @table.messages.clear
  end

  def connected_players
    @connections.values.map(&:player)
  end

  def as_json(viewer)
    {
      :players => connected_players.map { |p| p.as_json },
      :table => @table.as_json(viewer),
      :current_player => viewer.as_json(viewer)
    }
  end
end

EM.run do
  PokerRoom.new.start
end
