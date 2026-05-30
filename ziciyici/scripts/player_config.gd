# ============================================
# 文件: player_config.gd
# 功能: 定义玩家配置资源，包含玩家的句子、生命值、攻击力和跳跃属性
# 依赖: scripts/sentence_config.gd (SentenceConfig)
# 信号: 无
# 用法: 在 Godot 编辑器中创建 .tres 资源文件，配置玩家初始参数
# ============================================

extends Resource
class_name PlayerConfig

## 玩家的句子配置，包含哪些字可射击、每个字的效果等
@export var sentence: SentenceConfig

## 玩家生命值
@export var hp: int = 500

## 基础攻击力，玩家子弹击中敌人时造成的伤害
@export var base_attack: int = 300

## 基础跳跃高度（像素单位）
@export var base_jump_height: float = 80.0
