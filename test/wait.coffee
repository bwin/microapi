
ms = require 'ms'

delay = (t, cb) -> setTimeout cb, ms t

module.exports = wait = (ms) -> new Promise (resolve, reject) -> delay ms, resolve
