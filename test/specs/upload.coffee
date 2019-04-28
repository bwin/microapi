
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
			params: id: 'int'
			json: no # TODO remove this
			form: yes
			handler: (req, res) ->
				params: req.params
				files: req.body.files

	port = await server.ready
	upload.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



test 'file uploads should work', (t) ->
	data = id: 123
	files =
		'msg.txt':
			contentType: 'text/plain'
			content: 'msg'
		'readme.txt':
			contentType: 'text/plain'
			content: 'help'
	response = await upload '/upload', data, files
	t.is response.statusCode, 200
	t.deepEqual response.body.params, data

	i = 0
	for filename, file of files
		uploadedFile = response.body.files["file#{i++}"]
		t.is uploadedFile.name, filename
		t.is uploadedFile.type, file.contentType
		t.is uploadedFile.size, file.content.length
	return
