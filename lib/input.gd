extends LineEdit

@onready var entry = preload("res://entry.tscn")

func _on_text_submitted(new_text):
	var item = entry.instantiate()
	item.text = new_text
	get_meta("parent").add_child(item)
	queue_free()
