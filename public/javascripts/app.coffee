@app = angular.module('poker', ['ngSanitize'])

@app.service 'PokerService',
  class PokerService
    @$inject: ['$rootScope']

    constructor: (@$rootScope) ->
      @connected = false

    connect: (playerName) ->
      return if @connected
      @socket = new WebSocket("ws://localhost:9293/?name=#{playerName}");
      @socket.onopen = =>
        @connected = true

      @socket.onmessage = (mess) =>
        @handleMessage(mess)

    sendCommand: (message) ->
      console.log "sending command:", message
      @socket.send JSON.stringify(message)

    handleMessage: (message) ->
      if message?.data
        json = JSON.parse message.data
        console.log "received message:", json
        @$rootScope.$apply =>
          @$rootScope.$broadcast json["command"], json["data"]


controller = ($scope, PokerService) ->
  $scope.table = {}
  $scope.current_player = null
  $scope.messages = []

  $scope.connect = -> PokerService.connect $scope.myName

  $scope.seatClass = (player) ->
    if !player?
      "unoccupied"
    else if player.state == "active"
      "active"
    else
      ""

  betToMe = -> $scope.table?.to_call != 0

  $scope.callText = ->
    if betToMe() then "Call" else "Check"

  $scope.betText = ->
    if betToMe() then "Raise" else "Bet"

  $scope.handleBet = ->
    bet = parseInt($scope.numChips)
    if betToMe()
       bet += $scope.table.to_call

    $scope.sendCommand('bet', bet)
    $scope.numChips = ''

  $scope.playerHand = (player) ->
    return [] if !player?
    player.cards

  $scope.cardTemplate = (card) ->
    template = card?.rank || "back"
    "/cards/#{template}.html"

  $scope.cardImage = (card) ->
    "/img/faces/#{card.rank}/#{card.suit}.png"

  $scope.cardClass = (card) ->
    switch card?.suit
      when "c" then "club"
      when "h" then "heart"
      when "d" then "diamond"
      when "s" then "spade"
      else "back"

  $scope.cardRank = (card) ->
    switch card.rank
      when 11 then "J"
      when 12 then "Q"
      when 13 then"K"
      when 14 then "A"
      else card.rank

  $scope.cardSuit = (card) ->
    switch card.suit
      when "h" then "&hearts;"
      when "s" then "&spades;"
      when "c" then "&clubs;"
      when "d" then   "&diams;"

  $scope.tableStatus = ->
    return unless $scope.table.state

    if $scope.table.state == "waiting"
      "Waiting to start..."
    else if $scope.current_player?.state == "active"
      "Your action"
    else
      activePlayer = _($scope.seatedPlayers()).detect (player) -> player.state == 'active'
      "#{activePlayer.name}'s action"

  $scope.seatedPlayers = ->
    _($scope.table.players).compact()

  $scope.sendCommand = (command, data) ->
    PokerService.sendCommand
      command: command
      data: data

  $scope.$watch 'table.state', (newState, previousState) ->
    if previousState == 'waiting'
      $scope.messages.length = 0

  $scope.$on "update_poker_room", (e, room) ->
    $scope.players = room.players
    $scope.table = room.table
    $scope.current_player = room.current_player

  $scope.$on "broadcast_message", (e, message) ->
    $scope.messages.push message

controller.$inject = ['$scope', 'PokerService']

@app.controller 'pokerController', controller
