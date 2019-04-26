
{promisify} = require 'util'

redis = require 'redis'
redisLock = require 'redis-lock'

convertkey = require './convertkey'

redisClient = redis.createClient()
lock = redisLock redisClient

redisGet = promisify redisClient.get
.bind redisClient

redisMget = promisify redisClient.mget
.bind redisClient

redisSetex = (cacheKey, ttl, data) -> new Promise (resolve, reject) ->
	data = try JSON.stringify data if typeof data is 'object'
	#console.log "*** redisSetex", cacheKey, ttl, data
	redisClient.setex cacheKey, ttl, data, (err) ->
		return reject err if err
		return resolve()
	return

acquireLock = (lockKey, ttl) -> new Promise (resolve, reject) ->
	lock lockKey, ttl, (unlock) -> resolve unlock
	return

module.exports = cache = (config, route, req, res) ->
	try
		cacheKey = convertkey route.cache.key? req
		{id} = config
		cacheKey = "microapi:#{id}:cache:data:#{cacheKey}"
		cacheKeyHeaders = "microapi:#{id}:cache:headers:#{cacheKey}"
		lockKey = "microapi:#{id}:lock:#{cacheKey}"
		#lockKey = cacheKey.replace ':cache:', ':lock:'
		shouldCache = yes
		shouldCache = route.cache.shouldCache req if route.cache.shouldCache?
		res.shouldCache = shouldCache
		cachedVal = null
		data = null
		headers = null
		unlock = null
		waitedForLock = 0

		if shouldCache
			try
				[data, headers] = await redisMget [cacheKey, cacheKeyHeaders]
				headers = try JSON.parse headers
			catch err
				req.log 'warning', {type: 'cache:error', cacheKey}
			if data
				# cached result found
				req.log 'info', {type: 'cache:hit', cacheKey}
				res.setHeader key, val for key, val of headers if headers
				res.setHeader 'X-Cached', 'true'
				return data
			# no cached result found
			# acquire lock
			if route.cache.lockttl
				startTime = Date.now()
				unlock = await acquireLock lockKey, route.cache.lockttl
				waitedForLock = Date.now() - startTime
				# lock acquired, recheck cache
				[data, headers] = await redisMget [cacheKey, cacheKeyHeaders]
				headers = try JSON.parse headers
		if data
			# cached result found
			unlock?()
			req.log 'info', {type: 'cache:hit', cacheKey, waitedForLock}
			res.setHeader key, val for key, val of headers if headers
			res.setHeader 'X-Cached', 'true'
			return data
		else
			# get fresh data
			req.log 'info', {type: 'cache:miss', cacheKey}
			try
				data = await route.handler req, res
			catch err
				unlock?()
				throw err
			if data and res.shouldCache
				# set cache
				await redisSetex cacheKey, route.cache.ttl, data
				if config.cacheHeaders
					headers = res.getHeaders()
					await redisSetex cacheKeyHeaders, route.cache.ttl, headers
			unlock?()
	catch err
		throw err
	return data
