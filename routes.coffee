module.exports = routes = []
route = require 'koa-route'

routes.push route.get '/api/test', (ctx) ->
	@body =
		msg: "API speaks!"
