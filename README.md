# The End of the World Was Nice

A 20-second browser game. A meteor lands at 20.0 seconds; until then, walk around one screen and hold the button next to five things (hug someone, pet the dog, eat the cake, watch the sky, call mum). You will not get to all five.

Play it: https://thegrumpygamedev.itch.io/the-end-of-the-world-was-nice

Controls: arrows or WASD to move, hold Space or Z next to something, R or a tap to play again. On touch devices, the on-screen d-pad and DO IT button.

Written in [Odin](https://odin-lang.org/) compiled to WebAssembly (`js_wasm32`), drawing to a 2D canvas. The art and sound effects were made in the Anvil of SPLORR!! The game, the art and the sounds were made with Claude (generative AI). Text is the m5x7 pixel font by Daniel Linssen (managore).

## Build

Needs Odin (a recent nightly), Python 3, and Pillow only for the cover.

```bash
tools/test.sh                              # native tests, plus type-checks for wasm
tools/build.sh                             # builds build/web (use --size for the shipping build)
python3 -m http.server -d build/web 8000   # then open http://localhost:8000/
```

`tools/ship.sh` builds a zip for itch.io and pushes it only with `--push`. See `CLAUDE.md` for the architecture, and `DESIGN.md` for the design decisions.
