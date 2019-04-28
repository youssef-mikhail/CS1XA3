import Browser
import Browser.Navigation exposing (Key(..), load)
import GraphicSVG exposing (..)
import GraphicSVG.App exposing (..)
import Html exposing (button, Html)
import Html.Events exposing (onClick)
import Html.Attributes exposing (disabled)
import Url
import Http
import Dict exposing (Dict)
import Tuple exposing (first, second)
import Json.Decode as JDecode
import Json.Encode as JEncode

rootUrl = "https://mac1xa3.ca/e/mikhaily/"
---------------------------------------------------------------------------------------------------------

-- Models, Messages, etc


--App messages
type Msg
 = Tick Float GetKeyState
 | MakeRequest Browser.UrlRequest
 | UrlChange Url.Url
 | SquareClicked (Int, Int)
 | SquareHovered (Int, Int)
 | SendMove
 | GotGameData (Result Http.Error GameData)
 | GotSessionInfo (Result Http.Error (String,String))
 | GotMoveResponse (Result Http.Error String)
 | RefreshGameData



--App model
type alias Model = 
        { gameState : State,
          gameData : GameData,
          queries : String,
          error : String,
          message : String,
          sessionDescription : String,
          targetLocation : (Int, Int),
          opponentName : String,
          refreshTimer : Int,
          changeMessage : Bool,
          gameOver : Bool
          }


--Model to store information about a single ship
type alias Ship = 
  {
    location : (Int, Int),
    orientation : Float,
    size : Int
  }

--Model to keep track of game's current state, using data from the server
type alias GameData = 
  {
    playerShips : List Ship,
    playerSunkShips : List Ship,
    opponentSunkShips : List Ship,
    playerMissedMissiles : List (Int, Int),
    playerHitMissiles : List (Int, Int),
    opponentHitMissiles : List (Int, Int),
    opponentMissedMissiles : List (Int, Int),
    isPlayerTurn : Bool
  }

--Keep track of what the app is currently doing
type State = 
  Ready
  | MovingTarget
  | WaitingTurn
  | WaitingPlayer

--Initial values for the app model. Get session data and game state on page load
init : () -> Url.Url -> Key -> ( Model, Cmd Msg )
init flags url key = 
  ( { error = "",
      gameState = WaitingPlayer,
      sessionDescription = "",
      message = "",
      changeMessage = True,
      opponentName = "",
      gameOver = False,
      targetLocation = (0,0),
      queries = Maybe.withDefault "" url.query,
      gameData = GameData [Ship (0,0) 0.0 0] [Ship (0,0) 0.0 0] [Ship (0,0) 0.0 0] [(0,0)] [(0,0)] [(0,0)] [(0,0)] False,
      refreshTimer = 360
      }, Cmd.batch [getGameState (Maybe.withDefault "" url.query), getSessionData (Maybe.withDefault "" url.query)] )


---------------------------------------------------------------------------------------------------------

--HTTP functions, JSON Decoders, related helper functions

--Send move to server in POST body
sendMove : (Int, Int) -> String -> Cmd Msg
sendMove move queries = 
  Http.get {
    url = rootUrl ++ "game/submitmove/?" ++ queries ++ "&move=" ++ missileToString move,
    expect = Http.expectString GotMoveResponse
  }

--Decode game data received from the server and convert it to a GameData model
decodeGameData : JDecode.Decoder GameData
decodeGameData = JDecode.map8 GameData
  (JDecode.field "playerShips" (JDecode.list (JDecode.map stringToShip JDecode.string)))
  (JDecode.field "playerSunkShips" (JDecode.list (JDecode.map stringToShip JDecode.string)))
  (JDecode.field "opponentSunkShips" (JDecode.list (JDecode.map stringToShip JDecode.string)))
  (JDecode.field "playerMissedMissiles" (JDecode.list (JDecode.map stringToMissile JDecode.string)))
  (JDecode.field "playerHitMissiles" (JDecode.list (JDecode.map stringToMissile JDecode.string)))
  (JDecode.field "opponentHitMissiles" (JDecode.list (JDecode.map stringToMissile JDecode.string)))
  (JDecode.field "opponentMissedMissiles" (JDecode.list (JDecode.map stringToMissile JDecode.string)))
  (JDecode.field "isPlayerTurn" JDecode.bool)

