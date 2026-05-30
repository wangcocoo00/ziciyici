class_name BattleManagerLevel2
extends Node2D

@export var enemy_config: EnemyConfig
@export var player_config: PlayerConfig
@export var fox_taunt_library: FoxTauntLibrary
@export var next_level_scene: String = ""

var enemy_sentence: Array[String] = []
var player_words: Array[WordData] = []
var player_hp: int = 0
var enemy_hp: int = 0
var player_attack_power: int = 0
var player_jump_height: float = 0.0
var shots_remaining: int = 1
var battle_ended: bool = false
var is_jumping: bool = false
var _tween: Tween = null

signal sentence_updated()
signal fox_taunt(message: String)

func _ready() -> void:
	load_config()
	sentence_updated.emit()

func load_config() -> void:
	enemy_sentence.clear()
	for word in enemy_config.sentence.words:
		enemy_sentence.append(word.text)
	player_words.clear()
	for word in player_config.sentence.words:
		player_words.append(word.duplicate())
	shots_remaining = enemy_config.shots_allowed
	player_hp = player_config.hp
	enemy_hp = enemy_config.hp
	player_attack_power = player_config.base_attack
	player_jump_height = player_config.base_jump_height

func player_shoot(slot: int) -> void:
	if battle_ended or shots_remaining <= 0:
		return
	if slot < 0 or slot >= player_words.size():
		return

	var word = player_words[slot]
	if not word.can_be_shot:
		var msg = "狗屁不通！你是这样说话的吗！"
		if fox_taunt_library and not fox_taunt_library.taunts.is_empty():
			msg = fox_taunt_library.taunts[randi() % fox_taunt_library.taunts.size()]
		fox_taunt.emit(msg)
		return

	# 双向删除
	enemy_sentence[slot] = ""
	player_words[slot].text = ""
	player_words[slot].can_be_shot = false
	shots_remaining -= 1
	sentence_updated.emit()

	# 检查效果中的 ending 标记
	for effect in word.shot_effects:
		if effect.type == EffectData.EffectType.MODIFY_ATTRIBUTE and effect.target == EffectData.Target.ENEMY and effect.attribute == "ending":
			if int(effect.value) == 1:
				end_game(true, "熊熊小王良心发现，决定今天减肥", "好吧，你可以活着通过")
			elif int(effect.value) == 2:
				end_game(false, "熊熊小王是语言的主宰，你今天就是要被吃掉", "即使你能闪避，但我还是决定你要被我吃掉")
			return

func end_game(victory: bool, result_text: String, enemy_text: String) -> void:
	battle_ended = true
	var extra = $EnemyExtraText as Label
	if extra:
		extra.text = enemy_text
		extra.visible = true
	var ui = $GameOverUI
	if ui:
		ui.visible = true
		var label = ui.get_node("ResultLabel") as Label
		if label:
			label.text = result_text
		var restart = ui.get_node("RestartBtn") as Button
		if restart:
			restart.visible = true
		var next_btn = ui.get_node("NextLevelBtn") as Button
		if next_btn:
			next_btn.visible = victory and not next_level_scene.is_empty()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_next_level_pressed() -> void:
	if not next_level_scene.is_empty():
		get_tree().change_scene_to_file(next_level_scene)

func _on_shoot_pressed() -> void:
	print("请点击敌人句子中的有色字")

func _on_attack_pressed() -> void:
	print("攻击按钮被点击了")
	if battle_ended:
		return
	enemy_hp -= player_attack_power
	if enemy_hp <= 0:
		end_game(true, "熊熊小王被击败了！", "啊！我输了...")
	else:
		print("敌人剩余血量：", enemy_hp)

func _on_jump_pressed() -> void:
	print("跳跃按钮被点击了")
	if battle_ended or is_jumping:
		return

	is_jumping = true
	var player_node: Sprite2D = $PlayerSprite
	if not player_node:
		print("错误：找不到 PlayerSprite 节点！")
		is_jumping = false
		return

	var start_y: float = player_node.position.y

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)

	# 上升
	_tween.tween_property(player_node, "position:y", start_y - player_jump_height, 0.5)
	# 下落
	_tween.tween_property(player_node, "position:y", start_y, 0.5)

	_tween.finished.connect(_on_jump_finished)

func _on_jump_finished() -> void:
	is_jumping = false
	_tween = null
