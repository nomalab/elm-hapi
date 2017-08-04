module Hapi.Connection exposing (..)

import Json.Encode as Encode

import Hapi.Internals.Helpers as H
import Hapi.Server exposing (Server)


type alias Connection =
  { host: Maybe String
  , address: Maybe String
  , port_: Maybe String
  , uri: Maybe String
  , labels: Maybe (List String)
  , tls: Maybe Encode.Value
  }

init: Connection
init =
  { host = Nothing
  , address = Nothing
  , port_ = Nothing
  , uri = Nothing
  , labels = Nothing
  , tls = Nothing
  }

basic: String -> String -> Connection
basic host port_ =
  init
  |> withHost host
  |> withPort port_

withHost: String -> Connection -> Connection
withHost host connection =
  { connection | host = Just host }

withAddress: String -> Connection -> Connection
withAddress address connection =
  { connection | address = Just address }

withPort: String -> Connection -> Connection
withPort port_ connection =
  { connection | port_ = Just port_ }

withUri: String -> Connection -> Connection
withUri uri connection =
  { connection | uri = Just uri }

withLabel: String -> Connection -> Connection
withLabel label connection =
  let
    labels = case connection.labels of
      Nothing -> Just [ label ]
      Just ls -> Just (label :: ls)
  in
    { connection | labels = labels }

withTls: Encode.Value -> Connection -> Connection
withTls tls connection =
  { connection | tls = Just tls }

withConnection: Connection -> Server -> Server
withConnection connection server =
  Native.Hapi.withConnection (encode connection) server

-- -----------------------------------------------------------------------------
-- Encoders

encode: Connection -> Encode.Value
encode connection =
  [ H.encodeMaybeField "host" Encode.string connection.host
  , H.encodeMaybeField "address" Encode.string connection.address
  , H.encodeMaybeField "port" Encode.string connection.port_
  , H.encodeMaybeField "uri" Encode.string connection.uri
  , H.encodeMaybeField "labels" (List.map Encode.string >> Encode.list) connection.labels
  , H.encodeMaybeField "tls" identity connection.tls
  ]
  |> List.filterMap identity
  |> Encode.object
