
jwt = require 'jsonwebtoken'
createError = require 'http-errors'

jwtSecret = 'TODO:REPLACEME'

jwtVerify = (req) -> new Promise (resolve, reject) ->
	encodedToken = req.headers.authorization?.replace 'Bearer ', ''
	jwt.verify encodedToken, jwtSecret, (err, token) ->
		return reject err if err
		req.token = token
		return resolve token
	return

module.exports = auth = (route, req, res) ->
	try
		token = await jwtVerify req
		unless route.auth token
			#res.statusCode = 403
			throw new createError.Forbidden()
	catch err
		#res.statusCode = 401
		throw new createError.Unauthorized()
	return
