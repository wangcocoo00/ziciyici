class_name SentenceUI
extends Control

# ==================== 引用 ====================
@onready var enemy_container: HBoxContainer = $EnemySentenceContainer
@onready var player_container: HBoxContainer = $PlayerSentenceContainer

# 每个字的固定宽度（像素），确保上下对齐
const CHAR_WIDTH: float = 40.0

# ==================== 信号 ====================

# ==================== 初始化 ====================
func _ready():
	var battle = get_parent()
	if battle and battle.has_signal("sentence_updated"):
		battle.sentence_updated.connect(refresh_display)
		refresh_display()

# ==================== 刷新显示 ====================
func refresh_display() -> void:
	var battle = get_parent()
	if not battle or not battle.has_method("player_shoot"):
		return

	# 清空容器
	for child in enemy_container.get_children():
		child.queue_free()
	for child in player_container.get_children():
		child.queue_free()

	# 检查射击模式是否激活（从父节点读取）
	var shoot_mode_active: bool = false
	if battle.has_method("get_shoot_mode_active"):
		shoot_mode_active = battle.get_shoot_mode_active()
	elif "shoot_mode_active" in battle:
		shoot_mode_active = battle.shoot_mode_active

	# 遍历所有槽位
	for i in range(battle.enemy_sentence.size()):
		var enemy_text: String = battle.enemy_sentence[i]
		var player_word: WordData = battle.player_words[i] if i < battle.player_words.size() else null

		# 敌人文字 Label / Button
		var enemy_label: Control
		if shoot_mode_active:
			# 射击模式已激活：所有字都创建为 Button
			var btn := Button.new()
			btn.text = enemy_text
			btn.custom_minimum_size = Vector2(CHAR_WIDTH, 0)
			if player_word and player_word.can_be_shot:
				# 有色字：显示高亮颜色
				btn.modulate = player_word.highlight_color
			else:
				# 无色字：白色
				btn.modulate = Color.WHITE
			btn.pressed.connect(_on_enemy_word_clicked.bind(i))
			enemy_label = btn
		else:
			# 射击模式未激活：普通 Label
			var lbl := Label.new()
			lbl.text = enemy_text
			lbl.custom_minimum_size = Vector2(CHAR_WIDTH, 0)
			if player_word and player_word.can_be_shot:
				# 有色字但射击模式未激活：显示颜色但不可点击
				lbl.modulate = player_word.highlight_color
			else:
				lbl.modulate = Color.WHITE
			enemy_label = lbl

		enemy_container.add_child(enemy_label)

		# 玩家文字 Label
		var player_label := Label.new()
		if player_word:
			player_label.text = player_word.text
			player_label.custom_minimum_size = Vector2(CHAR_WIDTH, 0)
			player_label.modulate = player_word.highlight_color
		else:
			player_label.text = ""
			player_label.custom_minimum_size = Vector2(CHAR_WIDTH, 0)
		player_container.add_child(player_label)

# ==================== 事件 ====================
func _on_enemy_word_clicked(slot: int) -> void:
	var battle = get_parent()
	if battle and battle.has_method("player_shoot"):
		battle.player_shoot(slot)


func _on_battle_sentence_updated() -> void:
	refresh_display()
