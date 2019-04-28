
import test from 'ava';

microapi = require '../../index'
get = require '../get'
config = require '../test-config'

test 'should throw when the same endpoint is defined twice', (t) ->
	try
		server = await microapi.start config,
			'GET /test': -> x: 1
			'NAMESPACE /': routes:
				'GET /test': -> x: 2
	catch err
	t.truthy err instanceof Error

	await server?.ready
	await server?.stop()
	return

###
test 'should throw when trying to define a cache for a request that is not GET', (t) ->
	try
		server = await microapi.start config,
			'POST /test'
				cache: ttl: '1s', key: (req) -> req.path
				handler: ->
	catch err
	t.truthy err instanceof Error

	await server?.ready
	await server?.stop()
	return

test 'should throw when trying to define a cache for a request that is a stream', (t) ->
	try
		server = await microapi.start config,
			'GET /stream-and-cache':
				stream: yes
				cache: ttl: '1s', key: (req) -> req.path
				handler: ->
	catch err
	t.truthy err instanceof Error

	await server?.ready
	await server?.stop()
	return

test 'should throw when trying to define a route with an invalid method', (t) ->
	try
		server = await microapi.start config,
			'INVALID /test': ->
	catch err
	t.truthy err instanceof Error

	await server?.ready
	await server?.stop()
	return

test 'should throw when trying to define a route with invalid opts', (t) ->
	try
		server = await microapi.start config,
			'GET /options-missing': null
	catch err
	t.truthy err instanceof Error

	await server?.ready
	await server?.stop()
	return

test 'should throw when trying to define a route with an invalid handler', (t) ->
	try
		server = await microapi.start config,
			'GET /no-handler':
				params: x: 'int'
	catch err
	t.truthy err instanceof Error

	await server?.ready
	await server?.stop()
	return
###