@tool
extends ScrollContainer

const SafeData = preload("res://addons/sketchfab/SafeData.gd")
var ResultItem = load("res://addons/sketchfab/ResultItem.tscn")

var api = preload("res://addons/sketchfab/Api.gd").new()

@onready var grid = find_child("ResultsGrid")
@onready var trailer = find_child("Trailer")
@onready var label = find_child("Label")
@onready var cta_button = find_child("CTA")
@onready var search_domain = find_child("SearchDomain")

var next_page_url

func _ready():
	trailer.modulate.a = 0.0

func _exit_tree():
	api.term()

func search(query, categories, animated, staff_picked, min_face_count, max_face_count, sort_by, domain_suffix):
	for item in grid.get_children():
		grid.remove_child(item)
		item.queue_free()
	queue_sort()

	trailer.modulate.a = 1.0
	label.text = "Fetching..."
	cta_button.hide()
	await api.cancel()
	var result = await api.search_models(
		query,
		categories,
		animated,
		staff_picked,
		min_face_count,
		max_face_count,
		sort_by,
		domain_suffix
	)
	trailer.modulate.a = 0.0
	print(result.keys(), result["next"])
	var n_results = _process_page(result)

	# Upgrade to pro and empty results
	if domain_suffix == "/me":
		var user = await api.get_my_info()
		if user["account"] == "plus" || user["account"] == "basic":
			trailer.modulate.a = 1.0
			label.text = "Access your personal library of 3D models"
			cta_button.show()
			cta_button.text = "Upgrade to PRO"
		elif n_results == 0:
			trailer.modulate.a = 1.0
			label.text = "No results found"
	elif n_results == 0:
		trailer.modulate.a = 1.0
		label.text = "No results found"
		if domain_suffix == "/me/models/purchases":
			cta_button.show()
			cta_button.text = "Visit the Store"
	else:
		trailer.modulate.a = 0.0
		cta_button.hide()

func _process(delta):
	if !api.busy && next_page_url && trailer.get_global_rect().intersects(get_viewport_rect()):
		print(next_page_url)
		# Fetch next page
		trailer.modulate.a = 1.0
		label.text = "Fetching..."
		cta_button.hide()
		var result = await api.fetch_next_page(next_page_url)
		trailer.modulate.a = 0.0

		_process_page(result)

func _process_page(result_data):
	next_page_url = null

	# Canceled?
	if !result_data:
		return

	# Collect and check
	if typeof(result_data) != TYPE_DICTIONARY:
		return

	# Process
	var results = SafeData.array(result_data, "results")
	for result in results:
		var item = ResultItem.instantiate()
		item.set_data(result)
		grid.add_child(item)

	# Set next page now we know the current one succeeded
	next_page_url = SafeData.string(result_data, "next")

	return results.size()
