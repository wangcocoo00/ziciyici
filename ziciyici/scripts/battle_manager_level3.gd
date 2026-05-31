# ============================================
# 文件: battle_manager_level3.gd
# 功能: 第三关（小兔兔）战斗管理器
# 依赖: EnemyConfig, PlayerConfig, FoxTauntLibrary, WordData, EffectData, Bullet
# 信号: sentence_updated(), fox_taunt(message), battle_ended(victory)
# ============================================

extends Node2D
class_name BattleManagerLevel3

@onready var player_hp_label: Label = $PlayerHPLabel
@onready var enemy_hp_label: Label = $EnemyHPLabel

# ---------------------------------------------------------------------------
# 导出资源
# ---------------------------------------------------------------------------
@export var enemy_config: EnemyConfig
@export var player_config: PlayerConfig
@export var fox_taunt_library: FoxTauntLibrary
@export var bullet_scene: PackedScene
@export var next_level_scene: String = ""

# ---------------------------------------------------------------------------
# 运行时变量
# ---------------------------------------------------------------------------
var enemy_sentence: Array[String] = []
var enemy_words: Array[WordData] = []
var player_words: Array[WordData] = []
var enemy_hp: int = 0
var player_hp: int = 0
var player_attack_power: int = 0
var enemy_damage: int = 0
var shots_remaining: int = 0
var current_shoot_direction: Vector2 = Vector2.LEFT
var bullet_ricochet: bool = false
var bullet_can_hurt_self: bool = false
var is_jumping: bool = false
var is_dodging: bool = false
var shoot_mode_active: bool = false
var has_shot_this_turn: bool = false
var shot_slot: int = -1

# 第三关专用变量
## 第一次射击的颜色类型（"blue" 或 "yellow"），用于限制第二次射击只能同色
var first_shot_color: String = ""
## 是否已经完成第一次射击
var has_shot_once: bool = false
## 胜利按钮点击计数
var victory_btn_click_count: int = 0
## 胜利按钮是否已显示
var victory_btn_visible: bool = false
## 闪避按钮是否已解锁
var dodge_unlocked: bool = false
## 玩家子弹速度倍率（射击后变为2倍）
var player_bullet_speed_multiplier: float = 1.0
## 是否已显示"你跑再也没有用啦"标签
var has_shown_no_escape_label: bool = false
## 是否已显示鹅鹅想赢label
var has_shown_goose_label: bool = false
## 是否已触发10秒失败倒计时
var has_triggered_lose_timer: bool = false
## 是否已替换玩家精灵图
var has_switched_player_sprite: bool = false
## 玩家第二张精灵图（迷失后替换）
var player_sprite_alt: Texture2D = null

# ---------------------------------------------------------------------------
# 回合状态
# ---------------------------------------------------------------------------
enum State { PLAYER_TURN, ENEMY_TURN, GAME_OVER }
var current_state: State = State.PLAYER_TURN

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------
signal sentence_updated()
signal fox_taunt(message: String)
signal battle_ended(victory: bool)

# ---------------------------------------------------------------------------
# 内部变量
# ---------------------------------------------------------------------------
var _tween: Tween = null

# ===========================================================================
# 初始化
# ===========================================================================

func _ready() -> void:
	load_config()
	_setup_sprites()
	_update_all_button_states()

func _setup_sprites() -> void:
	var player_sprite: Sprite2D = $PlayerSprite
	var enemy_sprite: Sprite2D = $EnemySprite
	if player_sprite and player_config.sprite:
		player_sprite.texture = player_config.sprite
	if enemy_sprite and enemy_config.sprite:
		enemy_sprite.texture = enemy_config.sprite

func load_config() -> void:
	enemy_hp = enemy_config.hp
	player_hp = player_config.hp
	player_attack_power = player_config.base_attack
	enemy_damage = enemy_config.base_attack_damage
	shots_remaining = enemy_config.shots_allowed
	current_shoot_direction = enemy_config.base_shoot_direction
	bullet_ricochet = enemy_config.bullet_ricochet
	bullet_can_hurt_self = enemy_config.bullet_can_hurt_self

	# 加载敌人句子
	enemy_sentence.clear()
	enemy_words.clear()
	for word: WordData in enemy_config.sentence.words:
		enemy_sentence.append(word.text)
		enemy_words.append(word.duplicate())

	# 加载玩家句子
	player_words.clear()
	for word: WordData in player_config.sentence.words:
		player_words.append(word.duplicate())

	sentence_updated.emit()
	update_hp_display()

