# Riftstray structure cleanup

Agreed scope: 14 September 2026.

Project: `D:\Riftstray`. This document defines the cleanup; it does not claim that the changes have been implemented.

## Working rules

- Preserve the Riftstray shell and world selection. Work on the active Red Alchemist implementation; leave the backup world alone.
- Complete one numbered step at a time. Do not use this document as permission for an unrestricted rewrite.
- Read only the files needed for the current step. No tests, game launches, or repeated self-check loops unless the user explicitly authorizes them.
- Reuse existing mechanics. Add a script only for a clear responsibility that is not already owned elsewhere. Do not introduce a framework or central master script by default.
- Keep editable interface layouts in scenes and gameplay mechanics out of display scripts.
- Do not add unsolicited UI commentary, dynamic button wording, or unnecessary wrapper layers.
- Update affected references when moving files. Do not silently invalidate, delete, or overwrite existing saves. State any unavoidable compatibility limitation before implementing it.
- Report the files changed, responsibility moved, and any unresolved decision briefly after each step. Distinguish implemented changes from runtime verification.

## Agreed ownership

### Passive chapter information: `content/chapter/`

This folder contains data only. No executable scripts, scenes, or visual assets. Data may reference external character definitions, NPC types, maps' visual assets, items and other resources.

A chapter supplies:

- Its identifier and next story location.
- Whether preparation is available.
- Map dimensions, terrain layout and relevant map configuration.
- One consolidated placement list with stable instance IDs, named-character references or nameless NPC type, level where applicable, faction, starting position, behavior and behavior parameters.
- Whether the player may choose deployment positions, and the allowed tiles if so.
- Opening dialogue, conditional dialogue and scripted event data.
- Reinforcement placements and trigger conditions.
- Escape/destination information and win/defeat condition configuration.

Use a small set of related data files per chapter, such as `chapter.json`, `map.json`, `placements.json` and `events.json`, rather than one file per placed character. These names are a suggested organization, not a requirement to build a new schema framework. Dialogue and objective data may be grouped or separated when it improves readability.

Chapter data contains references and configuration, not copies of character templates. A placement entry may reference Mihata or Sophie; a separate Mihata-specific chapter script or placement resource is unnecessary.

### Chapter coordination: `system/chapter/`

If coordination is needed, this folder owns loading chapter information and passing it to existing preparation, map, NPC, story and condition systems. It contains no NPC definitions, chapter content, potion rules or hardcoded Chapter 1 sequence.

### Scripted events and tutorials

Use a reusable interpreter/coordinator for chapter event data, preferably extending the existing story system where its responsibilities fit. It evaluates configured triggers and requests operations from the owning systems.

Supported chapter needs include dialogue, story movement, reinforcements, a scripted casualty and tutorial restrictions/reminders. Restrictions must be enforced through the appropriate gameplay operation, not only hidden buttons. Combat must not know the name of a required item or character. Reminders remain dialogue-only: the player selects the character, inventory and item themselves.

Event completion and any active restriction must be restorable in an in-map save so loading does not repeat a casualty or reinforcement.

### Mechanics and presentation

- Existing movement, actions, turns, battle, inventory, gear, attributes and condition systems retain ownership of their mechanics.
- Movement reports a completed move. Configured destination/escape handling updates the unit state; win/defeat checks evaluate that state.
- Display receives state and submits player requests. It does not own chapter completion, turn resets, post-battle recovery or save progression.
- Condition checks own evaluation and progress values. Objective display formats those values without duplicating the rules.
- Action, forecast, dialogue, inventory and compact-character layouts belong in editable `.tscn` files. Drawing a bar or creating map unit instances dynamically does not require inventing additional scenes.

### Characters and NPCs

- `system/npc/` manages creation of nameless NPCs from supplied type, level and other parameters. The requesting system receives instances to place on the map.
- Named definitions, including Mihata Shirogane and Sophie, belong under `src`, following the existing named-character structure.
- NPC generation variation happens once at creation. Loading restores the generated values; it must not reroll them.
- Courtesan/citizen is currently an NPC role, not a class. Do not move the existing courtesan resource into classes and thereby formalize an unintended class. Represent a non-fighting NPC without a combat class and retain the explicit stats/movement it needs.
- Fighter and actual class definitions remain in the existing gameplay/classes structure. Similar names do not imply identical roles or resource types.

