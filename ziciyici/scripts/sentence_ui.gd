class_name SentenceUI
extends Control

# ==================== 引用 ====================
@onready var enemy_container: HBoxContainer = $EnemySentenceContainer
@onready var player_container: HBoxContainer = $PlayerSentenceContainer

# ==================== 信号 ====================

# ==================== 初始化 ====================
func _ready() -> void:
	# 连接 BattleManager 的句子更新信号
	var battle: BattleManager = get_parent() as BattleManager
	if battle:
		battle.sentence_updated.connect(refresh_display)
		# 立即刷新一次（数据可能已准备好）
		refresh_display()

# ==================== 刷新显示 ====================
func refresh_display() -> void:
	var battle: BattleManager = get_parent() as BattleManager
	if not battle:
		return

	# 清空容器
	for child in enemy_container.get_children():
		child.queue_free()
	for child in player_container.get_children():
		child.queue_free()

	# 遍历所有槽位
	for i in range(battle.enemy_sentence.size()):
		var enemy_text: String = battle.enemy_sentence[i]
		var player_word: WordData = battle.player_words[i] if i < battle.player_words.size() else null

		# 敌人文字 Label / Button
		var enemy_label: Control
		if player_word and player_word.can_be_shot:
			# 可射击：创建按钮，点击后触发射击
			var btn := Button.new()
			btn.text = enemy_text
			btn.modulate = player_word.highlight_color
			btn.pressed.connect(_on_enemy_word_clicked.bind(i))
			enemy_label = btn
		else:
			# 不可射击：普通 Label
			var lbl := Label.new()
			lbl.text = enemy_text
			lbl.modulate = Color.WHITE
			enemy_label = lbl

		enemy_container.add_child(enemy_label)

		# 玩家文字 Label
		var player_label := Label.new()
		if player_word:
			player_label.text = player_word.text
			player_label.modulate = player_word.highlight_color
		else:
			player_label.text = ""
		player_container.add_child(player_label)

# ==================== 事件 ====================
func _on_enemy_word_clicked(slot: int) -> void:
	var battle: BattleManager = get_parent() as BattleManager
	if battle:
		battle.player_shoot(slot)