func update_hp_display() -> void:
	if player_hp_label:
		player_hp_label.text = "鹅鹅血量：" + str(player_hp)
	if enemy_hp_label:
		enemy_hp_label.text = "小兔兔血量：" + str(enemy_hp)

func _update_all_button_states() -> void:
	_update_shoot_button_style()
	_update_shoot_count_label()
	_set_button_always_enabled("ActionButtons/HBoxContainer/AttackBtn")
	# 闪避按钮：只有解锁后才可点击
	var dodge_btn = get_node_or_null("ActionButtons/HBoxContainer/DodgeBtn") as Button
	if dodge_btn:
		if dodge_unlocked:
			dodge_btn.modulate = Color(0.8, 0.8, 0.8, 1.0)
			dodge_btn.disabled = false
		else:
			dodge_btn.modulate = Color(0.3, 0.3, 0.3, 1.0)
			dodge_btn.disabled = true

func _set_button_always_enabled(path: String) -> void:
	var btn = get_node_or_null(path) as Button
	if not btn:
		return
	btn.modulate = Color(0.8, 0.8, 0.8, 1.0)
	btn.disabled = false

func _update_shoot_button_style() -> void:
	var shoot_btn = get_node_or_null("ActionButtons/HBoxContainer/ShootVBox/ShootBtn") as Button
	if not shoot_btn:
		return
	if shots_remaining <= 0:
		shoot_btn.modulate = Color(0.3, 0.3, 0.3, 1.0)
		shoot_btn.disabled = true
	elif shoot_mode_active:
		shoot_btn.modulate = Color(0.3, 0.3, 0.3, 1.0)
		shoot_btn.disabled = false
	else:
		shoot_btn.modulate = Color(0.8, 0.8, 0.8, 1.0)
		shoot_btn.disabled = false

func _update_shoot_count_label() -> void:
	var label = get_node_or_null("ActionButtons/HBoxContainer/ShootVBox/ShootCountLabel") as Label
	if label:
		label.text = "剩余: " + str(shots_remaining)

# ===========================================================================
# 玩家行动
# ===========================================================================

func player_shoot(slot: int) -> void:
	if current_state != State.PLAYER_TURN or shots_remaining <= 0:
		return
	if slot < 0 or slot >= player_words.size():
		return

	# 检查敌人对应槽位的字是否可射击
	if slot >= enemy_words.size() or not enemy_words[slot].can_be_shot:
		var msg: String = "狗屁不通！你是这样说话的吗！"
		if fox_taunt_library and not fox_taunt_library.taunts.is_empty():
			msg = fox_taunt_library.taunts[randi() % fox_taunt_library.taunts.size()]
		fox_taunt.emit(msg)
		return

	# 检查颜色一致性：第二次射击必须与第一次同色
	var current_color = _get_word_color(slot)
	if has_shot_once:
		if current_color != first_shot_color:
			var msg: String = "只能射击同一种颜色的字！"
			if fox_taunt_library and not fox_taunt_library.taunts.is_empty():
				msg = fox_taunt_library.taunts[randi() % fox_taunt_library.taunts.size()]
			fox_taunt.emit(msg)
			return
	else:
		# 第一次射击，记录颜色
		first_shot_color = current_color
		# 将另一种颜色的字变为白色且不可射击
		_disable_other_color_words(current_color)

	# 执行射击
	enemy_sentence[slot] = ""
	enemy_words[slot].text = ""
	enemy_words[slot].can_be_shot = false
	player_words[slot].text = ""
	player_words[slot].can_be_shot = false
	shots_remaining -= 1
	has_shot_this_turn = true
	shot_slot = slot
	shoot_mode_active = false
	_update_all_button_states()
	sentence_updated.emit()

	# 执行射击效果
	if not has_shot_once:
		# 第一次射击
		has_shot_once = true
		_first_shot_slot_saved = slot
		_execute_first_shot_effect(slot)
	else:
		# 第二次射击
		_execute_second_shot_effect(slot)

	if current_state != State.GAME_OVER:
		change_state(State.ENEMY_TURN)

