extends LineEdit

func _on_text_submitted(new_text):
	Globals.add_task(get_meta("parent"), new_text)
	queue_free()
