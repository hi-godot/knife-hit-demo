extends Node2D

## Minimal Knife Hit test bed: click / tap / Space spawns a knife at the bottom
## that flies straight up into the rotating target and sticks.

const KnifeScene := preload("res://knife_hit/knife.tscn")

@onready var target: Area2D = $Target

var _spawn_point := Vector2(960, 980)  # bottom-center of the 1920x1080 viewport

func _enter_tree() -> void:
	# Friendly "Debug -> Visible Collision Shapes" without the menu: enabling the
	# hint here (before children enter the tree) makes the target's shape and
	# every spawned knife's CollisionShape2D + RayCast2D draw at runtime.
	get_tree().debug_collisions_hint = true

func _unhandled_input(event: InputEvent) -> void:
	var fire := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fire = true
	elif event is InputEventScreenTouch and event.pressed:
		fire = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		fire = true
	if fire:
		_spawn_knife()

func _spawn_knife() -> void:
	var knife: Knife = KnifeScene.instantiate()
	add_child(knife)
	knife.global_position = _spawn_point
	knife.throw(Vector2.UP)  # spawn sits directly below the target rim
