from django.shortcuts import render
from django.http import HttpResponse
from django.contrib.auth import authenticate, login, logout
import json

# Create your views here.

def add_user(request):
    userinfo = request.POST
    uname = userinfo.get('username', '')
    passwd = userinfo.get('password', '')

    if uname == '':
        return HttpResponse('Username cannot be empty!')
    elif passwd == '':
        return HttpResponse('Password cannot be empty!')

    else:
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
    return HttpResponse('LoggedOut')

def user_info(request):
    if not request.user.is_authenticated:
        return HttpResponse('Error: Not logged in')
    else:
        return HttpResponse(request.user.first_name + request.user.last_name)
