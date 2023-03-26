extends PanelContainer
class_name Entry

@export var text = ""
var selected = false

@onready var bg = get_theme_stylebox("panel").duplicate()

func _ready():
	$Edit.hide()
	%Toggle.text = ""
	%Label.text = text
	Globals.item_selected.connect(unselect)
	Globals.item_changed.connect(_cleanup)
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
		"collapsed": %Toggle.text == "+"
	}
	var subgroup = get_meta("subgroup")
	if subgroup:
		save_data["tasks"] = Globals._save_nested_tasks(subgroup)
	return save_data

func _get_drag_data(_at_position):
	print_debug(get_meta("subgroup"))
	return { "node": self, "id": _task_id() }
	
func _can_drop_data(_at_position, data):
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
	
	
	# at_position is relative to the target node. If you drag to the left of the
	# the node it's added on the same level, else as child
	if at_position.x < 50:
		add_sibling(data["node"])
	else:
		# if the element has no subgroup, create it. Append it then
		if not get_meta("subgroup"):
			Globals.add_nested_list(self)
		get_meta("subgroup").add_child(data["node"])
	
	# if the moved entry was a group itself, reparent them too
	var sub_list = data["node"].get_meta("subgroup")
	if sub_list:
		var container = sub_list.get_parent()
		container.get_parent().remove_child(container)
		data["node"].add_sibling(container)

func _task_id() -> String:
	return str(get_path()).replace("-children", "")
	
func rename():
	%Edit.text = text
	%Edit.show()
	%Edit.grab_focus()

func _on_edit_text_submitted(new_text):
	if new_text == "":
		%Edit.hide()
		return
		
	text = new_text
	%Label.text = new_text
	%Edit.hide()

func add_subtask_container() -> VBoxContainer:
	if get_meta("subgroup"):
		return get_meta("subgroup")

	var group = MarginContainer.new()
	group.add_theme_constant_override("margin_left", Globals.INDENT)
	group.name = name + "-children"
	var sub_list = VBoxContainer.new()
	group.add_child(sub_list)
	set_meta("subgroup", sub_list)
	add_sibling(group)
	%Toggle.text = "-"
	
	return sub_list

func toggle_children_visibility():
	if %Toggle.text == "-":
		%Toggle.text = "+"
		get_meta("subgroup").get_parent().hide()
	else: 
		%Toggle.text = "-"
		get_meta("subgroup").get_parent().show()

func _cleanup():
	# last child was deleted, so remove the whole group
	# Currently can't deep "cleanup" since due to nesting the list
	# contains some nodes that are already marked for deletion:
	# https://github.com/godotengine/godot/issues/62790	
	return
	
	if get_meta("subgroup"):		
		if len(get_meta("subgroup").get_children()) == 0:
			get_meta("subgroup").get_parent().queue_free()
			%Toggle.text = ""
