# Data Editor — Pokémon Essentials 19.1

**Version 1.0.0** · A local [Maker Studio](https://github.com/Toskan4134/maker-studio) mod for Pokémon Essentials 19.1.

This data editor covers most PBS data editing with an easy-to-use UI inside Maker Studio.

### Pokémon and forms

Edit Pokémon identity, types, stats, abilities, evolutions and forms.

<img src="assets/readme/1%20-%20Pokemon.png" alt="Pokémon editor" width="760">

Learnt moves can be searched, reordered and sorted.

<img src="assets/readme/2%20-%20Pokemon%20moves.png" alt="Pokémon level-up moves" width="760">

### Moves, items and abilities

Create, edit or remove moves with visual type and category controls.

<img src="assets/readme/3%20-%20Moves.png" alt="Move editor" width="760">

Items expose their fields through guided controls, including pockets and usage settings.

<img src="assets/readme/4%20-%20Items.png" alt="Item editor" width="760">

Abilities use the same searchable catalog workflow.

<img src="assets/readme/5%20-%20Abilities.png" alt="Ability editor" width="760">

### Trainers and parties

Configure trainer types and battles.

<img src="assets/readme/6%20-%20Trainers.png" alt="Trainer party editor" width="760">

### World tools

Edit regional maps and their points visually, including Fly destinations.

<img src="assets/readme/7%20-%20Townmap.png" alt="Town map editor" width="760">

Configure encounter methods, weighted Pokémon slots and level ranges.

<img src="assets/readme/8%20-%20Encounters.png" alt="Encounter editor" width="760">

Edit map metadata with rendered map previews and visual coordinate pickers.

<img src="assets/readme/9%20-%20Metadata.png" alt="Metadata editor" width="760">

Review and edit map connections on a navigable atlas that shows how maps fit together.

<img src="assets/readme/10%20-%20Connections.png" alt="Map connection editor" width="760">

### Elite Battle DX integration

When the **Elite Battle DX** plugin is installed, Data Editor includes an integration of **EBDX Sprite Positioner**, created by **Luka S.J.** to edit
Pokémon positions in battle.

<img src="assets/readme/11%20-%20EBDX%20Positioner.png" alt="EBDX Sprite Positioner integration" width="760">

### Safe saving

The editor preserves unedited lines and comments, validates data before saving, verifies the write afterwards, and creates `*.maker-studio.bak` copies of edited PBS files.

### Project structure

```text
com.miquel17.data-editor-19-1/
├── index.js          Maker Studio entry point
├── manifest.json     Mod identity and permissions
├── assets/           Distributed visual assets and README screenshots
├── src/
│   ├── app/          Editor composition and workspace state
│   ├── core/         Saving, validation and change tracking
│   ├── pbs/          Essentials 19.1 PBS parsing and editing
│   ├── world/        Town map, encounters, metadata and connections
│   ├── ebdx/         Optional Elite Battle DX integration
│   ├── ui/           Interface, controls and localization
│   └── infrastructure/ Project files and resource discovery
└── tests/            Automated regression tests
```

### Installation

This mod requires [Maker Studio](https://github.com/Toskan4134/maker-studio).

You can seach it in the mod marketplace and install it from there.

Otherwise, clone this repo in a path like this:

```text
<project>/Plugins/MakerStudio/003_Editor/Mods/com.miquel17.data-editor-19-1/
```

Restart Maker Studio and open **Mods → Data Editor — Pokémon Essentials 19.1**.

After saving PBS files, compile the data using Pokémon Essentials debugging tools to regenerate the game's `.dat` files.
