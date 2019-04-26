
request = require 'request-promise-native'

module.exports = post = (url, params, headers) -> await request.post
	uri: if post.baseUrl then "#{post.baseUrl}#{url}" else url
	body: params
	headers: headers
	json: yes
	simple: no
	resolveWithFullResponse: yes
