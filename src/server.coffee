
http = require 'http'
url = require 'url'

pmx = null
uuidv4 = require 'uuid/v4'
getStream = require 'get-stream'
{defaultsDeep} = require 'lodash'

defaultConfig = require './default-config'
routeParser = require './route-parser'
router = require './router'
log = require './logger'

poweredBy = 'microapi (+https://github.com/bwin/microapi)'

module.exports = microserver =
	start: (config, routeDefinitions) ->
		config = defaultsDeep {}, config, defaultConfig

		throw new Error "no id specified in config." unless config.id

		log.disable() if config.disableLogging
		log 'info', type: 'start'

		{routes, regexRoutes} = routeParser routeDefinitions
		handleRoute = router(routes, regexRoutes, config)

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

			res.setHeader 'X-Powered-By', poweredBy unless config.disablePoweredBy

			result = null
			try
				result = await handleRoute req, res
			catch err
				res.statusCode = err.statusCode or 500
				req.log err
				result = err:
					type: err.name
					msg: err.message

			res.writeHead res.statusCode, 'Content-Type': 'application/json'
			json = result
			json = JSON.stringify json if typeof json is 'object'
			res.end json
			req.log 'info',
				type: 'response'
				statusCode: res.statusCode
				body: result
				headers: res.getHeaders()
				len: json.length
				ms: Date.now() - req.begin
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
