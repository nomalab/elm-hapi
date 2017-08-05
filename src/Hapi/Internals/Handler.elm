module Hapi.Internals.Handler exposing (..)

import Json.Encode

import Hapi.Native

type Handler = Handler

init: Handler
init =
  Native.Hapi.handler

encode: Handler -> Json.Encode.Value
encode =
  Native.Hapi.identity

noWarnings: String
noWarnings = Hapi.Native.noWarnings
