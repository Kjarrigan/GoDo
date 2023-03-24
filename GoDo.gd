extends Panel

@onready var input = preload("res://lib/input.tscn")

func _ready():
	Globals.root_list = $Border/List
	Globals.new_input($Border/List)
