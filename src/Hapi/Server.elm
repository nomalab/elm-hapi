module Hapi.Server exposing (..)

import Dict exposing (Dict)
import Task exposing (Task)
import Json.Decode as Decode exposing (Decoder)

import Native.Hapi

type Server = Server

type Protocol = Http | Https | Socket

type alias Info =
  { id: String
  , created: Int
  , started: Int
  , port_: String
  , host: String
  , address: String
  , protocol: Protocol
  , uri: String
  }

type alias Load =
  { eventLoopDelay: Int
  , heapUsed: Int
  , rss: Int
  }

getInfos: Server -> Task String (List Info)
getInfos server =
  getInfos_ server
  |> Task.andThen (\js -> case Decode.decodeValue decoderInfos js of
    Err error -> Task.fail error
    Ok infos -> Task.succeed infos
  )

getLoad: Server -> Task String Load
getLoad server =
  getLoad_ server
  |> Task.andThen (\js -> case Decode.decodeValue decoderLoad js of
    Err error -> Task.fail error
    Ok load -> Task.succeed load
  )

getSettings: Server -> Dict String String
getSettings server =
  case Decode.decodeValue decoderSettings (getSettings_ server) of
    Ok dict -> dict
    Err _ -> Dict.empty

getSetting: String -> Server -> Maybe String
getSetting key server =
  case Decode.decodeValue decoderSetting (getSetting_ key server) of
    Ok value -> value
    Err _ -> Nothing

getVersion: Server -> String
getVersion =
  Native.Hapi.getVersion


-- -----------------------------------------------------------------------------
-- Decoders

decoderProtocol: Decoder Protocol
decoderProtocol =
  Decode.string
  |> Decode.andThen (\str ->
    case str of
      "http"   -> Decode.succeed Http
      "https"  -> Decode.succeed Https
      "socket" -> Decode.succeed Socket
      _        -> Decode.fail ("Invalid protocol: " ++ str)
  )

decoderInfos: Decoder (List Info)
decoderInfos =
  Decode.list decoderInfo

decoderInfo: Decoder Info
decoderInfo =
  Decode.map8 Info
    (Decode.field "id" Decode.string)
    (Decode.field "created" Decode.int)
    (Decode.field "started" Decode.int)
    (Decode.field "port" Decode.string)
    (Decode.field "host" Decode.string)
    (Decode.field "address" Decode.string)
    (Decode.field "protocol" decoderProtocol)
    (Decode.field "uri" Decode.string)

decoderLoad: Decoder Load
decoderLoad =
  Decode.map3 Load
    (Decode.field "eventLoopDelay" Decode.int)
    (Decode.field "heapUsed" Decode.int)
    (Decode.field "rss" Decode.int)

decoderSettings: Decoder (Dict String String)
decoderSettings =
  Decode.dict Decode.string

decoderSetting: Decoder (Maybe String)
decoderSetting =
  Decode.maybe Decode.string


-- -----------------------------------------------------------------------------
-- Native

getInfos_: Server -> Task String Decode.Value
getInfos_ =
  Native.Hapi.getInfos

getLoad_: Server -> Task String Decode.Value
getLoad_ =
  Native.Hapi.getLoad

getSettings_: Server -> Decode.Value
getSettings_ =
  Native.Hapi.getSettings

getSetting_: String -> Server -> Decode.Value
getSetting_ =
  Native.Hapi.getSetting
