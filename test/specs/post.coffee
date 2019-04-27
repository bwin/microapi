
import test from 'ava';

microapi = require '../../index'
config = require '../test-config'
post = require '../post'

server = null

test.before (t) ->
	server = microapi.start config,
		'POST /post-here':
			params:
				x: 'string'
				y: 'int'
				z: 'float'
				obj: 'object'
				arr: 'array'
			handler: (req, res) -> req.params

	port = await server.ready
	post.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'POST should work', (t) ->
	data =
		x: 'abcdef'
		y: 123
		z: 1.23
		obj:
			a: 1
			b: 2
		arr: [7, 8, 9]
	response = await post '/post-here', data
	t.is response.statusCode, 200
	t.deepEqual response.body, data
	return
