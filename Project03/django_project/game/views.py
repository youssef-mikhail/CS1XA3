from django.shortcuts import render
from django.http import HttpResponse
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
import json


# Create your views here.
def startgame(request):
    data = json.loads(request.body)
    print(data)
    return HttpResponse("Json received")
