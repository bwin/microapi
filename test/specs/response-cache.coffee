
import test from 'ava'

microapi = require '../../index'
config = require '../test-config'
get = require '../get'
wait = require '../wait'

server = null

test.before (t) ->
	i = 0

	server = microapi.start config,

		'GET /cache':
			cache: ttl: '1s', key: (req) -> req.path
			handler: (req, res) -> somevalue: 'XY18'

		'GET /cache-with-headers':
			cache: ttl: '1s', key: (req) -> req.path
			handler: (req, res) ->
				res.setHeader 'X-Test-Header', 123
				return somevalue: 'XY18'

		'GET /cache-if':
			params: x: 'int'
			cache:
				ttl: '1s'
				key: (req) -> req.path
				shouldCache: (req) -> req.params.x < 100
			handler: (req, res) -> somevalue: 'XY18'

		'GET /cache-if-2':
			params: x: 'int'
			cache: ttl: '1s', key: (req) -> req.path
			handler: (req, res) ->
				res.shouldCache = req.params.x < 100
				return somevalue: 'XY18'

		'GET /cache-err':
			cache: ttl: '1s', key: (req) -> req.path
			handler: (req, res) -> throw new Error 'just an err'

		'GET /cache-slow-req':
			cache: ttl: '1s', lock: "250ms", key: (req) -> req.path
			handler: (req, res) ->
				await wait '100ms'
				return i: ++i

		'GET /cache-obj-key':
			cache: ttl: '1s', key: (req) -> xy: 18
			handler: (req, res) -> somevalue: 'XY18'

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'should cache', (t) ->
	expectedResponse = somevalue: 'XY18'

	response = await get '/cache'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# 1st req shouldn't be cached
	t.is response.headers['x-cached'], undefined

	response = await get '/cache'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# 2nd req should be cached
	t.is response.headers['x-cached'], 'true'

	response = await get '/cache'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# 3rd req should be cached
	t.is response.headers['x-cached'], 'true'

	await wait '1s'

	response = await get '/cache'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# req after cooldown shouldn't be cached
	t.is response.headers['x-cached'], undefined
	return

test 'should cache headers, too', (t) ->
	expectedResponse = somevalue: 'XY18'

	response = await get '/cache-with-headers'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# 1st req shouldn't be cached
	t.is response.headers['x-cached'], undefined
	# we expect the header to be set
	t.is response.headers['x-test-header'], '123'

	response = await get '/cache-with-headers'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# 2nd req should be cached
	t.is response.headers['x-cached'], 'true'
	# we expect the header to be set
	t.is response.headers['x-test-header'], '123'
	return

test 'should cache with obj as cache key', (t) ->
	expectedResponse = somevalue: 'XY18'

	response = await get '/cache-obj-key'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# 1st req shouldn't be cached
	t.is response.headers['x-cached'], undefined

	response = await get '/cache-obj-key'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# 2nd req should be cached
	t.is response.headers['x-cached'], 'true'

	response = await get '/cache-obj-key'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# 3rd req should be cached
	t.is response.headers['x-cached'], 'true'

	await wait '1s'

	response = await get '/cache-obj-key'
	t.is response.statusCode, 200
	t.deepEqual response.body, expectedResponse
	# req after cooldown shouldn't be cached
	t.is response.headers['x-cached'], undefined
	return

test 'locking should work', (t) ->
	response1 = get '/cache-slow-req'
	response2 = get '/cache-slow-req'
	response3 = get '/cache-slow-req'
	[response1, response2, response3] = await Promise.all [response1, response2, response3]

	cachedReqCount = 0

	t.is response1.statusCode, 200
	# should be the 1st time the slow req actually ran
	t.deepEqual response1.body, i: 1
	# 1st req shouldn't be cached
	#t.is response1.headers['x-cached'], undefined
	++cachedReqCount if response1.headers['x-cached'] is 'true'

	t.is response2.statusCode, 200
	# should still be the 1st time the slow req actually ran
	t.deepEqual response2.body, i: 1
	# 2nd req should be cached
	#t.is response2.headers['x-cached'], 'true'
	++cachedReqCount if response2.headers['x-cached'] is 'true'

	t.is response3.statusCode, 200
	# should still be the 1st time the slow req actually ran
	t.deepEqual response3.body, i: 1
	# 3rd req should be cached
	#t.is response3.headers['x-cached'], 'true'
	++cachedReqCount if response3.headers['x-cached'] is 'true'

	# exactly 2 req should have been cached
	t.is cachedReqCount, 2

	await wait '1s'

	response3 = get '/cache-slow-req'
	response4 = get '/cache-slow-req'
	[response3, response4] = await Promise.all [response3, response4]

	t.is response3.statusCode, 200
	# should be the 2nd time the slow req actually ran
	t.deepEqual response3.body, i: 2
	# req after cooldown shouldn't be cached
	t.is response3.headers['x-cached'], undefined

	t.is response4.statusCode, 200
	# should still be the 2nd time the slow req actually ran
	t.deepEqual response4.body, i: 2
	# next req should be cached
	t.is response4.headers['x-cached'], 'true'
	return

test 'shouldCache should work', (t) ->
	response = await get '/cache-if', x: 5
	t.is response.statusCode, 200
	# 1st req shouldn't be cached
	t.is response.headers['x-cached'], undefined

	response = await get '/cache-if', x: 5
	t.is response.statusCode, 200
	# 2nd req should be cached
	t.is response.headers['x-cached'], 'true'

	response = await get '/cache-if', x: 500
	t.is response.statusCode, 200
	# 3rd req shouldn't be cached (bec x < 100)
	t.is response.headers['x-cached'], undefined
	return

test 'should not cache when res.shouldCache is false', (t) ->
	response = await get '/cache-if-2', x: 500
	t.is response.statusCode, 200
	# shouldn't be cached (bec x < 100)
	t.is response.headers['x-cached'], undefined

	response = await get '/cache-if-2', x: 500
	t.is response.statusCode, 200
	# shouldn't be cached (bec x < 100)
	t.is response.headers['x-cached'], undefined

	response = await get '/cache-if-2', x: 5
	t.is response.statusCode, 200
	# req shouldn't be cached
	t.is response.headers['x-cached'], undefined

	response = await get '/cache-if-2', x: 5
	t.is response.statusCode, 200
	# req should be cached
	t.is response.headers['x-cached'], 'true'
	return

test 'should not cache errors', (t) ->
	response = await get '/cache-err'
	t.is response.statusCode, 500
	# 1st req shouldn't be cached
	t.is response.headers['x-cached'], undefined

	response = await get '/cache-err'
	t.is response.statusCode, 500
	# 2n req shouldn't be cached
	t.is response.headers['x-cached'], undefined
	return
