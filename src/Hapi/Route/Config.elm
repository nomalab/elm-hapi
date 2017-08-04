module Hapi.Route.Config exposing (..)

import Dict exposing (Dict)
import Json.Encode as Encode

import Hapi.Internals.Helpers as H
import Hapi.Route.Cache as Cache exposing (Cache)
import Hapi.Route.Payload as Payload exposing (Payload)
import Hapi.Route.State as State exposing (State)


type alias Config =
  { app: Dict String String
  -- , auth: ???
  , cache: Maybe Cache
  -- , compression: ???
  -- , cors: ???
  -- , ext: ???
  -- , files: ???
  -- , handler: ???
  -- , id: ???
  , isInternal: Bool
  , jsonp: Maybe String
  , log: Bool
  , payload: Maybe Payload
  , state: Maybe State
  }

init: Config
init =
  { app = Dict.empty
  , cache = Nothing
  , isInternal = False
  , jsonp = Nothing
  , log = False
  , payload = Nothing
  , state = Nothing
  }


-- -----------------------------------------------------------------------------
-- Encoders

encode: Config -> Encode.Value
encode config =
  [ Just ("app", H.encodeDict Encode.string config.app)
  , H.encodeMaybeField "cache" Cache.encode config.cache
  , Just ("isInternal", Encode.bool config.isInternal)
  , H.encodeMaybeField "jsonp" Encode.string config.jsonp
  , Just ("log", Encode.bool config.log)
  , H.encodeMaybeField "payload" Payload.encode config.payload
  , H.encodeMaybeField "state" State.encode config.state
  ]
  |> List.filterMap identity
  |> Encode.object
