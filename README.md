

# Sound Space Plus: Perihelion Rewrite

### Sound Space Plus Plus, technically.

A stripped-down, Windows-only fork of the classic **Sound Space Plus**.

![Godot 3](https://img.shields.io/badge/Godot-3.x-478cbf?logo=godot-engine&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-0078d4)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-work%20in%20progress-orange)

## Play in your browser

This copy also builds for the web (Godot 3.6.2 HTML5 export):
**https://iloverhythia.github.io/test67/**

Web notes:

- The web build has no threads, so content loading runs on the main thread instead.
- On iPhone and iPad it uses Godot's GLES2 renderer, because the GLES3 one crashes there
  ("WebGL context lost"). Particle effects are switched to CPU particles for that. You can force
  a renderer with `?renderer=gles2` or `?renderer=gles3` at the end of the URL.
- The UI scales to fit the screen. On phones, turn the phone sideways. Tap to skip the intro.
- Saves (settings, scores, replays) are kept in your browser's storage.
- Adding your own maps from disk is not supported in the browser yet.

To rebuild it, export with the `HTML5` preset in `export_presets.cfg` and publish the
`build/web` folder (for example to the `gh-pages` branch).

## Why this exists

Sound Space Plus used to have online servers that calculated performance points. Those servers are
gone, and with them went pp. The game itself is open source, so this fork rebuilds the missing piece
on the client:

- no accounts, no server, no network needed
- a difficulty algorithm that reads the notes of **any** map
- a pp formula in the spirit of osu!, with weighted top plays
- scores saved on your own machine

It is also a cleanup project: remove everything we do not need, keep the game small and readable,
and make it a good base to build on (and eventually port to a newer Godot engine).

## Features

| | |
|---|---|
| **Local pp** | Passing a map awards pp based on the map's difficulty, your accuracy, and your speed mod. A notification shows the result on the results screen. |
| **Difficulty ratings** | Stars are computed from note positions and timing, so every map is rated, not just ones from a database. |
| **Top plays page** | A new page in the sidebar shows your total pp and your top 10 plays (pp, weighted pp, accuracy, misses, speed, stars). |
| **Max pp preview** | A card under the modifiers shows what 100% on the selected map would be worth at your current speed, your best on it, and how much it would raise your total. |
| **Fair-play gating** | No pp with easier-than-default hitbox or hit window, Nofail, a start offset, replays, or queue mode. Failed runs award nothing. Might be changed a bit later. |

Everything else (maps, mods, replays, settings, the menu) works like the original game.

## What was removed

Compared to upstream, this fork deliberately drops:

- Discord Rich Presence and the Discord SDK addon
- VR support (OpenVR)
- the native file dialog addon (the game's own file picker is used)
- the legacy menu and its settings
- the avatar system and other easter eggs
- the online map database and the auto-updater (networking is disabled)
- Android, macOS, Linux, and web code paths: **Windows only**

## Building and running

There are no release builds yet, so run it from source.

**Requirements**

- [Godot 3.x](https://godotengine.org/download/archive/) (use the same 3.x version as the upstream project)
- [Git LFS](https://git-lfs.com/) for the large asset files

**Steps**

```sh
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
git lfs fetch --all
git lfs pull
```

1. Open Godot 3 and import `project.godot`.
2. Press **F5** to run.

To make a distributable build, install the Godot 3 export templates and export with a Windows
preset (**Project > Export**).

> [TIP]
> If you run from the editor, the game's own personal-best saving is skipped (it checks for a debug
> build). pp saving is not affected.

## Your data

Saves keep the original folder name so existing settings and maps from Sound Space Plus carry over.

| Item | Location |
|---|---|
| User folder | `%appdata%\SoundSpacePlus` |
| Maps | `%appdata%\SoundSpacePlus\maps` |
| Settings | `%appdata%\SoundSpacePlus\settings.json` |
| Replays | `%appdata%\SoundSpacePlus\replays` |
| **pp scores** | `%appdata%\SoundSpacePlus\pp_scores.json` |

You can also open it from **Settings > Open User Folder**. To reset your pp, close the game and
delete `pp_scores.json`.

## Roadmap

These are plans, not promises.

- [ ] Calibrate the star rating against more maps. The current algorithm is insanely doodoo compared to what it could be
- [ ] Continue removing unused scripts, scenes, and assets
- [ ] Fully remove online-map leftovers. Potentially add online features back at a later date
- [ ] Rebalance pp (length, accuracy curve, mod handling such as Hard Rock)
- [ ] Better profile page (recent plays, pp history)
- [ ] Port to the latest Godot Engine (impossible task)

## Contributing

Issues and pull requests are welcome. Please keep changes small and focused, and run the game before
you open a PR. :)

## Credits and license

This project is built on **Sound Space Plus**, created by its original developers and contributors.
See the in-game **Credits** page, and the upstream repository:
[David20122/sound-space-plus](https://github.com/David20122/sound-space-plus).

Maps and music belong to their respective creators.

Licensed under the **MIT License**, same as upstream. See [`LICENSE`](LICENSE).
