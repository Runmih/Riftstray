# Current Handoff — G4a partial; Sol repair required

G3b remains accepted: architect `g3b3_tests.gd` 38/38; Sol previously reported 1,117 aggregate checks. G4a's contract is one generic path from authored character definition through ID-keyed build, mission, action, and result data. Character uniqueness belongs in authored data; evaluators contain no story identities.

Terra partially implemented G4a. Production `primary_character_id`, Mihata build/profile paths, selected-Mihata state, and the Mihata-named generic token were largely removed; chapters gained initial failure fields. Do not restart or broadly revert this work.

Reproduced blocker: `terrain_rows` disappeared from all three combat `.tres` resources. Each reports `Red Alchemist combat config has no terrain map rows`; missions start empty. Independent runs fail tactical 21/70 and R6b 20/41 as cascades. Restore the authored 10×8 layouts without redesigning maps.

G4a is also structurally incomplete: `objective_rules.gd` retains scalar legacy evaluation and `ObjectiveType` victory branching; `mission_state.gd` retains a positional legacy constructor and `_legacy_chapter_definition`; `turn_controller.gd` retains legacy summary state; Entry/chapter/tests retain objective-type and generic Mihata-named adapters. Replace these paths and update callers/tests to one ID-keyed, chapter-authored contract—no compatibility aliases.

Next owner: Sol/high, repair and complete G4a only. Preserve shipped outcomes, G3b, item-owner data, and shell/world boundaries. Do not change persistence schema or implement Casual/Classic, Sophie, classes, preparation, AoE, map redesign, or story. Run focused checks, then the full suite once; update this handoff with exact results.
