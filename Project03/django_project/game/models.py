from django.db import models
from django.contrib.auth.models import User

# Create your models here.

class BattleshipSessionManager(models.Manager):
    def create_session(self, user, ships):
        session = self.create(player1=user, player2="", currentTurn=user)
        strShips = ""
        #convert dictionary data for ships to comma separated string for database
        for entry in ships:
            strShips += str(ships[entry]["location"][0]) + str(ships[entry]["location"][1]) + ships[entry]["orientation"] + ","
        strShips = strShips[:-1]
        session.player1LiveShips = strShips
        return session
        

class BattleshipSession(models.Model):
    #keep track of users in the current session

    player1 = models.ForeignKey(User, on_delete=models.DO_NOTHING)
    player2 = models.ForeignKey(User, on_delete=models.DO_NOTHING)

    currentTurn = models.CharField(max_length=100)

    #Ships from both players that are still alive
    player1LiveShips = models.CharField(max_length=20)
    player2LiveShips = models.CharField(max_length=20)

    #Ships from both players that have been sunk
    player1SunkShips = models.CharField(max_length=20)
    player2SunkShips = models.CharField(max_length=20)

    #Keep track of what missiles missed and hit from both players
    player1MissedMissiles = models.CharField(max_length=300)
    player2MissedMissiles = models.CharField(max_length=300)

    player1HitMissiles = models.CharField(max_length=300)
    player2HitMissiles = models.CharField(max_length=300)

    
    #player who won this game (empty until game is over)
    gameWinner = models.CharField(max_length=100)

    objects = BattleshipSessionManager()

            


