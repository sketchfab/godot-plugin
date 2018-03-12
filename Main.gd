extends Control

const CONFIG_FILE_PATH = "user://sketchfab.ini"

const Api = preload("res://Api.gd")
var api = Api.new()

onready var search_text = find_node("SearchPanel").find_node("Text")
onready var paginator = find_node("Paginator")

onready var not_logged = find_node("NotLogged")
onready var login_name = not_logged.find_node("UserName")
onready var login_password = not_logged.find_node("Password")
onready var login_button = not_logged.find_node("Login")

onready var logged = find_node("Logged")
onready var logged_name = logged.find_node("UserName")
onready var logged_plan = logged.find_node("Plan")

var cfg

func _enter_tree():
	cfg = ConfigFile.new()
	cfg.load(CONFIG_FILE_PATH)
	
func _exit_tree():
	cfg.save(CONFIG_FILE_PATH)

func _ready():
	logged.visible = false
	not_logged.visible = false
	login_name.text = cfg.get_value("api", "user", "")
	
	var token = cfg.get_value("api", "token", null)
	if token:
		api.set_token(token)
		_populate_login()
	else:
		not_logged.visible = true
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
		_populate_login()
	else:
		_logout()
		
	cfg.save(CONFIG_FILE_PATH)
		
func _populate_login():
	_set_login_disabled(true)
	var user = yield(api.get_my_info(), "completed")
	_set_login_disabled(false)
	
	if !user || typeof(user) != TYPE_DICTIONARY:
		_logout()
		return
		
	if !user.has("username"):
		_logout()
		return

	not_logged.visible = false
	logged.visible = true
	
	logged_name.text = "User: %s" % user["username"]

func _logout():
	Api.set_token(null)
	cfg.set_value("api", "token", null)
	cfg.save(CONFIG_FILE_PATH)
	not_logged.visible = true
	logged.visible = false

func _search():
	paginator.search(search_text.text)

##### Helpers

func _set_login_disabled(disabled):
	login_name.editable = !disabled
	login_password.editable = !disabled
	if disabled:
		login_button.disabled = true
	else:
		_refresh_login_button()
	
func _refresh_login_button():
	login_button.disabled = !(login_name.text.length() > 0 && login_password.text.length() > 0)
