
{promisify} = require 'util'

ms = require 'ms'
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
	ttl = ms ttl if typeof ttl isnt 'number'
	redisClient.setex cacheKey, ttl, data, (err) ->
		return reject err if err
		return resolve()
	return

acquireLock = (lockKey, lockTimeout) -> new Promise (resolve, reject) ->
	lockTimeout = ms lockTimeout if typeof lockTimeout isnt 'number'
	lock lockKey, lockTimeout, (unlock) -> resolve unlock
	return




###
	CACHE is no normal mw (its like log)
	bec resp-cache needs to use it, it needs to be on every route

# cache normal (in-app)
await cache 'xy', ttl: '10s', -> data: '...'

# cache response
await cache 'xy', ttl: '10s',
	-> data: '...'
, -> no


###





module.exports = createCache = (id, log) ->
	cache = (key, opts, cb, shouldCache=yes) ->
		{ttl} = opts
		lockTimeout = opts.lock

		try
			keyStr = convertkey key
			cacheKey = "microapi:#{id}:cache:#{keyStr}"
			lockKey = "microapi:#{id}:lock:#{keyStr}"

			data = null
			unlock = null
			waitedForLock = 0

			startTime = Date.now()
			try
				data = await redisGet cacheKey
			catch err
				log 'warning', {type: 'cache:error', cacheKey, err}
			if data
				# cached result found
				elapsed = Date.now() - startTime
				log 'debug', {type: 'cache:hit', cacheKey, elapsed}
				return data
			# no cached result found
			# acquire lock
			if lockTimeout
				startTimeLock = Date.now()
				unlock = await acquireLock lockKey, lockTimeout
				waitedForLock = Date.now() - startTime
				# lock acquired, recheck cache
				data = await redisGet cacheKey
			if data
				# cached result found
				unlock?()
				elapsed = Date.now() - startTime
				log 'debug', {type: 'cache:hit', cacheKey, elapsed, waitedForLock}
				return data
			else
				# get fresh data
				log 'debug', {type: 'cache:miss', cacheKey}
				try
					data = cb()
				catch err
					unlock?()
					throw err

				shouldCache = shouldCache() if typeof shouldCache is 'function'
				if data and shouldCache
					# set cache
					await redisSetex cacheKey, ttl, data
				unlock?()
		catch err
			throw err
		return data

	cache.load = (key) ->
		startTime = Date.now()
		key = convertkey key
		result = await redisGet key
		elapsed = Date.now() - startTime
		log 'trace', {type: 'cache:load', key, elapsed}
		return result

	cache.loadMulti = (keys) ->
		startTime = Date.now()
		keys = keys.map (key) -> convertkey key
		results = await redisMget keys
		elapsed = Date.now() - startTime
		log 'trace', {type: 'cache:loadMulti', keys, elapsed}
		return results

	cache.save = (key, ttl, data) ->
		startTime = Date.now()
		key = convertkey key
		await redisSetex key, ttl, data
		elapsed = Date.now() - startTime
		log 'trace', {type: 'cache:save', key, ttl, elapsed}
		return

	return cache
