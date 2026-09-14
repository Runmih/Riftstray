# Red Alchemist menu

Riftstray -> Select World -> Red Alchemist.

- entry.gd / entry.tscn: connect this world to Riftstray's loader.
- system/display/menu/start/menu.gd / menu.tscn: compose the menu and quit modal; forward navigation requests.
- system/display/menu/start/start_menu.gd / start_menu.tscn: buttons, artwork layout and menu signals.
- system/display/menu/start/menu_content.gd: text resource definition.
- content/interface/menu.tres: world-specific menu text and availability messages.
- system/display/menu/start/modal/quit_dialog.tscn: exit confirmation.

New Game forwards a request to entry.gd; gameplay startup is not connected yet and shows a message. Continue and Load Game are disabled until save loading is connected. No chapter-selection screen remains in this menu. Back returns to Riftstray's world selection.

No tests, game launches or verification passes were run for this change.
