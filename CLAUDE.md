# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## State of the repo

The game is "Nice Apocalypse" (see `DESIGN.md` for decisions and open questions). A working skeleton exists: a player square moves on a 240x192 canvas while a 20-second bar drains, then the screen flashes white.

```bash
tools/test.sh                 # native tests of src/game + odin check of both packages for js_wasm32
tools/build.sh [--size]       # builds build/web (game.wasm, odin.js, index.html); --size for shipping
python3 -m http.server -d build/web 8000   # serve it; wasm cannot load from file://
odin test src/game -collection:tggd=src -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_NAMES=game.run_ends_at_twenty_seconds   # a single test
```

Layout: `src/game` is the pure rules (`step(&game, input, dt)`, dt in seconds, no platform imports); `src/web` is `#+build js`, owns key input, `step` export and drawing through the `fill_rect` import; `web/index.html` holds the JS canvas shim and is copied by the build. Both packages are imported with `-collection:tggd=src`. Task tracking is in the Coxswain project `tggd-20seconds` (tools need `agent: "claude"`; register first).

## The project

A game for the [20 Second Game Jam 2026](https://itch.io/jam/20-second-game-jam-2026) on itch.io (submissions October 23 to about November 17, 2026). Rules that shape design:

- A play-through or level lasts **20 seconds or less** of gameplay; title, menus and cutscenes do not count but should be minimal or skippable. Multiple 20-second levels are allowed only if each is self-contained (nothing carries over). An endless mode is fine only if the default is the 20-second one.
- A **free browser version hosted on itch.io** is required; a broken web build disqualifies. Other platforms are optional.
- Optional themes: "The End of the World is Nice", "Double or Quits", "You Are What You Eat", "Out of Order". Use any, combine, or ignore.
- Disclose generative AI use in the page's "AI generation disclosure" field; the jam wants human-made games. Mark mature content and flashing effects.

## Stack and tooling

- **Odin compiled to `js_wasm32`**, drawn on an HTML5 2D canvas through a small JS shim (no WebGL, no emscripten). Odin is `dev-2026-07` at `~/.local/bin/odin`.
- **Anvil** (MCP server `anvil-prod`, source in `/home/yermom/git/anvil-of-splorr`) is the asset editor for sprites, tiles, maps, palettes and sounds; worlds are saved as JSON in `/home/yermom/anvil-worlds`. Use its tools (`world_*`, `sprite_*`, `map_*`, `sound_*`, `render_*`) to make and preview assets, and `world_export` / `sound_export` to get them into the build.
- **Coxswain** (MCP server `coxswain`) tracks tasks. Create a project for this game (none exists yet) and file work there (`task_create`, `task_claim`, `task_complete`) instead of keeping ad-hoc TODO lists in the repo.
- The user's knowledge base is the **BOK** at `/home/yermom/git/bok-of-splorr/splorr` (an additional working directory). Read `Home.md` first; relevant notes: `Tech/Odin wasm recipe.md` (build, frame loop, input, and a catalogue of architecture variants), `Tech/Release standard.md`, `Tech/Shipping to itch.io.md`, `Tech/jsfxr sound effects.md`, `Gotchas.md`. Add new lessons to `Gotchas.md` there, not here.

## Build recipe (from the BOK; adapt when the layout exists)

```bash
odin build src -target:js_wasm32 -out:build/web/game.wasm -o:speed   # -o:size for shipping
cp "$(odin root)/core/sys/wasm/js/odin.js" build/web/
python3 -m http.server -d build/web 8000                              # wasm must be served over http, not file://
odin test src/game -collection:tggd=src -define:ODIN_TEST_THREADS=1   # native tests of the pure rules package
```

Architecture the user's recent Odin games converge on (see `Turn Left at the Cow` and `Roomba Rights` in the BOK):

- A **pure rules package** with no platform imports (clock and RNG passed in as arguments, so it is testable natively and a 20-second run is deterministic), plus a thin `#+build js` web package that owns `step`, input and drawing. Test files are `#+build !js` (`core:testing` panics on wasm).
- `odin check` the web package with `-target:js_wasm32`, and use `-vet-shadowing -vet-unused` explicitly, since `odin check` does not apply them.
- Seed the RNG in `main` (`rand.reset`); Odin constant arrays cannot be indexed at runtime (declare with `:=`).

## Release (itch.io)

Follow the BOK's `Release standard`: `ITCH_DESCRIPTION.md` and `assets/cover.png` (630x500) at the repo root, screenshots in `assets/screenshots/`, `devlog/YYYYMMDD/`, `tools/build.sh`, `tools/test.sh`, `tools/ship.sh` plus a one-line `shippit.sh` wrapper that pushes only with `--push`. Never run `shippit.sh --push`, `butler push` or `git push` unless the user explicitly says so (if "push" is ambiguous, ask git or itch). New pages use channel `html`. The user sets the project kind and pastes the page copy by hand.
