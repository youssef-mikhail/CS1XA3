module Main exposing (..)
import Browser
import Browser.Navigation exposing (load)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import String

rootURL = "https://mac1xa3.ca/e/mikhaily/"

---------------------------------------------------------------------------------------------------------

-- Models, Messages, etc

main =
 Browser.element
     { init = init
     , update = update
     , subscriptions = subscriptions
     , view = view
     }

--App Model
type alias Model =
    { response : String, name : String, password : String, confirmPassword : String }

type Msg
    = GotText (Result Http.Error String) --Triggered when response is recieved from the server
    | UsernameEntered String    --Triggered when something is entered in the username field
    | PasswordEntered String    --Triggered when something is entered in the password field
    | ConfirmPasswordEntered String 
    | SubmitButtonPressed  

--Initial model values
init : () -> ( Model, Cmd Msg )
init _ =
 ( { name = "", password = "", response = "", confirmPassword = ""}, Cmd.none )

---------------------------------------------------------------------------------------------------------


--App view
view : Model -> Html Msg
view model =
    div [] [
        h1 [] [text "Create Battleship Account"],
        input [placeholder "Username", value model.name, onInput UsernameEntered ] [],
        input [placeholder "Password", value model.password, onInput PasswordEntered, type_ "password" ] [],
        input [placeholder "Confirm Password", value model.confirmPassword, onInput ConfirmPasswordEntered, type_ "password" ] [],
        button [onClick SubmitButtonPressed, disabled (model.password /= model.confirmPassword || model.password == "" || model.name == "") ] [text "Create Account"],  --submit button is only enabled when password and confirm password boxes match
        a [href "login.html"] [text "Already have an account? You can log in here."],
        text model.response
     ]

--Submit credentials in POST body and get response
login : Model -> Cmd Msg
login model =
    Http.post
        { body = Http.stringBody "application/x-www-form-urlencoded" ("username=" ++ model.name ++ "&password=" ++ model.password)
        , expect = Http.expectString GotText
        , url = "https://mac1xa3.ca/e/mikhaily/userauth/adduser/"
        
        }

--Update function
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->   --Got response from server after submitting credentials
            case result of 
                Ok "Success" -> --Login successful, redirect to login page
                    (model, load (rootURL ++ "static/login.html"))

                Ok val ->   --Login not successful, show server response
                    ( { model | response = val }, Cmd.none )

                Err error ->    --Http error
                    ( handleError model error, Cmd.none )
        UsernameEntered username -> --Set username to whatever is in the username box. Same thing is done for messages below
            ({model | name = username}, Cmd.none)
        PasswordEntered passwd -> 
            ({model | password = passwd}, Cmd.none)
        ConfirmPasswordEntered passwd ->
            ({model | confirmPassword = passwd}, Cmd.none)
        SubmitButtonPressed -> (model, login model) --Submit values in boxes to the server

--Handle HTTP errors
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