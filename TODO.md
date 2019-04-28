
# TODO


- call res.done() in middleware to signal that no further mw should be processed
  - ... while res.__continueExecution

- lockTtl becomes lockTimeout or just lock ??
- differentiate between
  - cache (handles prefixing, locking, etc)
  - routeCache (uses cache, sets headers)
- give cache to route-handlers, so they may easily cache
  (and optional use locking on) partial data [optCbUseCache]

- maybe middleware becomes before/after

- TEST NAMESPACES
- test 2 servers with same port should fail (and improve coverage)
- test params
  - bool
  - date
- test more jwt (expired, invalid, alg:none)
- test middleware
- test cache
- test cache headers


- middleware:
  - microapi-db-mysql
  - microapi-render-pug

- 'GET /stream':
    stream: yes
    handler: (req, res) ->
  - also test this
  - forbid with cache (xor)
  - or body: no ?


- but wut about file uploads?


- X paramtype: date (moment)
- X paramtype: bool
- X paramtype: object
- X paramtype: array
- paramtype: email
- paramtype: url
- paramtype: url:(absolute|relative|local|remote|file|http|https|ws)?
- paramtype: url:(_absolute|_relative|_local|_remote|*)?

- server.ready (port, routes)
- lookat npm/deep-metrics

- how to use socketio? (maybe also return server from .ready?)



