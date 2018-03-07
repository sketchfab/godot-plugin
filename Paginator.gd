extends ScrollContainer

var ResultItem = load("res://ResultItem.tscn")

var api = preload("res://Api.gd").new()

onready var grid = $VBoxContainer/ResultsGrid
onready var trailer = $VBoxContainer/Trailer

var next_page_url

func _ready():
	trailer.modulate.a = 0.0

func _exit_tree():
	api.term()
	
func search(query = ""):
	for item in grid.get_children():
		grid.remove_child(item)
	scroll_vertical = 0
		
	trailer.modulate.a = 1.0
	yield(api.cancel(), "completed")
	var result = yield(api.search_models(query), "completed")
	trailer.modulate.a = 0.0

	_process_page(result)

func _process(delta):
	if !api.busy && next_page_url && trailer.get_global_rect().intersects(get_viewport_rect()):
		# Fetch next page
		trailer.modulate.a = 1.0
		var result = yield(api.fetch_next_page(next_page_url), "completed")
		trailer.modulate.a = 0.0

		_process_page(result)

func _process_page(result):
	next_page_url = null

	# Canceled?
	if !result:
		return
		
	# Collect and check
	if typeof(result) != TYPE_DICTIONARY:
		return
	var results = _safe_get(result, "results")
	if typeof(results) != TYPE_ARRAY:
		return
		
	# Process
	for result in results:
		var item = ResultItem.instance()
		item.set_data(result)
		grid.add_child(item)

	# Set next page now we know the current one succeeded
	next_page_url = _safe_get(result, "next")

func _safe_get(result, key):
	return result[key] if result.has(key) else null
