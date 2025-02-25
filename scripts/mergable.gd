extends RigidBody2D

class_name Mergable

@export var mergable_level: int = 1
@export var size_change_duration: float = 0.1
@export var start_at_zero_size: bool = false
var is_merging: bool = false


class LevelSpec:
	extends Resource
	
	@export var sprite: Resource
	@export var level: int
	@export var scale: Vector2
	
	func _init(level: int, mergable_scale: float, score: int, sprite: Resource) -> void:
		self.sprite = sprite
		self.level = level
		self.scale = Vector2.ONE * mergable_scale
	

var _levels: Dictionary = {
	1: LevelSpec.new(1, 0.3, 2, preload("res://assets/1-parrot.png")),
	2: LevelSpec.new(2, 0.5, 3, preload("res://assets/2-duck.png")),
	3: LevelSpec.new(3, 0.55, 6, preload("res://assets/3-penguin.png")),
	4: LevelSpec.new(4, 0.57, 10, preload("res://assets/4-sloth.png")),
	5: LevelSpec.new(5, 0.65, 15, preload("res://assets/5-gorilla.png")),
	6: LevelSpec.new(6, 0.75, 21, preload("res://assets/6-panda.png")),
	7: LevelSpec.new(7, 0.82, 28, preload("res://assets/7-cow.png")),
	8: LevelSpec.new(8, 0.97, 36, preload("res://assets/8-hippo.png")),
	9: LevelSpec.new(9, 1.05, 45, preload("res://assets/9-giraffe.png")),
	10: LevelSpec.new(10, 1.1, 55, preload("res://assets/10-elephant.png")),
	11: LevelSpec.new(11, 1.25, 66, preload("res://assets/11-whale.png")),
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_merging = false
	set_level()
	if start_at_zero_size:
		grow_from_zero()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _get_spec() -> LevelSpec:
	return _levels[mergable_level]


func set_level():
	#print("Setting mergable level and scale to: ", mergable_level, scale)
	var spec = _get_spec()
	$Sprite.texture = spec.sprite
	$Sprite.scale = spec.scale
	$CollisionShape.scale = spec.scale
	add_to_group("mergable_" + str(mergable_level))


func _on_body_entered(body: Node) -> void:
	var node: Mergable = body as Mergable
	if node and _is_mergable_with(body):
		_handle_merging_with(body)


func _is_mergable_with(node: Mergable) -> bool:
	if not node or "is_merging" not in node:
		return false
	if is_merging or node.is_merging or not _is_on_same_level_with(node):
		return false
	if mergable_level == len(_levels):
		print("MAX LEVEL REACHED")
		return false
	return true


func _handle_merging_with(node: Mergable) -> void:
	is_merging = true
	node.is_merging = true
	var nodes = _get_merge_order(node)
	SignalBus.mergable_items_collided.emit(nodes[0], nodes[1])


func _is_on_same_level_with(node: Node) -> bool:
	return node.get_groups() == get_groups()


func _get_merge_order(node: Mergable) -> Array[Mergable]:
	if position.y > node.position.y:
		return [$".", node]
	else:
		return [node, $"."]

func disable_collision():
	#$"CollisionShape".queue_free()
	set_deferred("freeze", true)
	#freeze = true
	
	
func set_size_to_zero():
	$Sprite.scale = Vector2.ZERO
	$CollisionShape.scale = Vector2.ZERO


func grow_from_zero():
	set_size_to_zero()
	var spec = _get_spec()
	var tween: Tween = create_tween()
	tween.tween_property($Sprite, "scale", spec.scale, size_change_duration)
	tween.parallel().tween_property($CollisionShape, "scale", spec.scale, size_change_duration)

func disable_gravity():
	freeze = true
	

func enable_gravity():
	freeze = false


func shrink_and_remove():
	$CollisionShape.queue_free()
	var tween: Tween = create_tween()
	tween.tween_property($Sprite, "scale", Vector2.ZERO, size_change_duration)
	tween.tween_callback(queue_free)
