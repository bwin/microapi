
import test from 'ava';

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config,

		'GET /echo-int':
			params:
				x: 'int'
				y: 'int'
			handler: (req, res) -> req.params

		'GET /echo-float':
			params:
				x: 'float'
				y: 'float'
			handler: (req, res) -> req.params

		'GET /len':
			params: x: 'string': len: 5
			handler: (req, res) -> req.params
		'GET /minlen':
			params: x: 'string': minlen: 3
			handler: (req, res) -> req.params
		'GET /maxlen':
			params: x: 'string': maxlen: 5
			handler: (req, res) -> req.params
		'GET /minmaxlen':
			params: x: 'string':
				minlen: 3
				maxlen: 5
			handler: (req, res) -> req.params

		'GET /check':
			params: x: 'string': (val) -> val is 'YES'
			handler: (req, res) -> req.params

		'GET /regex':
			params: x: 'string': /abc.*/
			handler: (req, res) -> req.params

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'int params should work', (t) ->
	data =
		x: 1
		y: 2
	response = await get '/echo-int', data
	t.is response.statusCode, 200
	t.deepEqual response.body, data
	return

test 'float params should work', (t) ->
	data =
		x: 1.23
		y: 9.876
	response = await get '/echo-float', data
	t.is response.statusCode, 200
	t.deepEqual response.body, data
	return

test 'missing param should result in 400', (t) ->
	response = await get '/echo-int',
		x: 1
	t.is response.statusCode, 400
	return

test 'len: too short param should result in 400', (t) ->
	response = await get '/len', x: 'a'
	t.is response.statusCode, 400
	return
test 'len: too long param should result in 400', (t) ->
	response = await get '/len', x: 'abcdefg'
	t.is response.statusCode, 400
	return
test 'len: right length param should result in 200', (t) ->
	response = await get '/len', x: 'abcde'
	t.is response.statusCode, 200
	return

test 'minlen: too short param should result in 400', (t) ->
	response = await get '/minlen', x: 'a'
	t.is response.statusCode, 400
	return
test 'minlen: should work', (t) ->
	response = await get '/minlen', x: 'abcde'
	t.is response.statusCode, 200
	return

test 'maxlen: too long param should result in 400', (t) ->
	response = await get '/maxlen', x: 'abcdefg'
	t.is response.statusCode, 400
	return
test 'maxlen: should work', (t) ->
	response = await get '/maxlen', x: 'a'
	t.is response.statusCode, 200
	return

test 'min+maxlen: too short param should result in 400', (t) ->
	response = await get '/minmaxlen', x: 'a'
	t.is response.statusCode, 400
	return
test 'min+maxlen: too long param should result in 400', (t) ->
	response = await get '/minmaxlen', x: 'abcdefg'
	t.is response.statusCode, 400
	return
test 'min+maxlen: right length param should result in 200', (t) ->
	response = await get '/minmaxlen', x: 'abcd'
	t.is response.statusCode, 200
	return

test 'check: should reject', (t) ->
	response = await get '/check', x: 'NO'
	t.is response.statusCode, 400
	return
test 'check: should work', (t) ->
	response = await get '/check', x: 'YES'
	t.is response.statusCode, 200
	return

test 'regex: should reject invalid param', (t) ->
	response = await get '/regex', x: 'xxx'
	t.is response.statusCode, 400
	return
test 'regex: should work', (t) ->
	response = await get '/regex', x: 'abcde'
	t.is response.statusCode, 200
	return
