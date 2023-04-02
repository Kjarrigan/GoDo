extends Panel

func _ready():
	Globals.root_list = %List
	Globals.menu = %Menu
	Globals.load_tasks(0)
	Globals.item_selected.emit(null)

func _on_prev_workspace_pressed():
	Globals.change_workspace.emit(-1)

func _on_next_workspace_pressed():
	Globals.change_workspace.emit(+1)
