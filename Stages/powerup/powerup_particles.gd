extends GPUParticles2D

func change_color(color):
	var gradient = get_process_material().get_color_ramp().get_gradient()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0))
	
func set_random_colors():
	get_process_material().set_color(Color(1,1,1,0.5))
	# 3.x used 0.3 with hue_variation_random = 1.0, i.e. a random hue shift
	# in [-0.3, 0.3]. 4.x takes that range directly as (min, max).
	get_process_material().set_param(ParticleProcessMaterial.PARAM_HUE_VARIATION, Vector2(-0.3, 0.3))

func _ready():
	pass
