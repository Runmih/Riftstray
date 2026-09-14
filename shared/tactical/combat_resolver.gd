class_name TacticalCombatResolver
extends RefCounted

const CombatExchangePreview = preload("res://shared/tactical/combat_exchange_preview.gd")

func preview_exchange(
	ruleset: TacticalRuleset,
	attacker: TacticalCombatantSnapshot,
	defender: TacticalCombatantSnapshot,
	context: TacticalCombatContext
) -> RefCounted:
	var exchange: RefCounted = CombatExchangePreview.new()
	exchange.initiating = preview(ruleset, attacker, defender, context)
	if not exchange.initiating.valid:
		exchange.error = exchange.initiating.error
		return exchange
	exchange.valid = true
	exchange.ordered_strikes.append(_preview_entry(
		TacticalCombatConstants.STRIKE_INITIATING, attacker.id, defender.id,
		exchange.initiating, false
	))
	if exchange.initiating.possible_riposte:
		exchange.riposte = preview(ruleset, defender, attacker, context)
		exchange.riposte_possible = exchange.riposte.valid
		if exchange.riposte_possible:
			exchange.ordered_strikes.append(_preview_entry(
				TacticalCombatConstants.STRIKE_RIPOSTE, defender.id, attacker.id,
				exchange.riposte, true
			))
	exchange.normal_counter_possible = can_normal_counter(defender, attacker, context)
	if exchange.normal_counter_possible:
		exchange.normal_counter = preview(ruleset, defender, attacker, context)
		exchange.ordered_strikes.append(_preview_entry(
			TacticalCombatConstants.STRIKE_NORMAL_COUNTER, defender.id, attacker.id,
			exchange.normal_counter, false
		))
	var attacker_speed := attack_speed(ruleset, attacker)
	var defender_speed := attack_speed(ruleset, defender)
	var follow_source: TacticalCombatantSnapshot
	var follow_target: TacticalCombatantSnapshot
	if attacker_speed - defender_speed >= ruleset.speed_follow_up_threshold and _can_basic_strike(attacker, defender, context):
		follow_source = attacker
		follow_target = defender
	elif exchange.normal_counter_possible and defender_speed - attacker_speed >= ruleset.speed_follow_up_threshold:
		follow_source = defender
		follow_target = attacker
	if follow_source != null:
		exchange.speed_follow_up = preview(ruleset, follow_source, follow_target, context)
		exchange.speed_follow_up_possible = exchange.speed_follow_up.valid
		exchange.follow_up_attacker_id = follow_source.id
		if exchange.speed_follow_up_possible:
			exchange.ordered_strikes.append(_preview_entry(
				TacticalCombatConstants.STRIKE_SPEED_FOLLOW_UP, follow_source.id, follow_target.id,
				exchange.speed_follow_up, false
			))
	return exchange

