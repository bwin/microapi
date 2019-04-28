
import test from 'ava'
import ms from 'ms'

microapi = require '../../index'
config = require '../test-config'
get = require '../get'

server = null

test.before (t) ->
	server = microapi.start config,
		'GET /restricted':
			auth: (token) -> token.userId
			handler: (req, res) -> status: 'OK'

		'GET /admin':
			auth: (token) -> 'admin' in token.roles
			handler: (req, res) -> status: 'OK'

	port = await server.ready
	get.baseUrl = "http://127.0.0.1:#{port}"
	return

test.after (t) -> await server?.stop()



invalidJwt = 'xxx'

# userId: 1234
validJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyMzR9.YDogdI-UqRfThM2yWHJbpqL6Ellp2wQkV1xuqUnhDBw'

# exp: 1516239022, userId: 1234
expiredJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyMzQsImV4cCI6MTUxNjIzOTAyMn0.SZiWjSTrRyjd3dMtC7qiQN6jmM57skJoPrLspJbw9a4'

# alg: none!!! (userId: 1234)
unsafeJwt = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0=.eyJ1c2VySWQiOjEyMzR9.'

# userId: 1234
# roles: ["admin"]
adminJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyMzQsInJvbGVzIjpbImFkbWluIl19.N5NgxtL_4MI82K8U9xes6C5hzwericTEVBtxM9t7MAc'

test "should reject without jwt", (t) ->
	response = await get '/restricted'
	t.is response.statusCode, 401
	return

test "should reject jwt with alg 'none'", (t) ->
	response = await get '/restricted', null,
		authorization: "Bearer #{unsafeJwt}"
	t.is response.statusCode, 401
	return

test "should reject an expired jwt", (t) ->
	response = await get '/restricted', null,
		authorization: "Bearer #{expiredJwt}"
	t.is response.statusCode, 401
	return

test "should reject with invalid jwt", (t) ->
	response = await get '/restricted', null,
		authorization: "Bearer #{invalidJwt}"
	t.is response.statusCode, 401
	return

test "should pass with valid jwt", (t) ->
	response = await get '/restricted', null,
		authorization: "Bearer #{validJwt}"
	t.is response.statusCode, 200
	return

test "should reject without required role", (t) ->
	response = await get '/admin', null,
		authorization: "Bearer #{validJwt}"
	t.is response.statusCode, 401
	return

test "should pass with required role", (t) ->
	response = await get '/admin', null,
		authorization: "Bearer #{adminJwt}"
	t.is response.statusCode, 200
	return