## 获取某个槽位字的颜色类型
func _get_word_color(slot: int) -> String:
	if slot < 0 or slot >= enemy_words.size():
		return ""
	var color = enemy_words[slot].highlight_color
	# 蓝色：B分量 > 0.5 且 R分量 < 0.5
	if color.b > 0.5 and color.r < 0.5:
		return "blue"
	# 黄色：R和G分量都 > 0.5
	if color.r > 0.5 and color.g > 0.5:
		return "yellow"
	return ""

## 禁用另一种颜色的所有字的可射击状态
func _disable_other_color_words(chosen_color: String) -> void:
	for i in range(enemy_words.size()):
		var word_color = _get_word_color(i)
		if word_color != "" and word_color != chosen_color:
			enemy_words[i].can_be_shot = false
			enemy_words[i].highlight_color = Color.WHITE
			# 同步玩家句子对应槽位的颜色
			if i < player_words.size():
				player_words[i].highlight_color = Color.WHITE

# ===========================================================================
# 第一次射击效果
# ===========================================================================

func _execute_first_shot_effect(slot: int) -> void:
	match slot:
		1:  # 消除"跑"（槽位1）
			# 玩家句子对应槽位"想"被消除（已在player_shoot中处理）
			# 敌人攻击方式没有变化
			# 玩家攻击子弹速度变为2倍
			player_bullet_speed_multiplier = 2.0
			# 显示胜利按钮
			_show_victory_button()

		2:  # 消除"再"（槽位2）
			# 玩家句子对应槽位"赢"被消除
			# 敌人攻击方式没有变化
			player_bullet_speed_multiplier = 2.0
			# 显示胜利按钮
			_show_victory_button()

		3:  # 消除"快"（槽位3）
			# 玩家句子对应槽位"倒"被消除
			# 闪避按钮直接消失
			_hide_dodge_button()
			# 显示"你跑再也没有用啦"标签
			_show_no_escape_label()
			player_bullet_speed_multiplier = 2.0
			# 显示胜利按钮
			_show_victory_button()

		5:  # 消除"没"（槽位5）
			# 玩家句子对应槽位"没"被消除
			# 解锁闪避按钮
			dodge_unlocked = true
			_update_all_button_states()
			player_bullet_speed_multiplier = 2.0
			# 显示鹅鹅想赢label
			_show_goose_label()
			# 10秒后触发失败
			_start_lose_timer()

## 显示胜利按钮（在PlayerSprite附近）
func _show_victory_button() -> void:
	var victory_btn = get_node_or_null("ActionButtons/HBoxContainer/VictoryBtn") as Button
	if victory_btn:
		victory_btn.visible = true
		victory_btn_visible = true
		# 调整位置到PlayerSprite附近
		var player_sprite = $PlayerSprite as Sprite2D
		if player_sprite:
			victory_btn.position = Vector2(player_sprite.position.x + 6, player_sprite.position.y - 2)

## 隐藏闪避按钮
func _hide_dodge_button() -> void:
	var dodge_btn = get_node_or_null("ActionButtons/HBoxContainer/DodgeBtn") as Button
	if dodge_btn:
		dodge_btn.visible = false

## 显示"你跑再也没有用啦"标签
func _show_no_escape_label() -> void:
	if has_shown_no_escape_label:
		return
	has_shown_no_escape_label = true
	var enemy_sprite = $EnemySprite as Sprite2D
	if enemy_sprite:
		var label = Label.new()
		label.text = "你跑再也没有用啦，你只能在这里乖乖和兔战斗！"
		label.position = Vector2(enemy_sprite.position.x + 20, enemy_sprite.position.y - 20)
		label.add_theme_font_size_override("font_size", 20)
		label.modulate = Color(1, 1, 1, 1)
		add_child(label)

## 显示鹅鹅想赢label
func _show_goose_label() -> void:
	if has_shown_goose_label:
		return
	has_shown_goose_label = true
	var player_sprite = $PlayerSprite as Sprite2D
	if player_sprite:
		var label = Label.new()
		label.text = "鹅鹅想赢是问题，\n所以鹅鹅拼尽全力也无法胜利吗……"
		label.position = Vector2(player_sprite.position.x + 7, player_sprite.position.y - 5)
		label.add_theme_font_size_override("font_size", 18)
		label.modulate = Color(1, 1, 1, 1)
		add_child(label)