--Get session info using a get request using the queries provided in the URL (specifically the "?gameid=" portion)
getSessionData : String -> Cmd Msg
getSessionData query = 
  Http.get {
    url = rootUrl ++ "game/sessioninfo/?" ++ query,
    expect = Http.expectJson GotSessionInfo sessionInfoDecoder
  }


--Decode session info
sessionInfoDecoder : JDecode.Decoder (String,String)
sessionInfoDecoder = JDecode.map2 Tuple.pair
    (JDecode.field "sessionDescription" JDecode.string)
    (JDecode.field "opponentName" JDecode.string)

--Convert a string representing a missile to a tuple of Ints representing their location on a grid
stringToMissile : String -> (Int, Int)
stringToMissile strMissile = (Maybe.withDefault 0 (String.toInt (String.dropRight 1 strMissile)), Maybe.withDefault 0 (String.toInt (String.dropLeft 1 strMissile)))

--Convert a missile to a string representing a missile
missileToString : (Int,Int) -> String
missileToString (a,b) = String.fromInt a ++ String.fromInt b

--Get game state from the server using the GET parameters in the URL
getGameState : String -> Cmd Msg
getGameState queries = 
  Http.get {
    url = rootUrl ++ "game/refreshgame/?" ++ queries,
    expect = Http.expectJson GotGameData decodeGameData
  }


--Convert a ship to a string representing a ship
--The format of this string is "12H3", with 1 representing the column, 2 representing the row,
--H representing horizontal (or D for down), and 3 representing the size of the ship in squares
shipToString : Ship -> String
shipToString ship = String.fromInt (first ship.location) ++ String.fromInt (second ship.location)
  ++ (if ship.orientation == 0 then "D" else "H")

--Convert a string in the format described above to a Ship model
stringToShip : String -> Ship
stringToShip strShip = Ship 
  (Maybe.withDefault 0 (String.toInt (String.dropRight 3 strShip)), Maybe.withDefault 0 (String.toInt (String.slice 1 2 strShip))) 
  (if String.slice 2 3 strShip == "D" then 0 else pi/2) 
  (Maybe.withDefault 0 (String.toInt (String.dropLeft 3 strShip)))


------------------------------------------------------------------------------------------------------------------

--More helper functions

--Given a list of ships, get the ship at the provided index
getShipAt : Int -> List Ship -> Ship
getShipAt n xs = case List.head (List.drop n xs) of 
  Just a -> a
  Nothing -> Ship (0,0) 0 0

--Given a ship and a set of coordinates, return a ship with those new coordinates
changeShipLocation : Ship -> (Int, Int) -> Ship
changeShipLocation ship newLocation = {ship | location = newLocation}

--A zip function just like the one available in Haskell.
--This function takes two lists and converts them to a list of tuples
zip : List a -> List b -> List (a, b)
zip a b = case a of
  [] -> []
  (x::xs) -> case b of
    [] -> []
    (y::ys) -> [(x, y)] ++ zip xs ys


--Given two lists, return True if any of their elements overlap
checkOverlap : List a ->  List a -> Bool
checkOverlap a b = case a of
  [] -> False
  (x::xs) -> List.member x b || checkOverlap xs b

--Given a ship, return a list of squares that it covers
locationsForShip : Ship -> List (Int, Int)
locationsForShip ship = if ship.orientation == 0 then 
  zip (List.repeat ship.size (first ship.location)) (List.range (second ship.location) (second ship.location + ship.size))
  else
  zip (List.range (first ship.location) (first ship.location + ship.size)) (List.repeat ship.size (second ship.location)) 


--Check if there is any collision between a ship and a list of ships
checkCollision : Ship -> List Ship -> Bool
checkCollision ship ships = case ships of
  [] -> False
  (a::b) -> (checkOverlap (locationsForShip ship) (locationsForShip a) && ship.location /= a.location) || checkCollision ship b
                                  

