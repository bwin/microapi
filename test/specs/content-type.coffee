
import test from 'ava';

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config,
		'GET /text': (req, res) ->
			res.setHeader 'Content-Type', 'text/plain'
			return "just text"

		'GET /html':
			type: 'text/html'
			handler: (req, res) -> "just <strong>html</strong>"

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'content-type should work when set with res.setHeader', (t) ->
	response = await get '/text'
	t.is response.statusCode, 200
	t.is response.headers['content-type'], 'text/plain'
	t.is response.body, "just text"
	return

test 'content-type should work when defined on route with type', (t) ->
	response = await get '/html'
	t.is response.statusCode, 200
	t.is response.headers['content-type'], 'text/html'
	t.is response.body, "just <strong>html</strong>"
	return
