# ============================================
# 文件: battle_manager.gd
# 功能: 战斗管理器，管理玩家与敌人的回合制战斗逻辑
# 依赖: EnemyConfig, PlayerConfig, FoxTauntLibrary, WordData, EffectData, Bullet
# 信号: sentence_updated(), fox_taunt(message), battle_ended(victory), player_jump_started(height)
# ============================================

extends Node2D
class_name BattleManager
@onready var player_hp_label: Label = $PlayerHPLabel
@onready var enemy_hp_label: Label = $EnemyHPLabel

# ---------------------------------------------------------------------------
# 导出资源（在 Godot 编辑器中拖入）
# ---------------------------------------------------------------------------

## 敌人配置资源
@export var enemy_config: EnemyConfig

## 玩家配置资源
@export var player_config: PlayerConfig

## 狐狸嘲讽台词库
@export var fox_taunt_library: FoxTauntLibrary

## 子弹场景（PackedScene，需包含 Bullet 脚本）
@export var bullet_scene: PackedScene

@export var next_level_scene: String = ""

# ---------------------------------------------------------------------------
# 运行时变量（从配置加载）
# ---------------------------------------------------------------------------

## 敌人句子文字数组（仅用于显示）
var enemy_sentence: Array[String] = []

## 敌人句子 WordData 数组（用于检查可射击状态）
var enemy_words: Array[WordData] = []

## 玩家句子 WordData 数组（射击时需要 effects）
var player_words: Array[WordData] = []

## 敌人当前生命值
var enemy_hp: int = 0

## 玩家当前生命值
var player_hp: int = 0

## 玩家基础攻击力
var player_attack_power: int = 0

## 敌人子弹伤害
var enemy_damage: int = 0

## 玩家跳跃高度
var player_jump_height: float = 0.0

## 玩家剩余可射击次数
var shots_remaining: int = 0

## 敌人当前射击方向
var current_shoot_direction: Vector2 = Vector2.LEFT

## 敌人子弹是否弹射
var bullet_ricochet: bool = false

## 敌人子弹是否可伤害自身
var bullet_can_hurt_self: bool = false

## 玩家是否正在跳跃中
var is_jumping: bool = false

## 射击模式状态：true=已激活（可点击有色字），false=未激活（点击有色字无反应）
var shoot_mode_active: bool = false

## 敌人攻击模式：true=投掷红色圆球（初始），false=普通子弹（射"雷"后改变）
var enemy_attack_mode_red_ball: bool = true

## 标记是否已射击（用于在敌人回合特殊处理）
var has_shot_this_turn: bool = false

## 当前射击的槽位（用于敌人回合判断）
var shot_slot: int = -1

# ---------------------------------------------------------------------------
# 回合状态
# ---------------------------------------------------------------------------

## 战斗回合状态枚举
enum State { PLAYER_TURN, ENEMY_TURN, GAME_OVER }

## 当前回合状态
var current_state: State = State.PLAYER_TURN

# ---------------------------------------------------------------------------
# 信号
# ---------------------------------------------------------------------------

## 句子显示更新时发出（射击后刷新 UI）
signal sentence_updated()

## 狐狸嘲讽时发出，携带嘲讽文本
signal fox_taunt(message: String)

## 战斗结束时发出，victory 为 true 表示玩家胜利
signal battle_ended(victory: bool)

## 玩家开始跳跃时发出，携带跳跃高度
signal player_jump_started(height: float)

# ---------------------------------------------------------------------------
# 内部变量
# ---------------------------------------------------------------------------

## 当前运行的 Tween，用于退出时清理
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

## 从配置资源加载所有运行时变量
func load_config() -> void:
	# 基础属性
	enemy_hp = enemy_config.hp
	player_hp = player_config.hp
	player_attack_power = player_config.base_attack
	enemy_damage = enemy_config.base_attack_damage
	player_jump_height = player_config.base_jump_height
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

	# 加载玩家句子（完整 WordData，需要 duplicate 避免修改原资源）
	player_words.clear()
	for word: WordData in player_config.sentence.words:
		player_words.append(word.duplicate())

	sentence_updated.emit()
	update_hp_display()

func update_hp_display() -> void:
	if player_hp_label:
		player_hp_label.text = "鹅鹅血量：" + str(player_hp)
	if enemy_hp_label:
		enemy_hp_label.text = "小兰血量：" + str(enemy_hp)

