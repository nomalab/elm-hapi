'use strict'

var target = process.argv[2]
var file = '../dist/' + target + 'Server.js'
var main = target + 'Server'

require(file)[main].worker()
