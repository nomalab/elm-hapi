module Hapi.Plugins.Plugin exposing (..)

-- Let's import all native helpers here so that plugins do not care about it
import Hapi.Native

type Plugin = Plugin

noWarnings: String
noWarnings =
  Hapi.Native.noWarnings