func preview(
	ruleset: TacticalRuleset,
	attacker: TacticalCombatantSnapshot,
	defender: TacticalCombatantSnapshot,
	context: TacticalCombatContext
) -> TacticalCombatPreview:
	var result := TacticalCombatPreview.new()
	result.error = _validation_error(attacker, defender, context)
	if not result.error.is_empty():
		return result
	var matchup_data := _resolve_matchup(ruleset, attacker, defender)
	result.matchup = int(matchup_data["value"])
	result.matchup_diagnostic = String(matchup_data["diagnostic"])
	var modifiers := _combat_modifiers(attacker, defender, context)
	result.damage_type = attacker.primary_weapon.damage_type
	result.mitigation_stat = &"resistance" if result.damage_type == TacticalCombatConstants.DAMAGE_MAGICAL else &"defense"
	result.mitigation_value = defender.resistance if result.damage_type == TacticalCombatConstants.DAMAGE_MAGICAL else defender.defense
	result.attacker_equipped_weight = attacker.equipped_weight
	result.defender_equipped_weight = defender.equipped_weight
	result.attacker_burden = burden(ruleset, attacker)
	result.defender_burden = burden(ruleset, defender)
	result.attacker_attack_speed = attack_speed(ruleset, attacker)
	result.defender_attack_speed = attack_speed(ruleset, defender)
	var offensive_stat := attacker.magic if result.damage_type == TacticalCombatConstants.DAMAGE_MAGICAL else attacker.strength
	result.attack_power = maxi(
		ruleset.attack_floor,
		offensive_stat + attacker.primary_weapon.might + int(modifiers["attack"]) + ruleset.matchup_attack_step * result.matchup
	)
	result.hit_chance = clampi(
		attacker.primary_weapon.accuracy
			+ ruleset.skill_hit_coefficient * attacker.skill
			- ruleset.speed_avoid_coefficient * result.defender_attack_speed
			+ attacker.terrain_hit_bonus
			- defender.terrain_avoid_bonus
			+ int(modifiers["hit"])
			+ ruleset.matchup_hit_step * result.matchup,
		ruleset.chance_minimum,
		ruleset.chance_maximum
	)
	result.crit_chance = clampi(
		attacker.primary_weapon.critical
			+ int(floori(float(attacker.skill) / float(ruleset.critical_skill_divisor)))
			- int(floori(float(defender.skill) / float(ruleset.critical_skill_divisor)))
			+ int(modifiers["critical"]),
		ruleset.chance_minimum,
		ruleset.chance_maximum
	)
	result.block_chance = 0
	result.block_applicable = defender.block_capable and (
		result.damage_type == TacticalCombatConstants.DAMAGE_PHYSICAL
		or not ruleset.magic_bypasses_physical_block
	)
	if result.block_applicable:
		result.block_chance = clampi(
			ruleset.block_skill_coefficient * defender.skill + _block_modifier(defender),
			ruleset.chance_minimum,
			ruleset.chance_maximum
		)
	result.normal_damage = maxi(0, result.attack_power - result.mitigation_value)
	result.block_break_damage = maxi(0, result.attack_power - defender.strength)
	result.block_break_stuns = result.block_break_damage > 0
	result.possible_riposte = (
		defender.has_reaction(TacticalCombatConstants.REACTION_RIPOSTE)
		and not defender.pending_stun
		and _in_range(defender, attacker, context)
	)
	result.valid = true
	return result


func resolve_exchange(
	ruleset: TacticalRuleset,
	attacker: TacticalCombatantSnapshot,
	defender: TacticalCombatantSnapshot,
	context: TacticalCombatContext,
	random_source: TacticalRandomSource,
	apply_strike: Callable = Callable()
) -> TacticalCombatExchangeResult:
	var exchange := TacticalCombatExchangeResult.new()
	var first := resolve_strike(ruleset, attacker, defender, context, random_source, false, TacticalCombatConstants.STRIKE_INITIATING)
	exchange.first_strike = first
	if not first.ok:
		exchange.error = first.error
		return exchange
	exchange.ok = true
	_commit_strike(exchange, first, context, apply_strike)
	if context.terminal:
		return exchange

	var fresh_reactor_source := context.get_combatant(defender.id)
	var fresh_target_source := context.get_combatant(attacker.id)
	if fresh_reactor_source == null or fresh_target_source == null:
		return exchange
	var fresh_reactor := fresh_reactor_source.duplicate_snapshot()
	var fresh_target := fresh_target_source.duplicate_snapshot()
	if can_riposte(first, fresh_reactor, fresh_target, context):
		exchange.events.append("Riposte: %s immediately strikes %s." % [fresh_reactor.display_name, fresh_target.display_name])
		var reaction := resolve_strike(ruleset, fresh_reactor, fresh_target, context, random_source, true, TacticalCombatConstants.STRIKE_RIPOSTE)
		exchange.reaction_strike = reaction
		_commit_strike(exchange, reaction, context, apply_strike)
		if context.terminal:
			return exchange

	var counter_source := context.get_combatant(defender.id)
	var counter_target_source := context.get_combatant(attacker.id)
	var counter_eligible := counter_source != null and counter_target_source != null and can_normal_counter(counter_source, counter_target_source, context)
	if counter_eligible:
		var counter := resolve_strike(
			ruleset, counter_source.duplicate_snapshot(), counter_target_source.duplicate_snapshot(),
			context, random_source, false, TacticalCombatConstants.STRIKE_NORMAL_COUNTER
		)
		exchange.normal_counter_strike = counter
		exchange.events.append("Counterattack: %s strikes %s." % [counter_source.display_name, counter_target_source.display_name])
		_commit_strike(exchange, counter, context, apply_strike)
		if context.terminal:
			return exchange

	var follow_attacker := context.get_combatant(attacker.id)
	var follow_defender := context.get_combatant(defender.id)
	if follow_attacker == null or follow_defender == null:
		return exchange
	var follow_source: TacticalCombatantSnapshot
	var follow_target: TacticalCombatantSnapshot
	if (
		attack_speed(ruleset, follow_attacker) - attack_speed(ruleset, follow_defender) >= ruleset.speed_follow_up_threshold
		and _can_basic_strike(follow_attacker, follow_defender, context)
	):
		follow_source = follow_attacker
		follow_target = follow_defender
	elif (
		counter_eligible
		and attack_speed(ruleset, follow_defender) - attack_speed(ruleset, follow_attacker) >= ruleset.speed_follow_up_threshold
		and _can_basic_strike(follow_defender, follow_attacker, context)
	):
		follow_source = follow_defender
		follow_target = follow_attacker
	if follow_source != null:
		exchange.events.append("Speed follow-up: %s gains one extra strike." % follow_source.display_name)
		var follow_up := resolve_strike(
			ruleset, follow_source.duplicate_snapshot(), follow_target.duplicate_snapshot(),
			context, random_source, false, TacticalCombatConstants.STRIKE_SPEED_FOLLOW_UP
		)
		exchange.follow_up_strike = follow_up
		_commit_strike(exchange, follow_up, context, apply_strike)
	return exchange


