# Itch.io page text

Page: https://thegrumpygamedev.itch.io/the-end-of-the-world-was-nice
Pasted in by hand; nothing here is published by the repo.

## Short description

A meteor lands in 20 seconds. Pet the dog, hug someone, eat the cake: do what you can, and have a nice time of it.

## Paste this as the page description

The end of the world is nice.

A meteor is coming, and it lands in exactly 20 seconds. You have a little bucket list: **hug someone, pet the dog, eat the cake, watch the sky, call mum.** Walk to each one and hold the button until it is done. You will not get to all five, so choose.

When the meteor lands, the screen goes soft and warm, and the game tells you how your last 20 seconds went. Then you can go again.

**Controls:** arrow keys or WASD to move, hold Space or Z next to something to do it, R to play again. On a phone or tablet, use the on-screen d-pad and the DO IT button, and tap to start and restart.

Every run is 20 seconds and nothing carries over.

**Made with:** Odin, compiled to WebAssembly, drawing to a plain 2D canvas. The pixel art and the three sound effects were made with the Anvil of SPLORR!!, TheGrumpyGameDev's own asset tools. The game, the art and the sounds were made with Claude (generative AI) working alongside TheGrumpyGameDev.

## Notes (not for the page)

- Push target: `thegrumpygamedev/the-end-of-the-world-was-nice:html`. `tools/ship.sh` tests, builds with `-o:size` and zips; it only pushes with `--push`.
- On the page's Edit game screen: "Kind of project" HTML, "This file will be played in the browser" ticked, and an embed of 720 by 576 (the game is 240 by 192 and scales to fit).
- The cover is `assets/cover.png` (630 by 500, `tools/make_cover.py`) and the screenshots are `assets/screenshots/` (`tools/make_shots.sh`, headless Chrome on the real build).
- The page text discloses the use of Claude. If the edit screen has a generative-AI disclosure field, fill it in to match.
- Originally started for the 20 Second Game Jam 2026; not entered.
