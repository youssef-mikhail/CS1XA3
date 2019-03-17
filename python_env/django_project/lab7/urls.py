from django.urls import path
from . import views

urlpatterns = [
    path("lab7/", views.authenticate, name = "lab7-authenticate"),
]