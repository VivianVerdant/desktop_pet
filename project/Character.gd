class_name Character
extends Node2D

var character_id: int

var is_selected: bool
# -1 is left, +1 is right
@onready var walk_direction: int
var character_position: Vector2 = Vector2(0.0, 0.0)
var character_velolcity: Vector2 = Vector2(0.0, 0.0)

@export var character_name: String = "Character"
@export var taskbar_height: int = 0
#Character walk speed
@export var walk_speed: float = 32
@export var character_size: Vector2i = Vector2i(128,128)
@onready var character_half_width: int = (character_size.x as float / 2.0) as int
@export var gravity: float = 5.0
enum STATE{
	IDLE,
	LOOKAROUND,
	WALK,
	SLEEP,
	UFFDA,
}
@export var character_state: STATE
var is_state_entering: bool = false
var is_state_exiting: bool = false

@onready var char_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var emitter: CPUParticles2D = $CPUParticles2D
@onready var display_rect: Rect2i

var state_tween: Tween

signal character_moving(id, pos)

func _ready():
	position = Vector2(character_half_width as float, character_size.y as float)
	print("character ", character_name ," ready")
	display_rect = DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
	#display_rect.end.y -= DisplayServer.screen_get_scale(DisplayServer.get_primary_screen()) * taskbar_height
	#print(display_rect)
	#print(DisplayServer.screen_get_scale(DisplayServer.get_primary_screen()))
	change_state()

func change_state():
	is_state_entering = true
	var chooseable_states = [
		STATE.IDLE,
		STATE.SLEEP,
		STATE.LOOKAROUND,
		STATE.WALK
	]
	var next_state = randi_range(0,chooseable_states.size()-1)
	while character_state == chooseable_states[next_state]:
		print(character_name, " you just did that, do something else dingus")
		next_state = randi_range(0,chooseable_states.size()-1)
	character_state = (chooseable_states[next_state])
	
	print(character_name, " state is now: ", STATE.keys()[character_state])

func clamp_position():
	# constrain to display bounds
	if character_position.x < (display_rect.position.x + character_half_width):
		print(character_name, " oob left")
		character_velolcity.x *= -.5
		character_position.x = display_rect.position.x + character_half_width
		
	if character_position.x > (display_rect.end.x - character_half_width):
		print(character_name, " oob right")
		character_velolcity.x *= -.5
		character_position.x = display_rect.end.x - character_half_width
		
	if character_position.y < (display_rect.position.y + character_size.y):
		print(character_name, " oob top")
		character_velolcity.y = max(character_velolcity.y, 0.0)
		character_position.y = display_rect.position.y + character_size.y
		
	if character_position.y > (display_rect.end.y):
		print(character_name, " oob bottom")
		if character_velolcity.y > .1:
			if state_tween:
				state_tween.kill()
			character_state = STATE.UFFDA
			is_state_entering = true
			is_state_exiting = false
		character_velolcity.y = min(character_velolcity.y, 0.0)
		character_position.y = display_rect.end.y

func _process(delta):
	
	clamp_position()
	
	if is_selected:
		follow_mouse()
		return
	else:
		if character_position.y < display_rect.end.y:
			character_velolcity.y += gravity * delta
			char_sprite.play("falling")
			moving()
			#clamp_position()
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
				STATE.UFFDA:
					uffda()
				_:
					print("nothing to do here yet")
					change_state()
			
	if character_velolcity != Vector2.ZERO:
		moving()
	
	#clamp_position()

func _input(_event: InputEvent) -> void:
	#On right click and hold it will follow the pet and when released
	#it will stop following
	if Input.is_action_pressed("right_click"):
		#print("right click down")
		is_selected = true
	if Input.is_action_just_released("right_click"):
		#print("right click up")
		is_selected = false
		display_rect = DisplayServer.screen_get_usable_rect(get_window().current_screen)
		#display_rect.end.y -= DisplayServer.screen_get_scale(get_window().current_screen) * taskbar_height
		print(display_rect)
		character_velolcity = Input.get_last_mouse_velocity() * Performance.get_monitor(Performance.TIME_PROCESS)
		change_state()
	#emit heart particles when petted
	if Input.is_action_just_pressed("left_click"):
		print("left click")
		emitter.emitting = true

