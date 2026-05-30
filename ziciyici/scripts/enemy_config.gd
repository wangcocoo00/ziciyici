# ============================================
# 文件: enemy_config.gd
# 功能: 定义敌人配置资源，包含敌人的属性、子弹行为和外观
# 依赖: scripts/sentence_config.gd (SentenceConfig)
# 信号: 无
# 用法: 在 Godot 编辑器中创建 .tres 资源文件，配置不同种类的敌人
# ============================================

extends Resource
class_name EnemyConfig

## 敌人名称，用于 UI 显示和调试
@export var enemy_name: String = "敌人"

## 敌人生命值
@export var hp: int = 300

## 敌人的句子配置，包含一组按顺序排列的字（仅用于显示）
@export var sentence: SentenceConfig

## 基础攻击力，子弹击中玩家时造成的伤害
@export var base_attack_damage: int = 99999

## 子弹默认射击方向
@export var base_shoot_direction: Vector2 = Vector2.LEFT

## 子弹是否可伤害敌人自身（反弹后击中自己）
@export var bullet_can_hurt_self: bool = false

## 子弹是否具有弹射能力（击中后反弹）
@export var bullet_ricochet: bool = false

## 玩家可以射击该敌人的次数
## 达到次数后敌人可能进入特殊状态或消失
@export var shots_allowed: int = 1

## 敌人形象纹理
@export var sprite: Texture2D
