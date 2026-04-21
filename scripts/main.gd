extends Node2D

enum Phase {
	SELECT_ACTION,
	PLAY_CARD,
	RESOLVE,
	ROUND_END,
}

var _round: int = 1
var _phase: Phase = Phase.SELECT_ACTION
var _selected_action: String = ""
var _play_count: int = 0
var _log_lines: PackedStringArray = []

@onready var _round_label: Label = $CanvasLayer/UI/Panel/Margin/VBox/RoundLabel
@onready var _status_label: Label = $CanvasLayer/UI/Panel/Margin/VBox/StatusLabel
@onready var _selected_label: Label = $CanvasLayer/UI/Panel/Margin/VBox/SelectedActionLabel
@onready var _option_attack: Button = $CanvasLayer/UI/Panel/Margin/VBox/Options/AttackButton
@onready var _option_defend: Button = $CanvasLayer/UI/Panel/Margin/VBox/Options/DefendButton
@onready var _option_charge: Button = $CanvasLayer/UI/Panel/Margin/VBox/Options/ChargeButton
@onready var _play_button: Button = $CanvasLayer/UI/Panel/Margin/VBox/PlayButton
@onready var _resolve_button: Button = $CanvasLayer/UI/Panel/Margin/VBox/ResolveButton
@onready var _next_round_button: Button = $CanvasLayer/UI/Panel/Margin/VBox/NextRoundButton
@onready var _log_label: Label = $CanvasLayer/UI/Panel/Margin/VBox/LogLabel

func _ready() -> void:
	_option_attack.pressed.connect(_on_select_action.bind("进攻"))
	_option_defend.pressed.connect(_on_select_action.bind("防御"))
	_option_charge.pressed.connect(_on_select_action.bind("蓄力"))
	_play_button.pressed.connect(_on_play_button_pressed)
	_resolve_button.pressed.connect(_on_resolve_button_pressed)
	_next_round_button.pressed.connect(_on_next_round_button_pressed)

	_add_log("进入第 %d 轮，请先选择下一步操作。" % _round)
	_refresh_ui()

func _on_select_action(action_name: String) -> void:
	if _phase != Phase.SELECT_ACTION:
		return

	_selected_action = action_name
	_phase = Phase.PLAY_CARD
	_play_count = 0
	_add_log("你选择了操作：%s" % _selected_action)
	_refresh_ui()

func _on_play_button_pressed() -> void:
	if _phase != Phase.PLAY_CARD:
		return

	_play_count += 1
	if _play_count == 1:
		_add_log("第一次出牌：%s" % _selected_action)
	elif _play_count == 2:
		_add_log("第二次出牌：%s" % _selected_action)
		_phase = Phase.RESOLVE

	_refresh_ui()

func _on_resolve_button_pressed() -> void:
	if _phase != Phase.RESOLVE:
		return

	_phase = Phase.ROUND_END
	_add_log("结算完成，第 %d 轮结束。" % _round)
	_refresh_ui()

func _on_next_round_button_pressed() -> void:
	if _phase != Phase.ROUND_END:
		return

	_round += 1
	_phase = Phase.SELECT_ACTION
	_selected_action = ""
	_play_count = 0
	_add_log("进入第 %d 轮，请先选择下一步操作。" % _round)
	_refresh_ui()

func _refresh_ui() -> void:
	_round_label.text = "当前轮次：第 %d 轮" % _round
	_selected_label.text = "已选操作：%s" % (_selected_action if _selected_action != "" else "（未选择）")

	_option_attack.disabled = _phase != Phase.SELECT_ACTION
	_option_defend.disabled = _phase != Phase.SELECT_ACTION
	_option_charge.disabled = _phase != Phase.SELECT_ACTION

	if _phase == Phase.SELECT_ACTION:
		_status_label.text = "请先选择下一步操作。"
		_play_button.text = "点击出牌"
		_play_button.disabled = true
		_resolve_button.disabled = true
		_next_round_button.disabled = true
	elif _phase == Phase.PLAY_CARD:
		if _play_count == 0:
			_status_label.text = "已选择操作，点击“出牌”。"
			_play_button.text = "点击出牌"
		else:
			_status_label.text = "已出牌一次，请“再打出”。"
			_play_button.text = "再打出"
		_play_button.disabled = false
		_resolve_button.disabled = true
		_next_round_button.disabled = true
	elif _phase == Phase.RESOLVE:
		_status_label.text = "已完成两次出牌，请点击“结算”。"
		_play_button.text = "出牌完成"
		_play_button.disabled = true
		_resolve_button.disabled = false
		_next_round_button.disabled = true
	else:
		_status_label.text = "本轮已结算，点击“下一轮”继续。"
		_play_button.text = "出牌完成"
		_play_button.disabled = true
		_resolve_button.disabled = true
		_next_round_button.disabled = false

	_log_label.text = "操作记录：\n" + "\n".join(_log_lines)

func _add_log(line: String) -> void:
	_log_lines.append(line)
	if _log_lines.size() > 8:
		_log_lines = _log_lines.slice(_log_lines.size() - 8, _log_lines.size())
