from django.urls import path
from . import views

urlpatterns = [
        path('startgame/', views.startgame, name = 'game-startgame'),
        path('getgames/', views.getGames, name = 'game-getgames')

    ]
