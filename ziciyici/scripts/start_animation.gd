extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	# 直接播放动画
	animation_player.play("intro")
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String) -> void:
	# 动画播放完后淡出变黑
	var tween = create_tween()
	tween.tween_property(color_rect, "color", Color.BLACK, 1.0)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/battle_xiongxiong.tscn")
	)
