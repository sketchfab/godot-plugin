extends Control

const CONFIG_FILE_PATH = "user://sketchfab.ini"

const FACE_COUNT_OPTIONS = [
	# Label, face_count, max_face_count
	["Any", null, null],
	["Up to 10k", null, 10000],
	["10k to 50k", 10000, 50000],
	["50k to 100k", 50000, 100000],
	["100k to 250k", 100000, 250000],
	["More than 250k", 250000, null],
]

const SORT_BY_OPTIONS = [
	["Relevance", null],
	["Recent", "-publishedAt"],
	["Likes", "-likeCount"],
	["Views", "-viewCount"],
]
const SORT_BY_DEFAULT_INDEX = 1

const SafeData = preload("res://SafeData.gd")
const Api = preload("res://Api.gd")
var api = Api.new()

onready var search_text = find_node("Search").find_node("Text")
onready var search_category = find_node("Search").find_node("Categories")
onready var search_animated = find_node("Search").find_node("Animated")
onready var search_staff_picked = find_node("Search").find_node("StaffPicked")
onready var search_face_count = find_node("Search").find_node("FaceCount")
onready var search_sort_by = find_node("Search").find_node("SortBy")

onready var paginator = find_node("Paginator")

onready var not_logged = find_node("NotLogged")
onready var login_name = not_logged.find_node("UserName")
onready var login_password = not_logged.find_node("Password")
onready var login_button = not_logged.find_node("Login")

onready var logged = find_node("Logged")
onready var logged_name = logged.find_node("UserName")
onready var logged_plan = logged.find_node("Plan")

var cfg
var can_search

func _enter_tree():
	cfg = ConfigFile.new()
	cfg.load(CONFIG_FILE_PATH)

func _exit_tree():
	cfg.save(CONFIG_FILE_PATH)

func _ready():
	can_search = false
	
	search_category.get_popup().add_check_item("All")
	search_category.get_popup().connect("index_pressed", self, "_on_Categories_index_pressed")

	for item in FACE_COUNT_OPTIONS:
		search_face_count.get_popup().add_item(item[0])
	_commit_face_count(0)
	search_face_count.get_popup().connect("index_pressed", self, "_on_FaceCount_index_pressed")

	for item in SORT_BY_OPTIONS:
		search_sort_by.get_popup().add_item(item[0])
	_commit_sort_by(SORT_BY_DEFAULT_INDEX)
	search_sort_by.get_popup().connect("index_pressed", self, "_on_SortBy_index_pressed")

	logged.visible = false
	not_logged.visible = false
	login_name.text = cfg.get_value("api", "user", "")
	
	if cfg.has_section_key("api", "token"):
		api.set_token(cfg.get_value("api", "token"))
		yield(_populate_login(), "completed")
	else:
		not_logged.visible = true
		
	yield(_load_categories(), "completed")
	_commit_category(0)
		
	can_search = true
	_search()

##### UI

func _on_any_login_text_changed(new_text):
	_refresh_login_button()

func _on_UserName_text_entered(new_text):
	login_password.grab_focus()

func _on_Password_text_entered(new_text):
	_login()

func _on_Login_pressed():
	_login()

func _on_Logout_pressed():
	_logout()

func _on_any_search_trigger_changed():
	_search()

func _on_Categories_index_pressed(index):
	_commit_category(index)
	_search()

func _on_FaceCount_index_pressed(index):
	_commit_face_count(index)
	_search()

func _on_SortBy_index_pressed(index):
	_commit_sort_by(index)
	_search()

func _on_SearchButton_pressed():
	_search()

func _on_SearchText_text_entered(new_text):
	_search()

##### Actions

func _login():
	if api.busy:
		return

	cfg.set_value("api", "user", login_name.text)

	_set_login_disabled(true)
	var token = yield(api.login(login_name.text, login_password.text), "completed")
	_set_login_disabled(false)

	if token:
		cfg.set_value("api", "token", token)
		cfg.save(CONFIG_FILE_PATH)
		yield(_populate_login(), "completed")
	else:
		OS.alert('Please check username and password and try again.', 'Cannot login')
		_logout()

	cfg.save(CONFIG_FILE_PATH)

func _populate_login():
	_set_login_disabled(true)
	var user = yield(api.get_my_info(), "completed")
	_set_login_disabled(false)

	if !user || typeof(user) != TYPE_DICTIONARY:
		_logout()
		return

	if !user.has("username") || !user.has("account"):
		_logout()
		return

	not_logged.visible = false
	logged.visible = true

	logged_name.text = "User: %s" % user["username"]

	var plan_name
	if user["account"] == "pro":
		plan_name = "PRO"
	elif user["account"] == "prem":
		plan_name = "PREMIUM"
	elif user["account"] == "biz":
		plan_name = "BUSINESS"
	elif user["account"] == "ent":
		plan_name = "ENTERPRISE"
	else:
		plan_name = "BASIC";

	logged_plan.text = "Plan: %s" % plan_name

func _logout():
	Api.set_token(null)
	cfg.set_value("api", "token", null)
	cfg.save(CONFIG_FILE_PATH)
	not_logged.visible = true
	logged.visible = false

func _load_categories():
	var result = yield(api.get_categories(), "completed")
	if typeof(result) != TYPE_DICTIONARY:
		return

	var categories = SafeData.array(result, "results")
	var i = 0
	for category in categories:
		search_category.get_popup().add_check_item(SafeData.string(category, "name"))
		search_category.get_popup().set_item_metadata(i + 1, SafeData.string(category, "slug"))
		i += 1

func _search():
	if !can_search:
		return

	paginator.search(
		search_text.text,
		search_category.get_meta("__slug"),
		search_animated.pressed,
		search_staff_picked.pressed,
		search_face_count.get_meta("__data")[1],
		search_face_count.get_meta("__data")[2],
		search_sort_by.get_meta("__key")
	)

##### Helpers

func _commit_category(index):
	var popup = search_category.get_popup()
	for i in range(popup.get_item_count()):
		var checked = i == index
		popup.set_item_checked(i, checked)

	search_category.text = popup.get_item_text(index)
	search_category.set_meta("__slug", popup.get_item_metadata(index))

func _commit_face_count(index):
	search_face_count.text = FACE_COUNT_OPTIONS[index][0]
	search_face_count.set_meta("__data", FACE_COUNT_OPTIONS[index])

func _commit_sort_by(index):
	search_sort_by.text = SORT_BY_OPTIONS[index][0]
	search_sort_by.set_meta("__key", SORT_BY_OPTIONS[index][1])

func _set_login_disabled(disabled):
	login_name.editable = !disabled
	login_password.editable = !disabled
	if disabled:
		login_button.disabled = true
	else:
		_refresh_login_button()

func _refresh_login_button():
	login_button.disabled = !(login_name.text.length() > 0 && login_password.text.length() > 0)
