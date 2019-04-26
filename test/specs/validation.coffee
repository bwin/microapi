
import test from 'ava';

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config,
		'GET /validate':
			params:
				x: 'int'
				y: 'int'
			validate: (params) -> params.x + params.y >= 10
			handler: (req, res) -> req.params

		'GET /validate-array':
			params:
				x: 'int'
				y: 'int'
			validate: (params) -> [
				params.x > 10
				params.y < 10
			]
			handler: (req, res) -> req.params

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()


test 'validation should accept valid params', (t) ->
	response = await get '/validate', x: 5, y: 5
	t.is response.statusCode, 200
	return

test 'validation should reject invalid params', (t) ->
	response = await get '/validate', x: 1, y: 1
	t.is response.statusCode, 400
	return

test 'validation (array) should accept valid params', (t) ->
	response = await get '/validate-array', x: 100, y: 0
	t.is response.statusCode, 200
	return
	
test 'validation (array) reject invalid valid params', (t) ->
	response = await get '/validate-array', x: 0, y: 0
	t.is response.statusCode, 400
	return
