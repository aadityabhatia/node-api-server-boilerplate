cluster = require 'cluster'

if not cluster.isMaster then return require './app'

console.log "[#{process.pid}] Starting cluster master: "

numCPUs = require('os').cpus().length
forkCount = 0
forkTokenCount = numCPUs
setInterval (-> forkTokenCount++ unless forkTokenCount >= numCPUs * 2), 1200000

cluster.fork() for i in [0..numCPUs]

cluster.on 'fork', -> forkCount++

cluster.on 'exit', (worker, code, signal) ->
	forkCount--
	if worker.exitedAfterDisconnect
		console.log "Worker disconnected: pid: #{worker.process.pid}, code #{code}, signal #{signal}"
	else
		console.log "Worker died: pid: #{worker.process.pid}, code #{code}, signal #{signal}"
		if forkTokenCount > 0
			forkTokenCount--
			console.log "Forking again. Tokens left: #{forkTokenCount}"
			setTimeout (-> cluster.fork()), 1000
		else
			console.log "Too many crashes. Giving up."
			console.log "Forks left: #{forkCount}"
			if not forkCount then process.exit(2)
