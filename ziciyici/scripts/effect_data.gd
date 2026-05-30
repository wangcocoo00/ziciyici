# ============================================
# 文件: effect_data.gd
# 功能: 定义游戏效果的数据资源，用于描述子弹/技能对目标产生的效果
# 依赖: 无
# 信号: 无
# 用法: 在 Godot 编辑器中创建 .tres 资源文件，配置具体效果参数
# ============================================

extends Resource
class_name EffectData

## 效果类型枚举
## MODIFY_ATTRIBUTE: 修改目标属性（如攻击力、跳跃高度）
## CHANGE_SHOOT_DIRECTION: 改变目标的射击方向
## SET_TAG: 为目标设置标签（如 "ricochet" 弹射、"can_hurt_shooter" 可伤害发射者）
enum EffectType { MODIFY_ATTRIBUTE, CHANGE_SHOOT_DIRECTION, SET_TAG }

## 效果作用目标
enum Target { ENEMY, PLAYER }

## 效果类型，决定该效果的具体行为
@export var type: EffectType = EffectType.MODIFY_ATTRIBUTE

## 效果作用的目标对象类型
@export var target: Target = Target.ENEMY

## 要修改的属性名称，仅用于 MODIFY_ATTRIBUTE 类型
## 例如："attack_damage", "jump_height", "move_speed"
@export var attribute: String = ""

## 属性修改的数值，仅用于 MODIFY_ATTRIBUTE 类型
## 正数表示增加，负数表示减少
@export var value: float = 0.0

## 新的射击方向，仅用于 CHANGE_SHOOT_DIRECTION 类型
## 默认 Vector2.LEFT 表示向左射击
@export var direction: Vector2 = Vector2.LEFT

## 要设置的标签名称，仅用于 SET_TAG 类型
## 例如："ricochet"（弹射）、"can_hurt_shooter"（可伤害发射者）
@export var tag: String = ""
