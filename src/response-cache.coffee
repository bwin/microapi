
convertkey = require './convertkey'

module.exports = responseCache = (config, cache, route, req, res) ->
	try
		cacheKey = convertkey route.cache.key? req
		cacheKey = "data:#{cacheKey}"
		cacheKeyHeaders = "headers:#{cacheKey}"

		shouldCache = yes
		shouldCache = route.cache.shouldCache req if route.cache.shouldCache?
		res.shouldCache = shouldCache
		data = null
		headers = null
		unlock = null
		#waitedForLock = 0

		if shouldCache
			#startTime = Date.now()
			[data, headers] = await cache.loadMulti [cacheKey, cacheKeyHeaders]
			headers = try JSON.parse headers

		if data
			# cached result found
			#elapsed = Date.now() - startTime
			#req.log 'debug', {type: 'cache:hit', cacheKey, elapsed, waitedForLock}
			res.setHeader key, val for key, val of headers if headers
			res.setHeader 'X-Cached', 'true'
			return data
		else
			# get fresh data
			#req.log 'debug', {type: 'cache:miss', cacheKey}
			try
				data = await route.handler req, res
			catch err
				unlock?()
				throw err
			if data and res.shouldCache
				# set cache
				await cache.save cacheKey, route.cache.ttl, data
				if config.cacheHeaders
					headers = res.getHeaders()
					await cache.save cacheKeyHeaders, route.cache.ttl, headers
			unlock?()
	catch err
		throw err
	return data
