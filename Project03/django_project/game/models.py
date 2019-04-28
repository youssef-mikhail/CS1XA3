from django.db import models
from django.contrib.auth.models import User, AnonymousUser
from django.db.models import Q

# Create your models here.

#This exception is thrown when a client attempts to join a game that is already full
class SessionFullException(Exception):
    pass

#This exception is thrown in the event of an invalid move
class InvalidMoveException(Exception):
    pass

#Battleship session model manager
class BattleshipSessionManager(models.Manager):
    #creates a new session and initializes all the necessary fields
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
        
    #gets a list of sessions that should be visible to the user.
    #this only includes games that the user is part of or games that are accepting a new player
    def getSessionsForUser(self,user):
        sessions = self.filter(Q(player1=user) | Q(player2=user) | Q(waitingForPlayer=True))
        return sessions
    

class BattleshipSession(models.Model):

    #True if the game is still waiting for someone to join, false otherwise
    waitingForPlayer = models.BooleanField()

    #keep track of players in the session
    player1 = models.ForeignKey(User, related_name="player1",on_delete=models.CASCADE)
    player2 = models.ForeignKey(User, related_name="player2",on_delete=models.CASCADE)

    #this field contains the user whose turn it currently is
    currentTurn = models.ForeignKey(User,related_name="currentTurn", on_delete=models.CASCADE)

    #Ships from both players that are still alive
    player1LiveShips = models.CharField(max_length=25)
    player2LiveShips = models.CharField(max_length=25)

    #Contains the number of hits each ship can take from each player until they sink
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

    #This method takes a missile and a player and determines whether the missile has hit one of their ships
    #All appropriate adjustments will be made here. The function returns true if the missile was a hit, and false otherwise
    def add_missile(self, missile, player):
        hit = False
        
        #helper function to get a list of all the coordinates a ship is on
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
        
        
        #Appropriate checks if the player firing the missile is player 1
        if player == self.player1:
            #check if missile has already been fired, raise InvalidMoveException if it has
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
        
        #Appropriate checks if the player firing the missile is player 2
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
        #if user is neither player 1 or player2, raise an exception
        else:
            raise InvalidMoveException("Player is not in game")
        #return whether the missile was a hit or not
        return hit
            
    #switch player turns
    def switch_player_turns(self):
        if self.currentTurn == self.player1:
            self.currentTurn = self.player2
        else:
            self.currentTurn = self.player1

    #Add a player and initialize the necessary fields. Raises an exception if the session is full and a player cannot be added
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
    
    #String description of this session
    def __str__(self):
        if not self.waitingForPlayer:
            string = self.player1.username + ' vs ' + self.player2.username
            if self.gameWinner == "":
                return string
            else:
                return string + " (Winner: " + self.gameWinner + ") "
        else:
            return "Join game with " + self.player1.username
            


