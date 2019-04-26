
# Microapi documentation

## currently NOT SUPPORTED

- respond with anything else than json
- anything else than json in req.body
- streaming of body

## route options

- auth: (token) -> token.roles.admin
- ratelimit: max: 3, time: '5s', key: (req) -> req.ip
- cache:
		ttl: '5s', key: (req) -> req.path
		shouldCache: (req) -> not req.something
		lockttl: '1s'
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
- before: [mw1]
- after: [mw2]
- afterDynamic: [mw3] # gets run even if result is cached

## config

- port: int (0)
- disableLogging: bool (no)
- usePmx: bool (no)
- enableGracefulShutdown: bool (yes)
- disablePoweredBy: bool (no)
