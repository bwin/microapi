
import test from 'ava';

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config,

		'GET /basic': -> status: 'OK'

		'GET /regex/:id':
			params: id: 'int'
			handler: (req, res) -> id: req.params.id

		'GET /regex/@:username/post-:postId': (req, res) -> req.params

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'invalid route should return 404', (t) ->
	response = await get '/does-not-exist'
	t.is response.statusCode, 404
	return

test 'basic route should work', (t) ->
	response = await get '/basic'
	t.is response.statusCode, 200
	t.deepEqual response.body, status: 'OK'
	return

test 'basic regex route should work', (t) ->
	response = await get '/regex/123'
	t.is response.statusCode, 200
	t.deepEqual response.body, id: 123
	return

test 'complex regex route should work', (t) ->
	response = await get '/regex/@exampleuser/post-987654'
	t.is response.statusCode, 200
	t.deepEqual response.body,
		postId: '987654'
		username: 'exampleuser'
	return
