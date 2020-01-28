
# TODO



- maybe:
	private: yes on route
	and block all traffic not from 127.0.0.1 with UNAUTHORIZED?


- call res.done() in middleware to signal that no further mw should be processed
  - ... while res.__continueExecution


- traditional mw to ma-mw:
  mw = (req, res) -> new Promise (resolve) -> oldmw req, res, resolve
  NOOOO, some will never resolve!


- maybe middleware becomes before/after

- TEST NAMESPACE inheritance
- test 2 servers with same port should fail (and improve coverage)
- test params
  - bool
  - date
- test cache: load/loadMulti/save/acquireLock/cbShouldCache
- form-opts
- ratelimit headers

- expose jwt/auth to req/res

- middleware:
  - microapi-db-mysql
  - microapi-render-pug
  - microapi-formdata
  - microapi-upload


- but wut about file uploads? (middleware?)

- paramtype: email
- paramtype: url
- paramtype: url:(absolute|relative|local|remote|file|http|https|ws)?
- paramtype: url:(_absolute|_relative|_local|_remote|*)?

- server.ready (port, routes)
- lookat npm/deep-metrics

- how to use socketio?





###

tmpDelay = (ms, cb) -> setTimeout cb, ms
tmpWait = (ms) -> new Promise (resolve, reject) -> tmpDelay ms, resolve
fakeWait = -> tmpWait Math.floor Math.random() * 250


reqDb = (req) ->
	query: (sql, params) ->
		startTime = Date.now()
		await fakeWait()
		elapsed = Date.now() - startTime
		req.log 'trace', {type: 'db:query', sql, elapsed}
		return
	transaction: (cb) ->
		startTime = Date.now()
		req.log 'trace', {type: 'db:transaction:begin'}
		try
			await cb req.db
			elapsed = Date.now() - startTime
			req.log 'trace', {type: 'db:transaction:end', elapsed}
		catch err
			elapsed = Date.now() - startTime
			req.log 'trace', {type: 'db:transaction:rollback:begin', elapsed}
			startTimeRollback = Date.now()
			await fakeWait()
			elapsed = Date.now() - startTimeRollback
			req.log 'trace', {type: 'db:transaction:rollback:end', elapsed}
		return

reqCache = (req) ->
	load: (key) ->
		startTime = Date.now()
		await fakeWait()
		elapsed = Date.now() - startTime
		req.log 'trace', {type: 'cache:load', key, elapsed}
		return
	save: (key, val, ttl) ->
		startTime = Date.now()
		await fakeWait()
		elapsed = Date.now() - startTime
		req.log 'trace', {type: 'cache:save', key, ttl, elapsed}
		return
###

