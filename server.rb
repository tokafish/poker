require 'em-websocket'
require 'yajl'
require 'yajl/json_gem'
require File.join(File.dirname(__FILE__), 'models', 'poker_room')

class PokerRoomConnection
  attr_accessor :player, :websocket

  def initialize(player, websocket)
    @player = player
    @websocket = websocket
  end

  def send_message(msg)
    @websocket.send(msg.to_json)
  end
end

class PokerRoomManager
  def initialize
    @connections = {}
    @room = PokerRoom.new
  end

  def start
    EM::WebSocket.run(:host => "0.0.0.0", :port => 9293) do |ws|
      ws.onopen { |handshake| player_connected!(ws, handshake) }
      ws.onclose { player_disconnected!(ws) }
      ws.onmessage { |msg| message_received!(ws, msg) }
    end
  end

  def player_connected!(ws, handshake)
    player = @room.add_player(handshake.query["name"])
    connection = PokerRoomConnection.new(player, ws)
    @connections[ws] = connection

    update_poker_room
  end

  def player_disconnected!(ws)
    connection = @connections.delete(ws)
    @room.remove_player(connection.player)

    if @room.playing?
      @room.cancel_hand
    end

    update_poker_room
  end

  def message_received!(ws, json)
    msg  = JSON.parse(json)

    @room.handle_command msg["command"], msg["data"]

    puts @room.inspect
    update_poker_room
  end

  def update_poker_room
    @connections.values.each do |connection|
      connection.send_message :command => :update_poker_room, :data => @room.as_json(connection.player)
    end
  end
end

EM.run do
 PokerRoomManager.new.start
end
