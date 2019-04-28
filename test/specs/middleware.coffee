
import test from 'ava'
import ms from 'ms'

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config,
		'GET /multiple-handlers': [
			(req, res) -> req.data.xy18 = 23
			(req, res) -> result: req.data.xy18
			(req, res) ->
				res.data.xy23 = 42
				return res.data
		]

		# this namespace doesnt work
		# TODO why?
		'NAMESPACE /':
			middleware: (req, res, next) ->
				res.data.y1 = 1
				return next()
			routes:
				'GET /connect-middleware': (req, res) ->
					res.data.y2 = 2
					return

		'GET /connect-middleware': [
			(req, res, next) ->
				res.data.y1 = 1
				return next()
			(req, res) ->
				res.data.y2 = 2
				return
		]

		'NAMESPACE /':
			middleware: (req, res) ->
				res.data.x1 = 1
				return
			routes:
				'NAMESPACE /':
					middleware: [
						(req, res) ->
							res.data.x2 = 2
							return
						(req, res) ->
							res.data.x3 = 3
							return
					]
					routes:
						'GET /test': (req, res) ->
							res.data.x4 = 4
							return

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()

test 'connect-style middleware defined on namespace should work', (t) ->
	response = await get '/connect-middleware'
	t.deepEqual response.body,
		y1: 1
		y2: 2
	return

test 'middleware defined on namespace should work', (t) ->
	response = await get '/test'
	t.deepEqual response.body,
		x1: 1
		x2: 2
		x3: 3
		x4: 4
	return

test 'multiple handlers should work', (t) ->
	response = await get '/multiple-handlers'
	t.is response.statusCode, 200
	t.deepEqual response.body,
		result: 23
		xy23: 42
	return
