extends CanvasLayer

# Lights ignore texture_filter in the Compatibility renderer (their textures are sampled linearly from a
# shared atlas), so each splash texture is upscaled with nearest-neighbour once and drawn at 1/UPSCALE.
# UPSCALE matches the largest magnification: Spread ends at scale 3 and setup() never enlarges further.
const UPSCALE = 3
static var _textures = {}

static func _get_texture(i):
	if not _textures.has(i):
		var img = load("res://assets/images/splash%d.png" % i).get_image()
		img.resize(img.get_width() * UPSCALE, img.get_height() * UPSCALE, Image.INTERPOLATE_NEAREST)
		_textures[i] = ImageTexture.create_from_image(img)
	return _textures[i]

func setup(color, size):
	get_node("Node2D").scale.x *= size
	get_node("Node2D").scale.y *= size
	get_node("Node2D/Splash").set_color(color)

func set_position(pos):
	get_node("Node2D").position = pos

func _ready():
	# Render on top of other ink splatters
	layer = get_parent().get_child_count() * -1
	# Randomize texture
	var splash = get_node("Node2D/Splash")
	splash.set_texture(_get_texture(randi()%3+1))
	splash.texture_scale = 1.0 / UPSCALE
	get_node("Node2D/AnimationPlayer").play("Spread")
