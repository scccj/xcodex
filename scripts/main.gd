extends Node2D

# 云波防御规则（同时出牌、同时结算）
# 规则来源：用户给定的 Markdown 规格。

enum Card {
	CLOUD,
	SMALL_WAVE,
	BIG_WAVE,
	SMALL_DEFENSE,
	BIG_DEFENSE,
}


func new_game_state() -> Dictionary:
	return {
		"player_hp": 1,
		"enemy_hp": 1,
		"player_cloud": 0,
		"enemy_cloud": 0,
	}


func card_cost(card: Card) -> int:
	match card:
		Card.CLOUD:
			return 0
		Card.SMALL_DEFENSE:
			return 0
		Card.SMALL_WAVE:
			return 1
		Card.BIG_DEFENSE:
			return 2
		Card.BIG_WAVE:
			return 3
		_:
			return 0


func is_wave(card: Card) -> bool:
	return card == Card.SMALL_WAVE or card == Card.BIG_WAVE


func can_block(attack_card: Card, defense_card: Card) -> bool:
	if not is_wave(attack_card):
		return false

	if defense_card == Card.BIG_DEFENSE:
		return true

	if defense_card == Card.SMALL_DEFENSE and attack_card == Card.SMALL_WAVE:
		return true

	return false


func resolve_round(state: Dictionary, player_card: Card, enemy_card: Card) -> Dictionary:
	var result := {
		"player_dead": false,
		"enemy_dead": false,
		"player_cloud_delta": 0,
		"enemy_cloud_delta": 0,
		"reason": "",
	}

	if state.player_cloud < card_cost(player_card):
		result.player_dead = true
		result.reason = "玩家云不足，无法出牌。"
		apply_result(state, result)
		return result

	if state.enemy_cloud < card_cost(enemy_card):
		result.enemy_dead = true
		result.reason = "对手云不足，无法出牌。"
		apply_result(state, result)
		return result

	# 先扣出牌成本（云牌成本为 0）。
	result.player_cloud_delta -= card_cost(player_card)
	result.enemy_cloud_delta -= card_cost(enemy_card)

	# 云牌结算（+1 云）。
	if player_card == Card.CLOUD:
		result.player_cloud_delta += 1
	if enemy_card == Card.CLOUD:
		result.enemy_cloud_delta += 1

	# 攻击牌判定。
	var player_attacks := is_wave(player_card)
	var enemy_attacks := is_wave(enemy_card)
	var player_blocks := can_block(enemy_card, player_card)
	var enemy_blocks := can_block(player_card, enemy_card)

	if player_attacks and not enemy_blocks:
		result.enemy_dead = true
	if enemy_attacks and not player_blocks:
		result.player_dead = true

	if result.player_dead and result.enemy_dead:
		result.reason = "双方攻击都未被防住，同归于尽。"
	elif result.player_dead:
		result.reason = "玩家被未拦截的波击杀。"
	elif result.enemy_dead:
		result.reason = "对手被未拦截的波击杀。"
	else:
		result.reason = "本回合无人阵亡。"

	apply_result(state, result)
	return result


func apply_result(state: Dictionary, result: Dictionary) -> void:
	state.player_cloud = max(0, state.player_cloud + result.player_cloud_delta)
	state.enemy_cloud = max(0, state.enemy_cloud + result.enemy_cloud_delta)

	if result.player_dead:
		state.player_hp = 0
	if result.enemy_dead:
		state.enemy_hp = 0


func _ready() -> void:
	# 最小演示：
	# 第 1 回合：双方出云。
	# 第 2 回合：玩家出小波，对手出小防（被挡住）。
	var game_state := new_game_state()

	var r1 := resolve_round(game_state, Card.CLOUD, Card.CLOUD)
	print("R1:", r1.reason, " | P云=", game_state.player_cloud, " E云=", game_state.enemy_cloud)

	var r2 := resolve_round(game_state, Card.SMALL_WAVE, Card.SMALL_DEFENSE)
	print("R2:", r2.reason, " | P云=", game_state.player_cloud, " E云=", game_state.enemy_cloud)
