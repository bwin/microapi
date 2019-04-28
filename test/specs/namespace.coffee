
import test from 'ava'
import ms from 'ms'

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config,
		'NAMESPACE /':
			middleware: (req, res, next) ->
				res.data.y1 = 1
				return next()
			routes:
				'GET /': -> status: 'index'
				'GET /test': -> status: 'test'
				'GET /connect-middleware': (req, res) ->
					res.data.y2 = 2
					return

		'NAMESPACE /user':
			routes:
				'GET /settings': -> status: 'user'

				'NAMESPACE /list':
					routes:
						'GET /all': -> status: 'all'
						'GET /some': -> status: 'some'
						'GET ^/root': -> status: 'root'

		'NAMESPACE /deep': routes:
			'NAMESPACE /deeper': routes:
				'NAMESPACE /rlydeep': routes:
					'GET /finally': -> status: 'done'

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()

getRoute = (method, path) -> server.routes[path]?[method]?

test 'namespaced routes should work', (t) ->
	t.truthy getRoute 'GET', '/'
	t.truthy getRoute 'GET', '/test'
	t.truthy getRoute 'GET', '/connect-middleware'
	t.truthy getRoute 'GET', '/user/settings'
	t.truthy getRoute 'GET', '/user/list/all'
	t.truthy getRoute 'GET', '/user/list/some'
	t.truthy getRoute 'GET', '/root'
	t.truthy getRoute 'GET', '/deep/deeper/rlydeep/finally'
	return

###
test 'namespace inheritance should work', (t) ->
	throw new Error 'TODO write test'
	return
###

test 'connect-style middleware defined on namespace should work', (t) ->
	response = await get '/connect-middleware'
	t.deepEqual response.body,
		y1: 1
		y2: 2
	return
