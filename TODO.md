
# TODO


- call res.done() in middleware to signal that no further mw should be processed
  - ... while res.__continueExecution

- maybe middleware becomes before/after

- TEST NAMESPACES
- test 2 servers with same port should fail (and improve coverage)
- test params
  - bool
  - date
- test cache: load/loadMulti/save/acquireLock/cbShouldCache


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



