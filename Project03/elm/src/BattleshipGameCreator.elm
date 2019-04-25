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


type Msg
 = Tick Float GetKeyState
 | MakeRequest Browser.UrlRequest
 | UrlChange Url.Url
 | SquareClicked (Int, Int)
 | MouseMoved (Float, Float)
 | EditShip Int
 | SquareHovered (Int, Int)
 | RotateShip
 | SendGame
 | GotResponse (Result Http.Error String)
 | GotJson (Result Http.Error String)
 | GotSessionID (Result Http.Error Int)



--App model
type alias Model = 
        { currentClick : (Int, Int),
          gameState : State,
          mouseLocation : (Float, Float),
          playerShips : List Ship,
          response : String,
          queries : String,
          title : String,
          opponentName : String
          }

--Initial values for the app model
init : () -> Url.Url -> Key -> ( Model, Cmd Msg )
init flags url key = 
  ( {currentClick = (0,0), 
      playerShips = 
        [Ship (0,0) 0 5, Ship (1,0) 0 4, Ship (2,0) 0 3, Ship (3,0) 0 3, Ship (4,0) 0 2],
      gameState = Idle,
      mouseLocation = (0,0),
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




decodeSessionInfo : JDecode.Decoder String
decodeSessionInfo = JDecode.field "opponentName" JDecode.string

shipToString : Ship -> String
shipToString ship = String.fromInt (first ship.location) ++ String.fromInt (second ship.location)
  ++ (if ship.orientation == 0 then "D" else "H") ++ String.fromInt ship.size


modelEncoder : Model -> JEncode.Value
modelEncoder model =
  JEncode.object [("ships", JEncode.list JEncode.string (List.map shipToString model.playerShips) )]


sendBoard : Model -> Cmd Msg
sendBoard model = 
  Http.post {
    url = rootUrl ++ (if model.opponentName == "" then "game/startgame/" else "game/joingame/?" ++ model.queries),
    body = Http.jsonBody (modelEncoder model),
    expect = Http.expectJson GotSessionID sessionIDDecoder 
  }

sessionIDDecoder : JDecode.Decoder Int
sessionIDDecoder = JDecode.field "gameid" JDecode.int

getSessionInfo : String -> Cmd Msg
getSessionInfo queries = 
  Http.get {
    url = rootUrl ++ "game/sessioninfo/?" ++ queries,
    expect = Http.expectJson GotJson decodeSessionInfo
  }

getShipAt : Int -> List Ship -> Ship
getShipAt n xs = case List.head (List.drop n xs) of 
  Just a -> a
  Nothing -> Ship (0,0) 0 0


changeShipLocation : Ship -> (Int, Int) -> Ship
changeShipLocation ship newLocation = {ship | location = newLocation}

zip : List a -> List b -> List (a, b)
zip a b = case a of
  [] -> []
  (x::xs) -> case b of
    [] -> []
    (y::ys) -> [(x, y)] ++ zip xs ys

checkOverlap : List a ->  List a -> Bool
checkOverlap a b = case a of
  [] -> False
  (x::xs) -> List.member x b || checkOverlap xs b

locationsForShip : Ship -> List (Int, Int)
locationsForShip ship = if ship.orientation == 0 then 
  zip (List.repeat ship.size (first ship.location)) (List.range (second ship.location) (second ship.location + ship.size))
  else
  zip (List.range (first ship.location) (first ship.location + ship.size)) (List.repeat ship.size (second ship.location)) 



checkCollision : Ship -> List Ship -> Bool
checkCollision ship ships = case ships of
  [] -> False
  (a::b) -> (checkOverlap (locationsForShip ship) (locationsForShip a) && ship.location /= a.location) || checkCollision ship b
                                  


locationFromSquare : Float -> Int -> (Int, Int) -> (Float, Float)
locationFromSquare orientation shipSize (a,b) = if orientation == 0 then 
  (first gridLocation + toFloat a*squareWidth, (squareWidth*10 + second gridLocation - toFloat b*squareWidth) - toFloat (shipSize//2)*squareWidth + toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2) )
  else 
  ((first gridLocation + toFloat a*squareWidth) + toFloat (shipSize//2)*squareWidth - toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2), squareWidth*10 + second gridLocation - toFloat b*squareWidth )


--TODO: Make sure ships do not overlap after rotating
rotateShip : Ship -> Ship
rotateShip ship = if ship.orientation == 0 then
  {ship | orientation = pi/2,
          location = if first ship.location > 10 - ship.size then (10 - ship.size, second ship.location) else ship.location
  }
    else 
      {ship | orientation = 0,
              location = if second ship.location > 10 - ship.size then (first ship.location, 10 - ship.size) else ship.location 
              }



view : Model -> { title : String, body : Collage Msg }
view model = 
  let 
    title = "Battleship Game"

    body  = collage 700 500 (mainScreen model) 
  in { title = title, body = body}



background = rectangle 700 500 |> filled lightBlue


gridLocation = (-300.0, -150.0)
squareWidth = 30

mainScreen model =  [
    background,
    text (if model.opponentName == "" then "Place your ships in the desired arrangement" else "Join game with " ++ model.opponentName) |> size 30 |> bold |> filled black |> move (-325, 200),
    text (if model.gameState == Idle then "Click on a ship to move it" else "Click on the square you would like to move your ship to") |> size 15 |> filled black |> move (0, 150),
    gameGrid |> move gridLocation |> notifyMouseMoveAt MouseMoved ,
    html 50 100 (rotateButton model) |> move (25,125),
    html 50 100 (submitButton model),
    gameShip 0 (getShipAt 0 model.playerShips),
    gameShip 1 (getShipAt 1 model.playerShips),
    gameShip 2 (getShipAt 2 model.playerShips),
    gameShip 3 (getShipAt 3 model.playerShips),
    gameShip 4 (getShipAt 4 model.playerShips),
    text model.response |> filled black,
    text (Debug.toString model.queries) |> filled black |> move (0, -100)
    ]


--TODO: make dragging and dropping easier
gameShip : Int -> Ship -> Shape Msg
gameShip n ship = group [
  rectangle (squareWidth + 2) (toFloat (squareWidth*ship.size + 12)) |> filled blank,
  oval squareWidth (toFloat (squareWidth*ship.size)) |> filled grey |> addOutline (solid 1) black   |> notifyTap (EditShip n)

  ] |> rotate ship.orientation |> move (locationFromSquare ship.orientation ship.size ship.location)

editShipButton : Int -> Model -> Html.Html Msg
editShipButton ship model = button [onClick (EditShip ship)] [Html.text ("Edit ship " ++ String.fromInt (ship + 1))]

rotateButton : Model -> Html.Html Msg
rotateButton model = button [onClick RotateShip, disabled (model.gameState == Idle)] [Html.text "Rotate ship"]

submitButton : Model -> Html.Html Msg
submitButton model = button [onClick SendGame, disabled (model.gameState /= Idle)] [Html.text "Start Game"]


squares : Int -> Int ->  List (Shape Msg)
squares row column = if column == 0 then
    squares (row - 1) 10
    else if row == 0 then []
    else
    [square squareWidth |> filled blue |> addOutline (solid 2) black |> move (squareWidth*10 - (toFloat row)*squareWidth,(toFloat column)*squareWidth) |> notifyTap (SquareClicked (10 - row, 10 - column)) |> notifyEnter (SquareHovered (10 - row, 10 - column))] 
    ++ (squares row (column - 1))

gameGrid = group (squares 10 10)

--App update function
update : Msg -> Model ->  (Model, Cmd Msg) 
update msg model = case msg of

    --Handling of real time animations and events that are not triggered by other messages
    Tick time getKeyState -> (
      case model.gameState of
        Idle -> model
      
        --MovingShip ship -> {model | playerShips = (List.take (ship - 1) model.playerShips) ++ [model.mouseLocation] ++ (List.drop (ship + 1) model.playerShips)}
        MovingShip ship -> model
      
      , Cmd.none)

      
    MakeRequest urlRequest -> (model, Cmd.none)
    UrlChange url -> (model,Cmd.none)
    SquareClicked location -> ({model | currentClick = location}, Cmd.none)
    SquareHovered location -> (
      case model.gameState of
        Idle -> model
        MovingShip ship -> {model | 
          playerShips = 
          let 
              newShip = if not <| checkCollision (changeShipLocation (getShipAt ship model.playerShips) location) ((List.take ship model.playerShips) ++ (List.drop (ship + 1) model.playerShips)) then
                if (getShipAt ship model.playerShips).orientation == 0 && second location > 10 - (getShipAt ship model.playerShips).size 
                 && (not <| checkCollision (changeShipLocation (getShipAt ship model.playerShips) location) ((List.take ship model.playerShips) ++ (List.drop (ship + 1) model.playerShips))) then
                changeShipLocation (getShipAt ship model.playerShips) (first location, 10 - (getShipAt ship model.playerShips).size)
                else if (getShipAt ship model.playerShips).orientation /= 0 && first location > 10 - (getShipAt ship model.playerShips).size 
                && (not <| checkCollision (changeShipLocation (getShipAt ship model.playerShips) location) ((List.take ship model.playerShips) ++ (List.drop (ship + 1) model.playerShips))) then
                changeShipLocation (getShipAt ship model.playerShips) (10 - (getShipAt ship model.playerShips).size, second location) 
                else
                changeShipLocation (getShipAt ship model.playerShips) location

                else getShipAt ship model.playerShips
             in
              (List.take ship model.playerShips) ++ [newShip] ++ (List.drop (ship + 1) model.playerShips)
               }
        , Cmd.none)
    MouseMoved location -> ({model | mouseLocation = location}, Cmd.none)
    EditShip ship -> (
      case model.gameState of 
        Idle -> {model | gameState = MovingShip ship}
        MovingShip _ -> {model | gameState = Idle}

      , Cmd.none)

    RotateShip -> ( 
      case model.gameState of 
        Idle -> model
        MovingShip ship -> {model | playerShips = (List.take ship model.playerShips) ++ [rotateShip (getShipAt ship model.playerShips)] ++ (List.drop (ship + 1) model.playerShips) } , Cmd.none)

    SendGame -> (model, sendBoard model)

    GotResponse result -> 
      case result of 
        Ok val -> ({model | response = val}, Cmd.none)
        Err error -> (handleError model error, Cmd.none)
    
    GotSessionID result ->
      case result of
        Ok val -> (model, load (rootUrl ++ "static/game.html?gameid=" ++ String.fromInt val))
        Err error -> (handleError model error, Cmd.none)

    GotJson result -> 
      case result of 
        Ok val -> ({model | opponentName = val}, Cmd.none)
        Err error -> (handleError model error, Cmd.none)


handleError model error = 
    case error of
        Http.BadUrl url ->
            { model | response = "Error: Bad url (" ++ url ++ ")"}
        Http.Timeout ->
            {model | response = "Error: Request timed out"}
        Http.NetworkError ->
            {model | response = "Error: Network error"}
        Http.BadStatus status ->
            {model | response = "Error: Bad status " ++ String.fromInt status}
        Http.BadBody body ->
            {model | response = "Bad body " ++ body}


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