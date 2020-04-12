process.env.NODE_ENV ?= 'development'
{version} = require './package.json';
console.log "[#{process.pid}] env: #{process.env.NODE_ENV}, version: #{version}"

Koa = require 'koa'
morgan = require 'koa-morgan'
bodyparser = require 'koa-bodyparser'
compress = require 'koa-compress'
helmet = require 'koa-helmet'
route = require 'koa-route'

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
api = require './controllers/api'
app.use route.get '/api/test', api.test

server = app.listen process.env.UNIX_SOCKET_PATH or process.env.PORT or 0, ->
	serverInfo = server.address()
	if serverInfo.family is 'IPv6' then serverInfo.address = "[#{serverInfo.address}]"
	console.log "[#{process.pid}] http://#{serverInfo.address}:#{serverInfo.port}/"

io = require('socket.io')(server)

io.on 'connection', (socket) ->
	socket.on 'broadcastMessage', (message) ->
		console.log 'broadcastMessage:', message
		io.sockets.emit 'messageReceived', message

process.on 'SIGINT', (signal) ->
	console.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit
	io.close()

process.on 'SIGTERM', (signal) ->
	console.log "[#{process.pid}] Caught signal: #{signal}; closing server connections."
	server.close process.exit
	io.close()

module.exports = app
