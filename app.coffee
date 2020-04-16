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
	serverInfo = server.address()
	if serverInfo.family is 'IPv6' then serverInfo.address = "[#{serverInfo.address}]"
	console.log "[#{process.pid}] http://#{serverInfo.address}:#{serverInfo.port}/"

process.on 'SIGINT', (signal) ->
	console.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit

process.on 'SIGTERM', (signal) ->
	console.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit

module.exports = app