## 启动10秒失败倒计时
func _start_lose_timer() -> void:
	if has_triggered_lose_timer:
		return
	has_triggered_lose_timer = true
	var timer = get_tree().create_timer(10.0)
	timer.timeout.connect(func():
		if current_state != State.GAME_OVER:
			_show_lose_screen()
	)

## 显示迷失画面
func _show_lose_screen() -> void:
	current_state = State.GAME_OVER
	battle_ended.emit(false)
	var ui = $GameOverUI
	if not ui:
		return
	ui.visible = true
	var label = ui.get_node("ResultLabel") as Label
	if label:
		label.text = "鹅鹅就这样在危险的森林中迷失了自我，点击重新挑战拯救鹅鹅"
	var restart_btn = ui.get_node("RestartBtn") as Button
	if restart_btn:
		restart_btn.visible = true
	var next_btn = ui.get_node("NextLevelBtn") as Button
	if next_btn:
		next_btn.visible = false

# ===========================================================================
# 第二次射击效果
# ===========================================================================

func _execute_second_shot_effect(slot: int) -> void:
	# 使用保存的第一次射击槽位
	var first_shot_slot = _first_shot_slot_saved
	
	# 组合效果
	if (first_shot_slot == 1 and slot == 3) or (first_shot_slot == 3 and slot == 1):
		# 消除"跑"+"快"组合
		_handle_pao_kuai_combination()
	elif (first_shot_slot == 2 and slot == 5) or (first_shot_slot == 5 and slot == 2):
		# 消除"再"+"没"组合
		_handle_zai_mei_combination()
	else:
		# 其他组合（不应发生，因为颜色限制）
		pass

## 保存第一次射击的槽位（在player_shoot中设置）
var _first_shot_slot_saved: int = -1

## 处理"跑"+"快"组合
func _handle_pao_kuai_combination() -> void:
	# 玩家句子变成【我赢是没问题】
	# 显示2秒的EnemyExtraText
	var extra = $EnemyExtraText as Label
	if extra:
		extra.text = "鹅鹅相信，鹅鹅必胜！"
		extra.visible = true
	# 2秒后弹出胜利画面
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): _show_victory_screen())

## 处理"再"+"没"组合
func _handle_zai_mei_combination() -> void:
	# 玩家所有按钮置灰
	_disable_all_buttons()
	# 显示label
	var player_sprite = $PlayerSprite as Sprite2D
	if player_sprite:
		var label = Label.new()
		label.text = "鹅鹅想战斗，但鹅鹅真的困了"
		label.position = Vector2(player_sprite.position.x + 7, player_sprite.position.y - 5)
		label.add_theme_font_size_override("font_size", 18)
		label.modulate = Color(1, 1, 1, 1)
		add_child(label)
	# 替换玩家精灵图
	_switch_player_sprite()
	# 3秒后弹出迷失画面
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): _show_lose_screen())

## 禁用所有按钮
func _disable_all_buttons() -> void:
	var buttons = ["ActionButtons/HBoxContainer/AttackBtn", "ActionButtons/HBoxContainer/ShootVBox/ShootBtn", "ActionButtons/HBoxContainer/DodgeBtn", "ActionButtons/HBoxContainer/VictoryBtn"]
	for path in buttons:
		var btn = get_node_or_null(path) as Button
		if btn:
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3, 1.0)

## 替换玩家精灵图
func _switch_player_sprite() -> void:
	if has_switched_player_sprite:
		return
	has_switched_player_sprite = true
	var player_sprite = $PlayerSprite as Sprite2D
	if player_sprite and player_sprite_alt:
		player_sprite.texture = player_sprite_alt

