from django.db import models
from django.contrib.auth.models import User, AnonymousUser
from django.db.models import Q

# Create your models here.

class SessionFullException(Exception):
    pass

class InvalidMoveException(Exception):
    pass

class BattleshipSessionManager(models.Manager):
    def create_session(self, user, ships):
        session = self.create(player1=user, 
            player2=user, 
            currentTurn=user,
            player1LiveShips = ','.join(ships),
            waitingForPlayer=True)
        shipHealth = []
        for ship in ships:
            shipHealth.append(ship[3])
        session.player1ShipHealth = ','.join(shipHealth)
        return session
        

    def getSessionsForUser(self,user):
        sessions = self.filter(Q(player1=user) | Q(player2=user) | Q(waitingForPlayer=True))
        return sessions
    

class BattleshipSession(models.Model):
    #keep track of users in the current session

    waitingForPlayer = models.BooleanField()

    player1 = models.ForeignKey(User, related_name="player1",on_delete=models.CASCADE)
    player2 = models.ForeignKey(User, related_name="player2",on_delete=models.CASCADE)

    currentTurn = models.ForeignKey(User,related_name="currentTurn", on_delete=models.CASCADE)

    #Ships from both players that are still alive
    player1LiveShips = models.CharField(max_length=25)
    player2LiveShips = models.CharField(max_length=25)

    player1ShipHealth = models.CharField(max_length=10)
    player2ShipHealth = models.CharField(max_length=10)

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

    def add_missile(self, missile, player):
        hit = False
        def coordinatesForShip(ship):
            origin = (int(ship[0]), int(ship[1]))
            size = int(ship[-1])
            coordinates = []
            for i in range(size):
                if ship[2] == "D":
                    coordinates.append((origin[0],origin[1] + i))
                elif ship[2] == "H":
                    coordinates.append((origin[0] + i, origin[1]))
            return coordinates
        
        
        
        if player == self.player1:
            #check if missile has already been fired
            if missile in self.player1MissedMissiles or missile in self.player1HitMissiles:
                raise InvalidMoveException("Missile has already been fired")
            
            missileCoordinates = (int(missile[0]), int(missile[1]))
            shipHealth = self.player2ShipHealth.split(",")
            ships = self.player2LiveShips.split(",")
            for index, ship in enumerate(ships):
                if missileCoordinates in coordinatesForShip(ship):
                    hit = True
                    shipHealth[index] = str(int(shipHealth[index]) - 1)
                    if self.player1HitMissiles == "":
                        self.player1HitMissiles = missile
                    else:
                        hitMissiles = self.player1HitMissiles.split(",")
                        hitMissiles.append(missile)
                        self.player1HitMissiles = ','.join(hitMissiles)
                    if shipHealth[index] == '0':
                        shipHealth.pop(index)
                        ships.pop(index)
                        sunkShips = self.player2SunkShips.split(",")
                        if self.player2SunkShips == "":
                            self.player2SunkShips = ship
                        else:
                            sunkShips.append(ship)
                            self.player2SunkShips = ','.join(sunkShips)
                    break
            self.player2LiveShips = ','.join(ships)
            self.player2ShipHealth = ','.join(shipHealth)
            if not hit:
                if self.player1MissedMissiles == "":
                        self.player1MissedMissiles = missile
                else:
                    missedMissiles = self.player1MissedMissiles.split(",")
                    missedMissiles.append(missile)
                    self.player1MissedMissiles = ','.join(missedMissiles)
        
        elif player == self.player2:
            #check if missile has already been fired
            if missile in self.player2MissedMissiles or missile in self.player2HitMissiles:
                raise InvalidMoveException("Missile has already been fired")
            
            missileCoordinates = (int(missile[0]), int(missile[1]))
            shipHealth = self.player1ShipHealth.split(",")
            ships = self.player1LiveShips.split(",")
            for index, ship in enumerate(ships):
                if missileCoordinates in coordinatesForShip(ship):
                    hit = True
                    shipHealth[index] = str(int(shipHealth[index]) - 1)
                    if self.player2HitMissiles == "":
                        self.player2HitMissiles = missile
                    else:
                        hitMissiles = self.player2HitMissiles.split(",")
                        hitMissiles.append(missile)
                        self.player2HitMissiles = ','.join(hitMissiles)
                    if shipHealth[index] == '0':
                        shipHealth.pop(index)
                        ships.pop(index)
                        sunkShips = self.player1SunkShips.split(",")
                        if self.player1SunkShips == "":
                            self.player1SunkShips = ship
                        else:
                            sunkShips.append(ship)
                            self.player1SunkShips = ','.join(sunkShips)
                    break
            self.player1LiveShips = ','.join(ships)
            self.player1ShipHealth = ','.join(shipHealth)
            if not hit:
                if self.player2MissedMissiles == "":
                        self.player2MissedMissiles = missile
                else:
                    missedMissiles = self.player2MissedMissiles.split(",")
                    missedMissiles.append(missile)
                    self.player2MissedMissiles = ','.join(missedMissiles)
        
        else:
            raise InvalidMoveException("Player is not in game")

        return hit
            

    def switch_player_turns(self):
        if self.currentTurn == self.player1:
            self.currentTurn = self.player2
        else:
            self.currentTurn = self.player1

    def add_player(self, user, ships):
        if self.waitingForPlayer:
            self.player2 = user
            self.player2LiveShips = ",".join(ships)
            shipHealth = []
            for ship in ships:
                shipHealth.append(ship[3])
            self.player2ShipHealth = ','.join(shipHealth)
            self.waitingForPlayer = False
        else:
            raise SessionFullException("This session is not accepting new players")
    
    def __str__(self):
        if not self.waitingForPlayer:
            string = self.player1.username + ' vs ' + self.player2.username
            if self.gameWinner == "":
                return string
            else:
                return string + " (Winner: " + self.gameWinner + ") "
        else:
            return "Join game with " + self.player1.username
            


