# Combat and progression authoring

Red Alchemist selects its world-owned definitions through `worlds/red_alchemist/data/combat_config.tres`. The selected `TacticalRuleset` supplies level budgets, formula coefficients, attribute definitions, equipment, skills, and classes. Character resources supply base stats, movement, and equipment. The scene-independent behavior that validates and evaluates those resources lives in `shared/tactical/`; the launcher and core persistence do not depend on it.

## Change existing content

- Edit `data/characters/*.tres` for base Strength, Skill, Speed, Defense, max HP, movement, and equipped IDs. These are baselines; build allocations are applied to a fresh derived profile at mission start.
- Edit `data/attributes/*.tres` to change allocation cost or gain. Max HP currently gains two per point; the other attributes gain one.
- Edit `data/weapons/*.tres` for type, might, accuracy, critical chance, range, weight, damage type, or block capability. Shield equipment enables blocking; it is not an offensive weapon. Only equipment whose `contributes_to_combat_burden` flag is true counts toward combat burden, which lets a later carried-item system keep unequipped inventory weight separate without changing this resolver.
- Edit `baseline_matchups` in `data/combat_ruleset.tres` to select the world's ordinary weapon relationships. Author each unordered pair once with attacker/defender type IDs and `1` or `-1`; the reverse perspective is automatic. Omit neutral pairs. Duplicate, contradictory, self-referential, missing-ID, and zero/out-of-range relationships are rejected, and resource order does not affect a valid ruleset.
- Edit `data/skills/*.tres` for cost, prerequisites, descriptions, and supported effects. Point totals count skill costs, not effect count.
- Edit `data/classes/*.tres` for tier, explicit priority, and branch-point requirements. The highest qualifying tier wins, followed by priority. Equal tier/priority entries are rejected as ambiguous.
- To select a replacement ruleset or character catalog for this world, change the Resource references in `data/combat_config.tres`. Increment the ruleset revision when an authored ruleset meaningfully changes.

Resource order does not decide outcomes. Derived effects use deterministic priority/ID ordering, and class selection uses explicit tier/priority. Never add derived bonuses back into a shared character Resource; derive a fresh runtime profile instead.

Weapon-restricted passive effects are active only when the character's offensive primary weapon has the required type. A valid unarmed/noncombatant character safely ignores those restricted effects; unrestricted effects on the same build still apply. A different equipped weapon type also leaves the restricted effect inactive.

## Author Chapter One enemy spawns

`data/combat_config.tres` owns `enemy_spawns`, and each entry explicitly couples a stable unit ID, one character-definition Resource, and one grid position. `required_enemy_spawn_count` documents the prototype encounter's expected count. Keep the list and expected count in agreement; every entry needs its own valid spawn and character definition. The validator rejects missing entries or definitions, repeated spawn/character IDs, duplicate cells, invalid positions, and unsupported presentation groups. Mission initialization iterates these authored references and never truncates, duplicates, or substitutes an enemy.

`presentation_group` may be `primary_enemy` (red) or `secondary_enemy` (purple). It controls only the token/ring palette. Hostility remains determined by tactical faction relationships, so recoloring an enemy cannot alter targeting or AI behavior.

If configuration validation fails, Chapter One is disabled and its selection screen displays the complete authoring diagnostic while keeping Back/Escape navigation available. The mission model also refuses partial initialization if called directly with invalid data.

## Add a skill with supported effects

Create a `TacticalSkillDefinition` Resource with a stable ID, display text, branch ID, positive point cost, prerequisite IDs, and one or more `TacticalEffectDefinition` subresources. Add the skill to the selected ruleset catalog.

Supported effect types are:

- `STAT_MODIFIER`: persistent attribute changes and/or attack, hit, or block percentage-point modifiers. `required_weapon_type` can restrict it.
- `CONDITIONAL_DUEL_MODIFIER`: attack/hit modifiers when the opponent has no other living on-map ally at Manhattan distance one.
- `MATCHUP_OVERRIDE`: replaces a specific weapon relationship. Set both weapon type IDs, the relationship from the specialist's perspective, and an explicit priority. Higher priority replaces lower priority; conflicting top-priority overrides resolve neutral with a diagnostic.
- `REACTION_PERMISSION`: grants a named reaction. The implemented reaction ID is `riposte`.

Reaction IDs are validated against the same small shared catalog used by combat execution. Empty or unknown IDs (for example, a misspelling) are authoring errors and report the supported identifier instead of silently becoming inert.

Use data for a new value or a new combination of those effects. Add shared code and deterministic tests only for a genuinely new mechanic, such as an active ability or a new combat timing window. Do not put Red Alchemist unit IDs, scene Nodes, mission objectives, or AI into shared effects.

## Session inventory, gear, and save limits

Chapter One preparation owns one `TacticalBuildSession`. Its build, inventory, and loadout survive mission restart and chapter return while the current Red Alchemist world instance remains loaded; unloading the world creates a clean session. `Reset Build` clears attribute allocations and skills, while `Respec Skills` clears skills only. Neither command deletes owned items or changes equipped slots. There is no XP economy, campaign build save, loot flow, or migration promise for future definition edits. `CrossworldData` remains informational and records only `red_alchemist.played`.

