module Hapi.Plugins.Nes exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)

type IncomingKind
  = Ping
  | Hello
  | Request
  | Sub
  | Unsub
  | Message

type alias IncomingMessage =
  { id: String
  , kind: IncomingKind
  , value: Encode.Value
  }

type OutgoingKind
  = Ping
  | Hello
  | Request
  | Sub
  | Unsub
  | Message
  | Update
  | Pub
  | Revoke

type alias OutgoingMessage =
  { kind: OutgoingKind
  , value: Encode.Value
  }
