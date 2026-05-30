class_name SentenceUI
extends Control

@onready var enemy_container: HBoxContainer = $EnemySentenceContainer
@onready var player_container: HBoxContainer = $PlayerSentenceContainer

signal slot_clicked(slot: int)

func _ready() -> void:
	var battle = get_parent()
	if battle and battle.has_signal("sentence_updated"):
		battle.sentence_updated.connect(refresh_display)
		refresh_display()

func refresh_display() -> void:
	var battle = get_parent()
	if not battle:
		return
	
	# 清空容器
	for child in enemy_container.get_children():
		child.queue_free()
	for child in player_container.get_children():
		child.queue_free()
	
	# 读取句子数据（不管管理器类型，只要有这两个数组即可）
	var enemy_sentence = battle.get("enemy_sentence") as Array[String]
	var player_words = battle.get("player_words") as Array
	
	if enemy_sentence == null or player_words == null:
		return
	
	for i in range(enemy_sentence.size()):
		var enemy_text = enemy_sentence[i]
		var player_word = player_words[i] if i < player_words.size() else null
		
		var enemy_label: Control
		if player_word and player_word.get("can_be_shot"):
			var btn := Button.new()
			btn.text = enemy_text
			btn.modulate = player_word.highlight_color
			btn.pressed.connect(_on_enemy_word_clicked.bind(i))
			enemy_label = btn
		else:
			var lbl := Label.new()
			lbl.text = enemy_text
			lbl.modulate = Color.WHITE
			enemy_label = lbl
		
		enemy_container.add_child(enemy_label)
		
		var player_label := Label.new()
		if player_word:
			player_label.text = player_word.text
			player_label.modulate = player_word.highlight_color
		else:
			player_label.text = ""
		player_container.add_child(player_label)

func _on_enemy_word_clicked(slot: int) -> void:
	var battle = get_parent()
	if battle and battle.has_method("player_shoot"):
		battle.player_shoot(slot)
