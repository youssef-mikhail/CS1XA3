import Browser
import Browser.Navigation exposing (Key(..))
import GraphicSVG exposing (..)
import GraphicSVG.App exposing (..)
import Html
import Html.Events exposing (onClick)
import Url
import Random

type Msg
 = Tick Float GetKeyState
 | MakeRequest Browser.UrlRequest
 | UrlChange Url.Url
 | StartGame
 | RandomTargets (List ((Float, Float), TargetType))
 | TargetClicked
 | DudClicked
 | Help
 | ReturnMenu


--Generates a list of 10 upcoming target locations, as well as their target types (actual target or dud)
spawnGenerator : Random.Generator (List ((Float, Float), TargetType))
spawnGenerator = Random.list 10 <| Random.pair (Random.pair (Random.float -300 300) (Random.float -200 200)) 
  (Random.map (\x -> if x == 5 then Dud else Target) (Random.int 1 10))




--A type used to distinguish good targets from trap targets
type TargetType 
  = Target
  | Dud


--Keeps track of what the game is currently doing
type State
  = GameRunning
  | MainMenu
  | GameOver
  | DudEliminated
  | Animating 
  | HelpScreen


--App model
type alias Model = 
        { state : State,  --Keeps track of game state using the State type
          score : Int,  --Keeps track of current score
          highScore : Int, --Keeps track of high score
          currentTarget : Shape Msg, --the current target that is on the screen while the game is running
          futureLocations : List ((Float, Float), TargetType), --The list of future target spawn points, as well as their type
          timeToLive : Float, --Time remaining until target disappears
          currentLocation : (Float, Float), --Keeps track of the current target's location
          currentSpeed : Float, --The amount of time that it should take each target to disappear
          currentType : TargetType, --Keeps track of the type of the current target
          animationTime : Float --Keeps track of how long it has been since an animation has started
          }


--Initial values for the app model
init : () -> Url.Url -> Key -> ( Model, Cmd Msg )
init flags url key = 
  ( { state = MainMenu, 
      score = 0, 
      highScore = 0, 
      currentTarget = gameTarget, 
      futureLocations = [],
      timeToLive = 180,
      currentLocation = (0,0),
      currentSpeed = 180,
      currentType = Target,
      animationTime = 0 },
      Random.generate RandomTargets spawnGenerator)


view : Model -> { title : String, body : Collage Msg }
view model = 
  let 
    title = "Quick Click"

--Switch to a different view for each state the game is in
    body  = 
      if model.state == MainMenu then collage 700 500 (menuShapes model) 
      else if model.state == HelpScreen then collage 700 500 (helpScreen model)
      else if model.state == GameOver then collage 700 500 (gameOverShapes model)
      else collage 700 500 (gameShapes model)
  in { title = title, body = body}



--HTML button to start the game
startButton : String -> Html.Html Msg
startButton message = Html.button [onClick StartGame] [Html.text message ]

--HTML button to show help
helpButton : Html.Html Msg
helpButton = Html.button [onClick Help] [Html.text "How to play"]

--HTML button to return to menu
backButton : Html.Html Msg
backButton = Html.button [onClick ReturnMenu] [Html.text "Return to Main Menu"]

--Help screen view
helpScreen : Model -> List (Shape Msg)
helpScreen model = [
  text "How to Play" |> size 50 |> bold |> filled black |> move (-300, 100),
  text "Click these targets before they disappear" |> size 20 |> filled black |> move (-200, 45),
  target |> scale 0.6 |> move (-250, 50),
  text "Avoid clicking these targets" |> size 20 |> filled black |> move(-200, -50),
  dud |> scale 0.6 |> move (-250, -50),
  html 100.0 100.0 backButton |> move (-10, -75)
  ] ++ targetAnimations model


--Menu view
menuShapes : Model -> List (Shape Msg)
menuShapes model = 
  [ html 100.0 100.0 (startButton "Start Game") |> move (-75, -25),
    html 100.0 100.0 helpButton |> move (15, -25),
    text ("High Score: " ++ String.fromInt model.highScore) |> size 20 |> filled black |> move (-50, 25),
    text "Quick Click" |> size 50 |> bold |> filled black |> move (-125,75)
  ] ++ targetAnimations model


--Menu animation that allows targets to scroll along the top and bottom of the screen. This view is combined with the menu and help screen views
targetAnimations model = [
    targetRow |> move (model.animationTime,200),
    targetRow |> move (-model.animationTime, -200)
    ]

--This is the view that is visible during the game
gameShapes : Model -> List (Shape Msg)
gameShapes model =
  [  text ("Score: " ++ (String.fromInt model.score ) ) |> bold |> filled black |> move (-325, 225),
    model.currentTarget
  ]

--Game over screen view
gameOverShapes : Model -> List (Shape Msg)
gameOverShapes model = 
  (gameShapes model) ++ [
    rectangle 700 500 |> filled (rgba 80 80 80 0.6),
    html 100.0 100.0 (startButton "Play Again") |> move (-100, 0),
    text "Game Over!" |> size 50 |> bold |> filled black |> move (-125,150),
    text ("Your score was: " ++ (String.fromInt model.score)) |> size 30 |> filled black |> move (-125, 100),
    text ("Your high score is: " ++ (String.fromInt model.highScore)) |> size 30 |> filled black |> move (-125, 50),
    html 200.0 100.0 backButton
  ] 
  

--A group of shapes representing a row of targets (used for menu animation)
targetRow : Shape Msg
targetRow = group [
  target,
  target |> move (110, 0),
  target |> move (220, 0),
  target |> move (330, 0),
  target |> move (440, 0),
  target |> move (-110, 0),
  target |> move (-220, 0),
  target |> move (-330,0),
  target |> move (-440, 0)
  ]


