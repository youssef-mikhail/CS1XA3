from django.shortcuts import render
from django.http import HttpResponse, HttpResponseBadRequest, HttpResponseNotFound, HttpResponseServerError, HttpResponseForbidden
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
from .models import BattleshipSession
import json
from django.http import JsonResponse

rootUrl = "https://mac1xa3.ca/e/mikhaily/"


#Returns session info as JSON
def getSessionInfo(request):
    #check that the session exists and that the user is logged in
    parameters = request.GET
    gameID = int(parameters.get("gameid", "0"))

    if not request.user.is_authenticated:
        return HttpResponseForbidden("You are not logged in")

    #Return a 400 status if a game ID is not specified. This is a required field
    if gameID == 0:
        return HttpResponseBadRequest("NoGameID")

    session = None

    #try to get the session with the appropriate game ID
    try:
        session = BattleshipSession.objects.get(id=gameID)
    except BattleshipSession.DoesNotExist:
        return HttpResponseNotFound("Error: This game ID does not exist")

    if session == None:
        return HttpResponseServerError("An unknown error occurred")

    #Get session info to return to the user
    sessionInfo = {
        "opponentName" : "",
        "sessionDescription" : ""
    }


    if session.waitingForPlayer:
        if not request.user == session.player1:
            sessionInfo["opponentName"] = session.player2.username
    else:
        if request.user == session.player1:
            sessionInfo["opponentName"] = session.player2.username
        else:
            sessionInfo["opponentName"] = session.player1.username
        
    
    sessionDescription = ""

    if session.waitingForPlayer:
        sessionDescription = "Waiting for player to join"
    else:
        sessionDescription = str(session)
    
    sessionInfo["sessionDescription"] = sessionDescription
    return JsonResponse(sessionInfo)

#Get and parse a player's move
def submitMove(request):
    parameters = request.GET
    gameID = int(parameters.get("gameid", "0"))
    body = request.POST
    move = body.get("move","")

    if gameID == 0:
        return HttpResponseBadRequest("No GameID was specified")

    session = None

    try:
        session = BattleshipSession.objects.get(id=gameID)
    except BattleshipSession.DoesNotExist:
        return HttpResponseNotFound("Error: This game ID does not exist")
    
    if session == None:
        return HttpResponseServerError("An unknown error has occured")
    
    #Make sure the user is actually in the game
    if not (request.user == session.player1 or request.user == session.player2):
        return HttpResponseForbidden("Error: You are not a part of this game")
    
    #make sure it is the user's turn
    if not request.user == session.currentTurn:
        return HttpResponse("It is not your turn!")

    #Switch turns if the missile missed
    didHit = session.add_missile(move, request.user)
    if not didHit:
        session.switch_player_turns()
    if session.player1LiveShips == "":
        session.gameWinner = session.player2.username
    elif session.player2LiveShips == "":
        session.gameWinner = session.player1.username
    session.save()
    if session.gameWinner == request.user.username:
        return HttpResponse("Win")
    elif session.gameWinner != "":
        return HttpResponse("Lose")

    #Return a hit response or a miss response depending on if the missile hit
    if didHit:
        return HttpResponse("Hit")
    else:
        return HttpResponse("Miss")

    

