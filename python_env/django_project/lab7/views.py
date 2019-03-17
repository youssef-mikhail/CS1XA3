from django.shortcuts import render
from django.http import HttpResponse

# Create your views here.

def authenticate(request):
    creds = request.POST
    user = creds.get("user", "")
    password = creds.get("pass", "")
    if user == "Jimmy" and password == "Hendrix":
        return HttpResponse("Cool")
    else:
        return HttpResponse("Bad User Name")