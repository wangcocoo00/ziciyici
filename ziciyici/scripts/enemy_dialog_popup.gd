# ============================================
# 文件: enemy_dialog_popup.gd
# 功能: 敌人对话弹窗，从屏幕上方滑入显示台词，停留后滑出
# 依赖: 场景中需包含 EnemyDialogSprite (Sprite2D) 和 EnemyDialogBubble (Label) 子节点
# 信号: 无
# ============================================

extends CanvasLayer
class_name EnemyDialogPopup

## 是否正在显示对话弹窗
var is_showing: bool = false

## 敌人形象精灵
@onready var enemy_dialog_sprite: Sprite2D = $EnemyDialogSprite

## 对话气泡文本标签
@onready var enemy_dialog_bubble: Label = $EnemyDialogBubble

## 存储当前运行的 Tween，用于退出时清理
var _tween: Tween = null


## 显示敌人对话台词
## 若正在显示则忽略本次调用
## @param message: 要显示的台词文本
func show_dialog(message: String) -> void:
	# 正在显示中则忽略
	if is_showing:
		return

	is_showing = true

	# 设置文本
	enemy_dialog_bubble.text = message

	# 创建 Tween 动画
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BOUNCE)
	_tween.set_ease(Tween.EASE_OUT)

	# 从 y=-100 滑入到 y=200
	_tween.tween_property(enemy_dialog_sprite, "position:y", 200.0, 0.6)

	# 停留 2 秒
	_tween.tween_interval(2.0)

	# 滑出到 y=-100
	_tween.tween_property(enemy_dialog_sprite, "position:y", -100.0, 0.5)

	# 动画完成后重置状态
	_tween.finished.connect(_on_dialog_finished)


## 对话动画完成回调
func _on_dialog_finished() -> void:
	is_showing = false
	_tween = null


## 节点退出场景树时清理 Tween，防止内存泄漏
func _exit_tree() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


## 接收 BattleManager 的 enemy_dialog 信号
func _on_battle_enemy_dialog(message: String) -> void:
	show_dialog(message)