func resolve_strike(
	ruleset: TacticalRuleset,
	attacker: TacticalCombatantSnapshot,
	defender: TacticalCombatantSnapshot,
	context: TacticalCombatContext,
	random_source: TacticalRandomSource,
	is_reaction: bool,
	strike_kind: StringName = &""
) -> TacticalStrikeResult:
	var result := TacticalStrikeResult.new()
	result.attacker_id = attacker.id if attacker != null else &""
	result.defender_id = defender.id if defender != null else &""
	result.is_reaction = is_reaction
	result.strike_kind = strike_kind if not strike_kind.is_empty() else (TacticalCombatConstants.STRIKE_RIPOSTE if is_reaction else TacticalCombatConstants.STRIKE_INITIATING)
	var combat_preview := preview(ruleset, attacker, defender, context)
	if not combat_preview.valid:
		result.error = combat_preview.error
		return result
	result.ok = true
	result.matchup = combat_preview.matchup
	result.matchup_diagnostic = combat_preview.matchup_diagnostic
	result.attack_power = combat_preview.attack_power
	result.damage_type = combat_preview.damage_type
	result.mitigation_stat = combat_preview.mitigation_stat
	result.mitigation_value = combat_preview.mitigation_value
	result.hit_chance = combat_preview.hit_chance
	result.crit_chance = combat_preview.crit_chance
	result.block_chance = combat_preview.block_chance
	result.remaining_hp = defender.current_hp
	result.hit_roll = random_source.roll_percent()
	result.hit = result.hit_roll < float(result.hit_chance)
	if not result.hit:
		result.dodged = true
		result.events.append("%s dodges %s's strike." % [defender.display_name, attacker.display_name])
		return result

	result.events.append("%s hits %s (power %d)." % [attacker.display_name, defender.display_name, result.attack_power])
	if combat_preview.block_applicable:
		result.block_attempted = true
		result.block_roll = random_source.roll_percent()
		result.blocked = result.block_roll < float(result.block_chance)
	if result.blocked:
		if result.attack_power <= defender.strength:
			result.events.append("%s blocks within Strength capacity; no HP is lost." % defender.display_name)
			return result
		result.block_broken = true
		result.calculated_damage = result.attack_power - defender.strength
		result.ordinary_damage = result.calculated_damage
		result.events.append("%s's block breaks: %d power exceeds %d Strength." % [defender.display_name, result.attack_power, defender.strength])
	else:
		result.ordinary_damage = combat_preview.normal_damage
		result.calculated_damage = result.ordinary_damage
		if result.block_attempted:
			result.events.append("%s fails to block." % defender.display_name)
		if result.crit_chance > 0:
			result.crit_roll = random_source.roll_percent()
			result.critical = result.crit_roll < float(result.crit_chance)
		if result.critical:
			result.calculated_damage *= ruleset.critical_damage_multiplier
			result.events.append("Critical hit: %d ordinary damage × %d." % [result.ordinary_damage, ruleset.critical_damage_multiplier])

	result.actual_hp_lost = mini(defender.current_hp, result.calculated_damage)
	result.remaining_hp = maxi(0, defender.current_hp - result.actual_hp_lost)
	if result.calculated_damage > 0:
		result.events.append("%s loses %d HP (calculated %d)." % [defender.display_name, result.actual_hp_lost, result.calculated_damage])
	else:
		result.events.append("%s's %s prevents HP loss." % [defender.display_name, String(result.mitigation_stat).capitalize()])
	result.killed = result.remaining_hp <= 0
	result.stunned = result.block_broken and not result.killed
	if result.stunned:
		result.events.append("%s is stunned and will skip the next activation." % defender.display_name)
	if result.killed:
		result.events.append("%s falls." % defender.display_name)
	return result


