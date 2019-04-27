
url = require 'url'

uuidv4 = require 'uuid/v4'
getStream = require 'get-stream'

addToObject = (obj, objToAdd) ->
	obj[key] = val for key, val of objToAdd
	return

module.exports = extendReqRes = (req, res, log, cache) ->
	{pathname, query} = url.parse req.url, yes
	isGetReq = req.method is 'GET'
	body =
		if isGetReq then null
		else
			await getStream(req).then (str) -> try JSON.parse str

	addToObject req, {
		id: uuidv4()
		log: (level, data) -> log level, {reqid: req.id, data...}
		cache
		pathname
		path: pathname
		ip: req.headers['X-Forwared-For'] or res.socket.remoteAddress
		begin: Date.now()
		params: {}
		data: {}
		query: if isGetReq then query else {}
		body: body
		sourceParams: if isGetReq then query else body
	}

	#res.data = {}
	addToObject res, {
		data: {}
		__continueExecution: yes
		done: ->
			res.__continueExecution = no
			return
	}
	return


###

tmpDelay = (ms, cb) -> setTimeout cb, ms
tmpWait = (ms) -> new Promise (resolve, reject) -> tmpDelay ms, resolve
fakeWait = -> tmpWait Math.floor Math.random() * 250


reqDb = (req) ->
	query: (sql, params) ->
		startTime = Date.now()
		await fakeWait()
		elapsed = Date.now() - startTime
		req.log 'trace', {type: 'db:query', sql, elapsed}
		return
	transaction: (cb) ->
		startTime = Date.now()
		req.log 'trace', {type: 'db:transaction:begin'}
		try
			await cb req.db
			elapsed = Date.now() - startTime
			req.log 'trace', {type: 'db:transaction:end', elapsed}
		catch err
			elapsed = Date.now() - startTime
			req.log 'trace', {type: 'db:transaction:rollback:begin', elapsed}
			startTimeRollback = Date.now()
			await fakeWait()
			elapsed = Date.now() - startTimeRollback
			req.log 'trace', {type: 'db:transaction:rollback:end', elapsed}
		return

reqCache = (req) ->
	load: (key) ->
		startTime = Date.now()
		await fakeWait()
		elapsed = Date.now() - startTime
		req.log 'trace', {type: 'cache:load', key, elapsed}
		return
	save: (key, val, ttl) ->
		startTime = Date.now()
		await fakeWait()
		elapsed = Date.now() - startTime
		req.log 'trace', {type: 'cache:save', key, ttl, elapsed}
		return
###
