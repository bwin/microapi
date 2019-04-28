
request = require 'request-promise-native'

###
	example:
	files =
		'msg.txt':
			contentType: 'text/plain'
			content: 'msg'
		'readme.txt':
			contentType: 'text/plain'
			content: 'help'
###

module.exports = upload = (url, params, files, headers) ->
	req = request.post
		uri: if upload.baseUrl then "#{upload.baseUrl}#{url}" else url
		headers: headers
		json: yes
		simple: no
		resolveWithFullResponse: yes

	form = req.form()
	form.append key, val for key, val of params
	i = 0
	for filename, file of files
		{content, contentType} = file
		form.append "file#{i++}", content, {filename, contentType}

	return req
