
import test from 'ava';

microapi = require '../../index'
config = require '../test-config'
upload = require '../upload'

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

		'POST /upload':
			#params: id: 'string'
			json: no
			handler: (req, res) ->
				console.log "body=", req.body
				return req.body

	port = await server.ready
	upload.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()


test '[TODO] move upload to @bwin/microapi-upload', (t) -> t.truthy yes

###
test 'file uploads should work', (t) ->
	data = id: 123
	files =
		'msg.txt':
			type: 'text/plain'
			content: 'msg'
		'readme.txt':
			type: 'text/plain'
			content: 'help'
	response = await upload '/upload', data, files
	console.error response.body
	t.is response.statusCode, 200
	t.deepEqual response.body.data, data
	t.deepEqual response.body.files, files
	return
###
