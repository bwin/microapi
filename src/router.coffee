
handleRoute = require './handler'

module.exports = router = (routes, regexRoutes, config) -> (req, res) ->
	{pathname, method} = req
	route = routes[pathname]?[method]
	route or= do ->
		return null unless regexRoutes[method]
		for route in regexRoutes[method]
			if route.regex.test pathname
				matches = route.regex.exec pathname
				for pathparam, idx in route.pathparams
					req.params[pathparam] = matches[idx + 1]
				return route
		return null
	req.routeName = route?.name
	return handleRoute config, route, req, res