## 更新所有按钮的状态
func _update_all_button_states() -> void:
	_update_shoot_button_style()
	_update_shoot_count_label()
	# 攻击/跳跃按钮始终为可点击的灰白色（不受回合状态影响）
	_set_button_always_enabled("ActionButtons/HBoxContainer/AttackBtn")
	_set_button_always_enabled("ActionButtons/HBoxContainer/JumpBtn")
	# 射击按钮路径在 ShootVBox 中，由 _update_shoot_button_style 处理

## 设置按钮始终为可点击的灰白色
func _set_button_always_enabled(path: String) -> void:
	var btn = get_node_or_null(path) as Button
	if not btn:
		return
	btn.modulate = Color(0.8, 0.8, 0.8, 1.0)  # 灰白色
	btn.disabled = false

## 更新射击按钮的样式
## 三种状态：
##   - 未激活（灰白色，可点击）：shoot_mode_active=false, shots_remaining>0
##   - 激活（灰黑色，可点击）：shoot_mode_active=true, shots_remaining>0
##   - 已用完（灰黑色，disabled）：shots_remaining<=0
func _update_shoot_button_style() -> void:
	var shoot_btn = get_node_or_null("ActionButtons/HBoxContainer/ShootVBox/ShootBtn") as Button
	if not shoot_btn:
		return
	if shots_remaining <= 0:
		# 已用完：灰黑色，不可点击
		shoot_btn.modulate = Color(0.3, 0.3, 0.3, 1.0)
		shoot_btn.disabled = true
	elif shoot_mode_active:
		# 激活：灰黑色，可点击
		shoot_btn.modulate = Color(0.3, 0.3, 0.3, 1.0)
		shoot_btn.disabled = false
	else:
		# 未激活：灰白色，可点击
		shoot_btn.modulate = Color(0.8, 0.8, 0.8, 1.0)
		shoot_btn.disabled = false

## 更新剩余射击次数显示
func _update_shoot_count_label() -> void:
	var label = get_node_or_null("ActionButtons/HBoxContainer/ShootVBox/ShootCountLabel") as Label
	if label:
		label.text = "剩余: " + str(shots_remaining)

# ===========================================================================
# 玩家行动
# ===========================================================================

## 玩家射击指定槽位的字
## @param slot: 字在 player_words 中的索引
func player_shoot(slot: int) -> void:
	# 状态检查
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

	# 执行射击：清除敌人对应位置的字，标记敌人字和玩家字已使用
	enemy_sentence[slot] = ""
	enemy_words[slot].text = ""
	enemy_words[slot].can_be_shot = false
	player_words[slot].text = ""
	player_words[slot].can_be_shot = false
	shots_remaining -= 1
	has_shot_this_turn = true
	shot_slot = slot
	# 射击后退出射击模式
	shoot_mode_active = false
	_update_all_button_states()
	sentence_updated.emit()

	# 根据槽位执行特殊效果
	_execute_shot_effect(slot)

	# 切换到敌人回合（如果还没结束的话）
	if current_state != State.GAME_OVER:
		change_state(State.ENEMY_TURN)


## 执行射击效果（根据槽位）
func _execute_shot_effect(slot: int) -> void:
	match slot:
		0:
			# 射"手"：双方上方闪电动画2秒，双方各扣250血
			_play_lightning_animation()
			enemy_hp -= 250
			player_hp -= 250
			update_hp_display()
			check_victory()

		1:
			# 射"雷"：敌人伤害变0（只触发后挪动画，不扣血），从玩家发射黄色球到敌人，敌人右侧显示文字
			enemy_damage = 0
			enemy_attack_mode_red_ball = false
			# 从玩家发射黄色球到敌人
			_spawn_projectile($PlayerSprite.position, $EnemySprite.position, Color.YELLOW, 0, false)
			# 在敌人右侧显示文字
			_show_label_near_node($EnemySprite, "对方限制行动一回合", Vector2(80, 0))

		6:
			# 射"跑"：从敌人发射无伤害红球到玩家左侧，显示文字，敌人HP归零
			var target_pos = $PlayerSprite.position + Vector2(-10, 0)
			_spawn_projectile($EnemySprite.position, target_pos, Color.RED, 0, false)
			_show_label_near_node($PlayerSprite, "闪避生效，你死吧！", Vector2(-120, -40))
			enemy_hp = 0
			update_hp_display()
			# 直接胜利，显示 EnemyExtraText 2秒后再显示 GameOverUI
			current_state = State.GAME_OVER
			battle_ended.emit(true)
			_show_victory_with_delay("护士小狗钦佩于鹅鹅冒险的勇气，决心跟随鹅鹅一起冒险")