### Items and inventory

The potion is a normal item. Its availability in Chapter 1 makes it unique; no special item-ID or Mihata checks belong in inventory, battle or display.

Its effects are separate reusable operations configured by item data: maximum-HP reduction and additional movement/actions. Preserve the agreed persistent HP cost and battle-duration movement/action benefit. Preserve current configured balance values unless separately requested.

Tutorial conditions can refer to the relevant item/effect through chapter data. They must not require potion-specific engine code. Item use follows the normal consumption and action rules. The button remains `Use`.

Inventory mechanics own the six-slot capacity; display follows it. Establish how the existing gear ownership representation interacts with those six slots before changing capacity. Do not silently lose excess items from old saves or hide them behind a six-row interface.

### Saves

Each save slot remains one package of saved game information. Keep the existing six-slot flow.

Persistent campaign data contains:

- One story location/next-chapter identifier sufficient to resume the story; no growing list of completed chapters.
- Player characters' stable identities, XP, level, attributes, HP-related permanent changes, items, gear, selected/unlocked skills and other persistent progression.
- Existing chosen game options.

An optional in-map snapshot additionally contains:

- Active chapter/map identity and all present units: player, enemy and citizen, including exact generated attributes and current positions.
- Current HP, life/escape status, equipment/items and relevant temporary effects.
- Turn/phase, remaining movement/actions and any state needed to resume the current playable point.
- Reinforcements already created, scripted events already completed, active tutorial restrictions, objective counters and other changed map state.
- The chapter-entry state required for defeat/retry rollback, or an equivalent retained representation.

Enemy and citizen state belongs in the battle snapshot, not the persistent player roster. Retry restores chapter-entry state. Successful completion retains earned progression and item changes, removes battle-only effects, fills HP to the resulting maximum, and advances the single story location through the existing save flow.

Saving writes a save file, not character source definitions. Restoring populates runtime objects. Avoid reaching into private bookkeeping such as inventory's next-ID counter from unrelated save code. Small capture/restore methods on existing owners are sufficient where needed; no new serialization layer is requested.

## Ordered implementation steps

### Implementation record

Step 1 implemented on 14 September 2026, without tests or game execution:

- Chapter 1 now uses passive `chapter.json`, `map.json`, `placements.json`, `objectives.json`, `events.json`, `opening.json` and a `dialogue/` data folder. Initial units and reinforcements share the placements list.
- `system/chapter/chapter_data.gd` reads the data and constructs the resource objects used by the existing systems. The map scene references the chapter manifest rather than individual chapter resources.
- Preparation and deployment are explicitly disabled in the current chapter data, matching the current fixed-placement flow. This does not implement a preparation interface.
- Sophie moved to `src/character/sophie/sophie.tres` as a named character. Citizens use no class and an explicit classless movement value of 2. Fighter movement remains class-owned.
- The save loader accepts Sophie's old resource path and resolves it to her new definition. Existing save-slot files were not modified.
- The old chapter resources, scattered dialogue/story data, Sophie's old definition and the accidental courtesan class resource were removed after preserving copies.
- Existing escort behavior remains pending Step 2. Its character/item defaults now come from chapter data; this is not yet the reusable scripted-event implementation.

Recoverable originals: `C:\Users\fprud\Documents\ChatGPT\Riftstray\cleanup-backups\step1-20260914-032611`. That folder includes restoration guidance and a list of newly created files. Runtime correctness has not been verified.

Step 2 implemented on 14 September 2026, without tests or game execution:

- Replaced escort director/definition, reinforcement trigger resource and escort display guidance with `system/story/events/event_manager.gd` and `event_conditions.gd`.
- Chapter `events.json` now supplies action restrictions, the allowed item during the restriction, reminder source, conditional events, their steps and a per-trigger limit. Chapter 1 retains one reinforcement event per player-turn start.
- Opening dialogue/casualty still use the existing story runner. Added reusable reinforcement and phase-refresh step handlers; phase refresh preserves the current round and faction instead of restarting the battle.
- Battle, turn and item-use operations consult a generic permission callback. No potion-specific gate remains in battle/map selection. Reminder display only plays dialogue and returns focus to the map.
- Item use emits a generic notification. Event conditions record any item's use in saved map counters; the existing consumed-item field remains a read fallback for older snapshots. Reusable item effects themselves remain Step 3.
- Event completion and completed-step progress use existing saved counters. Reinforcement completion keeps the previous counter keys for old saves. All added dialogue is passive chapter data.
- The map supplies explicit story context instead of passing its entire screen object to escort guidance. Other map ownership cleanup remains Step 4.

