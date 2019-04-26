
import test from 'ava'
import ms from 'ms'

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config,
		'GET /headers': (req, res) ->
			res.setHeader 'X-Test-Header-A', 123
			res.setHeader 'X-Test-Header-B', 987
			return somevalue: 'XY18'

		'GET /headers-reply': (req, res) -> req.headers

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()

test 'should set headers', (t) ->
	response = await get '/headers'
	t.is response.headers['x-test-header-a'], '123'
	t.is response.headers['x-test-header-b'], '987'
	return

test 'should be able to read headers', (t) ->
	response = await get '/headers-reply', null,
		'X-Test-Header-A': 123
		'X-Test-Header-B': 987
	{body} = response
	t.is body['x-test-header-a'], '123'
	t.is body['x-test-header-b'], '987'
	return
