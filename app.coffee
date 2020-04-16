process.env.NODE_ENV ?= 'development'
{version} = require './package.json';
console.log "[#{process.pid}] env: #{process.env.NODE_ENV}, version: #{version}"

Koa = require 'koa'
morgan = require 'koa-morgan'
bodyparser = require 'koa-bodyparser'
compress = require 'koa-compress'
helmet = require 'koa-helmet'

app = new Koa()

# koa options
## trust proxy header fields
app.proxy = true

# koa middleware
app.use morgan(if app.env is 'production' then 'combined' else 'tiny')
app.use helmet()
app.use compress()
app.use bodyparser()

# koa application
routes = require './routes'
for route in routes
	app.use route

server = app.listen process.env.UNIX_SOCKET_PATH or process.env.PORT or 0, ->
	server.timeout = 10000
	serverInfo = server.address()
	if typeof serverInfo is 'string'
		address = "unix: #{serverInfo}"
	else if serverInfo.family is 'IPv6'
		address = "http://[#{serverInfo.address}]:#{serverInfo.port}/"
	else
		address = "http://#{serverInfo.address}:#{serverInfo.port}/"
	console.log "[#{process.pid}] #{address}"

process.on 'SIGINT', (signal) ->
	console.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit

process.on 'SIGTERM', (signal) ->
	console.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit

module.exports = app
