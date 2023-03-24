extends LineEdit

func _ready():
	tree_exited.connect(func(): Globals.item_changed.emit())

func _on_text_submitted(new_text):
	Globals.add_task(get_meta("parent"), new_text)
	queue_free()
