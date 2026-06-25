class_name Knife
extends Area2D

## A thrown knife.
##
## It moves MANUALLY in code (no physics velocity/forces) and detects the target
## with a RayCast2D that is re-aimed every frame to cover one full frame of
## travel. Snapping to the ray's collision point makes every knife stick at the
## SAME depth, regardless of which physics frame the hit happens to land on. A
## plain Area2D overlap would register the hit a variable number of pixels deep.

@export var speed: float = 1400.0      ## flight speed in px/s
@export var embed_depth: float = 18.0  ## how far past the rim the tip sinks
@export var ray_margin: float = 8.0    ## extra ray length; prevents tunneling
## Cosmetic air-spin: each throw picks a random speed in this range AND a random
## direction. Sprite-only -- the body and ray never spin. Set both to 0 for none.
@export var spin_speed_min: float = 14.0  ## slowest air-spin (rad/s)
@export var spin_speed_max: float = 30.0  ## fastest air-spin (rad/s)

@onready var sprite: Sprite2D = $Sprite2D
@onready var ray: RayCast2D = $RayCast2D

var velocity: Vector2 = Vector2.ZERO
var spin_speed: float = 0.0  ## this throw's signed spin; rolled in throw()
var _stuck: bool = false

func _ready() -> void:
	# We drive the ray ourselves via force_raycast_update(); nothing happens
	# until throw() is called.
	set_physics_process(false)

## Public API: aim and launch.
func throw(direction: Vector2) -> void:
	velocity = direction.normalized() * speed
	rotation = direction.angle()  # local +X (blade tip & ray) faces flight dir
	# Roll a random air-spin for this throw: random magnitude AND random direction.
	spin_speed = randf_range(spin_speed_min, spin_speed_max)
	if randf() < 0.5:
		spin_speed = -spin_speed
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _stuck:
		return

	# Cosmetic spin lives ONLY on the sprite. The Area2D body and the RayCast2D
	# must stay locked to the flight heading or detection breaks.
	if spin_speed != 0.0:
		sprite.rotation += spin_speed * delta

	var step: Vector2 = velocity * delta

	# Aim the ray along the blade tip (+X) far enough to cover this whole frame
	# of travel plus a margin, so a fast knife can't tunnel through the rim.
	ray.target_position = Vector2(step.length() + ray_margin, 0.0)
	ray.force_raycast_update()

	if ray.is_colliding():
		_stick(ray.get_collision_point(), ray.get_collider())
	else:
		global_position += step

func _stick(point: Vector2, collider: Node) -> void:
	_stuck = true
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Snap to the exact collision point, then push the tip a fixed depth in.
	# global_rotation is the flight heading (sprite spin never touches the body).
	var tip_dir: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	global_position = point + tip_dir * embed_depth

	# Settle the cosmetic spin back to the flight heading so it doesn't snap.
	if spin_speed != 0.0:
		# wrapf first so a knife spun past +-PI takes the SHORT way back to 0
		# instead of unwinding the long way around.
		sprite.rotation = wrapf(sprite.rotation, -PI, PI)
		var t := create_tween()
		t.tween_property(sprite, "rotation", 0.0, 0.06) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Reparent under the target so the knife rides its rotation. Deferred so we
	# don't restructure the scene tree mid-physics-step; reparent() keeps the
	# global transform by default, so the knife stays exactly where it stuck.
	if collider is Node2D:
		call_deferred("reparent", collider)
