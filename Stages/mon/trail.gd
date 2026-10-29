extends GPUParticles2D

func set_color(color_string):
	var tex = load("res://assets/images/rastro_"+color_string+".png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_texture(tex)

func _ready():
	pass
