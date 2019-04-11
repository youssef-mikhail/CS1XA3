import Browser
import Browser.Navigation exposing (Key(..))
import GraphicSVG exposing (..)
import GraphicSVG.App exposing (..)
import Html
import Html.Events exposing (onClick)
import Url

type Msg
 = Tick Float GetKeyState
 | MakeRequest Browser.UrlRequest
 | UrlChange Url.Url
 | SquareClicked (Int, Int)



--App model
type alias Model = 
        { currentClick : (Int, Int)
          }


--Initial values for the app model
init : () -> Url.Url -> Key -> ( Model, Cmd Msg )
init flags url key = 
  ( {currentClick = (0,0)}, Cmd.none)


view : Model -> { title : String, body : Collage Msg }
view model = 
  let 
    title = "Battleship Game"

--Switch to a different view for each state the game is in
    body  = collage 700 500 (mainScreen model) 
  in { title = title, body = body}


mainScreen model =  [
    gameGrid |> move (-250, -25),
    text ("(" ++ (String.fromInt (Tuple.first model.currentClick)) ++ "," ++ String.fromInt (Tuple.second model.currentClick) ++ ")") |> filled black
    ]

ship1 = circle 30 |> filled blue

ship2 = circle 30 |> filled blue

ship3 = circle 30 |> filled blue

ship4 = circle 30 |> filled blue

ship5 = circle 30 |> filled blue

squares : Int -> Int ->  List (Shape Msg)
squares row column = if column == 0 then
    squares (row - 1) 10
    else if row == 0 then []
    else
    [square 25 |> filled blue |> addOutline (solid 2) black |> move ( 250.0 - (toFloat row)*25.0,(toFloat column)*25.0) |>notifyTap (SquareClicked (10 - row, 10 - column))] 
    ++ (squares row (column - 1))

gameGrid = group (squares 10 10)

--App update function
update : Msg -> Model ->  (Model, Cmd Msg) 
update msg model = case msg of

                      --Handling of real time animations and events that are not triggered by other messages
                      Tick time getKeyState -> (model, Cmd.none)

                        
                      MakeRequest urlRequest -> (model, Cmd.none)
                      UrlChange url -> (model,Cmd.none)
                      SquareClicked location -> ({model | currentClick = location}, Cmd.none)




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