func can_riposte(
	trigger: TacticalStrikeResult,
	reactor: TacticalCombatantSnapshot,
	target: TacticalCombatantSnapshot,
	context: TacticalCombatContext
) -> bool:
	if context.terminal or trigger == null or not trigger.ok or trigger.is_reaction:
		return false
	if trigger.defender_id != reactor.id or trigger.attacker_id != target.id:
		return false
	if not trigger.dodged and not (trigger.blocked and not trigger.block_broken):
		return false
	return (
		reactor.is_alive_and_present()
		and target.is_alive_and_present()
		and not reactor.pending_stun
		and reactor.has_reaction(TacticalCombatConstants.REACTION_RIPOSTE)
		and _in_range(reactor, target, context)
	)


func can_normal_counter(
	counter_attacker: TacticalCombatantSnapshot,
	counter_target: TacticalCombatantSnapshot,
	context: TacticalCombatContext
) -> bool:
	return _can_basic_strike(counter_attacker, counter_target, context)


func burden(ruleset: TacticalRuleset, combatant: TacticalCombatantSnapshot) -> int:
	return maxi(0, combatant.equipped_weight - int(floori(float(combatant.strength) / float(ruleset.strength_burden_divisor))))


func attack_speed(ruleset: TacticalRuleset, combatant: TacticalCombatantSnapshot) -> int:
	return maxi(0, combatant.speed - burden(ruleset, combatant))


func _can_basic_strike(
	strike_attacker: TacticalCombatantSnapshot,
	strike_target: TacticalCombatantSnapshot,
	context: TacticalCombatContext
) -> bool:
	return (
		not context.terminal
		and strike_attacker != null
		and strike_target != null
		and strike_attacker.is_alive_and_present()
		and strike_target.is_alive_and_present()
		and strike_attacker.alliance_id != strike_target.alliance_id
		and not strike_attacker.pending_stun
		and strike_attacker.primary_weapon != null
		and strike_attacker.primary_weapon.is_offensive()
		and _in_range(strike_attacker, strike_target, context)
	)


func _commit_strike(
	exchange: TacticalCombatExchangeResult,
	strike: TacticalStrikeResult,
	context: TacticalCombatContext,
	apply_strike: Callable
) -> void:
	if strike == null or not strike.ok:
		return
	exchange.ordered_strikes.append(strike)
	_append_events(exchange.events, strike.events)
	_apply_to_snapshot(strike, context)
	if apply_strike.is_valid() and bool(apply_strike.call(strike)):
		context.terminal = true


func _preview_entry(
	kind: StringName,
	attacker_id: StringName,
	defender_id: StringName,
	combat_preview: TacticalCombatPreview,
	conditional: bool
) -> Dictionary:
	return {
		"kind": kind,
		"attacker_id": attacker_id,
		"defender_id": defender_id,
		"preview": combat_preview,
		"conditional": conditional,
	}


func _validation_error(attacker: TacticalCombatantSnapshot, defender: TacticalCombatantSnapshot, context: TacticalCombatContext) -> String:
	if context == null or context.terminal:
		return "Combat cannot start after the mission is terminal."
	if attacker == null or defender == null:
		return "Combat participants are missing."
	if not attacker.is_alive_and_present() or not defender.is_alive_and_present():
		return "Combat participants must be living and on-map."
	if attacker.alliance_id == defender.alliance_id:
		return "Combat participants are not hostile."
	if attacker.primary_weapon == null:
		return "%s has no offensive weapon." % attacker.display_name
	if not _in_range(attacker, defender, context):
		return "Target is outside %s's weapon range." % attacker.display_name
	return ""


