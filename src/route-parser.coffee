
ms = require 'ms'
escapeRegex = require 'escape-string-regexp'
_ = require 'lodash'
{defaultsDeep} = _

validMethods = 'HEAD GET POST PUT DELETE'.split ' '
validTypes = 'int string date'.split ' '

isArrayEqual = (a, b) ->
	a = [a] unless Array.isArray a
	b = [b] unless Array.isArray b
	return no unless a.length is b.length
	#return _.isEqual _.sortBy(a), _.sortBy(b)
	return _.isEqual a, b # in our case they are already in the same order

module.exports = routeParser = (routeDefinitions, namespaceOpts={}) ->
	routes = {}
	regexRoutes = {}

	for key, routeOpts of routeDefinitions
		if typeof routeOpts is 'function' or Array.isArray routeOpts
			handler = routeOpts
			routeOpts = {handler}
		else if typeof routeOpts isnt 'object'
			throw new Error "opts should either be 'object', 'array' or 'function'"
		opts = defaultsDeep {}, routeOpts, namespaceOpts

		[method, path] = key.split ' '
		method = method?.toUpperCase()
		opts.name = path

		if path.startsWith '^'
			path = path.substr 1
		else
			path = namespaceOpts.path + path if namespaceOpts.path
			path = path.replace /\/+/, '/' # replace multiple /'s

		# non-GET routes can inherit cache opts
		# remove them, otherwise we throw an error because its not allowed
		delete opts.cache if method isnt 'GET' and namespaceOpts.cache?

		if method is 'NAMESPACE'
			delete opts.routes

			opts.path = path
			
			# namespace middleware handling
			if namespaceOpts.middleware? and opts.middleware?
				unless isArrayEqual namespaceOpts.middleware, opts.middleware
					opts.middleware = [].concat namespaceOpts.middleware, opts.middleware

			newRoutes = routeParser routeOpts.routes, opts
			routes = defaultsDeep {}, routes, newRoutes.routes
			regexRoutes = defaultsDeep {}, regexRoutes, newRoutes.regexRoutes
		else # endpoint
			throw new Error "invalid method '#{method}" unless method in validMethods

			delete opts.middleware

			# namespace middleware handling
			if namespaceOpts.middleware?
				opts.handler = [].concat namespaceOpts.middleware, opts.handler

			# endpoint middleware handling
			if Array.isArray opts.handler
				arr = opts.handler
				opts.handler = do (arr) -> (req, res) ->
					for fn in arr
						data = await fn req, res
						res.data = data if data
					return res.data

			unless typeof opts.handler is 'function'
				throw new Error "#{method} #{path} no handler defined"

			if path.includes(':') or path.includes('*') # regex route
				regexRoutes[method] ?= []
				regexRoutes[method].push opts
				opts.pathparams = pathparams = []
				reParam = /\:([\w\d]+)/g
				pathparams.push match[1] while match = reParam.exec path
				staticpath = escapeRegex path
				regex = staticpath
				regex = regex.replace reParam, '([\\w\\d\\-_:]+)'
				regex = regex.replace '\\*', '.*?'
				regex = "^#{regex}$"
				opts.regex = new RegExp regex
			else
				routes[path] ?= {}
				if routes[path][method]
					throw new Error "#{method} #{path} already has a handler"
				routes[path][method] = opts

			opts.ratelimit.time = ms opts.ratelimit.time if opts.ratelimit?

			if opts.cache?
				if method isnt 'GET'
					throw new Error "cache: cannot use cache for #{method} requests at #{path}"
				opts.cache.ttl = ms opts.cache.ttl
				opts.cache.lockttl = ms opts.cache.lockttl

			for key, param of opts.params
				defaults =
					required: yes
					type: 'string'
				if key.endsWith '?'
					defaults.required = no
					key = key.slice 0, -1

				param = switch typeof param
					when 'string' then param = type: param
					when 'object'
						type = Object.keys(param)?[0]
						unless type in validTypes
							throw new Error "invalid type '#{type}' for param #{key}"

						check = param[type]
						if typeof check is 'function'
							check: check
						else if check instanceof RegExp
							regex: check
						else if typeof check is 'object'
							check.type = type
							check
						else
							throw new Error "invalid check for param #{key}"
					else
						throw new Error "definition for param #{key} isnt string or object"

				if param.check instanceof RegExp
					param.regex = param.check
					delete param.check
				param = defaultsDeep {}, param, defaults
				opts.params[key] = param

	return {routes, regexRoutes}
