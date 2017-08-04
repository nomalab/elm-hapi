module Hapi.Route.State exposing (..)

import Json.Encode as Encode
import Hapi.Internals.Helpers as H
import Hapi.Route.FailAction as FailAction exposing (FailAction)

type alias State =
  { parse: Bool
  , failAction: Maybe FailAction
  }

init: State
init =
  { parse = False
  , failAction = Nothing
  }

-- -----------------------------------------------------------------------------
-- Encoders

encode: State -> Encode.Value
encode state =
 [ Just ("parse", Encode.bool state.parse)
 , H.encodeMaybeField "failAction" FailAction.encode state.failAction
 ]
 |> List.filterMap identity
 |> Encode.object
