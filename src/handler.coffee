
createError = require 'http-errors'

auth = require './auth'
cache = require './cache'
ratelimiter = require './ratelimiter'
checkparams = require './checkparams'

module.exports = handler = (config, route, req, res) ->
	unless route?
		throw new createError.NotFound "Can not #{req.method} #{req.pathname}"

	await ratelimiter route, req, res if route.ratelimit
	await auth route, req, res if route.auth
	await checkparams route, req, res if route.params
	return cache config, route, req, res if route.cache

	return route.handler req, res
