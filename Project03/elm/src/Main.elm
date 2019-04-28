module Main exposing (..)
import Browser
import Browser.Navigation exposing (load)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import String
import Json.Decode as JDecode

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

type alias Model =
    { currentUser : String, --Current username
      error : String, -- Errors received from the server
      sessionUrls : List String, --List of session URLs
      sessionDescriptions : List String -- List of session descriptions
     }

--Messages
type Msg
    = GotText (Result Http.Error String)    --Triggered when username is received
    | GotJson (Result Http.Error (List String, List String)) --Triggered when available session data is received

--Initial model values
init : () -> ( Model, Cmd Msg )
init _ =
 ( { currentUser = "", error = "", sessionUrls = [], sessionDescriptions = []}, checkAuth)

-------------------------------------------------------------------------------------------------------

--HTTP functions and decoders

--Get username
checkAuth : Cmd Msg
checkAuth =
    Http.get
        { expect = Http.expectString GotText
        , url = "https://mac1xa3.ca/e/mikhaily/userauth/userinfo/"
        }

--Get list of sessions
getGames : Cmd Msg
getGames = 
    Http.get
        { expect = Http.expectJson GotJson decodeSessions
        , url = "https://mac1xa3.ca/e/mikhaily/game/getgames/"
        }


--Decode JSON containing list of sessions as a tuple of two List Strings.
--One containing a list of URLs, and another containing a list of session descriptions to be displayed to the user
decodeSessions : JDecode.Decoder (List String, List String)
decodeSessions = JDecode.map2 Tuple.pair
    (JDecode.field "urls" (JDecode.list JDecode.string))
    (JDecode.field "descriptions" (JDecode.list JDecode.string))

------------------------------------------------------------------------------------------------------------------------

--Create a list of Html links with URLs and a description
sessionList : List String -> List String -> List (Html Msg)
sessionList urlList descriptionList = case urlList of
    [] -> []
    (url::urls) -> case descriptionList of
        [] -> []
        (description::descriptions) -> [div [] [a [href url] [text description]]] ++ sessionList urls descriptions


--View
view : Model -> Html Msg
view model =
    if model.error == "" then
    div [] ([
        h1 [] [text "Welcome to Battleship!"],
        a [href rootUrl ++ "e/mikhaily/userauth/logoutuser/"] [text "Log out"],
        div [] [a [href "creategrid.html"] [text "Create new game"]],
        h2 [] [text ("Available sessions for " ++ model.currentUser ++ ":")]
     ] ++ sessionList model.sessionUrls model.sessionDescriptions) --Get the list of sessions as HTML objects
     else 
     -- If there is an error, do not display the page, just display the error
        text model.error

--Update function
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->
            case result of
                Ok "NotLoggedIn" -> --If this is returned by the server, redirect to login page
                    (model, load "login.html")

                Ok val ->   --If anything else besides "NotLoggedIn" is returned, display it as the username
                    ( { model | currentUser = val }, getGames)

                Err error ->
                    ( handleError model error, Cmd.none )
        GotJson result ->   --Got the list of sessions URLs and descriptions as a tuple
            case result of
                Ok (urls, descriptions) -> ({model | sessionUrls = urls, sessionDescriptions = descriptions}, Cmd.none)

                Err error ->
                    (handleError model error, Cmd.none) --Handle Http errors


--Handle Http errors
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