module Hapi.Route exposing (..)

import Json.Encode as Encode

import Hapi.Internals.Helpers as H
import Hapi.Server exposing (Server)
import Hapi.Http.Method as Method exposing (Method)
import Hapi.Route.Cache as Cache exposing (Cache)
import Hapi.Route.Payload as Payload exposing (Payload)
import Hapi.Route.State as State exposing (State)
import Hapi.Route.Config as Config exposing (Config)


type RouteMethod
  = All
  | Only Method
  | Any (List Method)

type alias Route =
  { method: RouteMethod
  , path: String
  , vhost: Maybe String
  , config: Maybe Config
  -- handler will be set inside Native
  }

defaultState: State
defaultState = State.init

defaultPayload: Payload
defaultPayload = Payload.init

defaultCache: Cache
defaultCache = Cache.init

defaultConfig: Config
defaultConfig = Config.init

withRoute: Route -> Server -> Server
withRoute route server =
  Native.Hapi.withRoute (encode route) server


-- -----------------------------------------------------------------------------
-- Encoders

encodeRouteMethod: RouteMethod -> Encode.Value
encodeRouteMethod routeMethod =
  case routeMethod of
    All         -> Encode.string "*"
    Only method -> Method.encode method
    Any methods -> List.map Method.encode methods |> Encode.list

encode: Route -> Encode.Value
encode route =
  [ Just ("method", encodeRouteMethod route.method)
  , Just ("path", Encode.string route.path)
  , H.encodeMaybeField "vhost" Encode.string route.vhost
  , H.encodeMaybeField "config" Config.encode route.config
  ]
  |> List.filterMap identity
  |> Encode.object
