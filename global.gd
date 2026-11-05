extends Node

const MAX_PLAYERS = 4
const TOTAL_MONSTERS = 5 # Number  of monster types
const powerup_effects_dir = "res://Stages/mon/powerup_effects/"

# Color strings used by assets
const colors = ["azul", "vermelho", "verde", "amarelo"]

enum game_modes {SURVIVAL, PIXEL_THRONE, VIRUS, CO_OP}

enum powerup_types {FREEZE, UNICORN, SPIKES, ROCKETS, GHOST, NET, BOMBERMON, DASH, PEPPER, VIALS}

# Hardcoded for now, will be mapped later
var devices = ["keyboard", "dev0", "dev1", "dev2", "dev3"]

var player_list = []
var selected_stage = 2
var game_mode = game_modes.SURVIVAL

const LOADING_SCREEN = "res://LoadingScreen/LoadingScreen.tscn"
var next_stage = "" # the stage the loading screen switches to
var outgoing_scene = null # the scene game_start() left, kept loaded until the stage has loaded

class Player:
	var number
	var color
	var monster
	var controller_device
	var kills = 0
	var score = 0
	var win_count = 0

# Godot 4's Compatibility renderer compiles the process shader of a GPUParticles2D (one per
# ParticleProcessMaterial feature set) the first time those particles run, and the lit variant of the
# canvas shader the first time a light masks a sprite. Each compile stalls that frame for about 0.2-0.5 s,
# which shows as a hitch the first time a powerup, smash or death effect is used in a match.
# So before the first stage starts, the loading screen runs every particle effect and the ink splash light
# once, in a SubViewport that is never displayed. A compiled particle shader is freed with the last material
# that uses it, so a deep copy of each process material is kept for the session, and later stage starts skip
# the warm-up. The scenes themselves are not kept: scripts change their shared materials at runtime
# (powerup sparkles, vials trail), and the warm-up must not carry those changes into later rounds.
const WARM_UP_SCENES = [
	"res://Stages/mon/Mon.tscn",
	"res://Stages/powerup/Powerup.tscn",
	"res://CharacterSelection/TestTube.tscn",
	"res://Stages/mon/splash/Splash.tscn",
]
const WARM_UP_SIZE = Vector2i(64, 64)
var _warmed_up = false
var _warm_up_keep = [] # ParticleProcessMaterial copies, never used by gameplay
var _warm_up_pending = [] # warm-up nodes not added to the tree yet

func _notification(what):
	if what == NOTIFICATION_PREDELETE: # quit before the warm-up finished
		for n in _warm_up_pending:
			n.free()

# Awaited by the loading screen. Returns at once if the shaders were already warmed up this session.
func warm_up_shaders():
	if _warmed_up:
		return
	_warmed_up = true
	await _warm_up_effects()

# Compiles one effect per frame, so the warm-up is a few short stalls behind the loading screen instead of
# one long frame.
func _warm_up_effects():
	# process_frame (not frame_post_draw, which never fires headless): nodes added on a process_frame are
	# drawn, and their shaders compiled, at the end of that same frame.
	var vp = SubViewport.new()
	vp.size = WARM_UP_SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	for path in WARM_UP_SCENES:
		var steps = _warm_up_steps(path) # each step: nodes added to the viewport together
		await get_tree().process_frame # loading the scene was this frame's work
		for step in steps:
			for n in step:
				vp.add_child(n)
				_warm_up_pending.erase(n)
			await get_tree().process_frame
	await get_tree().process_frame # the last step's frame has been drawn now
	vp.queue_free()

func _warm_up_steps(path):
	var steps = []
	var scene = load(path)
	if scene == null:
		push_warning("Shader warm-up: cannot load " + path)
		return steps
	var center = Vector2(WARM_UP_SIZE) / 2
	var inst = scene.instantiate()
	for n in inst.find_children("*", "GPUParticles2D", true, false):
		var p = n.duplicate(0) # no script, signals or groups
		if p.process_material:
			p.process_material = p.process_material.duplicate(true) # same shader, not the scene's material
			_warm_up_keep.append(p.process_material)
		p.position = center
		p.one_shot = true
		p.emitting = true
		steps.append([p])
	var lit = []
	for n in inst.find_children("*", "PointLight2D", true, false):
		var l = n.duplicate(0)
		if l.texture == null: # splash.gd assigns the texture in _ready
			l.texture = load("res://assets/images/splash1.png")
		l.position = center
		lit.append(l)
	if not lit.is_empty():
		# Sprites under the light, with the default light mask and the one Stage2's TileMap uses
		# (Splash.tscn only lights light_mask 2), so the lit canvas shader variants compile too.
		for mask in [1, 2]:
			var s = Sprite2D.new()
			s.texture = load("res://icon.png")
			s.position = center
			s.light_mask = mask
			lit.append(s)
		steps.append(lit)
	inst.free()
	for step in steps:
		_warm_up_pending.append_array(step)
	return steps

# Called when a player joins the game in the character selection screen
func add_player(index, color, mon, device):
	var player
	if index > player_list.size()-1:
		player = Player.new()
		player_list.append(player)
	else:
		player = player_list[index]
	player.number = index+1
	player.color = color
	player.monster = mon
	player.controller_device = device

# Every stage starts through the loading screen, which warms up the shaders and then changes to next_stage.
func game_start():
	next_stage = "res://Stages/Stage"+var_to_str(selected_stage)+".tscn"
	# In 3.5 the stage loaded while the outgoing scene was still alive, so it reused the resources that scene
	# kept cached: the scoreboard's Mon.tscn, with any shared material a script changed in the last round
	# (a Vials trail shrink still active when the round ended carries into the next round). Holding the
	# outgoing PackedScene until the loading screen has loaded the stage keeps that behaviour.
	var current = get_tree().current_scene
	if current and not current.scene_file_path.is_empty():
		outgoing_scene = load(current.scene_file_path)
	get_tree().change_scene_to_file(LOADING_SCREEN)
	selected_stage = 1 + randi() % 2

func increase_kill_count(pnum):
	for p in player_list:
		if p.number == pnum:
			p.kills = p.kills + 1

func increase_player_score(pnum):
	for p in player_list:
		if p.number == pnum:
			p.score = p.score + 1

func reset_player_scores():
	for p in player_list:
		p.score = 0
