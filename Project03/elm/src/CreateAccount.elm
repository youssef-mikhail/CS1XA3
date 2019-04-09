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
    { response : String, name : String, password : String, confirmPassword : String }

type Msg
    = GotText (Result Http.Error String)
    | UsernameEntered String
    | PasswordEntered String
    | ConfirmPasswordEntered String
    | SubmitButtonPressed

login : Model -> Cmd Msg
login model =
    Http.post
        { body = Http.stringBody "application/x-www-form-urlencoded" ("username=" ++ model.name ++ "&password=" ++ model.password)
        , expect = Http.expectString GotText
        , url = "https://mac1xa3.ca/e/mikhaily/userauth/adduser/"
        
        }
init : () -> ( Model, Cmd Msg )
init _ =
 ( { name = "", password = "", response = "", confirmPassword = ""}, Cmd.none )

view : Model -> Html Msg
view model =
    div [] [
        h1 [] [text "Create Battleship Account"],
        input [placeholder "Username", value model.name, onInput UsernameEntered ] [],
        input [placeholder "Password", value model.password, onInput PasswordEntered, type_ "password" ] [],
        input [placeholder "Confirm Password", value model.confirmPassword, onInput ConfirmPasswordEntered, type_ "password" ] [],
        button [onClick SubmitButtonPressed, disabled (model.password /= model.confirmPassword || model.password == "" || model.name == "") ] [text "Create Account"],
        a [href "login.html"] [text "Already have an account? You can log in here."],
        text model.response
     ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->
            case result of
                Ok "Success" ->
                    (model, load (rootURL ++ "static/login.html"))

                Ok val ->
                    ( { model | response = val }, Cmd.none )

                Err error ->
                    ( handleError model error, Cmd.none )
        UsernameEntered username ->
            ({model | name = username}, Cmd.none)
        PasswordEntered passwd -> 
            ({model | password = passwd}, Cmd.none)
        ConfirmPasswordEntered passwd ->
            ({model | confirmPassword = passwd}, Cmd.none)
        SubmitButtonPressed -> (model, login model)

handleError model error =
    case error of
        Http.BadUrl url ->
            { model | response = "bad url: " ++ url }
        Http.Timeout ->
            { model | response = "timeout" }
        Http.NetworkError ->
            { model | response = "network error" }
        Http.BadStatus i ->
            { model | response = "bad status " ++ String.fromInt i }
        Http.BadBody body ->
            { model | response = "bad body " ++ body }

subscriptions model = Sub.none