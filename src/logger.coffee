
bunyan = require 'bunyan'
createError = require 'http-errors'

logLevels = "trace debug info warn error fatal".split ' '

module.exports = (name, defaultLevel) ->
	unless defaultLevel in logLevels
		throw new Error "invalid config.logLevel '#{defaultLevel}'"
	logger = bunyan.createLogger {name}
	logger.level bunyan[ defaultLevel.toUpperCase() ]
	return (level, data) ->
		inst = process.env.NODE_APP_INSTANCE or null
		type = null

		if level instanceof Error
			err = level
			if 400 <= err.statusCode < 500
				return
				#type = 'clienterror'
				#level = 'debug'
				#data = error:
				#	type: err.name
				#	msg: err.message
			else
				type = 'exception'
				level = 'error'
				data = error:
					type: err.name
					msg: err.message
					stack: err.stack
		else if typeof level isnt 'string'
			throw new Error 'wrong level #{level}'

		unless level in logLevels
			throw new Error "invalid log level '#{level}'"

		logdata = {inst, type, data...}
		logger[level]? logdata
		return
	return
