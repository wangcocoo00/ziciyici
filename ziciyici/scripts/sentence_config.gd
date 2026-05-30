# ============================================
# 文件: sentence_config.gd
# 功能: 定义句子配置资源，包含一组按顺序排列的 WordData
# 依赖: scripts/word_data.gd (WordData)
# 信号: 无
# 用法: 在 Godot 编辑器中创建 .tres 资源文件，配置句子中每个字的参数
# ============================================

extends Resource
class_name SentenceConfig

## 句子中包含的字列表，按顺序排列
## 每个元素是一个 WordData 资源，定义单个字的文字、攻击力、射击属性和效果
@export var words: Array[WordData] = []
