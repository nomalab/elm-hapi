module Hapi.State exposing (..)

import Json.Encode as Encode
import Hapi.Internals.Helpers as H
import Hapi.Server exposing (Server)

type SameSite = Strict | Lax

type Encoding = Base64 | Base64Json | Form | Iron

type alias State =
  { ttl: Maybe Int
  , isSecure: Bool
  , isHttpOnly: Bool
  , isSameSite: Maybe SameSite
  , path: Maybe String
  , domain: Maybe String
  , encoding: Maybe Encoding
  , password: Maybe String
  , ignoreErrors: Bool
  , clearInvalid: Bool
  , strictHeader: Bool
  }

withState: String -> State -> Server -> Server
withState name state server =
  Native.Hapi.withState name (encode state) server


-- -----------------------------------------------------------------------------
-- Encoders

encodeSameSite: SameSite -> Encode.Value
encodeSameSite sameSite =
  case sameSite of
    Strict -> Encode.string "Strict"
    Lax    -> Encode.string "Lax"

encodeEncoding: Encoding -> Encode.Value
encodeEncoding encoding =
  case encoding of
    Base64     -> Encode.string "base64"
    Base64Json -> Encode.string "base64json"
    Form       -> Encode.string "form"
    Iron       -> Encode.string "iron"

encode: State -> Encode.Value
encode state =
  [ H.encodeMaybeField "ttl" Encode.int state.ttl
  , Just ("isSecure", Encode.bool state.isSecure)
  , Just ("isHttpOnly", Encode.bool state.isHttpOnly)
  , H.encodeMaybeField "isSameSite" encodeSameSite state.isSameSite
  , H.encodeMaybeField "path" Encode.string state.path
  , H.encodeMaybeField "domain" Encode.string state.domain
  , Just ("encoding",state.encoding |> Maybe.map encodeEncoding |> Maybe.withDefault (Encode.string "none"))
  , H.encodeMaybeField "password" Encode.string state.password
  , Just ("ignoreErrors", Encode.bool state.ignoreErrors)
  , Just ("clearInvalid", Encode.bool state.clearInvalid)
  , Just ("strictHeader", Encode.bool state.strictHeader)
  ]
  |> List.filterMap identity
  |> Encode.object
