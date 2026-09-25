# Riftstray — finding your way around

Updated 2026-09-25. Navigation guide, not a request to restructure the project.

## Locate the actual project first

**The Godot project and Git repository are at `D:\Riftstray`.** Godot's `res://` paths are relative to that directory.

`C:\Users\fprud\Documents\ChatGPT\Riftstray` is the chat workspace. It contains documentation copies, art experiments and recovery backups. It is **not** the game source. A chat may start there: use `D:\Riftstray` explicitly when reading or editing the game. Do not create a second project in the chat workspace.

Start with `D:\Riftstray\AGENTS.md` for ownership/workflow rules and `development/docs/PROJECT_OVERVIEW.md` for game context. This guide supplies locations; the current user request supplies the work scope. Read only the source relevant to that request. Do not run tests or launch Godot unless authorized.

## Repository root

- `project.godot`: Godot project configuration.
- `app/main.tscn` and `app/main.gd`: Riftstray application shell, main interface and world selection.
- `core/worlds/`: world definitions, catalog and context passed to worlds.
- `core/persistence/`: application settings and informational crossworld data.
- `content/world_catalog.tres`: available worlds.
- `worlds/red_alchemist/`: the active Red Alchemist implementation.
- `development/docs/`: canonical project documentation. `README.md` is its index; `design/` holds drafts; `archive/` holds superseded material.
- `tools/`: development tools, including the existing escort smoke script. Presence does not authorize execution.
- `shared/`: shared code; inspect actual callers before assuming an older implementation here is still used.
- `.godot/`: generated editor/import cache, not authored source.

Old backups, archived milestone reports and legacy handoffs are not the current implementation. Do not restore their architecture or follow their next-task instructions by default.

## Red Alchemist folders

All paths below are relative to `D:\Riftstray\worlds\red_alchemist`.

### Entry and routing

`world.tres` identifies the world. `entry.tscn` and `entry.gd` connect its menus, saves, campaign locations and map screen. `content/campaign.json` defines story locations; `system/chapter/campaign_locations.gd` reads that catalog.

### display/ — what players see and interact with

Layouts belong in editable `.tscn` scenes. Scripts bind data, forward input and present results; they do not own combat rules, turn allowances or save progression.

- `menu/`, `new_game/`, `load_game/`, `end_of_content/`: world menus and associated screens.
- `map/map.tscn`, `map/map.gd`: map screen and interaction coordination.
- `map/board.gd`: map image, terrain fallback, tactical highlights and grid input.
- `map/selection/map_selection.gd`: translates selected cells into interaction requests.
- `map/weather/snowfall.tscn` and `.gd`: snowfall presentation.
- `npc/npc_layer.gd`, `npc/unit_view.gd`: on-map unit views; `npc/sprite_facing.gd` owns each view's directional state.
- `movement/`: movement-range presentation.
- `actions/`: character action menu.
- `inventory/modal/`: inventory side window and item information.
- `character/compact/`: compact character information display.
- `battle_preview/`: forecast interface. Forecast calculations are in `gameplay/battle_preview/`.
- `dialogue/dialogue_panel.tscn` and `.gd`: portrait, speaker name, dialogue text and advance input.
- `animation/animation_manager.gd`: combat/movement presentation coordination; `animation/effects/` contains individual effects.
- `objectives/objective_text.gd`: formats objective progress supplied by gameplay.

### gameplay/ — reusable mechanics

- `character/`: named-character definition schema and runtime character state.
- `npc/`: nameless NPC definitions, creation, groups, spawns and reinforcements. `behavior/` contains separate behaviors such as charge, stand ground and reach destination.
- `attributes/`, `classes/`, `skills/`: attribute rules, class definitions, skill families, slots and selections. Existing class/NPC resources also live alongside these systems; do not relocate them incidentally.
- `progression/xp_manager.gd`: XP and level progression.
- `actions/action_manager.gd`: action allowance.
- `movement/movement_manager.gd`: movement allowance and movement execution. `destinations/escape_handler.gd` handles authored escape destinations.
- `battle/turns/turn_manager.gd`: faction turns and operations such as Wait. `npc_turn_runner.gd` coordinates NPC phases.
- `battle/battle_session.gd`: battle session coordination; `battle_manager.gd`, `attack_resolver.gd`, `battle_rules.gd` and `exchange_order.gd` resolve combat.
- `battle/chances/`: hit/critical/skill/block-related chance handling. `battle/targeting/`: range and target selection mechanics.
- `battle_preview/battle_preview.gd`: forecast calculation, separate from the display and actual resolution.
- `inventory/`: item definitions, inventory and use. `effects/`: reusable effects such as percentage healing, extra movement/actions and maximum-HP reduction.
- `gear/`: equipment definitions and equipped state.
- `map/`: terrain definitions, grid, traversal and pathfinding; `map/terrain/*.tres` holds terrain costs and fallback appearance. No character combat or chapter victory logic.
- `win/`, `defeat/`, `conditions/`: outcome managers, map facts and reusable condition checks.

