
http = require 'http'
url = require 'url'

{defaultsDeep} = require 'lodash'
pmx = null

defaultConfig = require './default-config'
routeParser = require './route-parser'
createRouter = require './router'
logger = require './logger'
createCache = require './cache'
extendReqRes = require './extend-req-res'
handleRoute = require './handler'


module.exports = microserver =
	start: (config, routeDefinitions) ->
		config = defaultsDeep {}, config, defaultConfig

		throw new Error "no id specified in config." unless config.id

		log =
			if config.logLevel is 'off' then ->
			else logger config.id, config.logLevel
		log 'info', type: 'start'

		cache = createCache config.id, log

		{routes, regexRoutes} = routeParser routeDefinitions
		router = createRouter routes, regexRoutes

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
			
			# needed for routing
			{pathname} = url.parse req.url, yes
			req.pathname = pathname
			req.params = {}

			route = router req, res
			await extendReqRes req, res, route, log, cache

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

			if route?.type?
				res.setHeader 'Content-Type', route.type
			else
				res.setHeader 'Content-Type', 'application/json'
			res.setHeader 'X-Powered-By', config.poweredBy if config.poweredBy

			result = null
			try
				#result = await handleRoute req, res, config
				result = await handleRoute config, cache, route, req, res
				if route.stream is yes
					await new Promise (resolve) -> res.on 'end', resolve
					result = undefined
			catch err
				console.error err if config.debugLogErrors
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
				len: json?.length or 0
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

		server.routes = routes
		server.regexRoutes = regexRoutes

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