func _resolve_matchup(ruleset: TacticalRuleset, attacker: TacticalCombatantSnapshot, defender: TacticalCombatantSnapshot) -> Dictionary:
	var baseline := ruleset.get_baseline_matchup(attacker.primary_weapon.type_id, defender.primary_weapon.type_id if defender.primary_weapon != null else &"")
	var candidates: Array[Dictionary] = []
	_collect_matchup_overrides(candidates, attacker, defender, 1)
	_collect_matchup_overrides(candidates, defender, attacker, -1)
	if candidates.is_empty():
		return {"value": baseline, "diagnostic": ""}
	var highest_priority := -2_147_483_648
	for candidate: Dictionary in candidates:
		highest_priority = maxi(highest_priority, int(candidate["priority"]))
	var values: Dictionary = {}
	for candidate: Dictionary in candidates:
		if int(candidate["priority"]) == highest_priority:
			values[int(candidate["value"])] = true
	if values.size() > 1:
		return {"value": 0, "diagnostic": "Equal-priority opposing matchup overrides resolved to neutral."}
	return {"value": int(values.keys()[0]), "diagnostic": ""}


func _collect_matchup_overrides(
	result: Array[Dictionary],
	specialist: TacticalCombatantSnapshot,
	opponent: TacticalCombatantSnapshot,
	perspective: int
) -> void:
	if specialist.primary_weapon == null or opponent.primary_weapon == null:
		return
	for effect: TacticalEffectDefinition in specialist.effects:
		if (
			effect.type == TacticalEffectDefinition.Type.MATCHUP_OVERRIDE
			and effect.required_weapon_type == specialist.primary_weapon.type_id
			and effect.opponent_weapon_type == opponent.primary_weapon.type_id
		):
			result.append({"priority": effect.priority, "value": effect.matchup_value * perspective})


func _combat_modifiers(attacker: TacticalCombatantSnapshot, defender: TacticalCombatantSnapshot, context: TacticalCombatContext) -> Dictionary:
	var attack := 0
	var hit := 0
	var critical := 0
	for effect: TacticalEffectDefinition in attacker.effects:
		if not effect.required_weapon_type.is_empty() and effect.required_weapon_type != attacker.primary_weapon.type_id:
			continue
		if effect.type == TacticalEffectDefinition.Type.STAT_MODIFIER:
			attack += effect.attack_modifier
			hit += effect.hit_modifier
			critical += effect.critical_modifier
		elif effect.type == TacticalEffectDefinition.Type.CONDITIONAL_DUEL_MODIFIER and not context.has_adjacent_ally(defender):
			attack += effect.attack_modifier
			hit += effect.hit_modifier
			critical += effect.critical_modifier
	return {"attack": attack, "hit": hit, "critical": critical}


func _block_modifier(defender: TacticalCombatantSnapshot) -> int:
	var modifier := 0
	for effect: TacticalEffectDefinition in defender.effects:
		if (
			effect.type == TacticalEffectDefinition.Type.STAT_MODIFIER
			and (effect.required_weapon_type.is_empty() or (defender.primary_weapon != null and effect.required_weapon_type == defender.primary_weapon.type_id))
		):
			modifier += effect.block_modifier
	return modifier


func _in_range(attacker: TacticalCombatantSnapshot, defender: TacticalCombatantSnapshot, context: TacticalCombatContext) -> bool:
	if attacker.primary_weapon == null:
		return false
	var separation := context.distance(attacker, defender)
	return separation >= attacker.primary_weapon.minimum_range and separation <= attacker.primary_weapon.maximum_range


func _apply_to_snapshot(result: TacticalStrikeResult, context: TacticalCombatContext) -> void:
	var defender := context.get_combatant(result.defender_id)
	if defender == null:
		return
	defender.current_hp = result.remaining_hp
	if result.killed:
		defender.present = false
	if result.stunned:
		defender.pending_stun = true


func _append_events(destination: PackedStringArray, source: PackedStringArray) -> void:
	for event: String in source:
		destination.append(event)
