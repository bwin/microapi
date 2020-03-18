
mysql = require 'mysql'

module.exports = (config) ->
	db = mysql.createPool config.mysql

	# TODO better use `mysql2` instead
	db.queryPromise = (req, query, values) -> new Promise (resolve, reject) ->
		startTime = Date.now()
		q = db.query query, values, (err, rows, fields) ->
			elapsed = Date.now() - startTime
			req.log 'debug', {
				type: 'mysql:query'
				sql: q.sql
				rows: rows.length
				elapsed
			}
			return reject err if err
			resolve rows
			return
		return

	db.dbsafe = (req, val) ->
		return db
		.escape val
		.substr 1, val.length

	return db