Recoverable Step 2 originals: `C:\Users\fprud\Documents\ChatGPT\Riftstray\cleanup-backups\step2-20260914-033420`. No save-slot files were modified. This implementation does not add a preparation interface or expand the condition vocabulary beyond current chapter needs.

### 1. Consolidate passive chapter data

Create the chapter data organization above and consolidate current map configuration, placements, objectives, dialogue and event configuration. Move named Sophie to the named-character source structure. Remove the accidental courtesan-as-class representation without inventing a new class. Keep visual assets outside chapter content.

Completion: chapter information is consolidated and passive, and its consumers use the updated references. Do not leave duplicate authoritative old/new definitions.

### 2. Replace chapter-specific escort code with data-driven scripted events

Replace the current escort-specific director/definition responsibilities with reusable chapter/story coordination reading Step 1 data. Keep actual chapter rules in that data. Remove chapter-specific code from `system/chapter` and display guidance, including direct turn resets and hardcoded potion dialogue.

Completion: the opening, reminders, casualty and reinforcement sequence are configured by chapter data. No automatic inventory opening is reintroduced.

### 3. Make item effects reusable

Replace the potion-specific effect implementation with configured reusable effects. Route its use through normal inventory/item handling. Remove potion-name/ID checks from battle and display; chapter-configured restrictions use the scripted-event mechanism from Step 2.

Completion: another item could reuse either effect without modifying combat or inventory code. Persistent HP reduction and temporary action/movement benefits remain distinct.

### 4. Restore gameplay ownership

Remove citizen escape assumptions from generic movement/battle code. Connect configured destination handling to movement completion. Use existing win/defeat checks for outcomes. Move battle execution, turn changes and campaign transition responsibilities out of map display into their existing owners. Replace whole-screen access in helpers with the few operations/data they actually need.

Completion: generic combat has no Mihata/potion/Chapter 1 references; display does not decide gameplay outcomes or reset turns. Do not add a master script merely to relocate the same oversized responsibility.

### 5. Align campaign and snapshot saving

Remove fixed Chapter 1 identifiers from save handling and map completion logic. Record the single story location and optional complete battle snapshot described above. Restore NPC instances without random regeneration. Keep serialization straightforward and encapsulate private bookkeeping only where needed. Address resource-path changes from earlier steps explicitly.

Completion: campaign records retain player progression; in-map saves additionally retain enemies/citizens and event/turn state. Retry and completion follow the agreed rules. Save compatibility limitations are documented rather than silently discarded.

### 6. Enforce inventory capacity in mechanics

Make six-slot capacity authoritative in inventory operations. Align the existing inventory modal with that capacity. Handle equipment consistently and preserve existing overflow data pending an explicit resolution if necessary.

Completion: the UI cannot conceal items simply because mechanics permit more entries than it displays. No item-specific button behavior or extra confirmation modal.

### 7. Finish authored display scenes

Move code-built action, forecast and dialogue layouts into scenes. Put the compact character panel's actual controls into its existing scene. Keep scripts focused on binding state and interaction. Retain the established selection/movement/attack-preview flow and mouse/keyboard focus behavior.

Completion: layouts can be edited visually without reconstructing them in scripts. Remove redundant scene wrappers where they have no purpose; do not expand into the deferred full-character interface.

### 8. Separate objective presentation and remove superseded files

Format condition progress in the objective display rather than inside mechanics. Remove only files made obsolete by the preceding steps, with their references updated as part of the change. Preserve useful existing systems and the backup world.

Completion: objective text uses the same progress data as condition evaluation. No duplicate chapter definitions, obsolete escort implementation or redundant UI implementation remains from this cleanup.

## Handoff scope

For each implementation request, name one step from this document. Finish that bounded change and report any remaining dependency before proceeding further. Do not claim runtime correctness when execution was not authorized. Ask for clarification only where a concrete unresolved behavior prevents the current step from being implemented safely.
