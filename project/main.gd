extends Control

@onready var _MainWindow: Window = get_window()
@onready var character_container_node = $Characters
@onready var main_window = $Main_Window
var character_list:Array[Node]

var spawnable_character_list: Array

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print(event)

func _ready() -> void:
	print("first ready")
	spawnable_character_list = get_all_files_from_directory("res://spawnable/", "tscn")
	for character in spawnable_character_list:
		var scene_name:String = character.resource_path
		scene_name = scene_name.erase(0,16)
		print(scene_name)
		main_window.character_dropdown.add_item(scene_name)
	
	character_list = character_container_node.get_children()
	
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

func on_character_moving(id: int, pos: Vector2i) -> void:
	DisplayServer.window_set_position(pos, id)

func on_spawn_button_press() -> void:
	var scene_name = main_window.character_dropdown.get_item_text(main_window.character_dropdown.get_selected_id())
	print("character dropdown: ", main_window.character_dropdown.get_selected_id())
	var scene_instance = load("res://spawnable/" + scene_name).instantiate()
	scene_instance.character_moving.connect(on_character_moving)
	scene_instance.character_id = character_container_node.get_child_count() + 1
	print("Character id: ", scene_instance.character_id)
	var display_rect:Rect2i = DisplayServer.screen_get_usable_rect(get_window().current_screen)
	var pos = lerp(display_rect.position as Vector2, display_rect.end as Vector2, randf_range(0.2,0.8)) as Vector2i
	scene_instance.character_position = pos
	var window: Window = Window.new()
	window.borderless = true
	window.title = scene_instance.character_name
	window.position = pos
	window.visible = true
	window.transparent = true
	#window.transient = true
	window.always_on_top = true
	window.size = scene_instance.character_size
	window.add_child(scene_instance)
	character_container_node.add_child(window)
	print("spawn: ", main_window.character_dropdown.get_item_text(main_window.character_dropdown.get_selected_id()))


func get_all_files_from_directory(path : String, file_ext:= "", files := []):
	var resources = ResourceLoader.list_directory(path)
	print(resources)
	for res in resources:
		print(str(path+res))
		if res.ends_with("/"): 
			get_all_files_from_directory(path+res, file_ext, files)
		elif file_ext && res.ends_with(file_ext): 
			files.append(load(path+res))
	return files

func make_all_popups():
	var windows = character_container_node.get_children()
	for win:Window in windows:
		win.visible = false
		win.popup_window = true
		win.visible = true

func make_all_windows():
	var windows = character_container_node.get_children()
	for win:Window in windows:
		win.visible = false
		win.popup_window = false
		win.visible = true

func _on_mouse_entered() -> void:
	#make_all_windows()
	#print("mouse entered")
	pass

func _on_mouse_exited() -> void:
	#make_all_popups()
	#print("mouse exited")
	pass

func _on_gui_input(event: InputEvent) -> void:
	return
	#if event is InputEventMouseMotion:
		#print(event)