### system/ — saves and story coordination

- `save/save_file.gd`: file reading/writing.
- `save/save_slots.gd`: six slots and slot metadata.
- `save/campaign_state.gd`: serialization/restoration of story, player roster and optional full map snapshot.
- `chapter/chapter_data.gd`: loads passive chapter files into runtime definitions.
- `dialogue/dialogue_manager.gd`: reads dialogue data and advances lines.
- `story/scene_runner.gd`, `story/steps/`: executes story sequences, including walking and dialogue.
- `story/events/`: evaluates chapter-authored triggers, tutorial restrictions and event progress.

Do not put new chapter-specific NPC definitions or potion-specific rules in these managers.

### content/ — authored data

- `items/*.tres`: individual items, their descriptions and reusable effect configurations. For example, `healing_potion.tres` and `crimson_resolve.tres`.
- Terrain resources live in `gameplay/map/terrain/*.tres`, not content. Chapter map data references them.
- `chapter/chapter1/chapter.json`: chapter manifest, preparation/deployment options, weather, next location and map revision.
- `chapter/chapter1/map.json`: terrain resource list, tile rows and escape tiles.
- `chapter/chapter1/placements.json`: initial units and reinforcements, templates, levels, cells and assigned behaviors.
- `chapter/chapter1/objectives.json`: victory and defeat configuration.
- `chapter/chapter1/events.json`: conditional events and tutorial restrictions.
- `chapter/chapter1/opening.json`: opening sequence.
- `chapter/chapter1/dialogue/*.json`: speakers, portrait references and dialogue lines.

Chapter content does not execute itself. The user's later map-image convention is an explicit exception to the older AGENTS prohibition on chapter visual assets: **`chapter/<chapter>/mapvisual.png` lives beside that chapter's manifest.** The map display looks for this filename in the active chapter directory and falls back to terrain tiles when absent. It is a background image, not the movement grid; terrain changes in `map.json` do not repaint it.

### src/ — named characters and their assets

Mihata's folder is **`src/character/main/mihata/`**:

- `mihata.tres`: fixed starting attributes, level, level cap, class, initial items, gear, skills and base sprite reference.
- `avatar/03_refined.png`: current dialogue portrait, referenced by dialogue data.
- `Sprite/03_refined/Idle/rotations/`: directional sprites. The display loads `south.png`, `north.png`, `west.png` and `east.png` beside the assigned sprite; missing directions fall back to the assigned sprite.

Sophie currently lives at `src/character/sophie/sophie.tres`. Do not assume every named character has the same intermediate folder layout. Search by character name when needed.

Starting definitions do not overwrite existing save records. A new item or attribute change in `mihata.tres` normally requires a new game to see those defaults.

## Find files without asking the user for paths

Use the task's responsibility first: appearance/input → `display`; mechanics → `gameplay`; authored chapter/item settings → `content`; named-character defaults/assets → `src`; saving/story coordination → `system`.

Useful scoped searches from `D:\Riftstray`:

```powershell
rg --files worlds/red_alchemist/src -g '*mihata*'
rg --files worlds/red_alchemist/display -g '*dialogue*'
rg -n 'wait_unit' worlds/red_alchemist/gameplay worlds/red_alchemist/display
rg -n 'healing_potion' worlds/red_alchemist
```

Follow resource references and callers to establish the active path. Do not scan backups or load all documentation for a small edit. If a location has moved, locate it with `rg --files` rather than inventing a new parallel system.

## Creating folders

Follow the **Folder creation approval** section in the root `AGENTS.md`: propose the exact new folder path and purpose and get confirmation before creating it, including subfolders. A folder explicitly requested or already approved needs no second confirmation.

`AGENTS.md` also holds the authoritative **Subfolder approval exceptions** list. When the user says "stop asking for sub folders" for a specific parent, add that repository-relative parent path there. Future agents can create descendants there without asking again. No standing exceptions are granted merely by this documentation or by approving a single folder.