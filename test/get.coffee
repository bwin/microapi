
request = require 'request-promise-native'

module.exports = get = (url, params, headers) -> request.get
	uri: if get.baseUrl then "#{get.baseUrl}#{url}" else url
	qs: params
	headers: headers
	json: yes
	simple: no
	timeout: 2000
	resolveWithFullResponse: yes
