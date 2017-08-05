effect module Hapi where { command = HapiCmd, subscription = HapiSub } exposing (..)

import Dict exposing (Dict)
import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode

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

withPlugins: List Plugin -> Server -> Task String Server
withPlugins = Native.Hapi.withPlugins

withRoute: Route -> Server -> Server
withRoute = Route.withRoute

withConnection: Connection -> Server -> Server
withConnection = Hapi.Connection.withConnection

defaultHandler: Handler.Handler
defaultHandler = Handler.init

defaultRouteConfig: RouteConfig
defaultRouteConfig = RouteConfig.init


type alias CreateConfig =
  { settings: Dict String String
  }

encodeCreateConfig: CreateConfig -> Encode.Value
encodeCreateConfig config =
  [ Just ("settings", H.encodeDict Encode.string config.settings)
  ]
  |> List.filterMap identity
  |> Encode.object


-- -----------------------------------------------------------------------------
-- CMD
-- -----------------------------------------------------------------------------

type HapiCmd msg
  = Create CreateConfig
  | Start Server
  | Stop Server
  | Reply Replier Response

create: CreateConfig -> Cmd msg
create =
  command << Create

start: Server -> Cmd msg
start =
  command << Start

stop: Server -> Cmd msg
stop =
  command << Stop

reply: Replier -> Response -> Cmd msg
reply rp res =
  command (Reply rp res)

cmdMap : (a -> b) -> HapiCmd a -> HapiCmd b
cmdMap f cmd =
  case cmd of
    Create n  -> Create n
    Start n   -> Start n
    Stop n    -> Stop n
    Reply m n -> Reply m n


-- -----------------------------------------------------------------------------
-- SUB
-- -----------------------------------------------------------------------------

type Msg
  = Created (Result String Server)
  | Started (Result String Server)
  | Stopped (Result String Server)
  | Requested Replier Request

type HapiSub msg
  = Listen (Msg -> msg)

listen: (Msg -> msg) -> Sub msg
listen =
  subscription << Listen

subMap : (a -> b) -> HapiSub a -> HapiSub b
subMap f sub =
  case sub of
    Listen tagger -> Listen (tagger >> f)


-- -----------------------------------------------------------------------------
-- STATE
-- -----------------------------------------------------------------------------

type alias State msg = List (HapiSub msg)

init : Task Never (State msg)
init =
  Task.succeed []


-- -----------------------------------------------------------------------------
-- EFFECTS
-- -----------------------------------------------------------------------------

onEffects
  : Platform.Router msg SelfMsg
  -> List (HapiCmd msg)
  -> List (HapiSub msg)
  -> State msg
  -> Task Never (State msg)
onEffects router cmds subs state =
  List.foldl
    (\cmd taskState ->
      taskState
      |> Task.andThen (\currentState ->
        handleCommand router currentState cmd
      )
    )
    (Task.succeed subs)
    cmds

handleCommand: Platform.Router msg SelfMsg -> State msg -> HapiCmd msg -> Task Never (State msg)
handleCommand router state cmd =
  case cmd of
    Create config ->
      create_ (initInternals router) (encodeCreateConfig config)
      |> Task.map (Created << Ok)
      |> Task.onError (Task.succeed << Created << Err)
      |> Task.andThen (msgToApp router state)

    Start server ->
      start_ server
      |> Task.map (\_ -> Started <| Ok server)
      |> Task.onError (Task.succeed << Started << Err)
      |> Task.andThen (msgToApp router state)

    Stop server ->
      stop_ server
      |> Task.map (\_ -> Stopped <| Ok server)
      |> Task.onError (Task.succeed << Stopped << Err)
      |> Task.andThen (msgToApp router state)

    Reply replier response ->
      reply_ replier (Response.encode response)
      |> Task.map (\_ -> state)


-- -----------------------------------------------------------------------------
-- INTERNALS
-- -----------------------------------------------------------------------------

type SelfMsg
  = OnRequest Replier Encode.Value

msgToApp: Platform.Router msg SelfMsg -> State msg -> Msg -> Task Never (State msg)
msgToApp router state msg =
  state
  |> List.map (\sub -> case sub of
    Listen tagger -> Platform.sendToApp router (tagger msg)
  )
  |> Task.sequence
  |> Task.map (\_ -> state)

onSelfMsg : Platform.Router msg SelfMsg -> SelfMsg -> State msg -> Task Never (State msg)
onSelfMsg router selfMsg state =
  case selfMsg of
    OnRequest replier jsRequest ->
      case Decode.decodeValue Request.decoder jsRequest of
        Ok request -> msgToApp router state (Requested replier request)

        Err error ->
          let
            a = Debug.log "Failed to parse request" error
          in
            Task.succeed state

-- Native signatures
type alias Internals =
  { callback: SelfMsg -> Task Never ()
  , events:
      { onRequest: Replier -> Encode.Value -> SelfMsg
      }
  }

initInternals: Platform.Router msg SelfMsg -> Internals
initInternals router =
  { callback = Platform.sendToSelf router
  , events =
      { onRequest = OnRequest
      }
  }

create_: Internals -> Encode.Value -> Task String Server
create_ =
  Native.Hapi.create

start_: Server -> Task String ()
start_ =
  Native.Hapi.start

stop_: Server -> Task String ()
stop_ =
  Native.Hapi.stop

reply_: Replier -> Encode.Value -> Task Never ()
reply_ =
  Native.Hapi.reply

noWarnings: String
noWarnings = Hapi.Native.noWarnings
