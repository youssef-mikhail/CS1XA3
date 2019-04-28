from django.shortcuts import render
from django.http import HttpResponse, HttpResponseBadRequest, HttpResponseNotFound, HttpResponseServerError, HttpResponseForbidden
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
from .models import BattleshipSession
import json
from django.http import JsonResponse

rootUrl = "https://mac1xa3.ca/e/mikhaily/"

# Create your views here.
def getSessionInfo(request):
    parameters = request.GET
    gameID = int(parameters.get("gameid", "0"))

    if not request.user.is_authenticated:
        return HttpResponseForbidden("You are not logged in")

    if gameID == 0:
        return HttpResponseBadRequest("NoGameID")

    session = None

    try:
        session = BattleshipSession.objects.get(id=gameID)
    except BattleshipSession.DoesNotExist:
        return HttpResponseNotFound("Error: This game ID does not exist")

    if session == None:
        return HttpResponseServerError("An unknown error occurred")

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


def submitMove(request):
    parameters = request.GET
    gameID = int(parameters.get("gameid", "0"))
    move = parameters.get("move","")

    if gameID == 0:
        return HttpResponseBadRequest("No GameID was specified")

    session = None

    try:
        session = BattleshipSession.objects.get(id=gameID)
    except BattleshipSession.DoesNotExist:
        return HttpResponseNotFound("Error: This game ID does not exist")
    
    if session == None:
        return HttpResponseServerError("An unknown error has occured")
    
    if not (request.user == session.player1 or request.user == session.player2):
        return HttpResponseForbidden("Error: You are not a part of this game")
    
    if not request.user == session.currentTurn:
        return HttpResponse("It is not your turn!")

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

    if didHit:
        return HttpResponse("Hit")
    else:
        return HttpResponse("Miss")

    


def updateGameState(request):
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
    
    if not (request.user == session.player1 or request.user == session.player2):
        return HttpResponseForbidden("Error: You are not a part of this game")
    

    

    playerShips = []
    opponentSunkShips = []
    playerMissedMissiles = []
    playerHitMissiles = []
    opponentHitMissiles = []
    opponentMissedMissiles = []
    isPlayerTurn = (session.currentTurn == request.user) and not session.waitingForPlayer and session.gameWinner == ""
    print(session.gameWinner)


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

    print(playerShips)
    return JsonResponse(gameData)
    


def startgame(request):
    data = json.loads(request.body)
    if not request.user.is_authenticated:
        return HttpResponseForbidden("Not logged in")
    
    newSession = BattleshipSession.objects.create_session(request.user, data["ships"])
    newSession.save()
    response = {"gameid" : newSession.id}
    return JsonResponse(response)



def getGames(request):
    if not request.user.is_authenticated:
        return HttpResponse("NotLoggedIn")
    
    sessions = BattleshipSession.objects.getSessionsForUser(request.user)
    print(sessions)

    sessionData = {"urls" : [], "descriptions" : []}
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
    
    return JsonResponse(sessionData)
    
    
def joinGame(request):
    if not request.user.is_authenticated:
        return HttpResponseForbidden("Error: Not logged in. Please log in and try again")
    parameters = request.GET
    gameID = int(parameters.get("gameid", "0"))
    if gameID == 0:
        return HttpResponse("Error: Game ID not specified")

    ships = json.loads(request.body)

    if ships == "":
        return HttpResponse("Error: No game data was specified")
    session = None

    try:
        session = BattleshipSession.objects.get(id=gameID)
    except BattleshipSession.DoesNotExist:
        return HttpResponse("Error: This game ID does not exist")

    if session == None:
        return HttpResponse("An unknown error occured")

    response = {"gameid" : session.id}

    if not session.waitingForPlayer:
        return HttpResponse("Error: This game is not currently accepting a new player")
    elif session.player1 == request.user:
        return JsonResponse(response)

    session.add_player(request.user, ships["ships"])
    session.save()
    
    return JsonResponse(response)

    

