class_name Bullet
extends Area2D

@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.LEFT
@export var damage: int = 99999
@export var can_hurt_shooter: bool = false
@export var is_ricochet: bool = false

const LEFT_WALL_X: float = 0.0
var screen_width: float = 1024.0
var battle_ref: BattleManager = null

signal bullet_finished()

func _ready() -> void:
	var viewport_rect = get_viewport().get_visible_rect()
	screen_width = viewport_rect.size.x
	battle_ref = get_parent() as BattleManager

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	# 边界反弹或销毁
	if position.x <= LEFT_WALL_X:
		if is_ricochet and not can_hurt_shooter:
			direction.x *= -1
			can_hurt_shooter = true
			position.x = LEFT_WALL_X + 1
		else:
			queue_free_and_emit()
			return
	if position.x >= screen_width:
		queue_free_and_emit()
		return

	# 手动距离检测碰撞
	if not battle_ref or not is_inside_tree():
		return

	# 检查是否碰到玩家
	var player_sprite = battle_ref.get_node_or_null("PlayerSprite") as Sprite2D
	if player_sprite and not battle_ref.is_jumping:
		if position.distance_to(player_sprite.position) < 30.0:
			battle_ref.player_hp -= damage
			battle_ref.update_hp_display()
			battle_ref.check_victory()
			# 玩家向后挪50像素
			player_sprite.position.x -= 50
			queue_free_and_emit()
			return

	# 检查是否碰到敌人
	var enemy_sprite = battle_ref.get_node_or_null("EnemySprite") as Sprite2D
	if enemy_sprite and can_hurt_shooter:
		if position.distance_to(enemy_sprite.position) < 30.0:
			battle_ref.enemy_hp -= damage
			battle_ref.update_hp_display()
			battle_ref.check_victory()
			queue_free_and_emit()
			return

func queue_free_and_emit() -> void:
	if is_inside_tree():
		queue_free()
	bullet_finished.emit()
