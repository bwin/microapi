
createError = require 'http-errors'

auth = require './auth'
responseCache = require './response-cache'
ratelimiter = require './ratelimiter'
checkparams = require './checkparams'

module.exports = handler = (config, cache, route, req, res) ->
	unless route?
		throw new createError.NotFound "Can not #{req.method} #{req.pathname}"

	await ratelimiter route, req, res if route.ratelimit
	await auth route, req, res if route.auth
	await checkparams route, req, res if route.params
	return responseCache config, cache, route, req, res if route.cache

	return route.handler req, res
