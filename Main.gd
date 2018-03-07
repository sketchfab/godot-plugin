extends Control

onready var search_text = $VBoxContainer/PanelContainer/HBoxContainer/SearchText
onready var paginator = $VBoxContainer/Paginator

func _ready():
	_search()

##### UI

func _on_SearchButton_pressed():
	_search()

func _on_SearchText_text_entered(new_text):
	_search()

##### Actions

func _search():
	paginator.search(search_text.text)
