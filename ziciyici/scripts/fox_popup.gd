# ============================================
# 文件: fox_popup.gd
# 功能: 狐狸嘲讽弹窗，从屏幕上方滑入显示台词，停留后滑出
# 依赖: 场景中需包含 FoxSprite (Sprite2D) 和 DialogBubble (Label) 子节点
#       注意：DialogBubble 必须是 FoxSprite 的子节点，这样移动 FoxSprite 时文字也会跟随
# 信号: 无
# ============================================

extends CanvasLayer
class_name FoxPopup

## 嘲讽文字停留时间（秒），可在编辑器中调整
@export var taunt_duration: float = 2.0

## 是否正在显示嘲讽弹窗
var is_showing: bool = false

## 狐狸形象精灵（DialogBubble 应为其子节点，随其一起移动）
@onready var fox_sprite: Sprite2D = $FoxSprite

## 对话气泡文本标签
@onready var dialog_bubble: Label = $FoxSprite/DialogBubble

## 存储当前运行的 Tween，用于退出时清理
var _tween: Tween = null


func _ready() -> void:
	# 初始时狐狸在屏幕上方（不可见）
	fox_sprite.position = Vector2(400, -200)


## 显示嘲讽台词
## 若正在显示则忽略本次调用
## @param message: 要显示的台词文本
func show_taunt(message: String) -> void:
	# 正在显示中则忽略
	if is_showing:
		return

	is_showing = true

	# 设置文本
	dialog_bubble.text = message

	# 确保起始位置在屏幕上方
	fox_sprite.position = Vector2(400, -200)

	# 创建 Tween 动画
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BOUNCE)
	_tween.set_ease(Tween.EASE_OUT)

	# 从 y=-200 滑入到 y=200
	_tween.tween_property(fox_sprite, "position:y", 200.0, 0.6)

	# 停留 taunt_duration 秒（可在编辑器中调整）
	_tween.tween_interval(taunt_duration)

	# 滑出到 y=-200
	_tween.tween_property(fox_sprite, "position:y", -200.0, 0.5)

	# 动画完成后重置状态
	_tween.tween_callback(_on_taunt_finished)


## 嘲讽动画完成回调
func _on_taunt_finished() -> void:
	is_showing = false
	_tween = null


## 节点退出场景树时清理 Tween，防止内存泄漏
func _exit_tree() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _on_battle_fox_taunt(message: String) -> void:
	show_taunt(message)
