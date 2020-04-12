api = module.exports = {}

api.test = (ctx) ->
	@body = {err: false, msg: "API speaks!"}
