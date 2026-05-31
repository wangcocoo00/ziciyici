class_name SentenceUI
extends Control

# ==================== 引用 ====================
@onready var enemy_container: HBoxContainer = $EnemySentenceContainer
@onready var player_container: HBoxContainer = $PlayerSentenceContainer

# 每个字的固定宽度（像素），确保上下对齐
const CHAR_WIDTH: float = 15.0

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

	# 获取敌人 WordData 数组（用于颜色和可射击状态）
	var enemy_words: Array = battle.enemy_words if "enemy_words" in battle else []

	# 遍历所有槽位
	for i in range(battle.enemy_sentence.size()):
		var enemy_text: String = battle.enemy_sentence[i]
		var enemy_word: WordData = enemy_words[i] if i < enemy_words.size() else null
		var player_word: WordData = battle.player_words[i] if i < battle.player_words.size() else null

		# 判断该字是否可射击（以敌人字的 can_be_shot 为准）
		var can_shoot: bool = enemy_word != null and enemy_word.can_be_shot
		# 获取颜色（优先用敌人字的颜色，其次玩家字的颜色）
		var word_color: Color = Color.WHITE
		if enemy_word and enemy_word.highlight_color != Color.BLACK and enemy_word.highlight_color != Color.WHITE:
			word_color = enemy_word.highlight_color
		elif player_word and player_word.highlight_color != Color.BLACK and player_word.highlight_color != Color.WHITE:
			word_color = player_word.highlight_color

		# 敌人文字 Label / Button
		var enemy_label: Control
		if shoot_mode_active:
			# 射击模式已激活：所有字都创建为 Button
			var btn := Button.new()
			btn.text = enemy_text
			btn.custom_minimum_size = Vector2(CHAR_WIDTH, 0)
			if can_shoot:
				# 有色字：显示高亮颜色
				btn.modulate = word_color
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
			if can_shoot:
				# 有色字但射击模式未激活：显示颜色但不可点击
				lbl.modulate = word_color
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
