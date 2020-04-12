process.env.NODE_ENV ?= 'development'
debug = process.env.NODE_ENV isnt 'production'

express = require 'express'
morgan = require 'morgan'

version = "unknown"
gitsha = require 'gitsha'
gitsha __dirname, (error, output) ->
	if error then return console.error output
	version = output
	console.log "[#{process.pid}] env: #{process.env.NODE_ENV}, version: #{output}"

app = express()

app.use morgan(if debug then 'dev' else 'short')

# app.set 'trust proxy', 'loopback'
app.locals.pretty = debug

app.get '/api/test', (req, res) ->
	res.json {err: false, msg: "API speaks!"}

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