--The target shape used during the game. Unlike target, gameTarget sends a message when clicked
gameTarget : Shape Msg
gameTarget = target |> notifyTap TargetClicked

--The target shape. Unlike gameTarget, this shape doesn't send any messages (used in places where a target is shown but shouldn't be clicked)
target : Shape Msg
target = group [
    circle 50 |> filled white |> addOutline (solid 2) black,
    circle 40 |> filled blue |> addOutline (solid 2) black,
    circle 20 |> filled yellow |> addOutline (solid 2) black,
    circle 8 |> filled red |> addOutline (solid 2) black
  ]

--The "bad target" shape used during the game. This sends a message when clicked
gameDud : Shape Msg
gameDud =  dud |> notifyTap DudClicked


--The "bad target" shape. Unlike gameTarget, this shape doesn't send a message
dud : Shape Msg
dud =  group [
    target,
    line (-30, 30) (30, -30) |> outlined (solid 10) red,
    line (30, 30) (-30, -30) |> outlined (solid 10) red
  ]


--App update function
update : Msg -> Model ->  (Model, Cmd Msg) 
update msg model = case msg of

                      --Handling of real time animations and events that are not triggered by other messages
                      Tick time getKeyState -> ( 

                        --Handle animation in the menu and help screen
                          if model.state == MainMenu || model.state == HelpScreen then
                            {model | 
                              animationTime = if model.animationTime < 109 then model.animationTime + 1 else 0
                              }
                        --Handle animations of targets entering the screen during a game
                          else if model.state == Animating then
                            {model | 
                              currentTarget = (if model.currentType == Target then gameTarget else gameDud) |> move (Tuple.first model.currentLocation, -250 + (model.animationTime/15)*(250 + Tuple.second model.currentLocation)),
                              animationTime = model.animationTime + 1,
                              state = if model.animationTime < 15 then Animating else GameRunning
                              }
                        --Handle all real-time events during a game, such as target shrinking.
                          else if model.state == GameRunning then
                            {model | 
                              timeToLive = model.timeToLive - 1,
                              currentTarget = (if model.currentType == Dud then gameDud else gameTarget) |> scale (model.timeToLive/model.currentSpeed) |> move model.currentLocation,  --Scale our target based on how much time it has left to live
                              state = if model.timeToLive == 0 then   --Game ends when timeToLive is 0 (indicating that the target has disappeared)
                                        if model.currentType == Target then GameOver else DudEliminated
                                      else GameRunning
                              }
                          
                          --Spawn another target once a dud target has disappeared
                          else if model.state == DudEliminated then
                            {model |
                              timeToLive = model.currentSpeed,
                              currentLocation = Tuple.first (Maybe.withDefault ((0, 0), Target) (List.head model.futureLocations)),
                              futureLocations = Maybe.withDefault [] (List.tail model.futureLocations),
                              currentType = Tuple.second (Maybe.withDefault ((0, 0), Target) (List.head model.futureLocations)),
                              state = Animating,
                              animationTime = 0
                            }

                            --Update high score when game ends
                          else if model.state == GameOver then
                            {model |
                              highScore = if model.score > model.highScore then model.score else model.highScore}
                          else model , 
                            Cmd.none)
                      MakeRequest urlRequest -> (model, Cmd.none)
                      UrlChange url -> (model,Cmd.none)


                      --Triggered by the start button. Set up our model for a new game
                      StartGame -> ({model | 
                        state = Animating, 
                        score = 0, 
                        currentLocation = Tuple.first (Maybe.withDefault ((0, 0), Target) (List.head model.futureLocations)), 
                        futureLocations = Maybe.withDefault [] (List.tail model.futureLocations),
                        currentSpeed = 180,
                        timeToLive = 180,
                        currentType = Tuple.second (Maybe.withDefault ((0, 0), Target) (List.head model.futureLocations)),
                        animationTime = 0},
                         Cmd.none)
                        
                      --Message sent when a random list of spawn locations is generated
                      RandomTargets list -> ({model | futureLocations = list}, Cmd.none)
                      --Message sent when a target is clicked.
                      TargetClicked -> ({model | 
                        currentLocation = Tuple.first (Maybe.withDefault ((0, 0), Target) (List.head model.futureLocations)), --Get the next random location in our list
                        score = model.score + 1, --increment score
                        futureLocations = Maybe.withDefault [] (List.tail model.futureLocations), --Remove the first location from the list, as we will be using it next
                        timeToLive = model.currentSpeed, --Reset time to live of next target
                        currentSpeed = model.currentSpeed - 3, --Decrease the amount of time to live the next target has, increasing the speed that it will shrink at
                        animationTime = 0, --Prepare for animation
                        state = Animating, --Animate next target into the screen
                        highScore = if model.score > model.highScore then model.score else model.highScore, --update high score
                        currentType = Tuple.second (Maybe.withDefault ((0, 0), Target) (List.head model.futureLocations))}, --Set the type of the next target
                        if model.futureLocations == [] then Random.generate RandomTargets spawnGenerator else Cmd.none ) --If the list of future spawn locations is empty, randomly generate 10 more
                      
                      --Handle when a dud target is clicked. End the game
                      DudClicked -> ({model |
                        state = GameOver}, Cmd.none)
                      --Handle help button being clicked in the menu. Show the help screen
                      Help -> ({model | state = HelpScreen}, Cmd.none)
                      --Return to menu when the return button is pressed
                      ReturnMenu -> ({model | state = MainMenu}, Cmd.none)


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