module Hapi.Route.FailAction exposing (..)

import Json.Encode as Encode

type FailAction = Error | Log | Ignore

encode: FailAction -> Encode.Value
encode failAction =
  case failAction of
    Error  -> Encode.string "error"
    Log    -> Encode.string "log"
    Ignore -> Encode.string "ignore"
