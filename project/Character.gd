class_name Character
extends Node2D

var character_id: int

var is_selected: bool
# -1 is left, +1 is right
@onready var walk_direction: int
var character_position: Vector2 = Vector2(0.0, 0.0)
var character_velolcity: Vector2 = Vector2(0.0, 0.0)

@export var taskbar_height: int = 0
#Character walk speed
@export var _name: String = "Character"
@export var walk_speed: float = 32
@export var character_size: Vector2i = Vector2i(128,128)
@onready var character_half_width: int = (character_size.x as float / 2.0) as int
@export var gravity: float = 5.0
enum STATE{
	IDLE,
	LOOKAROUND,
	WALK,
	SLEEP,
}
@export var character_state: STATE
var is_state_entering: bool = false
var is_state_exiting: bool = false

@onready var char_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var emitter: CPUParticles2D = $CPUParticles2D
@onready var display_rect: Rect2i

signal character_moving(id, pos)

func _ready():
	position = Vector2(character_half_width as float, character_size.y as float)
	print("character ready")
	display_rect = DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
	display_rect.end.y -= DisplayServer.screen_get_scale(DisplayServer.get_primary_screen()) * taskbar_height
	print(display_rect)
	print(DisplayServer.screen_get_scale(DisplayServer.get_primary_screen()))
	change_state()

func change_state():
	is_state_entering = true
	var offset = randi_range(1,STATE.size()-1)
	character_state = ((character_state + offset)%STATE.size())
	
	print("character state is now: ", character_state)


func _process(delta):
	if is_selected:
		follow_mouse()
		return
	else:
		if character_position.y < display_rect.end.y:
			character_velolcity.y += gravity * delta
			char_sprite.play("grabbed")
			moving()
			return
		else:
			character_velolcity.y = 0.0
	
		match character_state:
			STATE.WALK:
				walk(delta)
			STATE.IDLE:
				idle()
			STATE.SLEEP:
				sleep()
			STATE.LOOKAROUND:
				lookaround()
			_:
				print("nothing to do here yet")
				change_state()
			
	if character_velolcity != Vector2.ZERO:
		moving()
	
	# constrain to display bounds
	if character_position.x < (display_rect.position.x + character_half_width):
		#print("oob left")
		character_position.x = display_rect.position.x + character_half_width
		
	if character_position.x > (display_rect.end.x - character_half_width):
		#print("oob right")
		character_position.x = display_rect.end.x - character_half_width
		
	if character_position.y < (display_rect.position.y + character_size.y):
		#print("oob top")
		character_position.y = display_rect.position.y + character_size.y
		
	if character_position.y > (display_rect.end.y):
		#print("oob bottom")
		character_position.y = display_rect.end.y

func _input(event: InputEvent) -> void:
	#On right click and hold it will follow the pet and when released
	#it will stop following
	if Input.is_action_pressed("right_click"):
		#print("right click down")
		is_selected = true
	if Input.is_action_just_released("right_click"):
		#print("right click up")
		is_selected = false
		display_rect = DisplayServer.screen_get_usable_rect(get_window().current_screen)
		display_rect.end.y -= DisplayServer.screen_get_scale(get_window().current_screen) * taskbar_height
		print(display_rect)
		change_state()
	#emit heart particles when petted
	if Input.is_action_just_pressed("left_click"):
		#print("left click")
		emitter.emitting = true

func start_exiting_state():
	print("exiting state")
	is_state_exiting = true

func follow_mouse():
	character_velolcity.y = 0
	#Follows mouse cursor but clamps it on the taskbar
	char_sprite.play("grabbed")
	character_position = DisplayServer.mouse_get_position() as Vector2 + Vector2(0.0, 100.0)
	character_moving.emit(character_id, (character_position - Vector2(character_half_width as float,character_size.y as float)) as Vector2i)

func moving():
	if character_velolcity.x > 0.0:
		char_sprite.flip_h = true
	else:
		char_sprite.flip_h = false
	
	character_position += character_velolcity
	
	character_moving.emit(character_id, (character_position - Vector2(character_half_width as float,character_size.y as float)) as Vector2i)

func walk(delta):
	if is_state_entering:
		is_state_entering = false
		
		char_sprite.play("walk")
		
		if (randi_range(0,1) == 0):
			walk_direction = -1
		else:
			walk_direction = 1
		
		var walk_time = randi_range(10,30)
		var tween = get_tree().create_tween().tween_callback(self.start_exiting_state).set_delay(walk_time)
		print("walking for ", walk_time, " seconds")

	elif is_state_exiting:
		is_state_exiting = false
		change_state()
		return
	
	#Moves the pet
	character_velolcity.x = walk_speed * delta * walk_direction
	
	#Changes direction if it hits the sides of the screen
	if character_position.x as int <= (display_rect.position.x + character_half_width):
		print("change direction")
		walk_direction = 1
	
	if character_position.x as int >= (display_rect.end.x - character_half_width):
		print("change direction")
		walk_direction = -1

func idle():
	if is_state_entering:
		is_state_entering = false
		
		char_sprite.play("idle")
		
		var idle_time = randi_range(5,15)
		var tween = get_tree().create_tween().tween_callback(self.start_exiting_state).set_delay(idle_time)
		print("idling for ", idle_time, " seconds")
		
		character_velolcity.x = 0.0

	elif is_state_exiting:
		is_state_exiting = false
		change_state()
		return
	
func sleep():
	if is_state_entering:
		is_state_entering = false
		char_sprite.play("sleep_start")
		
		char_sprite.flip_h = false
		var sleep_time = randi_range(30,90)
		var tween = get_tree().create_tween()
		var callback = func(): char_sprite.play("sleep")
		tween.tween_callback(callback).set_delay(2.0)
		tween.tween_callback(self.start_exiting_state).set_delay(sleep_time)
		
		print("sleeping for ", sleep_time, " seconds")
		
		character_velolcity.x = 0.0

	elif is_state_exiting:
		is_state_exiting = false
		change_state()
		return
	
	character_velolcity.x = 0.0

func lookaround():
	if is_state_entering:
		is_state_entering = false
		char_sprite.play("look_around")
		
		if (randi_range(0,1) == 0):
			char_sprite.flip_h = true
		else:
			char_sprite.flip_h = false
		
		var lookaround_time = randi_range(15,30)
		var tween = get_tree().create_tween()
		tween.tween_callback(self.start_exiting_state).set_delay(lookaround_time)
		
		print("lookaround for ", lookaround_time, " seconds")
		
		character_velolcity.x = 0.0

	elif is_state_exiting:
		is_state_exiting = false
		change_state()
		return
	
