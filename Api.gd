extends Object

const HOSTNAME = "api.sketchfab.com"
const USE_SSL = true
const BASE_PATH = "/v3"

const Requestor = preload("res://Requestor.gd")
var Result = Requestor.Result

var requestor = Requestor.new(HOSTNAME, USE_SSL)
var busy = false

func term():
	requestor.term()
	
func cancel():
	yield(requestor.cancel(), "completed")
	
func search_models(q):
	var query = {}

	busy = true
	if q.empty():
		requestor.request("%s/models" % BASE_PATH, query)
	else:
		query.q = q
		requestor.request("%s/search?type=models" % BASE_PATH, query)

	var result = yield(requestor, "completed")
	busy = false

	return _handle_result(result)
	
func fetch_next_page(url):
	# Strip protocol + domain
	var uri = url.right(url.find(HOSTNAME) + HOSTNAME.length())
	
	busy = true
	requestor.request(uri)

	var result = yield(requestor, "completed")
	busy = false

	return _handle_result(result)
	
func _handle_result(result):
	# Request canceled
	if !result:
		return null
		
	# General connectivity error
	if !result.ok:
		OS.alert('Network operation failed. Try again later.', 'Error')
		return null

	# HTTP error		
	if result.code / 100 != 2:
		OS.alert('API-level error.', 'Error')
		return null

	return result.data
