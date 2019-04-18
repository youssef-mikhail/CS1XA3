from django.db import models

# Create your models here.


def BattleshipSession(models.Model):
    #keep track of users in the current session
    
    #keep track of whether the game has started or if the session
    #is still waiting for another player to join
    gameStarted = models.BooleanField()
    
