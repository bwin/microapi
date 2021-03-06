
url = require 'url'

uuidv4 = require 'uuid/v4'
getStream = require 'get-stream'
formidable = require 'formidable'

addToObject = (obj, objToAdd) ->
	obj[key] = val for key, val of objToAdd
	return

parseForm = (req, opts) -> new Promise (resolve, reject) ->
	form = new formidable.IncomingForm()
	
	if typeof opts is 'object'
		form[key] = val for key, val of opts
	
	form.parse req, (err, fields, files) ->
		return reject err if err
		return resolve {fields, files}
	return

module.exports = extendReqRes = (req, res, route, log, cache, db) ->
	{pathname, query} = url.parse req.url, yes
	isGetReq = req.method is 'GET'
	body =
		if isGetReq then undefined
		else if route?.body? and route.body is no then undefined
		else if route?.form and route.form
			{fields, files} = await parseForm req, route.form
			{fields..., files}
		else await getStream req
	
	unless route?.json? and not route.json
		body = try JSON.parse body

	addToObject req, {
		id: uuidv4()
		log: (level, data) -> log level, {reqid: req.id, data...}
		cache
		db:
			queryPromise: -> db.queryPromise req, ...arguments
			dbsafe: -> db.dbsafe req, ...arguments
			escape: -> db.escape ...arguments
		#pathname
		path: pathname
		ip: req.headers['X-Forwared-For'] or res.socket.remoteAddress
		begin: Date.now()
		#params: {}
		data: {}
		query: if isGetReq then query else {}
		body: body
		sourceParams: if isGetReq then query else body
	}

	res.$$end = res.end

	#res.data = {}
	addToObject res, {
		data: {}
		__continueExecution: yes
		done: ->
			res.__continueExecution = no
			return
		end: ->
			res.__continueExecution = no
			res.$$end ...arguments
			return
	}
	return
