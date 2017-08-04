module Hapi.Http.Request exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)

import Hapi.Http.Method as Method exposing (Method)


type alias Request =
  { id: String
  , method: Method
  , path: String
  , headers: Dict String String
  , params: Dict String String
  , query: Dict String String
  , state: Dict String String
  , body: Maybe String
  }


---------------------------------------------------------------------
-- Decoders

decoder: Decoder Request
decoder =
  Decode.map8 Request
    (Decode.field "id" Decode.string)
    (Decode.field "method" Method.decoder)
    (Decode.field "path" Decode.string)
    (Decode.field "headers" (Decode.dict Decode.string))
    (Decode.field "params" (Decode.dict Decode.string))
    (Decode.field "query" (Decode.dict Decode.string))
    (Decode.field "state" (Decode.dict Decode.string))
    (Decode.maybe <| Decode.field "payload" Decode.string)
