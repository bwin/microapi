
# @bwin/microapi

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
- formdata handling [@bwin/microapi-formdata]
- file uploads [@bwin/microapi-upload]

## Getting started

- Install with `yarn add @bwin/microapi`

```coffee
microapi = require '@bwin/microapi'

config =
	id: 'my-1st-api'
	port: process.env.PORT or 8000

microapi.start config,
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
```
