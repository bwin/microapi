
# Microapi documentation

## route options

- auth: (token) -> token.roles.admin
- ratelimit: max: 3, time: '5s', key: (req) -> req.ip
- cache:
		ttl: '10s', key: (req) -> req.path
		shouldCache: (req) -> not req.something
		lock: '100ms'
- params:
		id: 'int'
		x: 'string'
		y: 'int?'
		z: 'int': (value) -> value > 5
		u: 'int?': (value) -> value > 5
		v: 'int': (value) -> [
			value > 5
			value isnt 42
		]
		r: 'string': /containsthis/
- validation: (params) -> params.x? or params.y?
		or
	validation: (params) -> [
		params.x + params.y isnt 35
		params.x - params.y > 10
	]
- body: bool
- stream: bool

- before: [mw1]
- after: [mw2]

## config

- poweredBy: string ('microapi (+https://github.com/bwin/microapi)')
- port: int (0)
- logLevel: string ('trace')
- usePmx: bool (no)
- enableGracefulShutdown: bool (yes)
- cacheHeaders: bool (yes)
- debugLogErrors: bool (no)
