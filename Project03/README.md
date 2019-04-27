# Project03: Battleship

This battleship game was created with Elm as the frontend, and with Django being the backend.

## Setting up Django on the server

If you already have Django set up you may skip this section.

If you do not already have Django installed, you can do so in a python virtual environment.
On your terminal, go to the directory where you want to place your virtual environment and run
the following command to create a new python environment:

``` bash
python3 -m venv django_env
```

where `django_env` is the name of the directory that your virtual environment will be in.

Once you have created your virtual environment, activate it using the following command:

``` bash
source django_env/bin/activate
```

You should now see the name of your environment in brackets at the beginning of your command line prompt as follows:

`(django_env) $`

Once you have activated your virtual environment, install Django and its dependencies using the following command:

``` bash
pip install -r requirements.txt
```

where `requirements.txt` is the requirements file included in the Project03 directory.

Once you have your virtual environment with Django set up, you are ready to start the Django server.

## Starting the Django server

Assuming you have activated your virtual environment and you are in the CS1XA3/Project03, you can run this project on the
mac1xa3 server by running the following commands:

``` bash
(django_env) user@1xa3-server:~/CS1XA3/Project03$ cd django_project/
(django_env) user@1xa3-server:~/CS1XA3/Project03/django_project$ python manage.py runserver localhost:10040
Performing system checks...

System check identified no issues (0 silenced).
April 27, 2019 - 18:33:16
Django version 2.1.7, using settings 'django_project.settings'
Starting development server at http://localhost:10040/
Quit the server with CONTROL-C.
```

If the server starts successfully, you should see the output above. Port 10040 is mapped to <https://mac1xa3.ca/e/mikhaily>,
which is the root URL that is already specified in the project code.

## Navigating the website

Once the server has been started, you can play by going to <https://mac1xa3.ca/u/mikhaily/main.html>. If you have not
already logged in, you should be redirected to the login page. You will need to create an account by clicking the "create
account" button on the page. Follow the page instructions to create a new username and password.

Once you have created an account, you will be redirected back to the login page, where you will enter your newly created
username and password. Once you have completed the account setup and have logged in, you will be redirected to the main
lobby, where you should see all of the available game sessions that you can join, as well as any games you have in
progress. If you do not see anything, that means that there are no sessions open, but you can create a new one by clicking
the "Create new game" button at the top of the screen.

You can arrange your ships by clicking on the ships and place them by clicking the square where you want them. You can also
rotate a ship you are moving with the "rotate ship" button. When you are ready to start the game, you can click "Start
game" and wait for a new player to join. Any player can now see a link on the lobby to join your game, inviting them to
arrange their ships and join your game.

## Features

### Backend features

#### Session models

Each game session is stored in its own `BattleshipSession` model that stores all information about the game in progress.
Information about player ships, missiles, and other data are stored as comma separated `CharField`s (which are parsed as
lists when they are sent out as JSON). The users in the session are stored as one to many relations in the session.

The advantage of using such a model is that many sessions can take place at the same time because all sessions are isolated
from each other, with the only limitation being server resources. Each session has its own unique integer ID, which can
be used to refer to any session.

#### Session filtering

Another way this type of model is used effectively is in the way it allows for effective filtering of sessions. When the
user enters the lobby and fetches all available sessions, Django filters the list it returns to include only sessions that
are either accepting new players, or sessions that the player is already a part of, so that they can resume the game.

#### User Authentication

Using Django's built-in `User` model, each user can create a username and password and have their own identity, and their
own set of game sessions, as described above. Any user can create an account by clicking the "Create Account" button on the
login page, then logging in with the new account on the login page. This also allows games to continue securely, so that
a third party who is not a part of a game cannot look at the boards and peek at each other. This is also one of the reasons
why the server only gives the user a list of games they are a part of, keeping in line with the principle of least privilege.

#### JSON

A variety of data is transferred when the client refreshes a game to get updated data on the session. Game data is transferred to the client as lists of strings (as well as other data types), which the client can parse into their appropriate objects.

#### GET and POST requests

GET and POST requests are used where appropriate. For instance, POST requests are used for login and for submitting a move
to the server during a game, as well as for JSON. GET requests are used to identify the Game ID that the player is
currently in directly in the URL, allowing the server to keep track of which session the client is requesting without having
to include it in every single POST request.

### Frontend Features

#### GraphicSVG

This game uses the Elm GraphicSVG library provided by MacCASOutreach for battleship graphics. All graphics present in the
game are drawn using shapes from the GraphicSVG library, as well as for mouse hovering and click events, which will be
discussed below.

#### Events

On the ship arrangement page, ships are moved around by clicking on a ship (using a `NotifyTap` event), and then letting
go of the ship by clicking the square you want to place it. The ship follows the mouse while it is being moved by using
`NotifyMouseHover` events for each individual square, allowing for a preview of where the ship will be placed before
letting it go.

#### JSON Encoders and Decoders

Decoders and encoders are used in Elm to convert `Ship` objects (and other data structures) to/from strings so that
they can be sent and recieved as strings. This is especially useful when updating the game state during a game. The state
is stored as a single `GameState` object in Elm, and any JSON data received from the server is converted directly to a
`GameState` object. They are also used to send the player's ship arrangement to the server.

#### Semi-realtime Updates

During a game, the browser checks for a new move from the opponent every 5 seconds by receiving new JSON data from the server. Each JSON is less than a kilobyte of data, so as not to put a strain on the server's bandwidth.