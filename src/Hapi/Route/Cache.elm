module Hapi.Route.Cache exposing (..)

import Json.Encode as Encode
import Hapi.Internals.Helpers as H

type Privacy = Default | Public | Private

type Expiration = ExpiresIn Int | ExpiresAt { hour: Int, minute: Int }

type alias Cache =
  { privacy: Maybe Privacy
  , expiration: Maybe Expiration
  , statuses: Maybe (List Int)
  , otherwise: Maybe String
  }

init: Cache
init =
  { privacy = Nothing
  , expiration = Nothing
  , statuses = Nothing
  , otherwise = Nothing
  }

-- -----------------------------------------------------------------------------
-- Encoders

encodeCachePrivacy: Privacy -> Encode.Value
encodeCachePrivacy privacy =
  case privacy of
    Default -> Encode.string "default"
    Public  -> Encode.string "public"
    Private -> Encode.string "private"

encode: Cache -> Encode.Value
encode cache =
  [ H.encodeMaybeField "privacy" encodeCachePrivacy cache.privacy
  , case cache.expiration of
      Nothing -> Nothing
      Just (ExpiresIn ms) -> Just ("expiresIn", Encode.int ms)
      Just (ExpiresAt at) -> Just ("expiresAt", ((toString at.hour) ++ ":" ++ (toString at.minute)) |> Encode.string)
  , H.encodeMaybeField "statuses" (Encode.list << List.map Encode.int) cache.statuses
  , H.encodeMaybeField "otherwise" Encode.string cache.otherwise
  ]
  |> List.filterMap identity
  |> Encode.object
