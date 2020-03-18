
microapi = require '../src/server'

config =
	id: 'testserver'
	port: 8000
	enableGracefulShutdown: no
	poweredBy: 'microapi/testserver'
	#logLevel: 'off'

mwB1 = (req, res) ->
	res.data.B1 = 123
	return
mwB2 = (req, res) ->
	res.data.B2 = 456
	return
mwA1 = (req, res) ->
	res.data.A1 = 789
	return
mwA2 = (req, res) ->
	res.data.A2 = Date.now()
	return
mwDA = (req, res) ->
	res.data.DA = Date.now()
	return

delay = (ms, cb) -> setTimeout cb, ms
wait = (ms) -> new Promise (resolve, reject) -> delay ms, resolve

render = (req, res, templateName) ->
	res.setHeader 'Content-Type', 'text/html'
	exampleTemplate = (req, params, data) -> "<button>#{params.x}</button>"
	html = exampleTemplate req, req.params, req.data
	return html

mwRender = (req, res) ->
	#req.log 'warn', type: 'mwRender'
	res.render = (templateName) -> render req, res, templateName
	return

microapi.start config,
	'GET /html': (req, res) ->
		res.setHeader 'content-type', 'text/html'
		return "<button>im a button</button>"

	'NAMESPACE /':
		middleware: mwRender
		routes:
			'GET /html2':
				params: x: 'string'
				handler: (req, res) -> res.render 'views/button'

			'NAMESPACE /':
				routes:
					'NAMESPACE /':
						middleware: (req, res) ->
							#req.log 'warn', type: 'mwRender2'
							res.render2 = res.render
							return
						routes:
							'NAMESPACE /':
								routes:
									'GET /html3':
										params: x: 'string'
										handler: (req, res) -> res.render2 'views/button'

	'GET /exceptional': -> throw new Error 'OOOOOOps'

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
			(req, res) ->
				#await req.db.query "SELECT * FROM games"
				#await req.db.transaction (db) ->
				#	await db.query "SELECT * FROM items"
				#	await db.query "SELECT * FROM subitems"
				#	return
				#await req.cache.load "cachedVal"
				#await req.cache.save "cachedVal", "someVal", "10s"
				return x: 'OKOK'
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
		# {method, path, url, params, ip, headers} = req
		# return {method, path, url, params, ip, headers}
		x: 'catchall'

	'SOCKETIO /socket.io': (socket) ->
		socket.on 'disconnect', ->
		socket.on 'chatmsg', (msg) ->
