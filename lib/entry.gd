extends PanelContainer
class_name Entry

@export var text = ""
var selected = false

@onready var label = $Item/Label
@onready var bg = get_theme_stylebox("panel").duplicate()

func _ready():
	label.text = text
	Globals.item_selected.connect(unselect)
	tree_exited.connect(func(): Globals.item_changed.emit())
	
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
	if get_meta("subgroup"):
		get_meta("subgroup").get_parent().queue_free()
	queue_free()
	Globals.item_changed.emit()
	
func save() -> Dictionary:
	var save_data = {
		"name": text,
	}
	var subgroup = get_meta("subgroup")
	if subgroup:
		save_data["tasks"] = Globals._save_nested_tasks(subgroup)
	return save_data

func _get_drag_data(at_position):
	print_debug(get_meta("subgroup"))
	return { "node": self, "id": _task_id() }
	
func _can_drop_data(at_position, data):
	if _task_id().begins_with(data["id"]):
		return false
		
	# TODO, show preview if adding as child or reorder	
	return true
	
func _drop_data(at_position, data):
	var old_parent = data["node"].get_parent()
		
	# Remove subgroup if this was the last child
	old_parent.remove_child(data["node"])
	if len(old_parent.get_children()) == 0:
		old_parent.get_parent().queue_free()
	
	add_sibling(data["node"])
	
	# if the moved entry was a group itself, reparent them too
	var sub_list = data["node"].get_meta("subgroup")
	if sub_list:
		var container = sub_list.get_parent()
		container.get_parent().remove_child(container)
		add_sibling(container)

func _task_id() -> String:
	return str(get_path()).replace("-children", "")
