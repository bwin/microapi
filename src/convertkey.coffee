
crypto = require 'crypto'

module.exports = convertkey = (key) ->
	if typeof key is 'object'
		key = crypto
		.createHash 'sha1'
		.update JSON.stringify key
		.digest 'hex'
	return key
