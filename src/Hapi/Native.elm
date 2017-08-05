module Hapi.Native exposing (noWarnings)

{-|
This is a very dirty hack

Problem: you cannot order native imports

Solution: create an Elm module that import all the Native stuff in correct order and then only import this module
-}

import Kernel.Helpers
import Native.Hapi.Utils
import Native.Hapi

noWarnings: String
noWarnings = Kernel.Helpers.removeWarnings

identity: a -> a
identity =
  Native.Hapi.identity

normalizeRequest: a
normalizeRequest =
  Native.Hapi.Utils.normalizeRequest
