
redis = require 'redis'
RateLimiter = require 'strict-rate-limiter'
createError = require 'http-errors'

convertkey = require './convertkey'

redisClient = redis.createClient()

rateLimit = (limitKey, max, time) -> new Promise (resolve, reject) ->
	limiter = new RateLimiter
		id: limitKey
		limit: max + 1
		duration: time
	, redisClient
	.get (err, limit, remaining, reset) ->
		return reject err if err
		return resolve {limit, remaining, reset}
	return

module.exports = ratelimiter = (route, req, res) ->
	limiterKey = convertkey route.ratelimit.key? req
	limiterKey = "microapi:limiter:#{limiterKey}"
	limits = await rateLimit limiterKey, route.ratelimit.max, route.ratelimit.time
	{limit, remaining, reset} = limits
	if remaining > 0
		res.setHeader 'X-RateLimit-Limit', limit
		res.setHeader 'X-RateLimit-Remaining', remaining
		res.setHeader 'X-RateLimit-Reset', Math.floor reset / 1000
	else
		# limit exceeded
		#req.log 'info', {type: 'ratelimit:exceeded', limiterKey}
		retryAfter = Math.floor (reset - Date.now()) / 1000
		res.setHeader 'Retry-After', retryAfter
		msg = "Rate limit exceeded. Retry in #{retryAfter}s."
		throw new createError.TooManyRequests msg
	return
