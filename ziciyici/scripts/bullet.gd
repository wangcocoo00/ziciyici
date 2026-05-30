# ============================================
# 文件: bullet.gd
# 功能: 子弹逻辑，包含飞行、边界反弹/销毁、碰撞伤害
# 依赖: 玩家节点需在 "player" group，敌人节点需在 "enemy" group
# 信号: bullet_finished() - 子弹销毁时发出
# ============================================

extends Area2D
class_name Bullet

## 子弹飞行速度（像素/秒）
@export var speed: float = 400.0

## 子弹飞行方向（归一化向量）
@export var direction: Vector2 = Vector2.LEFT

## 子弹伤害值
@export var damage: int = 99999

## 是否可伤害发射者自身（反弹后设为 true）
@export var can_hurt_shooter: bool = false

## 是否具有弹射能力（击中边界后反弹）
@export var is_ricochet: bool = false

## 子弹销毁时发出，通知管理器回收
signal bullet_finished()


func _ready() -> void:
	# 连接 area_entered 信号检测碰撞
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	# 安全校验：节点不在场景树中时不处理
	if not is_inside_tree():
		return

	# 更新子弹位置
	position += direction * speed * delta

	# 获取屏幕宽度用于边界检测
	var screen_width: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)

	# 左边界检测
	if position.x <= 0:
		if is_ricochet and not can_hurt_shooter:
			# 弹射：反转水平方向，标记可伤害发射者
			direction.x *= -1
			can_hurt_shooter = true
			return
		else:
			# 非弹射或已反弹过一次：销毁
			_destroy()
			return

	# 右边界检测
	if position.x >= screen_width:
		_destroy()
		return


## 碰撞检测回调
func _on_area_entered(area: Area2D) -> void:
	# 安全校验
	if not is_inside_tree():
		return

	# 与玩家碰撞（玩家需在 "player" group）
	if area.is_in_group("player") and not can_hurt_shooter:
		# 玩家扣血（假设玩家有 take_damage 方法）
		if area.has_method("take_damage"):
			area.take_damage(damage)
		_destroy()
		return

	# 与敌人碰撞且子弹可伤害发射者（反弹后）
	if area.is_in_group("enemy") and can_hurt_shooter:
		if area.has_method("take_damage"):
			area.take_damage(damage)
		_destroy()
		return


## 安全销毁子弹
func _destroy() -> void:
	# 断开信号避免重复触发
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)

	# 发出销毁信号
	bullet_finished.emit()

	# 从场景树移除
	queue_free()
