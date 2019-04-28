
# TODO


- call res.done() in middleware to signal that no further mw should be processed
  - ... while res.__continueExecution


- traditional mw to ma-mw:
  mw = (req, res) -> new Promise (resolve) -> oldmw req, res, resolve


- maybe middleware becomes before/after

- TEST NAMESPACES
- test 2 servers with same port should fail (and improve coverage)
- test params
  - bool
  - date
- test cache: load/loadMulti/save/acquireLock/cbShouldCache

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