--Given an orientation, ship size, and (row,column) coordinates, return (x,y) coordinates
--representing the exact location on the screen where the ship should be displayed
locationFromSquare : Float -> Int -> (Int, Int) -> (Float, Float)
locationFromSquare orientation shipSize (a,b) = if orientation == 0 then 
  (first gridLocation + toFloat a*squareWidth, (squareWidth*10 + second gridLocation - toFloat b*squareWidth) - toFloat (shipSize//2)*squareWidth + toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2) )
  else 
  ((first gridLocation + toFloat a*squareWidth) + toFloat (shipSize//2)*squareWidth - toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2), squareWidth*10 + second gridLocation - toFloat b*squareWidth )

--Just like locationFromSquare, but returns the (x,y) coordinates corresponding to the grid on the right
locationFromSquare2 : Float -> Int -> (Int, Int) -> (Float, Float)
locationFromSquare2 orientation shipSize (a,b) = if orientation == 0 then 
  (first grid2Location + toFloat a*squareWidth, (squareWidth*10 + second grid2Location - toFloat b*squareWidth) - toFloat (shipSize//2)*squareWidth + toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2) )
  else 
  ((first grid2Location + toFloat a*squareWidth) + toFloat (shipSize//2)*squareWidth - toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2), squareWidth*10 + second grid2Location - toFloat b*squareWidth )



---------------------------------------------------------------------------------------------------------

-- Default layout sizes and locations

background = rectangle 700 500 |> filled lightBlue
gridLocation = (-300.0, -150.0)
grid2Location = (50.0, -150.0)
squareWidth = 30
playerGrid = group (squares 10 10)
enemyGrid = group (squaresWithClickMsg 10 10)


---------------------------------------------------------------------------------------------------------

-- Shapes, buttons, related helper functions

--Cursor for the targetting interface
target : Shape Msg
target = group [
  circle (squareWidth/2) |> outlined (solid 2) red,
  line (0, squareWidth/2) (0, squareWidth/4) |> outlined (solid 2) red,
  line (0, -squareWidth/2) (0, -squareWidth/4) |> outlined (solid 2) red,
  line (-squareWidth/2, 0) (-squareWidth/4, 0) |> outlined (solid 2) red,
  line (squareWidth/2, 0) (squareWidth/4, 0) |> outlined (solid 2) red
  ]

--Given a list of coordinates, return a list of shapes representing the opponent's hit missiles
oppHitMissileList : List (Int, Int) -> List (Shape Msg)
oppHitMissileList missiles = case missiles of
  [] -> []
  (a::b) -> [hitMissile a |> move (locationFromSquare 0 1 a)] ++ oppHitMissileList b

--Given a list of coordinates, return a list of shapes representing the player's hit missiles
playerHitMissileList : List (Int, Int) -> List (Shape Msg)
playerHitMissileList missiles = case missiles of
  [] -> []
  (a::b) -> [hitMissile a |> move (locationFromSquare2 0 1 a)] ++ playerHitMissileList b

--Shape for a hit missile
hitMissile : (Int, Int) -> Shape Msg
hitMissile location = group [
  square (squareWidth + 2) |> filled blank,
  circle (squareWidth/2 - 4) |> filled red
  ]

--Given a list of coordinates, return a list of shapes representing the opponent's missed missiles
oppMissedMissileList : List (Int, Int) -> List (Shape Msg)
oppMissedMissileList missiles = case missiles of
  [] -> []
  (a::b) -> [missedMissile a |> move (locationFromSquare 0 1 a)] ++ oppMissedMissileList b

--Given a list of coordinates, return a list of shapes representing the player's missed missile
playerMissedMissileList : List (Int, Int) -> List (Shape Msg)
playerMissedMissileList missiles = case missiles of
  [] -> []
  (a::b) -> [missedMissile a |> move (locationFromSquare2 0 1 a)] ++ playerMissedMissileList b

--shape for a missed missile
missedMissile : (Int, Int) -> Shape Msg
missedMissile location = group [
  square (squareWidth + 2) |> filled blank,
  circle (squareWidth/2 - 8) |> filled black
  ]

--Given a list of Ship models, return a list of ship shapes
playerShips : List Ship -> List (Shape Msg)
playerShips ships = case ships of
    [] -> []
    (a::b) -> [playerShip a |> rotate a.orientation |> move (locationFromSquare a.orientation a.size a.location)]
              ++ playerShips b

--Given a list of Ship models, return a list of shapes representing opponent's sunk ships
oppSunkShips : List Ship -> List (Shape Msg)
oppSunkShips ships = case ships of
    [] -> []
    (a::b) -> [sunkShip a |> rotate a.orientation |> move (locationFromSquare2 a.orientation a.size a.location)]
              ++ oppSunkShips b

--Given a list of ships, return a list of shapes representing the player's sunk ships
sunkShips : List Ship -> List (Shape Msg)
sunkShips ships = case ships of
    [] -> []
    (a::b) -> [sunkShip a |> rotate a.orientation |> move (locationFromSquare a.orientation a.size a.location)]
              ++ sunkShips b

--Shape representing a sunken ship
sunkShip : Ship -> Shape Msg
sunkShip ship = group [
  rectangle (squareWidth + 2) (toFloat (squareWidth*ship.size + 12)) |> filled blank,
  oval squareWidth (toFloat (squareWidth*ship.size)) |> filled black |> addOutline (solid 1) black
  ]


--Shape representing a ship
playerShip : Ship -> Shape Msg
playerShip ship = group [
  rectangle (squareWidth + 2) (toFloat (squareWidth*ship.size + 12)) |> filled blank,
  oval squareWidth (toFloat (squareWidth*ship.size)) |> filled grey |> addOutline (solid 1) black 
  ] 

--Button used to submit a move. Only enabled when the game is in a "Ready" state
submitMoveButton : Model -> Html.Html Msg
submitMoveButton model = button [onClick SendMove, disabled (model.gameState /= Ready)] [Html.text "Fire Missile"]

--A button that can be used to update the game's state from the server
refreshGameButton : Html.Html Msg
refreshGameButton = button [onClick RefreshGameData] [Html.text "Refresh Game"]

--Grid containing squares that send SquareClicked and SquareHovered messages
squaresWithClickMsg : Int -> Int ->  List (Shape Msg)
squaresWithClickMsg row column = if column == 0 then
    squaresWithClickMsg (row - 1) 10
    else if row == 0 then []
    else
    [square squareWidth |> filled blue |> addOutline (solid 2) black |> move (squareWidth*10 - (toFloat row)*squareWidth,(toFloat column)*squareWidth) |> notifyTap (SquareClicked (10 - row, 10 - column)) |> notifyEnter (SquareHovered (10 - row, 10 - column))] 
    ++ (squaresWithClickMsg row (column - 1))

--Grid containing squares that do NOT send SquareClicked and SquareHovered messages
squares : Int -> Int ->  List (Shape Msg)
squares row column = if column == 0 then
    squares (row - 1) 10
    else if row == 0 then []
    else
    [square squareWidth |> filled blue |> addOutline (solid 2) black |> move (squareWidth*10 - (toFloat row)*squareWidth,(toFloat column)*squareWidth) ] 
    ++ (squares row (column - 1))

---------------------------------------------------------------------------------------------------------

-- Miscellaneous

--App view
view : Model -> { title : String, body : Collage Msg }
view model = 
  let 
    title = "Battleship Game"

    body  = collage 700 500 (mainScreen model) 
  in { title = title, body = body}


--Shapes for the app view
mainScreen model =  [
    background,
    text model.sessionDescription |> size 30 |> bold |> filled black |> move (-325, 200),
    playerGrid |> move gridLocation ,
    enemyGrid |> move grid2Location,
    html 50 100 (submitMoveButton model) |> move (150,-150),
    html 60 125 refreshGameButton |> move (0,-150),
    text model.error |> filled black |> move (-350, -200),
    text model.message |> bold |> filled black |> move (100,-200),
    text (if not (model.gameData.isPlayerTurn || model.gameOver) then
      ("Game will automatically refresh in " ++ String.fromInt (model.refreshTimer // 60) ++ " seconds")
      else "") |> size 10|> filled black |> move (-200,-175),
    target |> move (locationFromSquare2 0 1 model.targetLocation)
    ] 
    ++ playerShips model.gameData.playerShips
    ++ sunkShips model.gameData.playerSunkShips
    ++ oppSunkShips model.gameData.opponentSunkShips
    ++ oppHitMissileList model.gameData.opponentHitMissiles
    ++ playerHitMissileList model.gameData.playerHitMissiles
    ++ playerMissedMissileList model.gameData.playerMissedMissiles
    ++ oppMissedMissileList model.gameData.opponentMissedMissiles


--App update function
update : Msg -> Model ->  (Model, Cmd Msg) 
update msg model = case msg of

    --Handle refresh timer
    Tick time getKeyState -> ({model | 
      refreshTimer = if model.gameData.isPlayerTurn || model.gameOver then model.refreshTimer else model.refreshTimer - 1
        }, if model.refreshTimer <= 0 then Cmd.batch [getGameState model.queries, getSessionData model.queries] else Cmd.none)
      
    MakeRequest urlRequest -> (model, Cmd.none)
    UrlChange url -> (model,Cmd.none)
    --When a square is clicked, set the target to the appropriate location
    SquareClicked location -> ({model | gameState = if model.gameData.isPlayerTurn then Ready else model.gameState, 
      targetLocation = if model.gameData.isPlayerTurn then location else model.targetLocation}, Cmd.none)
    -- When a square is hovered, set the target to the appropriate location
    SquareHovered location -> (
      case model.gameState of
        Ready -> model

        MovingTarget -> {model | targetLocation = location}

        WaitingTurn -> model

        WaitingPlayer -> model

        , Cmd.none)

    --Send move
    SendMove -> (model, sendMove model.targetLocation model.queries)
    --Refresh game data
    RefreshGameData -> (model, getGameState model.queries)
    --Received updated game data from the server
    GotGameData result ->
      case result of
        Ok data -> ({model | gameData = data, --Save received data
                             refreshTimer = 360,  --Reset refresh timer
                             changeMessage = True, --Allow message below grid to be changed next time game is refreshed
                             gameOver = (List.length data.playerSunkShips == 5) || (List.length data.opponentSunkShips == 5), --Game is over if 5 ships are sunk on either side
                             message = if model.changeMessage then --Pick an appropriate message to display below enemy grid
                              if data.isPlayerTurn then "Click on a square to select your target"
                              else if model.opponentName == "" || ((List.length data.playerSunkShips == 5) || (List.length data.opponentSunkShips == 5)) then "" else "Waiting for other player's move..."
                              else if model.gameOver then ""
                              else model.message}, Cmd.none)
        --handle any errors
        Err error -> handleError model error
    --Received session info
    GotSessionInfo result ->
      case result of
        Ok (info, opponentName) -> ({model | sessionDescription = info, opponentName = opponentName}, Cmd.none)
        Err error -> handleError model error
    
    --Got a response from the server after submitting a move. Handle each scenario appropriately
    GotMoveResponse result ->
      case result of
        Ok "Hit" -> ({model | message = "Hit! Shoot again!", changeMessage = False, gameState = MovingTarget}, getGameState model.queries)
        Ok "Miss" -> ({model | message = "You missed!", gameState = WaitingTurn, changeMessage = False}, getGameState model.queries)
        Ok "Win" -> ({model | message = "You win!", gameOver = True, changeMessage = False, gameState = WaitingTurn}, Cmd.batch [getGameState model.queries, getSessionData model.queries])
        Ok "Lose" -> ({model | message = "You lost!", gameOver = True, changeMessage = False}, Cmd.batch [getGameState model.queries, getSessionData model.queries])
        Ok other -> ({model | message = other, changeMessage = False }, getGameState model.queries)
        Err error -> handleError model error

--Display an error message if there is an HTTP error
handleError model error = 
    case error of
        Http.BadUrl url ->
            ({ model | error = "Error: Bad url (" ++ url ++ ")"}, Cmd.none)
        Http.Timeout ->
            ({model | error = "Error: Request timed out"}, Cmd.none)
        Http.NetworkError ->
            ({model | error = "Error: Network error"}, Cmd.none)
        Http.BadStatus 403 -> (model, load "https://mac1xa3.ca/u/mikhaily/login.html") --Redirect the user to the login page if they are not authorized to view this game
        Http.BadStatus 404 -> ({model | error = "Error: The game this URL is referring to does not exist!"}, Cmd.none)
        Http.BadStatus status -> ({model | error = "Error: Bad status " ++ String.fromInt status}, Cmd.none)
        Http.BadBody body ->
            ({model | error = "Error: Bad body " ++ body}, Cmd.none)


subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

main : AppWithTick () Model Msg
main =
    appWithTick Tick
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlRequest = MakeRequest
        , onUrlChange = UrlChange
        }