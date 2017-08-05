module Hapi.Http.Response exposing (..)

import Dict exposing (Dict)
import Json.Encode as Encode
import Tuple exposing (first, second)

import Hapi.Internals.Helpers as H

type alias HeaderOptions =
  { append: Maybe Bool
  , separator: Maybe String
  , override: Maybe Bool
  , duplicate: Maybe Bool
  }

type alias Header =
  { name: String
  , value: String
  , options: Maybe HeaderOptions
  }

type alias Response =
  { statusCode: Int
  , body: String
  , headers: List Header
  , states: Dict String String
  , unstate: List String
  , end: Bool
  }

withStatusCode: Int -> Response -> Response
withStatusCode statusCode response =
  { response | statusCode = statusCode }

withHeader: String -> String -> Response -> Response
withHeader name value response =
  { response | headers = { name = name, value = value, options = Nothing } :: response.headers }

withHeaders: List (String, String) -> Response -> Response
withHeaders headers response =
  { response | headers =
      headers
      |> List.map (\header -> { name = first header, value = second header, options = Nothing })
      |> List.append response.headers
  }

withState: String -> String -> Response -> Response
withState name value response =
  { response |  states = Dict.insert name value response.states }

withoutState: String -> Response -> Response
withoutState name response =
  { response | unstate = name :: response.unstate }

withBody: String -> Response -> Response
withBody body response =
  { response | body = body }

withJsonBody: Encode.Value -> Response -> Response
withJsonBody jsBody response =
  withHeader "content-type" "application/json" (withBody (Encode.encode 0 jsBody) response)

keepAlive: Response -> Response
keepAlive response =
  { response | end = False }
  |> withHeader "Connection" "keep-alive"


-- -----------------------------------------------------------------------------
-- Predefined responses

shell: Response
shell =
  { statusCode = 0
  , body = ""
  , headers = []
  , states = Dict.empty
  , unstate = []
  , end = True
  }

continue: Response
continue = shell |> withStatusCode 100

switchingProcols: Response
switchingProcols = shell |> withStatusCode 101

processing: Response
processing = shell |> withStatusCode 102

ok: Response
ok = shell |> withStatusCode 200

created: Response
created = shell |> withStatusCode 201

accepted: Response
accepted = shell |> withStatusCode 202

noContent: Response
noContent = shell |> withStatusCode 204

redirect: String -> Response
redirect uri = shell |> withStatusCode 302 |> withHeader "Location" uri

notModified: Response
notModified = shell |> withStatusCode 304

badRequest: Response
badRequest = shell |> withStatusCode 400

unauthorized: Response
unauthorized = shell |> withStatusCode 401

paymentRequired: Response
paymentRequired = shell |> withStatusCode 402

forbidden: Response
forbidden = shell |> withStatusCode 403

notFound: Response
notFound = shell |> withStatusCode 404

requestTimeout: Response
requestTimeout = shell |> withStatusCode 408

teapot: Response
teapot = shell |> withStatusCode 418

unprocessableEntity: Response
unprocessableEntity = shell |> withStatusCode 422

internalServerError: Response
internalServerError = shell |> withStatusCode 500

notImplemented: Response
notImplemented = shell |> withStatusCode 501

badGateway: Response
badGateway = shell |> withStatusCode 502

serviceUnavailable: Response
serviceUnavailable = shell |> withStatusCode 503

-- -----------------------------------------------------------------------------
-- Encoders

encodeHeaderOptions: HeaderOptions -> Encode.Value
encodeHeaderOptions options =
  [ H.encodeMaybeField "append" Encode.bool options.append
  , H.encodeMaybeField "separator" Encode.string options.separator
  , H.encodeMaybeField "override" Encode.bool options.override
  , H.encodeMaybeField "duplicate" Encode.bool options.duplicate
  ]
  |> List.filterMap identity
  |> Encode.object

encodeHeader: Header -> Encode.Value
encodeHeader header =
  [ Just ("name", Encode.string header.name)
  , Just ("value", Encode.string header.value)
  , H.encodeMaybeField "options" encodeHeaderOptions header.options
  ]
  |> List.filterMap identity
  |> Encode.object

encode: Response -> Encode.Value
encode response =
  Encode.object
    [ ("statusCode", Encode.int response.statusCode)
    , ("body", Encode.string response.body)
    , ("headers", List.map encodeHeader response.headers |> Encode.list)
    , ("states", H.encodeDict Encode.string response.states)
    , ("unstate", List.map Encode.string response.unstate |> Encode.list)
    , ("end", Encode.bool response.end)
    ]
