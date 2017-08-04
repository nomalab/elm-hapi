var _nomalab$elm_hapi$Native_Hapi = function () {
  const Hapi = require('hapi')
  const PassThrough = require('stream').PassThrough
  const helpers = _pauldijou$elm_kernel_helpers$Native_Kernel_Helpers

  const internals = Symbol('internals')

  function create(internalSettings, config) {
    return helpers.task.fromCallback(succeed => {
      const server = new Hapi.Server({
        app: config.settings || {},
        debug: config.debug
      })

      server[internals] = internalSettings

      succeed(server)
    })
  }

  function start(server) {
    return helpers.task.fromPromise(server.start.bind(server))
  }

  function stop(server) {
    return helpers.task.fromPromise(server.stop.bind(server))
  }

  function withConnection(connection, server) {
    server.connection(connection)
    return server
  }

  function withState(name, state, server) {
    server.state(name, state)
    return state
  }

  const requestKeys = [
    "id",
    "method",
    "path",
    "headers",
    "params",
    "query",
    "state",
    "payload"
  ]

  function handleRequest(request, reply) {
    // If decoder fails, will crash at runtime
    // se we will normalize the request to prevent any circular structure
    // see: https://github.com/elm-lang/core/issues/890
    const normalizeRequest = requestKeys.reduce((acc, key) => {
      acc[key] = request[key]
      return acc
    }, {})
    const internals = getInternals(request.server)
    const onRequestEvent = A2(internals.events.onRequest, { reply: reply}, normalizeRequest)
    helpers.task.rawSpawn(internals.callback(onRequestEvent))
  }

  function withRoute(route, server) {
    route.handler = handleRequest
    server.route(route)
    return server
  }

  function getInfos(server) {
    return helpers.task.fromCallback(succeed => {
      if (server.info === undefined || server.info === null) {
        succeed((server.connections || []).map(connection => connection.info))
      } else {
        succeed([ server.info ])
      }
    })
  }

  function getLoad(server) {
    return helpers.task.fromCallback(succeed => {
      succeed(server.load)
    })
  }

  function getInternals(server) {
    return server[internals] || {}
  }

  function getSettings(server) {
    return server.settings || {}
  }

  function getSetting(key, server) {
    return getSettings(server)[key]
  }

  function getVersion(server) {
    return server.version
  }

  function isClosed(replier) {
    return replier.closed === true
  }

  function reply(replier, response) {
    // Init stream first time
    if (!replier.response) {
      replier.stream = new PassThrough()
      replier.response = replier.reply(replier.stream)
    }

    // Assign status code
    replier.response.code(response.statusCode)

    // Assign HTTP headers
    response.headers.forEach(header => {
      replier.response.header(header.name, header.value, header.options)
    })

    // Manage states
    Object.keys(response.states).forEach(name => {
      replier.response.state(name, response.states[name])
    })

    response.unstate.forEach(name => {
      replier.response.unstate(name)
    })

    // Write body
    replier.stream.write(response.body, 'utf8')

    if (response.end) {
      replier.stream.end()
      replier.closed = true
    }

    return helpers.task.succeed()
  }

  return {
    create: F2(create),
    withConnection: F2(withConnection),
    withState: F3(withState),
    withRoute: F2(withRoute),
    start: start,
    stop: stop,
    reply: F2(reply),
    getInfos: getInfos,
    getLoad: getLoad,
    getSettings: getSettings,
    getSetting: F2(getSetting),
    getVersion: getVersion,
    isClosed: isClosed
  }
}()
