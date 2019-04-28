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


type Msg
 = Tick Float GetKeyState
 | MakeRequest Browser.UrlRequest
 | UrlChange Url.Url
 | SquareClicked (Int, Int)
 | EditShip Int
 | SquareHovered (Int, Int)
 | RotateShip
 | SendGame
 | GotJson (Result Http.Error String)
 | GotSessionID (Result Http.Error Int)



--App model
type alias Model = 
        { gameState : State,
          playerShips : List Ship,
          response : String,
          queries : String,
          title : String,
          opponentName : String
          }

--Initial values for the app model
init : () -> Url.Url -> Key -> ( Model, Cmd Msg )
init flags url key = 
  ( {playerShips = 
        [Ship (0,0) 0 5, Ship (1,0) 0 4, Ship (2,0) 0 3, Ship (3,0) 0 3, Ship (4,0) 0 2],
      gameState = Idle,
      response = "",
      queries = Maybe.withDefault "" url.query,
      title = "Place your ships in the desired arrangement",
      opponentName = ""
      }, case url.query of
      Nothing -> Cmd.none
      Just a -> getSessionInfo a )


type alias Ship = 
  {
    location : (Int, Int),
    orientation : Float,
    size : Int
  }



type State = 
   MovingShip Int
  | Idle

---------------------------------------------------------------------------------------------------------

--HTTP functions, JSON decoders, related helper functions


--Decode opponent name from JSON
decodeSessionInfo : JDecode.Decoder String
decodeSessionInfo = JDecode.field "opponentName" JDecode.string

--Convert a ship to a string representing a ship
--The format of this string is "12H3", with 1 representing the column, 2 representing the row,
--H representing horizontal (or D for down), and 3 representing the size of the ship in squares
shipToString : Ship -> String
shipToString ship = String.fromInt (first ship.location) ++ String.fromInt (second ship.location)
  ++ (if ship.orientation == 0 then "D" else "H") ++ String.fromInt ship.size


--Encode ships into JSON
modelEncoder : Model -> JEncode.Value
modelEncoder model =
  JEncode.object [("ships", JEncode.list JEncode.string (List.map shipToString model.playerShips) )]

--Send board in JSON body and get the Game ID of the game that the user should be redirected to
sendBoard : Model -> Cmd Msg
sendBoard model = 
  Http.post {
    url = rootUrl ++ (if model.queries == "" then "game/startgame/" else "game/joingame/?" ++ model.queries),
    body = Http.jsonBody (modelEncoder model),
    expect = Http.expectJson GotSessionID sessionIDDecoder 
  }

--Get game ID from JSON
sessionIDDecoder : JDecode.Decoder Int
sessionIDDecoder = JDecode.field "gameid" JDecode.int

--Get session info of the game corresponding to the game ID specified in the URL
getSessionInfo : String -> Cmd Msg
getSessionInfo queries = 
  Http.get {
    url = rootUrl ++ "game/sessioninfo/?" ++ queries,
    expect = Http.expectJson GotJson decodeSessionInfo
  }

---------------------------------------------------------------------------------------------------------------

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
  (a::b) -> (checkOverlap (locationsForShip ship) (locationsForShip a)) || checkCollision ship b
                                  

