from django.shortcuts import render
from django.http import HttpResponse, HttpResponseRedirect
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
from .models import BattleshipSession
import json
from django.http import JsonResponse


# Create your views here.
def getSessionInfo(request):
    parameters = request.GET
    gameID = int(parameters.get("gameid", "0"))

    if gameID == 0:
        return HttpResponse("NoGameID")

    session = None

    try:
        session = BattleshipSession.objects.get(id=gameID)
    except BattleshipSession.DoesNotExist:
        return HttpResponse("Error: This game ID does not exist")

    if session == None:
        return HttpResponse("An unknown error occured")

    sessionInfo = {}

    if session.waitingForPlayer:
        if not request.user == session.player1:
            sessionInfo["opponentName"] = session.player2.username
    else:
        if request.user == session.player1:
            sessionInfo["opponentName"] = session.player2.username
        else:
            sessionInfo["opponentName"] = session.player1.username
        
        sessionInfo["isPlayerTurn"] = request.user == session.currentTurn
    
    return JsonResponse(sessionInfo)





    


def startgame(request):
    data = json.loads(request.body)
    if not request.user.is_authenticated:
        return HttpResponse("Not logged in")
    
    newSession = BattleshipSession.objects.create_session(request.user, data["ships"])
    newSession.save()
    return HttpResponse("SessionCreationSuccess")

def getGames(request):
    if not request.user.is_authenticated:
        return HttpResponse("NotLoggedIn")
    
    sessions = BattleshipSession.objects.getSessionsForUser(request.user)
    print(sessions)

    sessionData = {"urls" : [], "descriptions" : []}
    for session in sessions:
        if session.waitingForPlayer and request.user != session.player1:
            sessionData["urls"].append("https://mac1xa3.ca/e/mikhaily/static/creategrid.html?gameid=" + str(session.id))
            sessionData["descriptions"].append(str(session))

        elif session.waitingForPlayer:
            sessionData["urls"].append("https://mac1xa3.ca/e/mikhaily/static/game.html?gameid=" + str(session.id))
            sessionData["descriptions"].append("Waiting for player to join your game")
        else:
            sessionData["urls"].append("https://mac1xa3.ca/e/mikhaily/static/game.html?gameid=" + str(session.id))
            sessionData["descriptions"].append(str(session))
    
    return JsonResponse(sessionData)
    
    
def joinGame(request):
    if not request.user.is_authenticated:
        return HttpResponse("Error: Not logged in. Please log in and try again")
    parameters = request.GET
    postData = request.POST
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


    if not session.waitingForPlayer:
        return HttpResponse("Error: This game is not currently accepting a new player")
    elif session.player1 == request.user:
        return HttpResponseRedirect("https://mac1xa3.ca/e/mikhaily/static/game.html?gameid="+ str(gameID))
    

    session.player2 = request.user
    session.waitingForPlayer = False
    session.player2LiveShips = ships
    session.save()
    return HttpResponse("GameJoinSuccess")

    

