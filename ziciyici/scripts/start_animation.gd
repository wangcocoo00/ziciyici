extends Node2D

@onready var video_player: VideoStreamPlayer = $CanvasLayer/VideoStreamPlayer
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect

func _ready() -> void:
	# 开始播放视频
	video_player.play()
	video_player.finished.connect(_on_video_finished)

func _on_video_finished() -> void:
	# 视频播放完后淡出变黑
	var tween = create_tween()
	tween.tween_property(color_rect, "color", Color.BLACK, 1.0)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/battle_xiongxiong.tscn")
	)
