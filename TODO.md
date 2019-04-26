
# TODO

- TEST NAMESPACES
- test 2 servers with same port should fail (and improve coverage)
- lookat npm/deep-metrics
- test params
  - bool
  - date
- test ratelimiter with obj-key

- differentiate between
  - cache (handles prefixing, locking, etc)
  - routeCache (uses cache, sets headers)
- give cache to route-handlers, so they may easily cache (and optional use locking) partial data

- maybe route-handlers: (req, res, app) ?

- X paramtype: date (moment)
- X paramtype: bool
- X paramtype: object
- X paramtype: array
- paramtype: email
- paramtype: url
- paramtype: url:(absolute|relative|local|remote|file|http|https|ws)?
- paramtype: url:(_absolute|_relative|_local|_remote|*)?

- support html responses?
  - support pug templates?

- server.ready (port, routes)

- how to use socketio? (maybe also return server from .ready?)



