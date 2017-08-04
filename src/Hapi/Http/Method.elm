module Hapi.Http.Method exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)


type Method = Get | Post | Put | Patch | Delete | Options | Trace | Connect


-- -----------------------------------------------------------------------------
-- Encoders

encode: Method -> Encode.Value
encode method =
  case method of
    Get     -> Encode.string "GET"
    Post    -> Encode.string "POST"
    Put     -> Encode.string "PUT"
    Patch   -> Encode.string "PATCH"
    Delete  -> Encode.string "DELETE"
    Options -> Encode.string "OPTIONS"
    Trace   -> Encode.string "TRACE"
    Connect -> Encode.string "CONNECT"


---------------------------------------------------------------------
-- Decoders

decoder: Decoder Method
decoder =
  Decode.string
  |> Decode.andThen (\str -> case str of
    "get"     -> Decode.succeed Get
    "post"    -> Decode.succeed Post
    "put"     -> Decode.succeed Put
    "patch"   -> Decode.succeed Patch
    "delete"  -> Decode.succeed Delete
    "options" -> Decode.succeed Options
    "trace"   -> Decode.succeed Trace
    "connect" -> Decode.succeed Connect
    _         -> Decode.fail ("Unknown method: " ++ str)
  )
