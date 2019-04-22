from django.shortcuts import render
from django.http import HttpResponse
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
from .models import BattleshipSession
import json
from django.http import JsonResponse


# Create your views here.
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
        if session.waitingForPlayer:
            sessionData["urls"].append("https://mac1xa3.ca/e/mikhaily/static/creategrid.html?gameid=" + str(session.id))
        else:
            sessionData["urls"].append("https://mac1xa3.ca/e/mikhaily/static/game.html?gameid=" + str(session.id))
        
        sessionData["descriptions"].append(str(session))
    
    return JsonResponse(sessionData)
    
    
