module Hapi.Route.Payload exposing (..)

import Json.Encode as Encode
import Hapi.Internals.Helpers as H
import Hapi.Route.FailAction as FailAction exposing (FailAction)

type Output = Data | Stream | File

type Parse = NoParse | Parse | Gunzip

type Multipart = NoMultipart | MultipartOutput Output | MultipartAnnotated

type Timeout = NoTimeout | Timeout Int

type alias Payload =
  { output: Maybe Output
  , parse: Maybe Parse
  , multipart: Maybe Multipart
  , allow: Maybe (List String)
  , override: Maybe String
  , maxBytes: Maybe Int
  , timeout: Maybe Timeout
  , uploads: Maybe String
  , failAction: Maybe FailAction
  , defaultContentType: Maybe String
  }

init: Payload
init =
  { output = Nothing
  , parse = Nothing
  , multipart = Nothing
  , allow = Nothing
  , override = Nothing
  , maxBytes = Nothing
  , timeout = Nothing
  , uploads = Nothing
  , failAction = Nothing
  , defaultContentType = Nothing
  }

-- -----------------------------------------------------------------------------
-- Encoders

encodeOutput: Output -> Encode.Value
encodeOutput output =
  case output of
    Data   -> Encode.string "data"
    Stream -> Encode.string "stream"
    File   -> Encode.string "file"

encodeParse: Parse -> Encode.Value
encodeParse parse =
  case parse of
    NoParse -> Encode.bool False
    Parse   -> Encode.bool True
    Gunzip  -> Encode.string "gunzip"

wrapMultipartOutput: Encode.Value -> Encode.Value
wrapMultipartOutput output =
  Encode.object [ ("output", output) ]

encodeMultipart: Multipart -> Encode.Value
encodeMultipart multipart =
  case multipart of
    NoMultipart            -> Encode.bool False
    MultipartOutput output -> wrapMultipartOutput (encodeOutput output)
    MultipartAnnotated     -> wrapMultipartOutput (Encode.string "annotated")

encodeTimeout: Timeout -> Encode.Value
encodeTimeout timeout =
  case timeout of
    NoTimeout        -> Encode.bool False
    Timeout duration -> Encode.int duration

encode: Payload -> Encode.Value
encode payload =
  [ H.encodeMaybeField "output" encodeOutput payload.output
  , H.encodeMaybeField "parse" encodeParse payload.parse
  , H.encodeMaybeField "multipart" encodeMultipart payload.multipart
  , H.encodeMaybeField "allow" (List.map Encode.string >> Encode.list) payload.allow
  , H.encodeMaybeField "override" Encode.string payload.override
  , H.encodeMaybeField "maxBytes" Encode.int payload.maxBytes
  , H.encodeMaybeField "timeout" encodeTimeout payload.timeout
  , H.encodeMaybeField "uploads" Encode.string payload.uploads
  , H.encodeMaybeField "failAction" FailAction.encode payload.failAction
  , H.encodeMaybeField "defaultContentType" Encode.string payload.defaultContentType
  ]
  |> List.filterMap identity
  |> Encode.object
