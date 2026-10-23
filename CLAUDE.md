# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## State of the repo

The game is playable: a title screen, then 20 seconds on one 240x192 screen to walk to five bucket-list items and hold a button on each, a meteor flash, and an epilogue listing what got done. Keyboard and on-screen touch buttons both work. See `DESIGN.md` for decisions and open questions. Task status is in Coxswain.

```bash
tools/test.sh                 # native tests of src/game + odin check of both packages for js_wasm32
tools/build.sh [--size]       # builds build/web (game.wasm, odin.js, index.html); --size for shipping
python3 -m http.server -d build/web 8000   # serve it; wasm cannot load from file://
odin test src/game -collection:tggd=src -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_NAMES=game.run_ends_at_twenty_seconds   # a single test
```

Assets: `assets/art/world.json` is an export of the Anvil world (source copy `~/anvil-worlds/nice-apocalypse.json`; sprites 16x16, 16-colour palette); `tools/gen_atlas.py` packs its sprites into `build/web/art.png` in sprite-set order, which must match `Sprite` in `src/game/art.odin`. Sound effects are PLAY-text sounds in the Anvil world exported to `assets/sfx/*.wav` (`sound_export`); `Sound` order must match `SOUND_FILES` in `web/index.html`. Text is drawn from a bitmap font sheet, `assets/font/m5x7.png` (m5x7 by Daniel Linssen, credited on the itch page), by `drawBitmapText` in `web/index.html`: whole-number scales only, `y` is the baseline, and glyph widths are measured at load. Do not go back to canvas `fillText`; it blurred the pixel art. To change art or sound: edit in Anvil, re-export both, rebuild.

Layout: `src/game` is the pure rules (`step(&game, input, dt)`, dt in seconds, no platform imports); `src/web` is `#+build js`, owns key input, `step` export and drawing through the `fill_rect` import; `web/index.html` holds the JS canvas shim and is copied by the build. Both packages are imported with `-collection:tggd=src`. Task tracking is in the Coxswain project `tggd-20seconds` (tools need `agent: "claude"`; register first).

## The project

"The End of the World Was Nice", a 20-second browser game, to be shipped on itch.io as a regular release. It was begun for the [20 Second Game Jam 2026](https://itch.io/jam/20-second-game-jam-2026) but **the user decided not to enter the jam** (the jam wants human-made games), so the jam's deadline and rules no longer bind; the 20-second run is now simply the game's design. Finish it, then ship it, following the Release section below. State generative-AI use honestly on the itch page (the art and sound here were made through Anvil by Claude).

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

Layout follows the BOK's `Release standard`: `ITCH_DESCRIPTION.md`, `assets/cover.png` (630x500, `tools/make_cover.py`, needs a built `build/web/art.png`), `assets/screenshots/` (`tools/make_shots.sh`, headless Chrome against the real build; it uses the `index.html#play=SECONDS` QA hook backed by the `qa_advance` export), `tools/ship.sh` with the one-line `shippit.sh` wrapper. The itch page is https://thegrumpygamedev.itch.io/the-end-of-the-world-was-nice and the target is `thegrumpygamedev/the-end-of-the-world-was-nice:html` (channel `html`).

`tools/ship.sh` runs tests, builds with `-o:size` and zips `build/web`; it pushes to itch.io **only with `--push`**. Never run `shippit.sh --push`, `butler push` or `git push` unless the user explicitly says so (if "push" is ambiguous, ask git or itch). The user sets the project kind and pastes the page copy by hand.
