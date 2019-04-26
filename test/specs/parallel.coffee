
import test from 'ava'
import ms from 'ms'

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server1 = null
server2 = null
port1 = null
port2 = null
baseUrl = 'http://127.0.0.1'
get1 = (path) -> get "#{baseUrl}:#{port1}#{path}"
get2 = (path) -> get "#{baseUrl}:#{port2}#{path}"

test.before (t) ->
	server1 = microapi.start config,
		'GET /only-on-1st': (req, res) -> status: 'OK'

	server2 = microapi.start config,
		'GET /only-on-2nd': (req, res) -> status: 'OK'

	port1 = await server1.ready
	port2 = await server2.ready
	return

test.after (t) ->
	await Promise.all [
		server1?.stop()
		server2?.stop()
	]
	return



test 'two microapis shouldn\'t interfere with each other', (t) ->
	response = await get1 '/only-on-1st'
	t.is response.statusCode, 200
	response = await get1 '/only-on-2nd'
	t.is response.statusCode, 404

	response = await get2 '/only-on-1st'
	t.is response.statusCode, 404
	response = await get2 '/only-on-2nd'
	t.is response.statusCode, 200
	return

