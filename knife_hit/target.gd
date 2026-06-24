extends Area2D

## The spinning target disc.
##
## Lives on its OWN collision layer so the knife's RayCast2D can mask exactly
## this node. Because it is an Area2D (not a body), the knife ray must set
## collide_with_areas = true to see it.

@export var spin_speed: float = 2.0  ## rad/s
@export var radius: float = 150.0    ## keep in sync with the CollisionShape2D

func _process(delta: float) -> void:
	rotation += spin_speed * delta

func _draw() -> void:
	# Drawn once in local space; the node's rotation animates it for free.
	draw_circle(Vector2.ZERO, radius, Color(0.86, 0.27, 0.31))          # disc
	draw_circle(Vector2.ZERO, radius * 0.55, Color(0.95, 0.45, 0.30))   # ring
	draw_circle(Vector2.ZERO, radius * 0.16, Color(0.99, 0.86, 0.55))   # bullseye
	# Notches around the rim so the spin is visually obvious.
	for i in 8:
		var p := Vector2(radius * 0.8, 0.0).rotated(TAU * i / 8.0)
		draw_circle(p, 9.0, Color(0.99, 0.86, 0.55))
