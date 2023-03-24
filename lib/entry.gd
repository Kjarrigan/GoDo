extends PanelContainer
class_name Entry

const INDENT_WIDTH = 25
@export var text = ""
var selected = false

@onready var label = $Item/Label
@onready var bg = get_theme_stylebox("panel").duplicate()

func _ready():
	label.text = text
	Globals.item_selected.connect(unselect)
	
func _on_mouse_entered():
	if selected:
		return
		
	_set_bg_alpha(0.5)

func _on_gui_input(event : InputEvent):
	if event.is_action_pressed("select"):
		select()

func select():
	Globals.item_selected.emit(self)
	selected = true
	_set_bg_alpha(8.0)

func unselect(_item):
	selected = false
	_set_bg_alpha(0.0)

func _on_mouse_exited():
	if selected:
		return
		
	unselect(null)
	
func _set_bg_alpha(value : float):
	bg.bg_color.a = value
	add_theme_stylebox_override("panel", bg)
	
func _on_finish_pressed():
	queue_free()

func save() -> Dictionary:
	var save_data = {
		"name": text,
	}
	var subgroup = get_meta("subgroup")
	if subgroup:
		save_data["tasks"] = Globals._save_nested_tasks(subgroup)
	return save_data
