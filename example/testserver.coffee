
microapi = require '../src/server'

config =
	id: 'testserver'
	port: 8000
	enableGracefulShutdown: no
	disableLogging: yes

mwB1 = (req, res) ->
	#console.log "===> middleware B1"
	res.data.B1 = 123
	return
mwB2 = (req, res) ->
	#console.log "===> middleware B2"
	res.data.B2 = 456
	return
mwA1 = (req, res) ->
	#console.log "===> middleware A1"
	res.data.A1 = 789
	return
mwA2 = (req, res) ->
	#console.log "===> middleware A2"
	res.data.A2 = Date.now()
	return
mwDA = (req, res) ->
	#console.log "===> middleware DA"
	res.data.DA = Date.now()
	return

delay = (ms, cb) -> setTimeout cb, ms
wait = (ms) -> new Promise (resolve, reject) -> delay ms, resolve

microapi.start config,
	'GET /simple-params':
		params:
			#x: 'int': (value) -> value > 5
			x: 'string': /^hans$/
			y: 'int': (value) -> [
				value > 5
				value isnt 42
			]
		#validation: (params) -> [
		#	params.x + params.y isnt 35
		#	params.x - params.y > 10
		#]
		handler: (req, res) -> status: 'OKI-DOKI'

	'GET /test-mw':
		cache: ttl: '2s', lockttl: '100ms', key: (req) -> req.path
		#before: [mwB1, mwB2]
		#after: [mwA1, mwA2]
		#afterDynamic: [mwDA]
		handler: [
			(req, res) -> status: 'OKI-DOKI', x: Date.now()
			mwB1, mwB2
			mwA1, mwA2
		]

	'GET /test-wait':
		handler: (req, res, data) ->
			await wait 1000
			return status: 'OKI-DOKI-U-WAITED'

	'NAMESPACE /test':
		routes:
			'GET /test': (req, res) -> x: 'AAA'
			'GET /test2': (req, res) -> x: 'BBB'
			'GET /test3': (req, res) -> x: 'CCC'
			'GET /test4': (req, res) -> x: 'DDD'

	'GET /headers': (req, res) ->
		res.setHeader 'X-Test-Header-A', 123
		res.setHeader 'X-Test-Header-B', 987
		return somevalue: 'XY18'
	'GET /headers-reply': (req, res) -> req.headers
	
	'NAMESPACE /cached':
		cache: ttl: '5s', lockttl: '1s', key: (req) -> req.path
		routes:
			'GET /item': -> x: 'cached'
			'GET ^/root-item': -> x: 'root'

	'NAMESPACE /a':
		cache: ttl: '15s', lockttl: '1s', key: (req) -> req.path
		routes:
			'NAMESPACE /b':
				cache: ttl: '1s'
				routes:
					'GET /c': -> x: 'abc'
					'GET /:id': -> x: 'get-by-id'
					'GET /:id/comment/:commentid': -> x: 'get-by-id-with-comment'
					'GET /*/something': -> x: 'wildcard-in-middle'
					#'GET ^/*': -> x: 'root-catchall'

	'GET /*': (req, res) ->
		{method, path, url, params, ip, headers} = req
		return {method, path, url, params, ip, headers}