func start_exiting_state():
	print(character_name, " exiting state")
	is_state_exiting = true

func move_window():
	var pos = (character_position - Vector2(character_half_width as float,character_size.y as float)) as Vector2i
	get_window().position = pos

func follow_mouse():
	character_velolcity.y = 0
	#Follows mouse cursor but clamps it on the taskbar
	char_sprite.play("grabbed", 0.0)
	#char_sprite.frame = remap(character_velolcity.x, -20, 20, 0, 2)
	character_position = DisplayServer.mouse_get_position() as Vector2 + Vector2(0.0, 100.0)
	#print(character_position)
	move_window()
	#character_moving.emit(character_id, (character_position - Vector2(character_half_width as float,character_size.y as float)) as Vector2i)

func moving():
	if character_velolcity.x > 0.0:
		char_sprite.flip_h = true
	else:
		char_sprite.flip_h = false
	
	character_position += character_velolcity
	
	move_window()
	#print(character_position)
	#character_moving.emit(character_id, )

func walk(delta):
	if is_state_entering:
		is_state_entering = false
		
		char_sprite.play("walk")
		
		if (randi_range(0,1) == 0):
			walk_direction = -1
		else:
			walk_direction = 1
		
		var state_time = randi_range(10,30)
		
		if state_tween:
			state_tween.kill()
		state_tween = get_tree().create_tween()
		state_tween.tween_callback(self.start_exiting_state).set_delay(state_time)
		
		print(character_name, " walking for ", state_time, " seconds")

	elif is_state_exiting:
		is_state_exiting = false
		change_state()
		return
	
	#Moves the pet
	character_velolcity.x = walk_speed * delta * walk_direction
	
	#Changes direction if it hits the sides of the screen
	if character_position.x as int <= (display_rect.position.x + character_half_width):
		print(character_name, " change direction")
		walk_direction = 1
	
	if character_position.x as int >= (display_rect.end.x - character_half_width):
		print(character_name, " change direction")
		walk_direction = -1

func idle():
	if is_state_entering:
		is_state_entering = false
		
		char_sprite.play("idle")
		
		var state_time = randi_range(5,15)
		
		if state_tween:
			state_tween.kill()
		state_tween = get_tree().create_tween()
		state_tween.tween_callback(self.start_exiting_state).set_delay(state_time)
		
		print(character_name, " idling for ", state_time, " seconds")
		
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
		
		var state_time = randi_range(30,90)
		
		if state_tween:
			state_tween.kill()
		var callback = func(): char_sprite.play("sleep")
		state_tween = get_tree().create_tween()
		state_tween.tween_callback(callback).set_delay(2.0)
		state_tween.tween_callback(self.start_exiting_state).set_delay(state_time)
		
		print(character_name, " sleeping for ", state_time, " seconds")
		
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
		
		var state_time = randi_range(15,30)
		
		if state_tween:
			state_tween.kill()
		state_tween = get_tree().create_tween()
		state_tween.tween_callback(self.start_exiting_state).set_delay(state_time)
		
		print(character_name, " lookaround for ", state_time, " seconds")
		
		character_velolcity.x = 0.0

	elif is_state_exiting:
		is_state_exiting = false
		change_state()
		return
	
func uffda():
	if is_state_entering:
		is_state_entering = false
		char_sprite.play("uffda")
		
		if character_velolcity.x > 0.0:
			char_sprite.flip_h = true
		else:
			char_sprite.flip_h = false
		
		var state_time = randi_range(3,10)
		
		if state_tween:
			state_tween.kill()
		state_tween = get_tree().create_tween()
		state_tween.tween_callback(self.start_exiting_state).set_delay(state_time)
		
		print(character_name, " uffda for ", state_time, " seconds")
		
		#character_velolcity.x = 0.0

	elif is_state_exiting:
		is_state_exiting = false
		change_state()
		return
	
	character_velolcity.x *= 0.99
