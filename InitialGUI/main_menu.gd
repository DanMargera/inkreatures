extends Control

const PLAY = 0
const OPTIONS = 1
const QUIT = 2
const SELECTION_COUNT = 3

var selected_option = 0
var cursor_margin = 15
var cursor_offset

func _ready():
	set_process_input(true)
	cursor_offset = Vector2(get_node("cursor").get_size().x + cursor_margin,0)
	get_node("cursor").global_position = Vector2(get_node("container/play").global_position - cursor_offset)

func _input(event):
	if (event.is_action_pressed("ui_up")):
		selected_option = (selected_option - 1 + SELECTION_COUNT) % SELECTION_COUNT
	elif (event.is_action_pressed("ui_down")):
		selected_option = (selected_option + 1) % SELECTION_COUNT
	elif (event.is_action_pressed("ui_accept")):
		select(selected_option)
	update_cursor(selected_option)

func update_cursor(opt):
	if (opt == PLAY):
		get_node("cursor").global_position = Vector2(get_node("container/play").global_position - cursor_offset)
	elif (opt == OPTIONS):
		get_node("cursor").global_position = Vector2(get_node("container/options").global_position - cursor_offset)
	elif (opt == QUIT):
		get_node("cursor").global_position = Vector2(get_node("container/quit").global_position - cursor_offset)

func select(opt):
	if (opt == PLAY):
		get_tree().change_scene_to_file("res://CharacterSelection/CharacterSelection.tscn")
	elif (opt == OPTIONS):
		pass
	elif (opt == QUIT):
		get_tree().quit()
