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

type alias ClientMessage =
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

type alias ServerMessage =
  { kind: OutgoingKind
  , value: Encode.Value
  }
