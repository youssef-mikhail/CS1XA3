from django.shortcuts import render
from django.http import HttpResponse

def hello(request):
	return HttpResponse("Hello")

def gettest(request):
    reqDict = request.GET
    name = reqDict.get("name","")
    age = reqDict.get("age","")

    return HttpResponse("Hello " + name + " you're " + age + " years old")

def posttest(request):
    reqDict = request.POST
    name = reqDict.get("name","")
    age = reqDict.get("age","")

    return HttpResponse("Hello " + name + " you're " + age + " years old\n")


# Create your views here.
