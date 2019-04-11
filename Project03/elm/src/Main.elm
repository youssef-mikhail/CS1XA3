module Main exposing (..)
import Browser
import Browser.Navigation exposing (load)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import String

rootURL = "https://mac1xa3.ca/e/mikhaily/"

main =
 Browser.element
     { init = init
     , update = update
     , subscriptions = subscriptions
     , view = view
     }

type alias Model =
    { currentUser : String, error : String }

type Msg
    = GotText (Result Http.Error String)

checkAuth : Cmd Msg
checkAuth =
    Http.get
        { expect = Http.expectString GotText
        , url = "https://mac1xa3.ca/e/mikhaily/userauth/userinfo/"
        }
init : () -> ( Model, Cmd Msg )
init _ =
 ( { currentUser = "", error = ""}, checkAuth)

view : Model -> Html Msg
view model =
    if model.error == "" then
    div [] [
        h1 [] [text "Welcome to Battleship!"],
        h2 [] [text ("You are currently logged in as: " ++ model.currentUser)]
     ]
     else 
        text model.error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->
            case result of
                Ok "NotLoggedIn" ->
                    (model, load (rootURL ++ "static/login.html"))

                Ok val ->
                    ( { model | currentUser = val }, Cmd.none )

                Err error ->
                    ( handleError model error, Cmd.none )


handleError model error =
    case error of
        Http.BadUrl url ->
            { model | error = "bad url: " ++ url }
        Http.Timeout ->
            { model | error = "timeout" }
        Http.NetworkError ->
            { model | error = "network error" }
        Http.BadStatus i ->
            { model | error = "bad status " ++ String.fromInt i }
        Http.BadBody body ->
            { model | error = "bad body " ++ body }

subscriptions model = Sub.none