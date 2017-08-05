module Hapi.Plugins.Inert exposing (..)

import Dict exposing (Dict)
import Json.Encode as Encode

import Hapi.Internals.Helpers as H
import Hapi.Internals.Replier exposing (Replier)
import Hapi.Internals.Handler exposing (Handler)
import Hapi.Http.Response as Response exposing (Response)
import Hapi.Plugins.Plugin exposing (Plugin)

import Native.Hapi.Inert

type alias Options =
  { etagsCacheMaxSize: Maybe Int }

defaultOptions: Options
defaultOptions =
  { etagsCacheMaxSize = Nothing }

type Mode = NoMode | Attachment | Inline

type EtagMethod = NoEtag | Hash | Simple

type alias FileConfig =
  { path: String
  , confine: Maybe Bool
  , filename: Maybe String
  , mode: Maybe Mode
  , lookupCompressed: Maybe Bool
  , lookupMap: Maybe (Dict String String)
  , etagMethod: Maybe EtagMethod
  , start: Maybe Int
  , end: Maybe Int
  }

type DirectoryPath = Path String | Paths (List String)

type DirectoryIndex = NoIndex | DefaultIndex | Index String | Indexes (List String)

type alias DirectoryConfig =
  { path: DirectoryPath
  , index: Maybe DirectoryIndex
  , listing: Maybe Bool
  , showHidden: Maybe Bool
  , redirectToSlash: Maybe Bool
  , lookupCompressed: Maybe Bool
  , lookupMap: Maybe (Dict String String)
  , etagMethod: Maybe EtagMethod
  , defaultExtension: Maybe String
  }


fileConfigFromPath: String -> FileConfig
fileConfigFromPath path =
  { path = path
  , confine = Nothing
  , filename = Nothing
  , mode = Nothing
  , lookupCompressed = Nothing
  , lookupMap = Nothing
  , etagMethod = Nothing
  , start = Nothing
  , end = Nothing
  }

directoryConfigFromPath: String -> DirectoryConfig
directoryConfigFromPath path =
  { path = Path path
  , index = Nothing
  , listing = Nothing
  , showHidden = Nothing
  , redirectToSlash = Nothing
  , lookupCompressed = Nothing
  , lookupMap = Nothing
  , etagMethod = Nothing
  , defaultExtension = Nothing
  }


plugin: Options -> Plugin
plugin options =
  Native.Hapi.Inert.plugin (encodeOptions options)

-- We are returning a shell Response so that the user can add other headers
-- and customise the final response
replyFile: Replier -> FileConfig -> (Replier, Response)
replyFile replier config =
  (replyFile_ replier config, Response.shell)

fileHandlerFromPath: String -> Handler
fileHandlerFromPath path =
  fileHandler (fileConfigFromPath path)

fileHandler: FileConfig -> Handler
fileHandler config =
  Native.Hapi.Inert.file (encodeFileConfig config)

directoryHandler: DirectoryConfig -> Handler
directoryHandler config =
  Native.Hapi.Inert.directory (encodeDirectoryConfig config)


-- -----------------------------------------------------------------------------
-- Encoders

encodeOptions: Options -> Encode.Value
encodeOptions options =
  [ H.encodeMaybeField "etagsCacheMaxSize" Encode.int options.etagsCacheMaxSize
  ]
  |> List.filterMap identity
  |> Encode.object

encodeMode: Mode -> Encode.Value
encodeMode mode =
  case mode of
    NoMode     -> Encode.bool False
    Attachment -> Encode.string "attachment"
    Inline     -> Encode.string "inline"

encodeEtagMethod: EtagMethod -> Encode.Value
encodeEtagMethod etag =
  case etag of
    NoEtag -> Encode.bool False
    Hash   -> Encode.string "hash"
    Simple -> Encode.string "simple"

encodeDirectoryPath: DirectoryPath -> Encode.Value
encodeDirectoryPath directoryPath =
  case directoryPath of
    Path path      -> Encode.string path
    Paths paths    -> List.map Encode.string paths |> Encode.list

encodeDirectoryIndex: DirectoryIndex -> Encode.Value
encodeDirectoryIndex directoryIndex =
  case directoryIndex of
    NoIndex         -> Encode.bool False
    DefaultIndex    -> Encode.bool True
    Index index     -> Encode.string index
    Indexes indexes -> List.map Encode.string indexes |> Encode.list

encodeFileConfig: FileConfig -> Encode.Value
encodeFileConfig config =
  [ Just ("path", Encode.string config.path)
  , H.encodeMaybeField "confine" Encode.bool config.confine
  , H.encodeMaybeField "filename" Encode.string config.filename
  , H.encodeMaybeField "mode" encodeMode config.mode
  , H.encodeMaybeField "lookupCompressed" Encode.bool config.lookupCompressed
  , H.encodeMaybeField "lookupMap" (H.encodeDict Encode.string) config.lookupMap
  , H.encodeMaybeField "etagMethod" encodeEtagMethod config.etagMethod
  , H.encodeMaybeField "start" Encode.int config.start
  , H.encodeMaybeField "end" Encode.int config.end
  ]
  |> List.filterMap identity
  |> Encode.object

encodeDirectoryConfig: DirectoryConfig -> Encode.Value
encodeDirectoryConfig config =
  [ Just ("path", encodeDirectoryPath config.path)
  , H.encodeMaybeField "index" encodeDirectoryIndex config.index
  , H.encodeMaybeField "listing" Encode.bool config.listing
  , H.encodeMaybeField "showHidden" Encode.bool config.showHidden
  , H.encodeMaybeField "redirectToSlash" Encode.bool config.redirectToSlash
  , H.encodeMaybeField "lookupCompressed" Encode.bool config.lookupCompressed
  , H.encodeMaybeField "lookupMap" (H.encodeDict Encode.string) config.lookupMap
  , H.encodeMaybeField "etagMethod" encodeEtagMethod config.etagMethod
  , H.encodeMaybeField "defaultExtension" Encode.string config.defaultExtension
  ]
  |> List.filterMap identity
  |> Encode.object


-- -----------------------------------------------------------------------------
-- Native

replyFile_: Replier -> FileConfig -> Replier
replyFile_ replier config =
  Native.Hapi.Inert.replyFile replier (encodeFileConfig config)
