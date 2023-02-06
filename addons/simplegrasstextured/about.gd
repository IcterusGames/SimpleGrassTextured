@tool
extends AcceptDialog


func _ready():
	get_ok_button().custom_minimum_size.x = 100


func _on_rich_text_label_meta_clicked(meta):
	OS.shell_open(str(meta))
