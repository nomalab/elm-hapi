var _nomalab$elm_hapi$Native_Hapi = function () {
  const utils = _nomalab$elm_hapi$Native_Hapi_Utils;
  const Hapi = utils.requireModule('hapi');
  const PassThrough = require('stream').PassThrough;
  const helpers = _pauldijou$elm_kernel_helpers$Native_Kernel_Helpers;
  const settings = {};

  function createServer(config) {
    const server = new Hapi.Server({
      app: config.settings || {},
      debug: config.debug
    });

    return {
      start: function start({ onRequest }) {
        settings.onRequest = onRequest;
        return server.start();
      },
      stop: function stop() {
        settings.onRequest = undefined;
        return server.stop();
      }
    }
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
    if (settings.onRequest) {
      settings.onRequest(reply, utils.normalizeRequest(request));
    }
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

  function getProperty(name, server) {
    return helpers.maybe.parse(server[name])
  }

  const elmHapiStuff = Symbol('elm-hapi');

  function isClosed(replier) {
    return replier[elmHapiStuff].closed
  }

  function init(replier) {
    if (!replier[elmHapiStuff]) {
      const stream = new PassThrough;
      replier[elmHapiStuff] = {
        stream: stream,
        response: replier.reply(stream)
      };
    }
    return replier;
  }

  function withStatusCode(code, replier) {
    if (code > 0) {
      replier[elmHapiStuff].response.code(code);
    }
    return replier;
  }

  function withHeader(header, replier) {
    replier[elmHapiStuff].response.header(header.name, header.value, {
      append: true
    });
    return replier;
  }

  function withCookie(cookie, replier) {
    replier[elmHapiStuff].response.state(cookie.name, cookie);
    return replier;
  }

  function withBody(body, replier) {
    replier[elmHapiStuff].stream.write(body, 'utf8');
    return replier;
  }

  function send(end, replier) {
    if (end) {
      replier[elmHapiStuff].stream.end()
      replier[elmHapiStuff].closed = true;
    }
    return replier;
  }

  return {
    identity: function identity(a) { return a },
    createServer: createServer,
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
    getProperty: F2(getProperty),
    isClosed: isClosed,
    init: init,
    withStatusCode: F2(withStatusCode),
    withHeader: F2(withHeader),
    withBody: F2(withBody),
    send: F2(send),
    handler: handleRequest
  }
}()
