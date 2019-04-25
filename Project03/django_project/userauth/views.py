from django.shortcuts import render
from django.http import HttpResponse, HttpResponseRedirect
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout
import json

# Create your views here.


#TODO Check if username already exists
def add_user(request):
    userinfo = request.POST
    uname = userinfo.get('username', '')
    passwd = userinfo.get('password', '')

    if uname == '':
        return HttpResponse('Username cannot be empty!')
    elif passwd == '':
        return HttpResponse('Password cannot be empty!')

    else:
        User.objects.create_user(username=uname, password=passwd)
        return HttpResponse('Success')

def login_user(request):
    credentials = request.POST 
    uname = credentials.get('username', '')
    passwd = credentials.get('password','')

    user = authenticate(request, username=uname, password=passwd)

    if user is not None:
        login(request,user)
        return HttpResponse('LoggedIn')
    else:
        return HttpResponse('LoginFailed')

def logout_user(request):
    logout(request)
    return HttpResponseRedirect("https://mac1xa3.ca/e/mikhaily/static/login.html")

def user_info(request):
    if not request.user.is_authenticated:
        return HttpResponse('NotLoggedIn')
    else:
        return HttpResponse(request.user.username)
