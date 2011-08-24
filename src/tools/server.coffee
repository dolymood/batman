#
# server.coffee
# batman.js
#
# Created by Nick Small
# Copyright 2011, Shopify
#

connect = require 'connect'
path    = require 'path'
fs      = require 'fs'
cli     = require './cli'
utils   = require './utils'
Batman  = require '../lib/batman.js'

# Creates a connect server. This file is required by the main batman executable,
# but it can also be required by clients wishing to extend the connect stack for
# their own nefarious purposes.
#
# Options:
#  * `build` - Boolean : if truthy the server will transparently compile requests for a .js file from a .coffee file if the .coffee file exists.
#  * `buildDir` - Path : where to place the built Coffeescript files if `build` is true. Defaults to './build'
#  * `port` - Number   : what port to listen on.
getServer = (options) ->
  # Create a connect server with the
  #  * transparent coffee compilation middleware
  #  * staic file serving middle ware for the current directory
  #  * static file serving at the /batman path for the lib dir of batman
  # and tell it to serve on the passed port.
  server = connect.createServer(
    connect.favicon(),
    connect.logger(),
    connect.static(process.cwd()),
    connect.directory(process.cwd())
  )

  if options.build
    server.use utils.CoffeeCompiler(src: process.cwd(), dest: path.join(process.cwd(), options.buildDir))

  server.use '/batman', connect.static(path.join(__dirname,'..','lib'))
  server.listen options.port, '127.0.0.1'
  return server

if typeof RUNNING_IN_BATMAN isnt 'undefined'
  cli.enable('daemon')
     .setUsage('batman server [OPTIONS]')
     .parse
        port: ['p', "Port to run HTTP server on", "number", 1047]
        build: ['b', "Build coffeescripts on the fly into the build dir (default is ./build) and serve them as js", "boolean", true]
        'build-dir': [false, "Where to store built coffeescript files (default is ./build)", "path"]

  cli.main (args, options) ->
    Batman.mixin options, utils.getConfig()
    options.buildDir = options['build-dir'] if options['build-dir']?
    server = getServer(options)
    @ok 'Batman is waiting at http://127.0.0.1:' + options.port
else
  module.exports = getServer