Character definitions grant item definition IDs once when the session begins. Runtime inventory stores separate owned instances with stable IDs; quantities come from those instances. Gear slots are authored in `data/equipment_slots/` and selected by `equipment_slots` in the ruleset. Weapons declare `compatible_slots`; a multi-slot item also lists `reserved_slots`. Equip validates ownership, compatibility, every reservation, and duplicate assignment before committing anything. Unequipping any occupied/reserved slot releases that one item’s complete assignment. Equipped definitions are deduplicated before derivation, so a reserved two-hand fixture contributes weight and effects once. Unequipped carried items contribute no combat burden.

Add a slot by creating a `TacticalEquipmentSlotDefinition`, adding it to the ruleset, then listing its ID on compatible items. Empty, duplicate, unknown, self-reserved, or contradictory slot references fail ruleset validation. Do not encode new slots in the Character screen; it enumerates ruleset data.

Preparation is the only mutation surface. The same five-tab Character screen is available from Mihata’s contextual battle actions for inspection, with equipment/build controls disabled and an explanation. Level grants, deterministic RNG notes/fixtures, and Seconds per strike are consolidated under preparation’s `Development Tools` entry.

Before shipping a future persisted build, store its ruleset ID/revision and explicitly handle removed or renamed IDs. Do not reuse the current session object as a save format.

## Forecast and strike presentation

Chapter One builds its opposed forecast only from `TacticalCombatPreview` and presents resolved attacks only from `TacticalCombatExchangeResult` / `TacticalStrikeResult`. Presentation code must not roll, parse prose history, change grid coordinates, or infer reactions. New resolver outcomes should first add explicit structured result data, then add a presentation cue that returns its animation pivot to the stable tile anchor on completion or cancellation.

The current forecast shows the resolver's ordered initiating attack, conditional Riposte, normal counterattack, and eligible speed follow-up. Each card identifies direction, ordinary per-hit damage, hit chance, and crit chance. Relevant block results and attack speed appear in the opposed unit panels. Potential-loss HP bars count currently scheduled ordinary strikes; they deliberately exclude blocks, crit multipliers, the conditional Riposte, and strikes that could be prevented by an earlier death or stun. Previewing never consumes RNG. Keep formulas inside the bounded scrollable calculation detail and keep confirmation controls outside it.

## R2 combat coefficients

The selected ruleset owns the editable coefficients. Red Alchemist currently uses:

- `burden = max(0, equipped_weight - floor(Strength / strength_burden_divisor))`, with divisor 2.
- `attack_speed = max(0, Speed - burden)`.
- One speed follow-up when the attack-speed difference is at least `speed_follow_up_threshold` (4). A defender can receive it only when eligible for a normal counter.
- `critical = clamp(weapon critical + floor(attacker Skill / critical_skill_divisor) - floor(defender Skill / critical_skill_divisor) + modifiers, 0, 100)`, with divisor 2 and a 2× ordinary-damage multiplier.

An exchange is strictly initiating attack → conditional defender Riposte → defender normal counterattack → one eligible speed follow-up. Riposte checks only the initiating attack and triggers only after its dodge or full block; counterattacks and follow-ups never start reaction chains. Every executed strike rolls its own applicable hit, block, and crit checks and rechecks life, range, stun, and terminal state. Extra strikes do not consume or refresh normal activation.

`damage_type = physical` uses Strength for attack power, Defense for ordinary mitigation, and the physical shield-block route. `damage_type = magical` uses Magic and Resistance and bypasses physical block while `magic_bypasses_physical_block` is true. Red Alchemist has no spell or magic-class content yet; the magical route is covered only by a test fixture.

Successful blocks never roll or apply critical multipliers. At or below defender Strength they deal zero; above Strength they deal the direct power-minus-Strength overflow and stun. Thus power 13 against Strength 10 remains exactly 3 HP plus stun regardless of Defense.

`mihata_token.gd` is the replaceable sword-and-shield placeholder renderer used by every on-map unit. Reuse does not grant combat capability. `presentation_group` chooses the blue/green/yellow/red/purple palette; faction and alliance data alone decide targeting and hostility.

The development-only Seconds per strike preference is local presentation data (`user://red_alchemist_playback.cfg`), not campaign state. Its authored bounds are 0.25–3.00 seconds in 0.05 steps; the accepted Medium value and initial default are 1.00 second per strike. Playback uses fixed anticipation/impact/recovery proportions and an additional 0.40-second lethal hold. Speed changes must never affect resolver calls, AI choices, RNG consumption, HP, or activation state.

## Focused validation

Run Godot headlessly with `res://tests/combat_progression_tests.gd` for definitions, formulas, reactions, and status lifecycle; `res://tests/tactical_tests.gd` for rescue behavior and seeded simulations; `res://tests/mouse_input_tests.gd` for full viewport mouse/keyboard paths; `res://tests/r1b_tests.gd` for forecast/presentation behavior; and `res://tests/r3_tests.gd` for owned inventory, atomic equipment transactions, flexible/reserved slots, preparation, unified Character tabs, restart/unload ownership, and battle inspection. `res://tests/r3_render_capture.gd` regenerates the R3 review images in `docs/` with a real renderer; pass `-- --compact` for the exact 900×560 capture.