## 播放闪电渐现渐隐闪烁动画（在敌我双方上方）
func _play_lightning_animation() -> void:
	var lightning = ColorRect.new()
	lightning.color = Color(1, 1, 0.8, 0.9)  # 亮黄色
	lightning.size = Vector2(1600, 100)
	lightning.position = Vector2(0, 100)  # 在双方上方
	lightning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lightning)

	var tween = create_tween()
	# 闪烁效果：快速交替透明度
	tween.tween_property(lightning, "modulate:a", 0.1, 0.1)
	tween.tween_property(lightning, "modulate:a", 0.9, 0.1)
	tween.tween_property(lightning, "modulate:a", 0.1, 0.1)
	tween.tween_property(lightning, "modulate:a", 0.9, 0.1)
	tween.tween_property(lightning, "modulate:a", 0.1, 0.1)
	tween.tween_property(lightning, "modulate:a", 0.9, 0.1)
	tween.tween_property(lightning, "modulate:a", 0.1, 0.1)
	tween.tween_property(lightning, "modulate:a", 0.9, 0.1)
	tween.tween_property(lightning, "modulate:a", 0.0, 0.2).set_delay(0.2)
	tween.finished.connect(func(): lightning.queue_free())


## 生成一个从起点到终点的投射物
## @param from: 起始位置
## @param to: 目标位置
## @param color: 颜色
## @param damage: 伤害（0=无伤害）
## @param hurt_target: 是否伤害目标
func _spawn_projectile(from: Vector2, to: Vector2, color: Color, damage: int, hurt_target: bool) -> void:
	var projectile = ColorRect.new()
	projectile.color = color
	projectile.size = Vector2(16, 16)
	projectile.position = from - Vector2(8, 8)
	projectile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(projectile)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(projectile, "position", to - Vector2(8, 8), 0.5)
	tween.finished.connect(func():
		projectile.queue_free()
		if damage > 0 and hurt_target:
			# 如果投射物到达敌人位置
			if to == $EnemySprite.position:
				enemy_hp -= damage
				update_hp_display()
				check_victory()
			elif to == $PlayerSprite.position or abs(to.x - $PlayerSprite.position.x) < 20:
				player_hp -= damage
				update_hp_display()
				check_victory()
	)


## 在节点附近显示一个 Label
## @param node: 参考节点
## @param text: 显示文字
## @param offset: 相对节点的偏移
func _show_label_near_node(node: Node2D, text: String, offset: Vector2) -> void:
	var label = Label.new()
	label.text = text
	label.position = node.position + offset
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color(1, 1, 1, 1)
	add_child(label)

	# 2秒后淡出消失
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func(): label.queue_free())


## 应用单个效果到对应目标
## @param effect: 要应用的效果数据
func apply_effect(effect: EffectData) -> void:
	match effect.type:
		EffectData.EffectType.MODIFY_ATTRIBUTE:
			if effect.target == EffectData.Target.ENEMY and effect.attribute == "attack_damage":
				enemy_damage = int(effect.value)
			elif effect.target == EffectData.Target.PLAYER and effect.attribute == "jump_height":
				player_jump_height = effect.value
			elif effect.target == EffectData.Target.ENEMY and effect.attribute == "hp":
				enemy_hp -= int(effect.value)
				update_hp_display()
				check_victory()
			elif effect.target == EffectData.Target.PLAYER and effect.attribute == "hp":
				player_hp -= int(effect.value)
				update_hp_display()
				check_victory()

		EffectData.EffectType.CHANGE_SHOOT_DIRECTION:
			if effect.target == EffectData.Target.ENEMY:
				current_shoot_direction = effect.direction

		EffectData.EffectType.SET_TAG:
			if effect.target == EffectData.Target.ENEMY:
				if effect.tag == "ricochet":
					bullet_ricochet = true
				elif effect.tag == "can_hurt_shooter":
					bullet_can_hurt_self = true


