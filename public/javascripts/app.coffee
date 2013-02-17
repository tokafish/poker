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

  $scope.connect = -> PokerService.connect $scope.myName

  $scope.playerClass = (player) ->
    ''
    # if player.id == $scope.table.active_player_id then 'active' else ''

  $scope.drawText = ->
    return "" unless $scope.table.state == 'draw'
    return "" unless $scope.current_player.state == "active"

    anyCardSelected = _($scope.current_player.hand).some (card) ->
      card.selected

    if anyCardSelected
      "Draw!"
    else
      "Stand Pat!"

  $scope.cardClicked = (card) ->
    card.selected = !card.selected

  $scope.cardTemplate = (card) ->
    "/cards/#{card.rank}.html"

  $scope.cardImage = (card) ->
    "/img/faces/#{card.rank}/#{card.suit}.png"

  $scope.cardClass = (card) ->
    switch card.suit
      when "c"
        "club"
      when "h"
        "heart"
      when "d"
        "diamond"
      when "s"
        "spade"

  $scope.cardRank = (card) ->
    switch card.rank
      when 11
        "J"
      when 12
        "Q"
      when 13
        "K"
      when 14
        "A"
      else
        card.rank

  $scope.cardSuit = (card) ->
    switch card.suit
      when "h"
        "&hearts;"
      when "s"
        "&spades;"
      when "c"
        "&clubs;"
      when "d"
        "&diams;"

  $scope.tableStatus = ->
    switch $scope.table.state
      when "waiting"
        "Waiting for hand to begin"
      when "draw"
        "Waiting for #{$scope.activePlayer.name} to draw"

  $scope.seatedPlayers = ->
    _($scope.table.players).compact()

  $scope.sendCommand = (command, data) ->
    PokerService.sendCommand
      command: command
      data: data

  $scope.$on "update_poker_room", (e, room) ->
    $scope.players = room.players
    $scope.table = room.table
    $scope.current_player = room.current_player

controller.$inject = ['$scope', 'PokerService']

@app.controller 'pokerController', controller
