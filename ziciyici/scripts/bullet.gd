class_name Bullet
extends Area2D

# ==================== 属性 ====================
@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.LEFT
@export var damage: int = 99999
@export var can_hurt_shooter: bool = false
@export var is_ricochet: bool = false

# 屏幕宽度边界（左墙为反弹镜，右墙子弹消失）
const LEFT_WALL_X: float = 0.0
var screen_width: float = 1024.0  # 默认，会在 _ready 中获取实际值

# ==================== 信号 ====================
signal bullet_finished()

# ==================== 初始化 ====================
func _ready() -> void:
	# 获取实际视口宽度
	var viewport_rect = get_viewport().get_visible_rect()
	screen_width = viewport_rect.size.x
	# 设置初始位置（从敌人位置发射，脚本外部设置 position）

# ==================== 物理更新 ====================
func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	# 左边界反弹或销毁
	if position.x <= LEFT_WALL_X:
		if is_ricochet and not can_hurt_shooter:
			direction.x *= -1
			can_hurt_shooter = true
			# 反弹后稍微进入安全区域防止再次触发
			position.x = LEFT_WALL_X + 1
		else:
			queue_free()
			bullet_finished.emit()
			return

	# 右边界销毁
	if position.x >= screen_width:
		queue_free()
		bullet_finished.emit()
		return

# ==================== 碰撞检测 ====================
func _on_area_entered(area: Area2D) -> void:
	# 这个方法在子弹的 Area2D 与其他 Area2D 重叠时调用
	# 我们需要判断碰撞对象是玩家还是敌人，并造成伤害
	_check_hit(area)

func _on_body_entered(body: Node2D) -> void:
	# 如果子弹的碰撞层设置为与身体碰撞，这里会触发
	_check_hit(body)

func _check_hit(node: Node) -> void:
	if not is_inside_tree():
		return

	# 获取 BattleManager
	var battle: BattleManager = get_parent() as BattleManager
	if not battle:
		queue_free()
		bullet_finished.emit()
		return

	# 判断是否碰到玩家
	if node.name == "PlayerSprite":
		if not battle.is_jumping:
			battle.player_hp -= damage
			battle.check_victory()
			queue_free()
			bullet_finished.emit()
		return

	# 判断是否碰到敌人
	if node.name == "EnemySprite" and can_hurt_shooter:
		battle.enemy_hp -= damage
		battle.check_victory()
		queue_free()
		bullet_finished.emit()
		return
