import Browser
import Browser.Navigation exposing (Key(..))
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
 | SquareHovered (Int, Int)
 | SendGame
 | GotResponse (Result Http.Error String)
 | GotGameData (Result Http.Error GameData)
 | GotSessionInfo (Result Http.Error String)



--App model
type alias Model = 
        { gameState : State,
          gameData : GameData,
          queries : String,
          response : String,
          sessionDescription : String,
          targetLocation : (Int, Int)
          }

type alias Ship = 
  {
    location : (Int, Int),
    orientation : Float,
    size : Int
  }


type alias GameData = 
  {
    playerShips : List Ship,
    opponentSunkShips : List Ship,
    playerMissedMissiles : List (Int, Int),
    playerHitMissiles : List (Int, Int),
    opponentHitMissiles : List (Int, Int),
    opponentMissedMissiles : List (Int, Int),
    isPlayerTurn : Bool
  }


type State = 
  Idle
  | MovingTarget
  | WaitingTurn

--Initial values for the app model
init : () -> Url.Url -> Key -> ( Model, Cmd Msg )
init flags url key = 
  ( { response = "",
      gameState = WaitingTurn,
      sessionDescription = "",
      targetLocation = (0,0),
      queries = Maybe.withDefault "" url.query,
      gameData = GameData [Ship (0,0) 0.0 0] [Ship (0,0) 0.0 0] [(0,0)] [(0,0)] [(0,0)] [(0,0)] False 
      }, Cmd.batch [getGameState (Maybe.withDefault "" url.query), getSessionData (Maybe.withDefault "" url.query)] )


decodeGameData : JDecode.Decoder GameData
decodeGameData = JDecode.map7 GameData
  (JDecode.field "playerShips" (JDecode.list (JDecode.map stringToShip JDecode.string)))
  (JDecode.field "opponentSunkShips" (JDecode.list (JDecode.map stringToShip JDecode.string)))
  (JDecode.field "playerMissedMissiles" (JDecode.list (JDecode.map stringToMissile JDecode.string)))
  (JDecode.field "playerHitMissiles" (JDecode.list (JDecode.map stringToMissile JDecode.string)))
  (JDecode.field "opponentHitMissiles" (JDecode.list (JDecode.map stringToMissile JDecode.string)))
  (JDecode.field "opponentMissedMissiles" (JDecode.list (JDecode.map stringToMissile JDecode.string)))
  (JDecode.field "isPlayerTurn" JDecode.bool)

getSessionData : String -> Cmd Msg
getSessionData query = 
  Http.get {
    url = rootUrl ++ "game/sessioninfo/?" ++ query,
    expect = Http.expectJson GotSessionInfo sessionInfoDecoder
  }

sessionInfoDecoder : JDecode.Decoder String
sessionInfoDecoder = JDecode.field "sessionDescription" JDecode.string

stringToMissile : String -> (Int, Int)
stringToMissile strMissile = (Maybe.withDefault 0 (String.toInt (String.dropRight 1 strMissile)), Maybe.withDefault 0 (String.toInt (String.dropLeft 1 strMissile)))

getGameState : String -> Cmd Msg
getGameState queries = 
  Http.get {
    url = rootUrl ++ "game/refreshgame/?" ++ queries,
    expect = Http.expectJson GotGameData decodeGameData
  }

shipToString : Ship -> String
shipToString ship = String.fromInt (first ship.location) ++ String.fromInt (second ship.location)
  ++ (if ship.orientation == 0 then "D" else "H")


stringToShip : String -> Ship
stringToShip strShip = Ship 
  (Maybe.withDefault 0 (String.toInt (String.dropRight 3 strShip)), Maybe.withDefault 0 (String.toInt (String.slice 1 2 strShip))) 
  (if String.slice 2 3 strShip == "D" then 0 else pi/2) 
  (Maybe.withDefault 0 (String.toInt (String.dropLeft 3 strShip)))


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

