var _nomalab$elm_hapi$Native_Hapi_Inert = function () {
  const utils = _nomalab$elm_hapi$Native_Hapi_Utils
  const Inert = utils.requireModule('inert')

  function plugin(options) {
    return {
      register: Inert.register,
      options: options
    }
  }

  function replyFile(replier, config) {
    return Object.assign({}, replier, { response: replier.reply.file(config.path, config) })
  }

  function file(config) {
    return { file: config }
  }

  function directory(config) {
    return { directory: config }
  }

  return {
    plugin: plugin,
    replyFile: F2(replyFile),
    file: file,
    directory: directory
  }
}()
