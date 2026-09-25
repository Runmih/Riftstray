# Riftstray project instructions

These rules apply throughout this repository. Explicit user instructions take precedence.

## Ownership
- Preserve the Riftstray shell and world selector. Keep world-specific content inside its world.
- `worlds/red_alchemist/display/`: editable `.tscn` interfaces, map rendering, presentation scripts and animation effects. Bind data and forward input; do not decide battle outcomes, own turn allowances or advance campaign state here.
- `worlds/red_alchemist/gameplay/`: battle, turns, movement, terrain mechanics, attributes, classes, skills, inventory, gear, conditions, character runtime and nameless NPC creation/behavior.
- `worlds/red_alchemist/system/`: save handling, chapter loading and story/dialogue coordination. Do not turn it into a catch-all.
- `worlds/red_alchemist/content/`: passive configuration and resources. Chapter folders contain only data: map configuration, consolidated placements, objectives, deployment/preparation settings, dialogue and conditional events. No scripts, scenes or visual assets inside chapter data.
- `worlds/red_alchemist/src/`: named-character definitions and their assets. Named characters use fixed starting attributes. Nameless NPC variation happens at creation, not when restoring a save.
- A character role such as courtesan/citizen does not imply a combat class. Classless movement is explicit; actual classes own their movement and attribute gains.

- Terrain resources and their movement costs belong in `worlds/red_alchemist/gameplay/map/terrain/` alongside terrain mechanics. Chapter content references them; it does not own their definitions.

## Implementation
- Use existing systems and their public operations. Keep files small around real responsibilities; avoid central master scripts and unnecessary abstractions.
- Chapter-specific identities, placements and scripted requirements belong in data. Reusable combat, movement, item and display code must not know Mihata, Crimson Resolve or Chapter 1 by name.
- Items combine reusable effects. Item availability controls scarcity. Tutorial gating and reminders belong to chapter-configured events, not item effects.
- Movement and actions are separate allowances. After combat, consult gameplay state before choosing the next interface state.
- Win/defeat systems evaluate outcomes and supply progress data. Display formats objective text without duplicating condition logic.
- Author interface layouts in scenes. Repeated elements may instantiate reusable scenes; scripts should not rebuild entire layouts. Keep labels simple and menus compact.
- Save one current story location, a persistent player roster, and an optional full map snapshot including enemies/citizens, generated attributes, positions, turn allowances and event progress.
- Retry restores chapter-entry state. Victory retains progression and permanent costs, removes battle-only state and heals surviving players to their resulting maximum HP.
- Preserve existing saves when moving resources. Update references and migrate saved paths; never silently discard unavailable data or reroll saved NPCs.
- Inventory capacity is six carried, unequipped items. Gear is separate. Preserve legacy overflow and keep it accessible.

## Workflow
- Work on the requested bounded step. Stop for clarification when ownership or intended behavior is unclear.
- No unsolicited features, UI commentary, label switching, framework additions or broad rewrites.
- Do not run tests/game launches or repeat checking loops unless the user authorizes testing. When authorized, run focused checks and repeat only for failures or changed code.
- Back up or otherwise preserve recoverable originals before broad moves. Leave the old backup world untouched unless explicitly asked to remove it.
- Report changes and actual verification concisely. Do not claim runtime correctness without execution.
- `development/docs/archive/` holds historical plans, not current architecture instructions.

## Folder creation approval
- Before creating a new folder, propose its exact repository-relative path and purpose, and wait for the user's confirmation. This applies to subfolders too, unless covered by an exception below.
- An explicit user request or prior approval for that exact folder already counts as confirmation; do not ask again. Approval of one folder does not authorize unrelated folders.
- If the user says "stop asking for sub folders", record the applicable parent folder as a new line in the exception list below. Infer it only when the current context identifies one unambiguous parent; otherwise ask which path they mean.
- Each exception permits new descendant folders under that parent without further structure approval. It does not permit changes to ownership boundaries, unrelated moves/deletions, or broader task scope.
- Store exceptions as repository-relative paths, one per line. Only add an exception when the user explicitly requests it. Do not treat a single approved folder creation as a standing exception.

### Subfolder approval exceptions
None yet. Replace this sentence with path entries when the user grants an exception, for example: `worlds/red_alchemist/display/map/`.
