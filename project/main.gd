extends Node2D

@onready var _MainWindow: Window = get_window()

var character_list:Array[Node]




func _ready():
	character_list = get_children()
	
	for i in character_list.size():
		if i == 0:
			#Change the size of the window
			_MainWindow.min_size = character_list[i].character_size
			_MainWindow.size = _MainWindow.min_size
			#Places the character in the middle of the screen and on top of the taskbar
			#_MainWindow.position = DisplayServer.screen_get_size() / 2
			character_list[i].character_position = _MainWindow.position
			character_list[i].character_id = i
			character_list[i].character_moving.connect(on_character_moving)

func on_character_moving(id: int, pos: Vector2i):
	DisplayServer.window_set_position(pos, id)