## 玩家普通攻击（直接扣敌人血）
func player_attack() -> void:
	if current_state != State.PLAYER_TURN:
		return

	enemy_hp -= player_attack_power
	update_hp_display()  
	check_victory()
		

	if current_state != State.GAME_OVER:
		change_state(State.ENEMY_TURN)


## 玩家跳跃
## 跳跃动画完成后自动切换到敌人回合

func player_jump() -> void:
	if current_state != State.PLAYER_TURN or is_jumping:
		return

	is_jumping = true
	player_jump_started.emit(player_jump_height)

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

## 跳跃完成回调
func _on_jump_finished() -> void:
	is_jumping = false
	_tween = null

	if current_state != State.GAME_OVER:
		change_state(State.ENEMY_TURN)


# ===========================================================================
# 敌人回合
# ===========================================================================

## 敌人回合：发射子弹
func _on_enemy_turn() -> void:
	# 实例化子弹
	var bullet: Bullet = bullet_scene.instantiate() as Bullet
	bullet.position = $EnemySprite.position  # 从敌人位置发射
	# 如果子弹方向是斜上方，稍微调整发射点
	if current_shoot_direction.y < 0:
		bullet.position.y -= 20

	# 设置子弹属性
	bullet.damage = enemy_damage
	bullet.direction = current_shoot_direction
	bullet.can_hurt_shooter = bullet_can_hurt_self
	bullet.is_ricochet = bullet_ricochet

	# 如果是红色圆球模式，设置子弹颜色为红色
	if enemy_attack_mode_red_ball:
		bullet.modulate = Color.RED

	# 添加到场景
	add_child(bullet)

	# 监听子弹销毁信号
	bullet.bullet_finished.connect(_on_bullet_finished)


## 子弹销毁回调
func _on_bullet_finished() -> void:
	check_victory()

	if current_state != State.GAME_OVER:
		change_state(State.PLAYER_TURN)


# ===========================================================================
# 胜负判定
# ===========================================================================

## 检查双方生命值，判定胜负
func check_victory() -> void:
	update_hp_display()
	if enemy_hp <= 0:
		current_state = State.GAME_OVER
		battle_ended.emit(true)
		_show_game_over(true)
	elif player_hp <= 0:
		current_state = State.GAME_OVER
		battle_ended.emit(false)
		_show_game_over(false)


# ===========================================================================
# 状态管理
# ===========================================================================

## 切换到新状态
## @param new_state: 目标状态
func change_state(new_state: State) -> void:
	current_state = new_state
	_update_all_button_states()

	if new_state == State.ENEMY_TURN:
		_on_enemy_turn()


# ===========================================================================
# 生命周期与防御
# ===========================================================================

## 显示胜利文字2秒后再显示 GameOverUI
func _show_victory_with_delay(enemy_text: String) -> void:
	var extra = $EnemyExtraText as Label
	if extra:
		extra.text = enemy_text
		extra.visible = true
	# 2秒后显示 GameOverUI
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): _show_game_over(true))

## 显示游戏结束界面
func _show_game_over(victory: bool) -> void:
	var ui = $GameOverUI
	if not ui:
		return
	ui.visible = true
	var label = ui.get_node("ResultLabel") as Label
	if label:
		label.text = "熊熊小王良心发现，今天决定减肥，不吃肉了"
	var restart_btn = ui.get_node("RestartBtn") as Button
	if restart_btn:
		restart_btn.visible = true
	var next_btn = ui.get_node("NextLevelBtn") as Button
	if next_btn:
		next_btn.visible = victory and not next_level_scene.is_empty()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_next_level_pressed() -> void:
	if next_level_scene != "":
		get_tree().change_scene_to_file(next_level_scene)


func _on_jump_pressed() -> void:
	player_jump()


func _on_shoot_pressed() -> void:
	if current_state != State.PLAYER_TURN or shots_remaining <= 0:
		return
	# 切换射击模式状态
	shoot_mode_active = not shoot_mode_active
	_update_all_button_states()
	# 刷新句子显示，更新有色字可点击状态
	sentence_updated.emit()


func _on_attack_pressed() -> void:
	print("攻击按钮被点击了")
	player_attack()