--Given an orientation, ship size, and (row,column) coordinates, return (x,y) coordinates
--representing the exact location on the screen where the ship should be displayed
locationFromSquare : Float -> Int -> (Int, Int) -> (Float, Float)
locationFromSquare orientation shipSize (a,b) = if orientation == 0 then 
  (first gridLocation + toFloat a*squareWidth, (squareWidth*10 + second gridLocation - toFloat b*squareWidth) - toFloat (shipSize//2)*squareWidth + toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2) )
  else 
  ((first gridLocation + toFloat a*squareWidth) + toFloat (shipSize//2)*squareWidth - toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2), squareWidth*10 + second gridLocation - toFloat b*squareWidth )

--Given a ship, return the same ship, but rotated 90 degrees
rotateShip : Ship -> Ship
rotateShip ship = if ship.orientation == 0 then
  {ship | orientation = pi/2,
          location = if first ship.location > 10 - ship.size then (10 - ship.size, second ship.location) else ship.location
  }
    else 
      {ship | orientation = 0,
              location = if second ship.location > 10 - ship.size then (first ship.location, 10 - ship.size) else ship.location 
              }
----------------------------------------------------------------------------------------------------------------


--App view
view : Model -> { title : String, body : Collage Msg }
view model = 
  let 
    title = "Battleship Game Creator"

    body  = collage 700 500 (mainScreen model) 
  in { title = title, body = body}


--App background
background = rectangle 700 500 |> filled lightBlue

--Location of grid
gridLocation = (-300.0, -150.0)
--Width of each individual square
squareWidth = 30

--Shapes for the main screen
mainScreen model =  [
    background,
    text (if model.opponentName == "" then "Place your ships in the desired arrangement" else "Join game with " ++ model.opponentName) |> size 30 |> bold |> filled black |> move (-325, 200),
    text (if model.gameState == Idle then "Click on a ship to move it" else "Click on the square you would like to move your ship to") |> size 15 |> filled black |> move (0, 150),
    gameGrid |> move gridLocation,
    html 50 100 (rotateButton model) |> move (0,125),
    html 50 100 (submitButton model),
    gameShip 0 (getShipAt 0 model.playerShips),
    gameShip 1 (getShipAt 1 model.playerShips),
    gameShip 2 (getShipAt 2 model.playerShips),
    gameShip 3 (getShipAt 3 model.playerShips),
    gameShip 4 (getShipAt 4 model.playerShips),
    text model.response |> filled black
    ]

--------------------------------------------------------------------------------------------------------------------

--Shapes and buttons

--Shape representing a ship
gameShip : Int -> Ship -> Shape Msg
gameShip n ship = group [
  rectangle (squareWidth + 2) (toFloat (squareWidth*ship.size + 12)) |> filled blank,
  oval squareWidth (toFloat (squareWidth*ship.size)) |> filled grey |> addOutline (solid 1) black   |> notifyTap (EditShip n)

  ] |> rotate ship.orientation |> move (locationFromSquare ship.orientation ship.size ship.location)

--Button that sends RotateShip message to rotate the selected ship. Inactive if no ship is selected
--This function also checks if rotating the ship will result in collision with another ship, and disables the button
--if it does.
rotateButton : Model -> Html.Html Msg
rotateButton model = let
                        ship = case model.gameState of
                          MovingShip a -> a
                          Idle -> -1
                          
                        in
                        button [onClick RotateShip, disabled (model.gameState == Idle || 
                            (checkCollision (rotateShip (getShipAt ship model.playerShips)) ((List.take ship model.playerShips) ++ (List.drop (ship + 1) model.playerShips)) && ship /= -1))] 
                            [Html.text "Rotate ship"]

--Submit the positions of the ships to the server, start the game
submitButton : Model -> Html.Html Msg
submitButton model = button [onClick SendGame, disabled (model.gameState /= Idle)] [Html.text "Start Game"]

--Grid of 10 by 10 squares. Each individual square sends a SquareClicked and SquareHovered message
squares : Int -> Int ->  List (Shape Msg)
squares row column = if column == 0 then
    squares (row - 1) 10
    else if row == 0 then []
    else
    [square squareWidth |> filled blue |> addOutline (solid 2) black |> move (squareWidth*10 - (toFloat row)*squareWidth,(toFloat column)*squareWidth) |> notifyTap (SquareClicked (10 - row, 10 - column)) |> notifyEnter (SquareHovered (10 - row, 10 - column))] 
    ++ (squares row (column - 1))

--Grid containing list of all the squares defined by the function above
gameGrid = group (squares 10 10)

--App update function
update : Msg -> Model ->  (Model, Cmd Msg) 
update msg model = case msg of


    Tick time getKeyState -> (model, Cmd.none)
    MakeRequest urlRequest -> (model, Cmd.none)
    UrlChange url -> (model,Cmd.none)
    SquareClicked location -> (model, Cmd.none)
    SquareHovered location -> ( --Move a ship to the square that was just hovered if the ship is currently being moved
      case model.gameState of   -- Only move it if it passes the collision detection tests below
        Idle -> model
        MovingShip ship -> {model | 
          playerShips = 
          let 
              --Test collision detection in two steps
                -- 1. Make sure that it does not go off the grid. If it does, move the origin the appropriate amount so it stays inside
              wallShip = 
                if (getShipAt ship model.playerShips).orientation == 0 && second location > 10 - (getShipAt ship model.playerShips).size then
                changeShipLocation (getShipAt ship model.playerShips) (first location, 10 - (getShipAt ship model.playerShips).size)
                else if (getShipAt ship model.playerShips).orientation /= 0 && first location > 10 - (getShipAt ship model.playerShips).size then
                changeShipLocation (getShipAt ship model.playerShips) (10 - (getShipAt ship model.playerShips).size, second location) 
                else
                changeShipLocation (getShipAt ship model.playerShips) location
              
              --Second step of collision detection: Once the boundaries have been checked, check all the other ships to make sure that the
              --ship does not collide with any others.
              newShip = if not <| checkCollision wallShip ((List.take ship model.playerShips) ++ (List.drop (ship + 1) model.playerShips)) then
                wallShip else getShipAt ship model.playerShips
                
             in   --If the new location meets the condittions described above, then move the ship, otherwise, leave it the way it is
              (List.take ship model.playerShips) ++ [newShip] ++ (List.drop (ship + 1) model.playerShips)
               }
        , Cmd.none)
    EditShip ship -> (  --Triggered when ship is clicked. Set the game state to MovingShip (ship number)
      case model.gameState of 
        Idle -> {model | gameState = MovingShip ship}
        MovingShip _ -> {model | gameState = Idle}

      , Cmd.none)
    
    RotateShip -> ( --Rotate ship button pressed. Rotate the ship that was selected when this button was pressed
      case model.gameState of 
        Idle -> model
        MovingShip ship -> {model | playerShips = (List.take ship model.playerShips) ++ [rotateShip (getShipAt ship model.playerShips)] ++ (List.drop (ship + 1) model.playerShips) } , Cmd.none)

    SendGame -> (model, sendBoard model) --Start Game button pressed. Send the game board to the server and start the game
    
    GotSessionID result ->  --Got the new game ID. Redirect user to it
      case result of
        Ok val -> (model, load ("game.html?gameid=" ++ String.fromInt val))
        Err error -> handleError model error

    GotJson result -> --Got JSON with session info 
      case result of 
        Ok val -> ({model | opponentName = val}, Cmd.none)
        Err error -> handleError model error


handleError model error = 
    case error of
        Http.BadUrl url ->
            ({ model | response = "Error: Bad url (" ++ url ++ ")"}, Cmd.none)
        Http.Timeout ->
            ({model | response = "Error: Request timed out"}, Cmd.none)
        Http.NetworkError ->
            ({model | response = "Error: Network error"}, Cmd.none)
        Http.BadStatus statusNum ->  case statusNum of
          403 -> (model, load "login.html") --If a 403 is received, redirect user to login page
          status -> ({model | response = "Error: Bad status " ++ String.fromInt status}, Cmd.none)
        Http.BadBody body ->
            ({model | response = "Bad body " ++ body}, Cmd.none)


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