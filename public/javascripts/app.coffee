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

    sendMessage: (message) ->
      console.log "sending message:", message
      @socket.send JSON.stringify(message)

    handleMessage: (message) ->
      if message?.data
        json = JSON.parse message.data
        console.log "received message:", json
        @$rootScope.$apply =>
          @$rootScope.$broadcast json["command"], json["data"]


controller = ($scope, PokerService) ->
  $scope.room = {}
  $scope.current_player = null
  $scope.active_player = null

  $scope.connect = -> PokerService.connect $scope.myName

  $scope.playerClass = (player) ->
    if player.id == $scope.room.active_player_id then 'active' else ''

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

  $scope.roomStatus = ->
    switch $scope.room.state
      when "waiting"
        "Waiting for hand to begin"
      when "draw"
        "Waiting for #{$scope.activePlayer.name} to draw"

  $scope.sendCommand = (command) ->
    PokerService.sendMessage command: command

  $scope.$on "update_poker_room", (e, room) ->
    $scope.room = room
    $scope.current_player = _($scope.room.players).find (player) ->
      player.id == $scope.room.current_player_id
    $scope.active_player = _($scope.room.players).find (player) ->
      player.id == $scope.room.active_player_id

controller.$inject = ['$scope', 'PokerService']

@app.controller 'pokerController', controller
