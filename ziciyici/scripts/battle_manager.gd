# ============================================
# 文件: battle_manager.gd
# 功能: 战斗管理器，管理玩家与敌人的回合制战斗逻辑
# 依赖: EnemyConfig, PlayerConfig, FoxTauntLibrary, WordData, EffectData, Bullet
# 信号: sentence_updated(), fox_taunt(message), battle_ended(victory), player_jump_started(height)
# ============================================

extends Node2D
class_name BattleManager

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

# ---------------------------------------------------------------------------
# 运行时变量（从配置加载）
# ---------------------------------------------------------------------------

## 敌人句子文字数组（仅用于显示）
var enemy_sentence: Array[String] = []

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

	# 加载敌人句子（仅文字）
	enemy_sentence.clear()
	for word: WordData in enemy_config.sentence.words:
		enemy_sentence.append(word.text)

	# 加载玩家句子（完整 WordData，需要 duplicate 避免修改原资源）
	player_words.clear()
	for word: WordData in player_config.sentence.words:
		player_words.append(word.duplicate())


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

	var word: WordData = player_words[slot]

	# 该字不可射击时触发狐狸嘲讽
	if not word.can_be_shot:
		var msg: String = "狗屁不通！你是这样说话的吗！"
		if fox_taunt_library and not fox_taunt_library.taunts.is_empty():
			msg = fox_taunt_library.taunts[randi() % fox_taunt_library.taunts.size()]
		fox_taunt.emit(msg)
		return

	# 执行射击：清除敌人对应位置的字，标记玩家字已使用
	enemy_sentence[slot] = ""
	player_words[slot].text = ""
	player_words[slot].can_be_shot = false
	shots_remaining -= 1
	sentence_updated.emit()

	# 应用该字绑定的所有效果
	for effect: EffectData in word.shot_effects:
		apply_effect(effect)

	# 切换到敌人回合
	change_state(State.ENEMY_TURN)


## 应用单个效果到对应目标
## @param effect: 要应用的效果数据
func apply_effect(effect: EffectData) -> void:
	match effect.type:
		EffectData.EffectType.MODIFY_ATTRIBUTE:
			if effect.target == EffectData.Target.ENEMY and effect.attribute == "attack_damage":
				enemy_damage = int(effect.value)
			elif effect.target == EffectData.Target.PLAYER and effect.attribute == "jump_height":
				player_jump_height = effect.value

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

	# 获取玩家精灵节点（假设在场景中路径为 ../PlayerSprite）
	var player_node: Node2D = get_node("../PlayerSprite") as Node2D
	if not player_node:
		is_jumping = false
		return

	var start_y: float = player_node.position.y

	# 创建跳跃动画 Tween
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)

	# 上升
	_tween.tween_property(player_node, "position:y", start_y - player_jump_height, 0.5)
	# 下落
	_tween.tween_property(player_node, "position:y", start_y, 0.5)

	# 动画完成后恢复状态并切换回合
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
	if not bullet:
		return

	# 设置子弹属性
	bullet.damage = enemy_damage
	bullet.direction = current_shoot_direction
	bullet.can_hurt_shooter = bullet_can_hurt_self
	bullet.is_ricochet = bullet_ricochet

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
	if enemy_hp <= 0:
		current_state = State.GAME_OVER
		battle_ended.emit(true)
	elif player_hp <= 0:
		current_state = State.GAME_OVER
		battle_ended.emit(false)


# ===========================================================================
# 状态管理
# ===========================================================================

## 切换到新状态
## @param new_state: 目标状态
func change_state(new_state: State) -> void:
	current_state = new_state

	if new_state == State.ENEMY_TURN:
		_on_enemy_turn()


# ===========================================================================
# 生命周期与防御
# ===========================================================================

## 节点退出场景树时清理 Tween，防止内存泄漏
func _exit_tree() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

func _on_attack_pressed() -> void:
	player_attack()
	


func _on_jump_pressed() -> void:
	player_jump()


func _on_shoot_pressed() -> void:
	print("请点击敌人头顶的有色字进行射击")
