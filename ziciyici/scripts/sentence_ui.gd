# ============================================
# 文件: sentence_ui.gd
# 功能: 句子 UI，显示敌人和玩家的字，玩家字可点击射击
# 依赖: scripts/word_data.gd (WordData)
# 信号: slot_clicked(slot: int) - 玩家点击某个字时发出
# ============================================

extends Control
class_name SentenceUI

## 敌人句子容器（HBoxContainer），显示敌人句子的每个字
@onready var enemy_sentence_container: HBoxContainer = $EnemySentenceContainer

## 玩家句子容器（HBoxContainer），显示玩家可射击的字
@onready var player_sentence_container: HBoxContainer = $PlayerSentenceContainer

## 玩家点击某个字时发出，参数为字在数组中的索引
signal slot_clicked(slot: int)


## 刷新显示内容
## @param enemy_words: 敌人句子的文字数组（仅用于显示）
## @param player_words: 玩家句子的 WordData 数组（可点击射击）
func refresh_display(enemy_words: Array[String], player_words: Array[WordData]) -> void:
	# 清空两个容器
	_clear_container(enemy_sentence_container)
	_clear_container(player_sentence_container)

	# 渲染敌人句子（纯文本 Label）
	for word_text: String in enemy_words:
		var label: Label = Label.new()
		label.text = word_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		enemy_sentence_container.add_child(label)

	# 渲染玩家句子（可点击 Button）
	for i: int in player_words.size():
		var word: WordData = player_words[i]
		var button: Button = Button.new()
		button.text = word.text
		button.modulate = word.highlight_color
		button.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		# 连接点击信号，传递索引
		var slot_index: int = i
		button.pressed.connect(_on_slot_pressed.bind(slot_index))

		player_sentence_container.add_child(button)


## 清空容器中所有子节点
func _clear_container(container: HBoxContainer) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


## 字槽点击回调，发出 slot_clicked 信号
func _on_slot_pressed(slot: int) -> void:
	slot_clicked.emit(slot)


func _on_battle_sentence_updated() -> void:
	pass # Replace with function body.
