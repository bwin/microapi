
# @bwin/microapi

[![build status](http://img.shields.io/travis/bwin/microapi/master.svg?style=flat-square)](https://travis-ci.org/bwin/microapi)
[![dependencies](http://img.shields.io/david/bwin/microapi.svg?style=flat-square)](https://david-dm.org/bwin/microapi)
[![npm version](http://img.shields.io/npm/v/microapi.svg?style=flat-square)](https://npmjs.org/package/microapi)

Small and opinionated api-server framework with few dependencies.

## Features

- routing
- caching (optional with locking)
- rate-limiting
- auth
- params
- validation
- namespaces
- supports streaming

## Opinionated how?

- auth: jwt
- request handler: promise
- caching: redis
- logger: bunyan
- process-manager: pm2
- default output: json
- expected post body format: json
- optimized to be beautiful when used with coffeescript

### only relevant for contributors and users of generator
- written in: coffeescript
- package-manager: yarn
- test-framework: ava
- test-coverage: istanbul

## Available middleware

- mysql db [@bwin/microapi-db-mysql]
- render pug templates [@bwin/microapi-render-pug]

## Getting started

- Install with `yarn add @bwin/microapi`

```coffee
microapi = require '@bwin/microapi'

config = # require './config'
	id: 'my-1st-api'
	port: process.env.PORT or 8000

routes = # require './routes'
	'GET /':
		cache: ttl: '10m', lock: '200ms', key: -> 'index'
		handler: (req, res) -> status: 'OK'

	'GET /echo':
		body: no
		stream: yes
		handler: (req, res) -> req.pipe res

	'NAMESPACE /user/:userId':
		params:
			userId: 'int'
		auth: (token) -> token.roles.admin
		routes:

			'GET /': (req, res) -> status: 'OK', userId: params.userId

			'GET /edit':
				handler: (req, res) -> status: 'OK', userId: params.userId

	'GET /*':
		type: 'text/plain'
		handler: (req, res) -> 'catchall'

microapi.start config, routes
```


### wut?
```coffee
routes = # require './routes'
	'/': GET:
		cache: ttl: '10m', lock: '200ms', key: -> 'index'
		handler: (req, res) -> status: 'OK'

	'/echo': GET:
		body: no
		stream: yes
		handler: (req, res) -> req.pipe res

	'/user/:userId':
		params:
			userId: 'int'
		auth: (token) -> token.roles.admin
		
		#'/': GET: (req, res) -> status: 'OK', userId: params.userId
		GET: (req, res) -> status: 'OK', userId: params.userId

		'/edit':
			GET: (req, res) -> status: 'OK', userId: params.userId
			POST: (req, res) -> status: 'OK', userId: params.userId

		'/test-params':
			GET:
				params: x: 'string'
				handler: (req, res) -> status: 'OK', userId: params.userId
			POST:
				params: y: 'string'
				handler: (req, res) -> status: 'OK', userId: params.userIdy

	'/*': ALL:
		type: 'text/plain'
		handler: (req, res) -> 'catchall'




# BETTER

routes = # require './routes'
	'/':
		cache: ttl: '10m', lock: '200ms', key: -> 'index'
		GET: (req, res) -> status: 'OK'

	'/echo':
		body: no
		stream: yes
		GET: (req, res) -> req.pipe res

	'/user/:userId':
		params:
			userId: 'int'
		auth: (token) -> token.roles.admin

		GET: (req, res) -> status: 'OK', userId: params.userId

		'/edit':
			GET: (req, res) -> status: 'OK', userId: params.userId
			POST: (req, res) -> status: 'OK', userId: params.userId

		'/test-params':
			params: z: 'int': (val) -> val >= 5
			GET:
				params: x: 'int?'
				handler: (req, res) -> status: 'OK', userId: params.userId
			POST:
				params: y: 'int?'
				handler: (req, res) -> status: 'OK', userId: params.userIdy

	'/*':
		type: 'text/plain'
		ALL: (req, res) -> 'catchall'



# ...
methods = ['HEAD', 'GET']

if route.startsWith '/' # or ^
	# namespace
else if route in methods
	# invalid outside of namespace
	# endpoint
	# then fn or opts
else
	# namespace opts

```
