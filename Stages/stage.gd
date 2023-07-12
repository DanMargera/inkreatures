extends Node2D

var players
var not_playing = [1, 2, 3, 4] # Initially no one is playing

var players_alive
var round_finished = false

func _on_player_kill(player):
	get_node("/root/global").increase_kill_count(player)

func _on_player_death(player):
	var player_nodes = get_tree().get_nodes_in_group("players")
	var winner = null
	var alive_count = 0
	for n in player_nodes:
		if n.isAlive:
			alive_count += 1
			winner = n
	if alive_count == 1:
		round_finish(winner.player)
	elif alive_count == 0:
		round_finish(player)

func round_finish(winner):
	if round_finished:
		return
	round_finished = true
	get_node("/root/global").increase_player_score(winner)
	Engine.time_scale = 0.6
	yield(get_tree().create_timer(2), "timeout")
	Engine.time_scale = 1
	get_tree().change_scene("res://Stages/scoreboard/Scoreboard.tscn")

func _ready():
	# Stage configuration
	# Player setup
	players = get_node("/root/global").player_list
	for player in players:
		not_playing.erase(player.number)
		var node_name = "player"+var2str(player.number)
		get_node(node_name).player = player.number
		get_node(node_name).controller = player.controller_device
		var tex = load("res://assets/images/m_0"+var2str(player.monster)+"_"+player.color+".png")
		tex.set_flags(0)
		get_node(node_name+"/Sprite").set_texture(tex)
		get_node(node_name).set_color(player.color)
		get_node(node_name).connect("on_kill", self, "_on_player_kill")
		get_node(node_name).connect("on_death", self, "_on_player_death")
	
	players_alive = players.size()
	
	# Remove unused players
	for p in not_playing:
		get_node("player"+var2str(p)).queue_free()
