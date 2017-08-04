module Hapi.Internals.Replier exposing (..)

import Native.Hapi

type Replier = Replier

isClosed: Replier -> Bool
isClosed =
  Native.Hapi.isClosed
