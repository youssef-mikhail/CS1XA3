from django.urls import path
from . import views

urlpatterns = [
        path('startgame/', views.startgame, name = 'game-startgame'),
        path('getgames/', views.getGames, name = 'game-getgames'),
        path('joingame/', views.joinGame, name = 'game-joingame'),
        path('sessioninfo/', views.getSessionInfo, name = 'game-sessioninfo'),
        path('refreshgame/', views.updateGameState, name = 'game-updateGameState')

    ]
