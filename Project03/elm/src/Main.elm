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

main =
 Browser.element
     { init = init
     , update = update
     , subscriptions = subscriptions
     , view = view
     }

type alias Model =
    { currentUser : String, 
      error : String,
      sessionUrls : List String,
      sessionDescriptions : List String
     }

type Msg
    = GotText (Result Http.Error String)
    | GotJson (Result Http.Error (List String, List String))

checkAuth : Cmd Msg
checkAuth =
    Http.get
        { expect = Http.expectString GotText
        , url = "https://mac1xa3.ca/e/mikhaily/userauth/userinfo/"
        }

getGames : Cmd Msg
getGames = 
    Http.get
        { expect = Http.expectJson GotJson decodeSessions
        , url = "https://mac1xa3.ca/e/mikhaily/game/getgames/"
        }


decodeSessions : JDecode.Decoder (List String, List String)
decodeSessions = JDecode.map2 Tuple.pair
    (JDecode.field "urls" (JDecode.list JDecode.string))
    (JDecode.field "descriptions" (JDecode.list JDecode.string))

sessionList : List String -> List String -> List (Html Msg)
sessionList urlList descriptionList = case urlList of
    [] -> []
    (url::urls) -> case descriptionList of
        [] -> []
        (description::descriptions) -> [a [href url] [text description]] ++ sessionList urls descriptions


init : () -> ( Model, Cmd Msg )
init _ =
 ( { currentUser = "", error = "", sessionUrls = [], sessionDescriptions = []}, checkAuth)

view : Model -> Html Msg
view model =
    if model.error == "" then
    div [] ([
        h1 [] [text "Welcome to Battleship!"],
        a [href "https://mac1xa3.ca/e/mikhaily/userauth/logoutuser/"] [text "Log out"],
        h2 [] [text ("Available sessions for " ++ model.currentUser ++ ":")]
     ] ++ sessionList model.sessionUrls model.sessionDescriptions)
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
                    ( { model | currentUser = val }, getGames)

                Err error ->
                    ( handleError model error, Cmd.none )
        GotJson result ->
            case result of
                Ok (urls, descriptions) -> ({model | sessionUrls = urls, sessionDescriptions = descriptions}, Cmd.none)

                Err error ->
                    (handleError model error, Cmd.none)


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