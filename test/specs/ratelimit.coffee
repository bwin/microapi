
import test from 'ava'

microapi = require '../../index'
config = require '../test-config'
get = require '../get'
wait = require '../wait'

server = null

test.before (t) ->
	server = microapi.start config,
		'GET /limit':
			ratelimit: max: 3, time: '1s', key: (req) -> req.ip
			handler: (req, res) -> status: 'OK'

		'GET /limit-obj-key':
			ratelimit: max: 3, time: '1s', key: (req) -> ip: req.ip
			handler: (req, res) -> status: 'OK'

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'should ratelimit', (t) ->
	response = await get '/limit'
	# 1st req should pass
	t.is response.statusCode, 200

	response = await get '/limit'
	# 2nd req should pass
	t.is response.statusCode, 200

	response = await get '/limit'
	# 3rd req should pass
	t.is response.statusCode, 200

	response = await get '/limit'
	# 4th req should get rejected
	t.is response.statusCode, 429

	await wait '1s'

	response = await get '/limit'
	# req should pass after cooldown
	t.is response.statusCode, 200

	return

test 'should ratelimit with object key', (t) ->
	response = await get '/limit-obj-key'
	# 1st req should pass
	t.is response.statusCode, 200

	response = await get '/limit-obj-key'
	# 2nd req should pass
	t.is response.statusCode, 200

	response = await get '/limit-obj-key'
	# 3rd req should pass
	t.is response.statusCode, 200

	response = await get '/limit-obj-key'
	# 4th req should get rejected
	t.is response.statusCode, 429

	await wait '1s'

	response = await get '/limit-obj-key'
	# req should pass after cooldown
	t.is response.statusCode, 200

	return
