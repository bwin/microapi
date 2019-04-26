
http = require 'http'
url = require 'url'

pmx = null
uuidv4 = require 'uuid/v4'
getStream = require 'get-stream'
{defaultsDeep} = require 'lodash'

defaultConfig = require './default-config'
routeParser = require './route-parser'
router = require './router'
logger = require './logger'


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

addToObject = (obj, objToAdd) ->
	obj[key] = val for key, val of objToAdd
	return

extendReqRes = (req, res, log) ->
	{pathname, query} = url.parse req.url, yes
	isGetReq = req.method is 'GET'
	body =
		if isGetReq then null
		else
			await getStream(req).then (str) -> try JSON.parse str

	addToObject req, {
		id: uuidv4()
		log: (level, data) -> log level, {reqid: req.id, data...}
		pathname
		path: pathname
		ip: req.headers['X-Forwared-For'] or res.socket.remoteAddress
		begin: Date.now()
		params: {}
		data: {}
		query: if isGetReq then query else {}
		body: body
		sourceParams: if isGetReq then query else body
		db: reqDb req
		cache: reqCache req
	}

	res.data = {}
	return

module.exports = microserver =
	start: (config, routeDefinitions) ->
		config = defaultsDeep {}, config, defaultConfig

		throw new Error "no id specified in config." unless config.id

		log =
			if config.logLevel is 'off' then ->
			else logger config.id, config.logLevel
		log 'info', type: 'start'

		{routes, regexRoutes} = routeParser routeDefinitions
		handleRoute = router routes, regexRoutes, config

		if config.usePmx
			try
				pmx = require 'pmx'
			catch err
				throw new Error "pmx not found. run `yarn add pmx`."
			pmx.init
				network: yes
				ports: yes
			probe = pmx.probe()
			reqMeterSec = probe.meter
				name: 'req/sec'
				samples: 1
			reqMeterMin = probe.meter
				name: 'req/min'
				samples: 60
			reqCounter = probe.counter
				name : 'Current req processed'
			latencyHistogram = probe.histogram
				name: 'latency'
				agg_type: 'avg'
				#measurement: 'p95'

		server = http.createServer (req, res) ->
			### istanbul ignore next ###
			if config.usePmx
				reqMeterSec.mark()
				reqMeterMin.mark()
				reqCounter.inc()
				req.on 'end', ->
					reqCounter.dec()
					latencyHistogram.update Date.now() - req.begin
					return

			###
			parsedUrl = url.parse req.url, yes
			req.id = uuidv4()
			req.pathname = req.path = parsedUrl.pathname
			req.query = parsedUrl.query
			req.ip = req.headers['X-Forwared-For'] or res.socket.remoteAddress
			req.begin = Date.now()
			if req.method isnt 'GET'
				req.body = await getStream req
				.then (str) -> try JSON.parse str
			req.sourceParams = if req.method is 'GET' then req.query else req.body
			req.params = {}
			req.data = {}
			
			res.data = {}

			req.log = (level, data) -> log level, {reqid: req.id, data...}
			###

			await extendReqRes req, res, log

			{method, path, ip, headers, query, body} = req
			req.log 'info', {
				type: 'request'
				method
				path
				ip
				headers
				query: if method is 'GET' then query
				body: if method isnt 'GET' then body
			}

			res.setHeader 'Content-Type', 'application/json'
			res.setHeader 'X-Powered-By', config.poweredBy if config.poweredBy

			result = null
			try
				result = await handleRoute req, res, config
			catch err
				res.statusCode = err.statusCode or 500
				req.log err
				result = err:
					type: err.name
					msg: err.message

			json = result
			json = JSON.stringify json if typeof json is 'object'
			res.end json

			req.log 'info',
				type: 'response'
				statusCode: res.statusCode
				route: req.routeName
				body: result
				headers: res.getHeaders()
				len: json.length
				elapsed: Date.now() - req.begin
			return

		server.ready = new Promise (resolve, reject) ->
			server.listen config.port, (err) ->
				### istanbul ignore next ###
				return reject err if err
				log 'info',
					type: 'listen'
					port: config.port
				adr = server.address()
				resolve adr.port
				return

		#server.closed = new Promise (resolve, reject) ->
		#	server.on 'closed', resolve
		#	return
		server.stop = -> new Promise (resolve, reject) -> server.close resolve

		if config.enableGracefulShutdown
			### istanbul ignore next ###
			process.on 'SIGINT', ->
				log 'info', type: 'SIGINT'
				begin = Date.now()
				server.close ->
					elapsed = Date.now() - begin
					log 'info', {type: 'shutdown', elapsed}
					process.exit 0
					return
				return

		return server
