
import test from 'ava';

microapi = require '../../index'
config = require '../test-config'
post = require '../post'

server = null

test.before (t) ->
	server = microapi.start config,
		'POST /no-body':
			body: no
			handler: (req, res) -> req.body

		'POST /stream':
			body: no
			stream: yes
			handler: (req, res) -> req.pipe res

		'POST /stream-body':
			body: no
			handler: (req, res) ->
				req.pipe res
				# with await
				await new Promise (resolve) -> res.on 'end', resolve
				return # return nothing, so streaming works

		'POST /stream-body-return-promise':
			body: no
			handler: (req, res) ->
				req.pipe res
				# by returning promise wich resolves to undefined
				return new Promise (resolve) -> res.on 'end', resolve

	port = await server.ready
	post.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'req.body should be undefined when using body: no', (t) ->
	data = x: 'abcdef'
	response = await post '/no-body', data
	t.is response.statusCode, 200
	t.is response.body, undefined
	return

test 'streaming should work', (t) ->
	data = 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'
	response = await post '/stream', data
	t.is response.statusCode, 200
	t.deepEqual response.body, data
	return

test 'streaming should work (2)', (t) ->
	data = 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'
	response = await post '/stream-body', data
	t.is response.statusCode, 200
	t.deepEqual response.body, data
	return

test 'streaming should work with returned promise', (t) ->
	data = 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef'
	response = await post '/stream-body-return-promise', data
	t.is response.statusCode, 200
	t.deepEqual response.body, data
	return
