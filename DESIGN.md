# Nice Apocalypse: design

Theme: "The End of the World is Nice". One run is 20 seconds; a meteor lands at 20.0 s. (Started for the 20 Second Game Jam 2026; not entering the jam, so it ships as a normal itch.io release.)

## Decided

- **Verb:** walk around one screen (top-down, 4-way) and hold a single action button next to a thing.
- **Items:** 5 bucket-list items on one screen. Not all fit in 20 s, so the player routes and chooses.
- **Interaction:** hold the button ~1 to 2 s next to an item to complete it; stepping away or releasing cancels (progress resets). Each item has its own hold time.
- **Ending:** at 20.0 s the meteor lands in a soft flash and fade, then a warm epilogue with one line per completed item. Not a game-over; restart is offered.
- **Clock:** only gameplay counts toward 20 s; title and epilogue are skippable and brief.

## Implemented (task #34)

- Items (hold seconds): Hug someone 1.5, Pet the dog 1.0, Eat the cake 2.0, Watch the sky 1.0, Call mum 1.5. Positions and epilogue lines are in `ITEM_DEFS` in `src/game/game.odin`.
- Only the nearest unfinished item within 14 px progresses; release or walking away resets it.
- Walking speed is 36 px/s; a test pins that a straight, good route lands on 3 or 4 items, never 5.
- The meteor flash fades over 1.5 s, then the epilogue lists completed items (placeholder canvas text and squares).

## Open

- Walking speed of 36 px/s and the three sounds are confirmed by the user as good (October 23, 2026). `PLAYER_SPEED` is guarded by the tuning test.
- Palette, sprite size and sound set.
- Whether a second run changes anything (default: no; each run is self-contained).
