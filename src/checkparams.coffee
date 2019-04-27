
createError = require 'http-errors'
moment = require 'moment'

performCheck = (validationFn, arg) ->
	results = await validationFn arg
	if Array.isArray results
		return no for result in results when not result
		return yes
	return results

module.exports = checkparams = (route, req, res) ->
	for key, param of route.params
		val = req.params[key] or req.sourceParams[key]

		# convert
		req.params[key] = val = switch param.type
			when 'int' then if val then parseInt val, 10 else null
			when 'float' then if val then parseFloat val else null
			when 'string' then val and "#{val}" or ''
			when 'date' then if val then moment.parse val else null
			when 'bool'
				val = "#{val}".toLowerCase()
				if val in ['true', 'yes', 'on', '1'] then yes
				else if val in ['false', 'no', 'off', '0', '-1'] then no
				else null
			when 'object'
				if typeof val is 'object' then val
				else if typeof val is 'string' then try JSON.parse val
			when 'array'
				val = (try JSON.parse val) if typeof val is 'string'
				if Array.isArray val then val
				else null
			else val

		# check
		if param.required
			if not val? or val is ''
				throw new createError.BadRequest "#{key} is required"

		if param.len? and val.length isnt param.len
			throw new createError.BadRequest "#{key} length is not #{param.len}"

		if param.minlen? and val.length < param.minlen
			throw new createError.BadRequest "#{key} length < #{param.minlen}"

		if param.maxlen? and val.length > param.maxlen
			throw new createError.BadRequest "#{key} length > #{param.maxlen}"

		if param.check? and not await performCheck param.check, val or ''
			throw new createError.BadRequest "invalid value for #{key}"

		if param.regex? and not param.regex.test val or ''
			throw new createError.BadRequest "invalid value for #{key}"

	if route.validate? and not await performCheck route.validate, req.params
		throw new createError.BadRequest "param validation failed"
	return
