extends PanelContainer
class_name Entry

@export var text = ""
@export var label_id = 0
var selected = false

@onready var bg = get_theme_stylebox("panel").duplicate()
@onready var label_bg = %Label.get_theme_stylebox("normal").duplicate()

func _ready():
	%Label.hide()
	$Edit.hide()
	disable_toggle()
	%Title.text = text
	Globals.item_selected.connect(unselect)
	Globals.item_changed.connect(_cleanup)

func disable_toggle():
	%Toggle.text = ""
	%Toggle.disabled = true
	
func enable_toggle():
	%Toggle.text = "-"
	%Toggle.disabled = false

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
	
func _on_finish_pressed(save=true):
	if get_meta("subgroup"):
		var container = get_meta("subgroup").get_parent()
		container.get_parent().remove_child(container)
		container.queue_free()
		set_meta("subgroup", null)
	
	var sub_list = get_parent()
	var container = sub_list.get_parent()
	sub_list.remove_child(self)
		
	# TODO, remove once _cleanup can be implemented
	if container.name.ends_with("-children") and sub_list.get_child_count() == 0:
		var parent_task = container.get_meta("parent")
		if parent_task:
			parent_task.disable_toggle()
			parent_task.set_meta("subgroup", null)
		container.get_parent().remove_child(container)
		container.queue_free()
		
	if save:
		queue_free()
		Globals.save_data.emit()
	
func to_dict() -> Dictionary:
	var save_data = {
		"name": text,
		"collapsed": %Toggle.text == "+",
	}
	var subgroup = get_meta("subgroup")
	if subgroup:
		save_data["tasks"] = Globals._save_nested_tasks(subgroup)
	if label_id > 0:
		save_data["label_id"] = label_id
	return save_data

func _get_drag_data(_at_position):
	return { "node": self, "id": _task_id() }
	
func _can_drop_data(_at_position, data):
	if _task_id().begins_with(data["id"]):
		return false
		
	# Prevent dropping on element on it's parent if it's the last element
	var sub_id = data["id"].rsplit("/", true, 2)
	var sub_group = get_meta("subgroup")
	if sub_id[0] == _task_id() and sub_group is VBoxContainer and sub_group.get_child_count() == 1:
		return false
	
	# TODO, show preview if adding as child or reorder	
	return true
	
func _drop_data(at_position, data):
	# Cleanup the old stuff
	data["node"]._on_finish_pressed(false)
	
	# at_position is relative to the target node. If you drag to the left of the
	# the node it's added on the same level, else as child
	if at_position.x < 50:
		add_sibling(data["node"])
	else:
		# if the element has no subgroup, create it. Append it then
		if not get_meta("subgroup") is VBoxContainer:
			add_subtask_container()
		get_meta("subgroup").add_child(data["node"])
	
	# if the moved entry was a group itself, reparent them too
	var sub_list = data["node"].get_meta("subgroup")
	if sub_list:
		var container = sub_list.get_parent()
		container.get_parent().remove_child(container)
		data["node"].add_sibling(container)
		
	Globals.save_data.emit()

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
	%Title.text = new_text
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
	group.set_meta("parent", self)
	add_sibling(group)
	enable_toggle()
	
	return sub_list

func toggle_children_visibility():
	if get_meta("subgroup") == null:
		disable_toggle()
		return
	
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
		if get_meta("subgroup").get_child_count() == 0:
			get_meta("subgroup").get_parent().queue_free()
			%Toggle.text = ""

func set_label(new_label_id : int):
	label_id = new_label_id
	if label_id < 1:
		label_id = 0
		%Label.hide()
		return
	
	var lbl = Globals.labels[label_id]
	if not lbl is TaskLabel:
		push_error("Invalid label-id '%d'" % new_label_id)
		return
	
	%Label.text = lbl.name
	label_bg.bg_color = lbl.color
	%Label.add_theme_stylebox_override("normal", label_bg)
	%Label.show()
