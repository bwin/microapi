
request = require 'request-promise-native'

###
	example:
	files =
		'msg.txt':
			type: 'text/plain'
			content: 'msg'
		'readme.txt':
			type: 'text/plain'
			content: 'help'
###

module.exports = upload = (url, params, files, headers) ->
	_attachments = {}
	parts = []
	for filename, attachment of files
		_attachments[filename] =
			follows: true
			length: attachment.content.length
			content_type: attachment.type
		parts.push body: attachment.content

	return request.post
		uri: if upload.baseUrl then "#{upload.baseUrl}#{url}" else url
		#body: params
		headers: headers
		json: yes
		simple: no
		resolveWithFullResponse: yes
		multipart: [
			'content-type': 'application/json'
			body: JSON.stringify {params..., _attachments}
		,
			parts...
		]
