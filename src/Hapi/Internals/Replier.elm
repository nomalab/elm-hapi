module Hapi.Internals.Replier exposing (..)

import Hapi.Native

type Replier = Replier

isClosed: Replier -> Bool
isClosed =
  Native.Hapi.isClosed

noWarnings: String
noWarnings = Hapi.Native.noWarnings
