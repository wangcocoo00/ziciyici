# ============================================
# 文件: word_data.gd
# 功能: 定义游戏中"字"的数据资源，包含文字内容、攻击力、射击属性及效果列表
# 依赖: resources/effect_data.gd (EffectData)
# 信号: 无
# 用法: 在 Godot 编辑器中创建 .tres 资源文件，配置具体字的参数和关联效果
# ============================================

extends Resource
class_name WordData

## 文字内容，显示在游戏中的字符
@export var text: String = "字"

## 攻击力数值，击中目标时造成的伤害值
@export var attack_value: int = 0

## 是否可被玩家射击，false 表示该字不可被射击（如障碍物或装饰字）
@export var can_be_shot: bool = true

## 可射击时显示的颜色标记，用于 UI 提示玩家该字可被交互
@export var highlight_color: Color = Color.WHITE

## 射击此字后触发的效果列表
## 每个 EffectData 定义一种效果（修改属性、改变射击方向、设置标签）
## 可在编辑器中通过数组添加多个 EffectData 资源
@export var shot_effects: Array[EffectData] = []
