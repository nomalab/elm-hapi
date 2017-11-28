module Hapi exposing (..)

import Dict exposing (Dict)
import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode
import Error exposing (Error)

import

import Hapi.Internals.Helpers as H
import Hapi.Internals.Replier as Replier
import Hapi.Internals.Handler as Handler

import Hapi.Http.Request as Request
import Hapi.Http.Response as Response

import Hapi.Route as Route
import Hapi.Route.Config as RouteConfig

import Hapi.Server as Server
import Hapi.Connection exposing (Connection)
import Hapi.Plugins.Plugin as Plugin

import Hapi.Native


-- -----------------------------------------------------------------------------
-- ALIASES
-- -----------------------------------------------------------------------------

type alias Replier = Replier.Replier
type alias Server = Server.Server
type alias Request = Request.Request
type alias Response = Response.Response
type alias Plugin = Plugin.Plugin
type alias Route = Route.Route
type alias RouteConfig = RouteConfig.Config


type alias CreateConfig =
  { settings: Dict String String
  }

createServer: CreateConfig -> Task Error Server
createServer config =
  { implementation = Native.Hapi.createServer (encodeCreateConfig config)
  , request =
    { decoder = requestDecoder
    }
  , replier =
    { init = init
    , withStatusCode = withStatusCode
    , withHeader = withHeader
    , withCookie = withCookie
    , withBody = withBody
    , send = send
    }
  }


withPlugins: List Plugin -> Server -> Task Error Server
withPlugins = Native.Hapi.withPlugins

withRoute: Route -> Server -> Server
withRoute = Route.withRoute

withConnection: Connection -> Server -> Server
withConnection = Hapi.Connection.withConnection

defaultHandler: Handler.Handler
defaultHandler = Handler.init

defaultRouteConfig: RouteConfig
defaultRouteConfig = RouteConfig.init


-- ----------------------------------------------------------------------------
-- Internals

encodeCreateConfig: CreateConfig -> Encode.Value
encodeCreateConfig config =
  [ Just ("settings", H.encodeDict Encode.string config.settings)
  ]
  |> List.filterMap identity
  |> Encode.object

init: Replier -> Replier
init =
  Native.Hapi.init

withStatusCode: Int -> Replier -> Replier
withStatusCode =
  Native.Hapi.withStatusCode

withHeader: Header -> Replier -> Replier
withHeader header =
  Native.Hapi.withHeader (encodeHeader header)

withCookie: Cookie -> Replier -> Replier
withCookie cookie =
  Native.Hapi.withCookie (encodeCookie header)

withBody: String -> Replier -> Replier
withBody =
  Native.Hapi.withBody

send: Bool -> Replier -> Replier
send =
  Native.Hapi.send

encodeHeader: Header -> Json.Encode.Value
encodeHeader header =
  Encode.object
    [ ("name", Encode.string header.name)
    , ("value", Encode.string header.value)
    ]

encodeCookie: Cookie -> Encode.Value
encodeCookie cookie =
  Encode.object
    [ ( "name", Encode.string cookie.name )
    , ( "value", Encode.string cookie.value )
    , ( "options"
      , [ case cookie.expiration of
            Nothing -> Nothing
            Just Session -> Just ("ttl", Encode.null)
            Just (In seconds) -> Just ("ttl", Encode.int seconds)
            Just (At date) -> Nothing -- FIXME
        , Just ("isSecure", Encode.bool cookie.secure)
        , Just ("isHttpOnly", Encode.bool cookie.httpOnly)
        , Just
            ( "isSameSite"
            , case cookie.sameSite of
                Nothing -> Encode.bool False
                Just Strict -> Encode.string "Strict"
                Just Lax -> Encode.string "Lax"
            )
        , Just ("path", Encode.string cookie.path)
        , Maybe.map (\d -> ("domain", Encode.string d)) cookie.domain
        , Just ("encoding", if cookie.signed then Encode.string "iron" else Encode.string "none")
        ]
        |> List.filterMap identity
        |> Encode.object
      )
    ]

requestDecoder: Decoder Request
requestDecoder =
  Decode.map7 Request
    (Decode.field "method" Server.Method.decoderLower)
    (Decode.field "path" Decode.string)
    (Decode.field "headers" <| Decode.dict Decode.string)
    (Decode.field "params" <| Decode.dict Decode.string)
    (Decode.field "query" <| Decode.dict Decode.string)
    (Decode.field "state" <| Decode.dict Decode.string)
    (Decode.maybe <| Decode.field "payload" Decode.string)


noWarnings: String
noWarnings = Hapi.Native.noWarnings