#Send updated game state to the client in JSON
def updateGameState(request):
    #Get game ID and get its corresponding session
    parameters = request.GET
    gameID = int(parameters.get("gameid", "0"))

    if gameID == 0:
        return HttpResponse("Error: No gameID was specified")
    
    session = None

    try:
        session = BattleshipSession.objects.get(id=gameID)
    except BattleshipSession.DoesNotExist:
        return HttpResponseNotFound("Error: This game ID does not exist")
    
    if session == None:
        return HttpResponse("An unknown error has occured")
    
    #Send a 403 if user is not in the session
    if not (request.user == session.player1 or request.user == session.player2):
        return HttpResponseForbidden("Error: You are not a part of this game")
    

    
    #Initialize all of the data to be sent to the client
    playerShips = []
    opponentSunkShips = []
    playerMissedMissiles = []
    playerHitMissiles = []
    opponentHitMissiles = []
    opponentMissedMissiles = []
    isPlayerTurn = (session.currentTurn == request.user) and not session.waitingForPlayer and session.gameWinner == ""

    #Send the appropriate data for player 1 and player 2
    if request.user == session.player1:
        playerShips = session.player1LiveShips.split(",")
        playerSunkShips = session.player1SunkShips.split(",")
        opponentSunkShips = session.player2SunkShips.split(",")
        playerMissedMissiles = session.player1MissedMissiles.split(",")
        playerHitMissiles = session.player1HitMissiles.split(",")
        opponentHitMissiles = session.player2HitMissiles.split(",")
        opponentMissedMissiles = session.player2MissedMissiles.split(",")
        
    else:
        playerShips = session.player2LiveShips.split(",")
        playerSunkShips = session.player2SunkShips.split(",")
        opponentSunkShips = session.player1SunkShips.split(",")
        playerMissedMissiles = session.player2MissedMissiles.split(",")
        playerHitMissiles = session.player2HitMissiles.split(",")
        opponentHitMissiles = session.player1HitMissiles.split(",")
        opponentMissedMissiles = session.player1MissedMissiles.split(",")
    
    #replace any data containing a list with one empty string with an empty list
    playerShips = [] if playerShips == [""] else playerShips
    playerSunkShips = [] if playerSunkShips == [""] else playerSunkShips
    opponentSunkShips = [] if opponentSunkShips == [""] else opponentSunkShips
    playerMissedMissiles = [] if playerMissedMissiles == [""] else playerMissedMissiles
    playerHitMissiles = [] if playerHitMissiles == [""] else playerHitMissiles
    opponentHitMissiles = [] if opponentHitMissiles == [""] else opponentHitMissiles
    opponentMissedMissiles = [] if opponentMissedMissiles == [""] else opponentMissedMissiles

    #Put all of the data obtained above in a dictionary
    gameData = {
        "playerShips" : playerShips,
        "playerSunkShips" : playerSunkShips,
        "opponentSunkShips" : opponentSunkShips,
        "playerMissedMissiles" : playerMissedMissiles,
        "playerHitMissiles" : playerHitMissiles,
        "opponentHitMissiles" : opponentHitMissiles,
        "opponentMissedMissiles" : opponentMissedMissiles,
        "isPlayerTurn" : isPlayerTurn,
        "gameWinner" : session.gameWinner
    }
    
    #Return dictionary as JSON
    return JsonResponse(gameData)
    

#Create and initialize a new game session
def startgame(request):
    data = json.loads(request.body)
    if not request.user.is_authenticated:
        return HttpResponseForbidden("Not logged in")
    
    newSession = BattleshipSession.objects.create_session(request.user, data["ships"])
    newSession.save()
    #Send the new game ID to the client
    response = {"gameid" : newSession.id}
    return JsonResponse(response)


#Get a list of all available sessions for a user
def getGames(request):
    if not request.user.is_authenticated:
        return HttpResponseForbidden("NotLoggedIn")
    
    #Get a list of all available sessions for a user
    sessions = BattleshipSession.objects.getSessionsForUser(request.user)


    sessionData = {"urls" : [], "descriptions" : []}

    #Personalize each URL and description depending on who the user is
    for session in sessions:
        if session.waitingForPlayer and request.user != session.player1:
            sessionData["urls"].append("creategrid.html?gameid=" + str(session.id))
            sessionData["descriptions"].append(str(session))

        elif session.waitingForPlayer:
            sessionData["urls"].append("game.html?gameid=" + str(session.id))
            sessionData["descriptions"].append("Waiting for player to join your game")
        else:
            sessionData["urls"].append("game.html?gameid=" + str(session.id))
            sessionData["descriptions"].append(str(session))
    
    #Return descriptions and URLs
    return JsonResponse(sessionData)
    

#Join an existing game that is accepting players
def joinGame(request):
    if not request.user.is_authenticated:
        return HttpResponseForbidden("Error: Not logged in. Please log in and try again")
    
    #Get game ID
    parameters = request.GET
    gameID = int(parameters.get("gameid", "0"))
    if gameID == 0:
        return HttpResponse("Error: Game ID not specified")

    #Get ships from request body
    ships = json.loads(request.body)

    #Return a 400 if no ships were sent in the request body
    if ships == "":
        return HttpResponseBadRequest("Error: No game data was specified")
    session = None

    try:
        session = BattleshipSession.objects.get(id=gameID)
    except BattleshipSession.DoesNotExist:
        return HttpResponse("Error: This game ID does not exist")

    if session == None:
        return HttpResponse("An unknown error occured")

    response = {"gameid" : session.id}
    
    #Make sure the game is accepting a new player before adding the player to it
    #If the player is already in the session and wants to join themselves for some
    #reason, just redirect that silly rascal to the game page and let em wait it out
    if not session.waitingForPlayer:
        return HttpResponse("Error: This game is not currently accepting a new player")
    elif session.player1 == request.user:
        return JsonResponse(response)

    session.add_player(request.user, ships["ships"])
    session.save()
    #return new game ID
    return JsonResponse(response)

    

