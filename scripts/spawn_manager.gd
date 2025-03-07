extends Node2D

const MERGABLE_SCENE = preload("res://scenes/mergable.tscn")
const POOF_PARTICLE_SCENE = preload("res://scenes/poof_particle.tscn")
const MAX_LEVEL: int = 5
var _max_spawned_level: int = 1
var _next_item: Mergable = null

@export var merge_animation_duration: float = 0.1

var _temp = 1;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.mergable_items_collided.connect(_on_mergable_items_collided)
	_spawn_next_item()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _next_item != null:
		var fall_position = _get_valid_spawn_position(get_viewport().get_mouse_position())
		_next_item.position.x = fall_position.x
		if Input.is_action_just_pressed("drop"):
			#_next_item.position.x = fall_position.x
			_next_item.enable_gravity()
			_next_item = null
			$SpawnTimer.start()
	elif $SpawnTimer.paused:
		_spawn_next_item()


func _get_valid_spawn_position(spawn_position: Vector2):
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	return Vector2(
		min(max(spawn_position.x, 0), 410),
		min(max(spawn_position.y, 30), viewport_size.y)
	)

func _spawn_next_item():
	if _next_item != null:
		return
	var spawn_position: Vector2 = Vector2(200, 30)
	_next_item = _spawn_mergable(randi() % min(MAX_LEVEL, _max_spawned_level) + 1, spawn_position)
	_next_item.disable_gravity()
	

func _spawn_mergable(level: int, spawn_position: Vector2) -> Mergable:
	var item = MERGABLE_SCENE.instantiate()
	item.mergable_level = level
	item.position = _get_valid_spawn_position(spawn_position)
	item.set_size_to_zero()
	item.start_at_zero_size = true
	add_child(item)
	_max_spawned_level = level
	return item


func _on_mergable_items_collided(target_item: Mergable, other_item: Mergable):
	var spawn_level = target_item.mergable_level + 1
	var spawn_position = target_item.position
	other_item.disable_collision()
	target_item.disable_collision()
	call_deferred("_start_merge_animation", target_item, other_item)

func _start_merge_animation(target_item: Mergable, other_item: Mergable):
	var tween: Tween = create_tween()
	tween.tween_property(other_item, "position", target_item.position, merge_animation_duration)
	tween.tween_callback(_remove_merged_items.bind(target_item, other_item))

func _remove_merged_items(target_item: Mergable, other_item: Mergable):
	_spawn_merge_particles(target_item.position)
	_play_merge_sound()
	
	target_item.shrink_and_remove()
	other_item.shrink_and_remove()
	
	var spawn_level = target_item.mergable_level + 1
	var spawn_position = target_item.position
	_spawn_mergable(spawn_level, spawn_position)


func _on_spawn_timer_timeout() -> void:
	_spawn_next_item()


func _spawn_merge_particles(particle_position: Vector2):
	var particle: Node2D = POOF_PARTICLE_SCENE.instantiate()
	particle.position = particle_position
	particle.z_index = 10
	add_child(particle)

func _play_merge_sound():
	$MergeSound.play()
