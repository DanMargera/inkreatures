extends Node2D

var mon = null
enum vial_types {SHRINK, BOUNCY, GRAVITY}
var type = vial_types.SHRINK
var shrinking = false

func effect(player):
	if (mon == null):
		mon = player
		mon.connect("on_death", Callable(self, "effect_finish"))
		type = randi() % vial_types.size()
		type = vial_types.SHRINK
		match type:
			vial_types.BOUNCY:
				mon.bounce_factor = 0.55
			vial_types.SHRINK:
				var trail_material = mon.get_node("Trail").get_process_material()
				trail_material.scale_min = 0.5
				trail_material.scale_max = 0.5
				shrinking = true
			vial_types.GRAVITY:
				mon.GRAVITY *= 0.666
				mon.WALK_FORCE *= 0.4
		get_node("DurationTimer").start()

func effect_finish():
	match type:
		vial_types.BOUNCY:
			mon.bounce_factor = 0
		vial_types.SHRINK:
			var trail_material = mon.get_node("Trail").get_process_material()
			trail_material.scale_min = 1.0
			trail_material.scale_max = 1.0
			shrinking = false
		vial_types.GRAVITY:
			mon.GRAVITY /= 0.666
			mon.WALK_FORCE /= 0.4
	mon.remove_powerup()
	mon = null
	get_node("Sprite2D").hide()
	get_parent().get_node("PowerupAnimations").stop(true)

func _process(delta):
	var player = get_parent().get_parent()
	# Hacked tween cause I can't set scale values (since I'm sometimes inverting the scale)
	if (shrinking and abs(player.scale.y) > 0.5):
		player.scale.x *= 0.99
		player.scale.y *= 0.99
	elif (not shrinking and abs(player.scale.y) < 1):
		player.scale.x *= 1.01
		player.scale.y *= 1.01
		if (abs(player.scale.x) > 1 or abs(player.scale.y) > 1):
			player.scale.x = sign(player.scale.x)
			player.scale.y = sign(player.scale.y)

func _ready():
	set_process(true)
	get_node("DurationTimer").connect("timeout", Callable(self, "effect_finish"))
