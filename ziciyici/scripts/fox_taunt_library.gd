# ============================================
# 文件: fox_taunt_library.gd
# 功能: 定义狐狸嘲讽台词库资源，存储一组可随机播放的嘲讽文本
# 依赖: 无
# 信号: 无
# 用法: 在 Godot 编辑器中创建 .tres 资源文件，添加多条嘲讽台词
# ============================================

extends Resource
class_name FoxTauntLibrary

## 嘲讽台词列表，游戏运行时从中随机选取播放
@export var taunts: Array[String] = []
