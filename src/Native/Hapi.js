var _nomalab$elm_hapi$Native_Hapi = function () {
  const utils = _nomalab$elm_hapi$Native_Hapi_Utils
  const Hapi = utils.requireModule('hapi')
  const PassThrough = require('stream').PassThrough
  const helpers = _pauldijou$elm_kernel_helpers$Native_Kernel_Helpers
  const settings = {}

  function init(stgs) {
    return helpers.task.fromCallback(succeed => {
      for (let key in stgs) {
        settings[key] = stgs[key]
      }
      succeed()
    })
  }

  function create(config) {
    return helpers.task.fromCallback((succeed, fail) => {
      try {
        const server = new Hapi.Server({
          app: config.settings || {},
          debug: config.debug
        })
        succeed(server)
      } catch (e) {
        fail(e)
      }
    })
  }

  function start(server) {
    return helpers.task.fromPromise(() =>
      server.start()
        .then(() => server)
        .catch(err => server.stop().then(() =>  Promise.reject(err)))
    )
  }

  function stop(server) {
    return helpers.task.fromPromise(server.stop.bind(server))
  }

  function withPlugins(plugins, server) {
    return helpers.task.fromCallback((succeed, fail) => {
      server.register(helpers.list.toArray(plugins), err => {
        if (err) { fail(err) }
        else { succeed(server) }
      })
    })
  }

  function withConnection(connection, server) {
    server.connection(connection)
    return server
  }

  function withState(name, state, server) {
    server.state(name, state)
    return state
  }

  function handleRequest(request, reply) {
    // If decoder fails, will crash at runtime
    // so we will normalize the request to prevent any circular structure
    // see: https://github.com/elm-lang/core/issues/890
    const normalizeRequest = utils.normalizeRequest(request)
    const onRequestEvent = A2(settings.messages.onRequest, { reply: reply, closed: false }, normalizeRequest)
    helpers.task.rawSpawn(settings.sendToSelf(onRequestEvent))
  }

  function withRoute(route, server) {
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
    return replier.closed
  }

  function reply(replier, response) {
    return helpers.task.fromCallback((succeed, fail) => {
      try {
        // Init stream first time
        if (!replier.response) {
          replier.stream = new PassThrough()
          replier.response = replier.reply(replier.stream)
        }

        // Assign status code
        if (response.statusCode > 0) {
          replier.response.code(response.statusCode)
        }

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
        if (replier.stream) {
          replier.stream.write(response.body, 'utf8')

          if (response.end) {
            replier.stream.end()
            replier.closed = true
          }
        }
      } catch (e) {
        fail(e)
      }
    })
  }

  return {
    identity: function identity(a) { return a },
    init: init,
    create: create,
    withPlugins: F2(withPlugins),
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
    isClosed: isClosed,
    handler: handleRequest
  }
}()