## 显示胜利画面
func _show_victory_screen() -> void:
	current_state = State.GAME_OVER
	battle_ended.emit(true)
	var ui = $GameOverUI
	if not ui:
		return
	ui.visible = true
	var label = ui.get_node("ResultLabel") as Label
	if label:
		label.text = "如果是语言赋予了小动物们沟通与理解的契机，那在只此一次的相遇中，用「字此一次」去伤害，而不是去爱，会不会太过可惜？\n如果文字拥有改变世界的能力，那使用言灵之力的副作用，是不是也迷失了自己？\n小企鹅想知道：你呢？如果你也能改变别人的话语，你会冒着忘记自我的副作用，去施暴？还是拥抱？"
	var restart_btn = ui.get_node("RestartBtn") as Button
	if restart_btn:
		restart_btn.visible = true
	var next_btn = ui.get_node("NextLevelBtn") as Button
	if next_btn:
		next_btn.visible = false  # 第三关没有下一关，显示"感谢游玩"
		next_btn.text = "感谢游玩"
		next_btn.visible = true

# ===========================================================================
# 玩家攻击（发射子弹）
# ===========================================================================

func player_attack() -> void:
	if current_state != State.PLAYER_TURN:
		return
	# 从玩家发射黑色子弹到敌人
	_spawn_player_bullet()
	# 攻击后切换到敌人回合
	if current_state != State.GAME_OVER:
		change_state(State.ENEMY_TURN)

## 生成玩家子弹
func _spawn_player_bullet() -> void:
	var bullet: Bullet = bullet_scene.instantiate() as Bullet
	bullet.position = $PlayerSprite.position
	bullet.damage = player_attack_power
	bullet.direction = Vector2.RIGHT  # 向右射向敌人
	bullet.can_hurt_shooter = false
	bullet.is_ricochet = false
	bullet.speed = 800.0 * player_bullet_speed_multiplier
	bullet.modulate = Color.BLACK  # 黑色子弹
	add_child(bullet)
	bullet.bullet_finished.connect(_on_player_bullet_finished)

## 玩家子弹销毁回调
func _on_player_bullet_finished() -> void:
	# 玩家子弹击中敌人后扣血
	enemy_hp -= player_attack_power
	update_hp_display()
	check_victory()

# ===========================================================================
# 敌人回合
# ===========================================================================

func _on_enemy_turn() -> void:
	var bullet: Bullet = bullet_scene.instantiate() as Bullet
	bullet.position = $EnemySprite.position
	bullet.damage = enemy_damage
	bullet.direction = Vector2.LEFT  # 向左射向玩家
	bullet.can_hurt_shooter = bullet_can_hurt_self
	bullet.is_ricochet = bullet_ricochet
	bullet.modulate = Color.WHITE  # 白色子弹
	add_child(bullet)
	bullet.bullet_finished.connect(_on_bullet_finished)

func _on_bullet_finished() -> void:
	check_victory()
	if current_state != State.GAME_OVER:
		change_state(State.PLAYER_TURN)

# ===========================================================================
# 胜负判定
# ===========================================================================

func check_victory() -> void:
	update_hp_display()
	if enemy_hp <= 0:
		current_state = State.GAME_OVER
		battle_ended.emit(true)
		_show_victory_screen()
	elif player_hp <= 0:
		current_state = State.GAME_OVER
		battle_ended.emit(false)
		_show_lose_screen()

# ===========================================================================
# 状态管理
# ===========================================================================

func change_state(new_state: State) -> void:
	current_state = new_state
	_update_all_button_states()
	if new_state == State.ENEMY_TURN:
		_on_enemy_turn()

# ===========================================================================
# 按钮回调
# ===========================================================================

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_next_level_pressed() -> void:
	if next_level_scene != "":
		get_tree().change_scene_to_file(next_level_scene)

func _on_shoot_pressed() -> void:
	if current_state != State.PLAYER_TURN or shots_remaining <= 0:
		return
	shoot_mode_active = not shoot_mode_active
	_update_all_button_states()
	sentence_updated.emit()

func _on_attack_pressed() -> void:
	player_attack()

func _on_dodge_pressed() -> void:
	if current_state != State.PLAYER_TURN or is_dodging or not dodge_unlocked:
		return
	is_dodging = true
	change_state(State.ENEMY_TURN)

func _on_victory_pressed() -> void:
	if current_state != State.PLAYER_TURN:
		return
	victory_btn_click_count += 1
	if victory_btn_click_count >= 5:
		enemy_hp = 0
		update_hp_display()
		_show_victory_screen()
