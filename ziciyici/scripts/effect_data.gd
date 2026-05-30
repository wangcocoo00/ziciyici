# ============================================================================
# EffectData
# 效果数据资源，定义战斗中各种效果的类型和参数
# 作为 Resource 可被复用和序列化，用于配置子弹、技能等效果
# ============================================================================
@tool
class_name EffectData
extends Resource

# ----------------------------------------------------------------------------
# 枚举定义
# ----------------------------------------------------------------------------

## 效果类型枚举
enum EffectType {
	MODIFY_ATTRIBUTE,    # 修改属性（如攻击力、速度等）
	CHANGE_SHOOT_DIRECTION,  # 改变射击方向
	SET_TAG,             # 设置标签（用于标记状态或触发条件）
}

## 目标对象枚举
enum Target {
	ENEMY,   # 敌方
	PLAYER,  # 玩家
}

# ----------------------------------------------------------------------------
# 导出属性
# ----------------------------------------------------------------------------

## 效果类型，决定该效果执行何种操作
@export var type: EffectType = EffectType.MODIFY_ATTRIBUTE

## 效果作用的目标对象
@export var target: Target = Target.ENEMY

## 要修改的属性名称（仅 MODIFY_ATTRIBUTE 类型使用）
## 例如: "hp", "speed", "attack_power"
@export var attribute: String = ""

## 属性修改的数值（仅 MODIFY_ATTRIBUTE 类型使用）
## 正数表示增加，负数表示减少
@export var value: float = 0.0

## 射击方向（仅 CHANGE_SHOOT_DIRECTION 类型使用）
## 默认 Vector2.LEFT 表示向左射击
@export var direction: Vector2 = Vector2.LEFT

## 标签名称（仅 SET_TAG 类型使用）
## 用于标记目标对象的状态，如 "stunned", "poisoned"
@export var tag: String = ""
