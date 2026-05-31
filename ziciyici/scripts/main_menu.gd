class_name MainMenu
extends Control

@onready var play_button: TextureButton = $PlayButton

func _ready() -> void:
	# 检查按钮节点是否存在
	if play_button == null:
		print("错误：找不到 PlayButton 节点！请检查场景中是否存在名为 PlayButton 的子节点。")
		return
	# 连接按钮点击信号

func _on_play_pressed() -> void:
	# 点击后切换到开场动画场景
	get_tree().change_scene_to_file("res://scenes/start_animation.tscn")
