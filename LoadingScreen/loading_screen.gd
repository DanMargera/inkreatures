extends Control

# Shown when a stage is about to start (global.game_start). It waits for the shader warm-up, which only
# does work the first time, then switches to the stage, which loads behind it.
func _ready():
	var global = get_node("/root/global")
	# process_frame, not frame_post_draw, which never fires headless
	for i in 2: # let this screen be drawn and shown before the stalls start
		await get_tree().process_frame
	await global.warm_up_shaders()
	get_tree().change_scene_to_file(global.next_stage) # loads the stage before it returns
	global.outgoing_scene = null