locationFromSquare2 : Float -> Int -> (Int, Int) -> (Float, Float)
locationFromSquare2 orientation shipSize (a,b) = if orientation == 0 then 
  (first grid2Location + toFloat a*squareWidth, (squareWidth*10 + second grid2Location - toFloat b*squareWidth) - toFloat (shipSize//2)*squareWidth + toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2) )
  else 
  ((first grid2Location + toFloat a*squareWidth) + toFloat (shipSize//2)*squareWidth - toFloat (remainderBy 2 (shipSize + 1))*(squareWidth/2), squareWidth*10 + second grid2Location - toFloat b*squareWidth )

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
grid2Location = (50.0, -150.0)
squareWidth = 30

mainScreen model =  [
    background,
    text model.sessionDescription |> size 30 |> bold |> filled black |> move (-325, 200),
    playerGrid |> move gridLocation ,
    enemyGrid |> move grid2Location,
    html 50 100 (submitMoveButton model) |> move (150,-150),
    text model.response |> filled black |> move (-350, -200),
    target |> move (locationFromSquare2 0 1 model.targetLocation),
    text (Debug.toString model.gameData.playerShips) |> filled black |> move (-350, -200)
    ] ++ playerShips model.gameData.playerShips


target : Shape Msg
target = group [
  circle (squareWidth/2) |> outlined (solid 2) red,
  line (0, squareWidth/2) (0, squareWidth/4) |> outlined (solid 2) red,
  line (0, -squareWidth/2) (0, -squareWidth/4) |> outlined (solid 2) red,
  line (-squareWidth/2, 0) (-squareWidth/4, 0) |> outlined (solid 2) red,
  line (squareWidth/2, 0) (squareWidth/4, 0) |> outlined (solid 2) red
  ]

playerShips : List Ship -> List (Shape Msg)
playerShips ships = case ships of
    [] -> []
    (a::b) -> [gameShip a] ++ playerShips b

--TODO: make dragging and dropping easier
gameShip : Ship -> Shape Msg
gameShip ship = group [
  rectangle (squareWidth + 2) (toFloat (squareWidth*ship.size + 12)) |> filled blank,
  oval squareWidth (toFloat (squareWidth*ship.size)) |> filled grey |> addOutline (solid 1) black 

  ] |> rotate ship.orientation |> move (locationFromSquare ship.orientation ship.size ship.location)


submitMoveButton : Model -> Html.Html Msg
submitMoveButton model = button [onClick SendGame, disabled (not model.gameData.isPlayerTurn)] [Html.text "Fire Missile"]



squaresWithClickMsg : Int -> Int ->  List (Shape Msg)
squaresWithClickMsg row column = if column == 0 then
    squaresWithClickMsg (row - 1) 10
    else if row == 0 then []
    else
    [square squareWidth |> filled blue |> addOutline (solid 2) black |> move (squareWidth*10 - (toFloat row)*squareWidth,(toFloat column)*squareWidth) |> notifyTap (SquareClicked (10 - row, 10 - column)) |> notifyEnter (SquareHovered (10 - row, 10 - column))] 
    ++ (squaresWithClickMsg row (column - 1))

squares : Int -> Int ->  List (Shape Msg)
squares row column = if column == 0 then
    squares (row - 1) 10
    else if row == 0 then []
    else
    [square squareWidth |> filled blue |> addOutline (solid 2) black |> move (squareWidth*10 - (toFloat row)*squareWidth,(toFloat column)*squareWidth) ] 
    ++ (squares row (column - 1))


playerGrid = group (squares 10 10)
enemyGrid = group (squaresWithClickMsg 10 10)

--App update function
update : Msg -> Model ->  (Model, Cmd Msg) 
update msg model = case msg of

    --Handling of real time animations and events that are not triggered by other messages
    Tick time getKeyState -> (model, Cmd.none)

      
    MakeRequest urlRequest -> (model, Cmd.none)
    UrlChange url -> (model,Cmd.none)
    SquareClicked location -> ({model | gameState = Idle, targetLocation = location}, Cmd.none)
    SquareHovered location -> (
      case model.gameState of
        Idle -> model

        MovingTarget -> {model | targetLocation = location}

        WaitingTurn -> model

        , Cmd.none)

    SendGame -> (model, Cmd.none)

    GotResponse result -> 
      case result of 
        Ok val -> ({model | response = val}, Cmd.none)
        Err error -> (handleError model error, Cmd.none)
    
    GotGameData result ->
      case result of
        Ok data -> ({model | gameData = data}, Cmd.none)
        Err error -> (handleError model error, Cmd.none)

    GotSessionInfo result ->
      case result of
        Ok info -> ({model | sessionDescription = info}, Cmd.none)
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
            {model | response = "Error: Bad body " ++ body}


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