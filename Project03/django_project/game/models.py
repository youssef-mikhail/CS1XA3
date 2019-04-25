from django.db import models
from django.contrib.auth.models import User, AnonymousUser
from django.db.models import Q

# Create your models here.

class SessionFullException(Exception):
    pass

class BattleshipSessionManager(models.Manager):
    def create_session(self, user, ships):
        session = self.create(player1=user, 
            player2=user, 
            currentTurn=user,
            player1LiveShips = ','.join(ships),
            waitingForPlayer=True)
        return session
        

    def getSessionsForUser(self,user):
        sessions = self.filter(Q(player1=user) | Q(player2=user) | Q(waitingForPlayer=True))
        return sessions
    

class BattleshipSession(models.Model):
    #keep track of users in the current session

    waitingForPlayer = models.BooleanField()

    player1 = models.ForeignKey(User, related_name="player1",on_delete=models.DO_NOTHING)
    player2 = models.ForeignKey(User, related_name="player2",on_delete=models.DO_NOTHING)

    currentTurn = models.ForeignKey(User,related_name="currentTurn", on_delete=models.DO_NOTHING)

    #Ships from both players that are still alive
    player1LiveShips = models.CharField(max_length=25)
    player2LiveShips = models.CharField(max_length=25)

    #Ships from both players that have been sunk
    player1SunkShips = models.CharField(max_length=25)
    player2SunkShips = models.CharField(max_length=25)

    #Keep track of what missiles missed and hit from both players
    player1MissedMissiles = models.CharField(max_length=300)
    player2MissedMissiles = models.CharField(max_length=300)

    player1HitMissiles = models.CharField(max_length=300)
    player2HitMissiles = models.CharField(max_length=300)

    
    #player who won this game (empty until game is over)
    gameWinner = models.CharField(max_length=100)

    objects = BattleshipSessionManager()

    def add_player(self, user, ships):
        if self.waitingForPlayer:
            self.player2 = user
            self.player2LiveShips = ",".join(ships)
            self.waitingForPlayer = False
        else:
            raise SessionFullException("This session is not accepting new players")
    
    def __str__(self):
        if not self.waitingForPlayer:
            return self.player1.username + ' vs ' + self.player2.username
        else:
            return "Join game with " + self.player1.username
            


