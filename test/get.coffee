
request = require 'request-promise-native'

module.exports = get = (url, params, headers) -> await request.get
	uri: if get.baseUrl then "#{get.baseUrl}#{url}" else url
	qs: params
	headers: headers
	json: yes
	simple: no
	resolveWithFullResponse: yes
