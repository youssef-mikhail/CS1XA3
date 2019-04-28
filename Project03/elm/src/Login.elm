module Main exposing (..)
import Browser
import Browser.Navigation exposing (load)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import String

rootUrl = "https://mac1xa3.ca/e/mikhaily/"

---------------------------------------------------------------------------------------------------------

-- Models, Messages, etc

main =
 Browser.element
     { init = init
     , update = update
     , subscriptions = subscriptions
     , view = view
     }

--App model
type alias Model =
    { response : String, name : String, password : String }

--App messages
type Msg
    = GotText (Result Http.Error String)
    | UsernameEntered String
    | PasswordEntered String
    | SubmitButtonPressed

--Initial model values
init : () -> ( Model, Cmd Msg )
init _ =
 ( { name = "", password = "", response = "" }, Cmd.none )
---------------------------------------------------------------------------------------------------------

--Submit username and passwords to the server in a POST body
login : Model -> Cmd Msg
login model =
    Http.post
        { body = Http.stringBody "application/x-www-form-urlencoded" ("username=" ++ model.name ++ "&password=" ++ model.password)
        , expect = Http.expectString GotText
        , url = rootUrl ++ "userauth/loginuser/"
        
        }

--App view
view : Model -> Html Msg
view model =
    div [] [
        h1 [] [text "Please log in to battleship to continue"],
        input [placeholder "Username", value model.name, onInput UsernameEntered ] [],
        input [placeholder "Password", value model.password, onInput PasswordEntered, type_ "password" ] [],
        button [onClick SubmitButtonPressed] [text "Submit"],
        a [href "createaccount.html"] [text "Don't have an account? Create one here."],
        div [style "color" "red"] [text model.response]
     ]

--Update function
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->   --Got response from server after submitting login
            case result of  --Set text below boxes to the appropriate message
                Ok "LoginFailed" ->
                    ( {model | response = "Your username or password is invalid"}, Cmd.none)

                Ok "LoggedIn" ->    --Login successful, redirect to main page
                    (model, load (rootUrl ++ "static/main.html"))
                
                Ok val ->
                    ( { model | response = val }, Cmd.none )

                Err error ->
                    ( handleError model error, Cmd.none )
        UsernameEntered username -> --Change model data to whatever is in the username and password fields
            ({model | name = username}, Cmd.none)
        PasswordEntered passwd -> 
            ({model | password = passwd}, Cmd.none)
        SubmitButtonPressed ->  --Check if username or password are empty before submitting login to the server
            if model.name /= "" && model.password /= "" then
                (model, login model)
            else
                ({model | response = "Username and password cannot be empty"}, Cmd.none)

--Handle HTTP Errors
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