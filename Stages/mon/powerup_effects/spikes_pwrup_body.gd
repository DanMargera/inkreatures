extends CharacterBody2D

const GRAVITY = 1280.0 # Pixels/second

func _physics_process(delta):
	var force = Vector2(0, GRAVITY)
	velocity += force*delta
	var motion = velocity*delta
	var collision = move_and_collide(motion, false)
	var floor_velocity = Vector2()
	if (collision):
		# Ran against something, is it the floor? Get normal and angle
		var n = collision.get_normal()
		var angle = rad_to_deg(acos(n.dot(Vector2(0, -1))))
		# Check if collision is vertical/floor
		if (angle < 0.4):
			floor_velocity = collision.get_collider_velocity()
			velocity.x = 0
			velocity.y = 0
	if (floor_velocity != Vector2()):
		# If floor moves, move with floor. Use a temporary velocity so the
		# body's own velocity (the CharacterBody2D property) is preserved.
		var own_velocity = velocity
		velocity = floor_velocity*delta
		move_and_slide()
		velocity = own_velocity

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(true)

