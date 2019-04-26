
import test from 'ava';

microapi = require '../../index'
log = require '../../lib/logger'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config, (endpoint) ->

		endpoint.setDefaults params: x: 'int'

		endpoint
			method: 'GET', path: '/test-defaults'
			params: y: 'float'
			handler: (req, res) -> req.params

		return
	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'logger should throw when log level is not a string', (t) ->
	level = invalid: 1
	data = x: 1
	try log level, data
	catch err
	t.truthy err instanceof Error
	return
