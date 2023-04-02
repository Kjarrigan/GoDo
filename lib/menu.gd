extends MarginContainer

func _ready():
	Globals.rename_workspace.connect(_rename_workspace)
	%WorkspaceTitle.show()
	%WorkspaceEdit.hide()

func _rename_workspace(new_name):
	print_debug("Renaming to %s", new_name)
	if new_name:
		%WorkspaceTitle.text = new_name
		return
	else:
		%WorkspaceTitle.hide()
		%WorkspaceEdit.text = %WorkspaceTitle.text
		%WorkspaceEdit.show()
		%WorkspaceEdit.grab_focus()

func _on_prev_workspace_pressed():
	Globals.change_workspace.emit(-1)

func _on_next_workspace_pressed():
	Globals.change_workspace.emit(+1)

func _on_workspace_edit_text_submitted(new_text):
	%WorkspaceEdit.hide()
	%WorkspaceTitle.text = %WorkspaceEdit.text
	%WorkspaceTitle.show()
	Globals.save_data.emit()

func workspace_name() -> String:
	return %WorkspaceTitle.text
