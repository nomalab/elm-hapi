var _nomalab$elm_hapi$Native_Hapi_Utils = function () {
  function requireModule(name) {
    try {
      return require(name)
    } catch (e) {
      console.log('')
      console.log('You must install Node module "' + name + '". Best way is probably to add it as a dependency inside your package.json')
      console.log('')
      process.exit(1)
    }
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

  function normalizeRequest(request) {
    return requestKeys.reduce((acc, key) => {
      acc[key] = request[key]
      return acc
    }, {})
  }

  return {
    requireModule: requireModule,
    normalizeRequest: normalizeRequest
  }
}()
