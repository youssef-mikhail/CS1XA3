import Browser
import Html exposing (Html, h1, text, input, div)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onInput)

main = 
 Browser.sandbox { init = init, update = update, view = view }

-- Model 
type alias Model = { string1 : String , string2 : String }

init : Model
init = { string1 = "", string2 = ""}

-- View
view : Model -> Html Msg
view model = div [] [
      input [ placeholder "String 1", value model.string1, onInput ChangeFirst  ] []
    , input [ placeholder "String 2", value model.string2, onInput ChangeSecond ] []
    , div [] [text (model.string1 ++ " : " ++ model.string2)] ]

-- Update
update : Msg -> Model -> Model
update msg model = case msg of
                    ChangeFirst newContent -> {model | string1 = newContent}
                    ChangeSecond newContent -> {model | string2 = newContent}

type Msg = ChangeFirst String
            | ChangeSecond String