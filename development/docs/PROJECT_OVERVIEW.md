# Riftstray — project overview

Updated: 2026-09-23. Read this for context, not as a request to implement everything described below.

## What the game is

Riftstray is a Godot game inspired by Fire Emblem and 2D Zelda. Its base application is a launcher: a main menu, options, world selection, and a small store of crossworld information. Players select separately authored worlds, similar to DLCs. Each world owns its story, gameplay and progression, and may differ substantially from the others.

The first world is **Red Alchemist**, currently focused on turn-based tactical combat. The goal is a playable, readable game built from small, understandable parts that can be edited and reused without accumulating special-case code. This is an evolving prototype, not a finished design.

Crossworld data is informational. A world can record a fact, such as having been played or a major choice; another world may choose to react to it. The shared shell should not implement world-specific consequences.

## Red Alchemist and Chapter 1

The central character is **Mihata Shirogane**, a sword-and-shield fighter associated with power through sacrifice. Her authored starting level is 8, class Fighter, and current personal level cap 10. Named characters have fixed starting attributes; Mihata favors HP and defense, has 1 Magic and low Resistance.

The story premise: Mihata kills a noble who is abusing a courtesan. Facing retaliation, she helps six courtesans flee while she holds off their pursuers. Sophie is a named character among this story's cast; being a courtesan is a role, not automatically a combat class.

Chapter 1 is a guided escape tutorial. Courtesans move toward safety on their own. Enemy pressure and a scripted casualty introduce Mihata's costly potion. Dialogue guides the player to select Mihata, open Inventory and use it; the game should not force the inventory open. A small number of reinforcement waves keeps the escape urgent.

The underlying escape objective is that all surviving courtesans flee, with at least three surviving. Four courtesan deaths cause defeat. Chapter-specific guidance, events, spawns and objectives are authored as data and evaluated by reusable systems.

**Crimson Resolve** permanently reduces maximum HP and grants extra movement and an extra action for the battle, allowing Mihata to move and act twice per turn. Its scarcity comes from availability, not potion-specific engine code. It combines reusable item effects. A retry restores the chapter-entry state, including the unused potion and original HP; a victory retains the permanent cost.

## Gameplay direction

- Movement and actions are independent allowances. After attacking, a character with movement remaining should be able to move again before choosing another action.
- Combat uses attributes, weapon range, hit, critical, evasion and block chances. Weapon weight affects effective speed and follow-up attacks. Preview is separate from resolution and must not roll outcomes.
- Normal melee exchange includes an attack and an eligible counterattack. Riposte is an additional skill-triggered strike between them, with no reaction chains. Skill-triggered attack replacements such as Astra take priority over a normal or critical attack.
- A successful overpower block negates damage but stuns the defender. Earlier overflow-damage proposals are superseded.
- Player characters earn level-difference-based XP on a 0–100 progress scale. Attributes are manually allocated; the intended budget is 3–5 points per level. Nameless NPC attributes vary at creation and are preserved on save/load.
- The latest skill direction is class-family access to six slots by level 30, with two choices per slot. Unlocked alternatives can be swapped during preparation. Exact skills, unlock levels and balance remain editable. Earlier branch-investment promotion plans are historical, not the default specification.
- Inventory and gear are separate. Inventory holds six unequipped items. Equipment slots should remain extensible.
- Terrain affects movement according to movement type and can grant bonuses. World-specific rules should be replaceable without rewriting the interface.

## Interface and presentation

Riftstray retains its world selector. Red Alchemist has New Game, Continue and Load Game, with six save slots. New Game records difficulty and Casual/Classic preference; do not assume every mode-specific rule is finished.

Selecting a controllable character exposes movement. Selecting its destination or selecting it again opens actions. Selecting an enemy in range opens the forecast and an explicit attack confirmation. Mouse and keyboard should share this flow.

Readable forecasts, visible combat feedback, compact character information and small menus matter more than elaborate visuals. Dialogue advances through click/confirm and can coordinate map-sprite movement for story scenes. The end of available content has a simple thank-you screen and return button.

Faction colors: blue player, green non-fighting friendly, yellow fighting ally, red enemy, purple secondary enemy. Art is provisional. Current sprite experiments aim for small, readable sword-and-shield figures inspired by the supplied pixel-art references; no draft should be treated as approved final art.

## Persistence and structure

Saves retain a single story location and the player roster, including XP, levels, attributes, skills, inventory and equipment. Mid-map saves additionally retain all map participants, positions, generated NPC values, turn allowances and event progress. Victory carries progression forward and heals surviving players to their resulting maximum HP; retry restores the chapter-entry snapshot.

The project is at `D:\Riftstray`, repository `https://github.com/Runmih/Riftstray.git`. Read the root `AGENTS.md` before editing. It defines ownership for `display`, `gameplay`, `system`, `content` and `src` inside Red Alchemist. Chapter content is passive data; displays present information; gameplay owns mechanics. Use the systems already present rather than adding parallel implementations.

## Starting a new chat

Use [FILE_STRUCTURE.md](FILE_STRUCTURE.md) to locate source files without asking the user for paths.

Read this overview and `D:\Riftstray\AGENTS.md`, then the user's specific task. Read only the relevant source files afterward. This overview summarizes intent; it is not a verified inventory of implemented features. Do not infer runtime correctness or completion from it.

Keep changes bounded and token use low. Do not run tests or launch the game unless requested. Avoid repeated self-check loops, unsolicited features and broad refactors. Ask when a real structural ambiguity blocks the requested work. Archived plans and test counts are historical, not current instructions.
