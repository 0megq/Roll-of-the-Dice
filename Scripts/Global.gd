extends Node

export var win_scene: PackedScene
export var main_scene: PackedScene

func _ready() -> void:
	$Music.play()
	
func _process(delta: float) -> void:
	if !$Music.playing:
		$Music.play()

func win() -> void:
	$WinSound.play()
	yield(get_tree().create_timer(0.3), "timeout")
	get_tree().change_scene_to(win_scene)
	yield(get_tree().create_timer(20), "timeout")
	get_tree().change_scene_to(main_scene)
