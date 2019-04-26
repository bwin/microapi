
import test from 'ava';

microapi = require '../../index'
config = require '../test-config'
post = require '../post'

server = null
console.log "____________________"
console.log "____________________"
console.log "ssds"
console.log "____________________"
console.log "____________________"
test.before (t) ->
	server = microapi.start config,
		'POST /post-here':
			params:
				x: 'string'
				y: 'int'
			handler: (req, res) -> req.params

	port = await server.ready
	post.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'POST should work', (t) ->
	data =
		x: 'abc'
		y: 123
	response = await post '/post-here', data
	t.is response.statusCode, 200
	t.deepEqual response.body, data
	return
