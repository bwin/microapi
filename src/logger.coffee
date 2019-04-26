
bunyan = require 'bunyan'
createError = require 'http-errors'

logger = bunyan.createLogger name: 'xy18'

module.exports = log = (level, data) ->
	# TODO: use process.env.NODE_APP_INSTANCE instead?
	pm_id = process.env.pm_id or null
	type = null

	if level instanceof Error
		err = level
		if 400 <= level.statusCode < 500
			return
		#	type = 'clienterror'
		#	level = 'info'
		#	data = error:
		#		type: err.name
		#		msg: err.message
		else
			type = 'exception'
			level = 'error'
			data = error:
				type: err.name
				msg: err.message
				stack: err.stack
	else if typeof level isnt 'string'
		throw new Error 'wrong level #{level}'
	logdata = {pm_id, type, data...}
	logger[level]? logdata
	return

log.disable = ->
	logger.level bunyan.FATAL + 1
	return
