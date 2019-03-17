import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http



-- MAIN


main =
  Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }



-- MODEL


type alias Model =
  { name : String
  , password : String
  , passwordAgain : String
  , response : String
  }


init : () -> (Model, Cmd Msg)
init _ =
  (Model "" "" "" "", Cmd.none)



-- UPDATE


type Msg
  = Name String
  | Password String
  | PasswordAgain String
  | CheckFields
  | GotText (Result Http.Error String)


checkCredentials : Model -> Cmd Msg
checkCredentials model =
    Http.post
        { body = Http.stringBody "application/x-www-form-urlencoded" ("user=" ++ model.name ++ "&pass=" ++ model.password)
        , expect = Http.expectString GotText
        , url = "https://mac1xa3.ca/e/mikhaily/lab7/"
        
        }


update : Msg  -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Name name ->
      ({ model | name = name }, Cmd.none)

    Password password ->
      ({ model | password = password }, Cmd.none)

    PasswordAgain password ->
      ({ model | passwordAgain = password }, Cmd.none)

    CheckFields ->
        if model.password == model.passwordAgain then
            (model, checkCredentials model)
        else (model, Cmd.none)
    
    GotText result ->
        case result of
            Ok val ->
                ({model | response = val}, Cmd.none)
            Err error ->
                ( handleError model error, Cmd.none)

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



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ viewInput "text" "Name" model.name Name
    , viewInput "password" "Password" model.password Password
    , viewInput "password" "Re-enter Password" model.passwordAgain PasswordAgain
    , button [onClick CheckFields, disabled (model.password /= model.passwordAgain)] [text "Submit"]
    , viewValidation model
    , text (model.response)
    ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg ] []


viewValidation : Model -> Html msg
viewValidation model =
  if model.password == model.passwordAgain then
    div [ style "color" "green" ] [ text "OK" ]
  else
    div [ style "color" "red" ] [ text "Passwords do not match!" ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none