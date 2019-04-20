from django.shortcuts import render
from django.http import HttpResponse
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
from .models import BattleshipSession
import json


# Create your views here.
def startgame(request):
    data = json.loads(request.body)
    if not request.user.is_authenticated:
        return HttpResponse("Not logged in")
    
    newSession = BattleshipSession.objects.create_session(request.user, data["ships"])
    newSession.save()
    return HttpResponse("New Session Created")

