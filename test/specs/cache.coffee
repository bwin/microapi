
import test from 'ava'

microapi = require '../../index'
config = require '../test-config'
get = require '../get'
wait = require '../wait'

server = null

test.before (t) ->
	i = 0

	server = microapi.start config,
		'GET /cache-some-val': (req, res) ->
			data = await req.cache 'my-cache-key', ttl: '1s', -> d: Date.now()
			data.status = 'OK'
			return data

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'should cache', (t) ->
	response = await get '/cache-some-val'
	t.is response.statusCode, 200
	expectedDatetime = response.body.d

	response = await get '/cache-some-val'
	t.is response.statusCode, 200
	t.is expectedDatetime, response.body.d
	# 2nd req should be cached

	response = await get '/cache-some-val'
	t.is response.statusCode, 200
	t.is expectedDatetime, response.body.d
	# 3rd req should be cached

	await wait '1s'

	response = await get '/cache-some-val'
	t.is response.statusCode, 200
	t.not expectedDatetime, response.body.d
	expectedDatetime = response.body.d
	# req after cooldown shouldn't be cached

	response = await get '/cache-some-val'
	t.is response.statusCode, 200
	t.is expectedDatetime, response.body.d
	# but the next one should be cached again
	return
