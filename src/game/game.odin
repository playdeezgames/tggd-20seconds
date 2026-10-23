// Pure rules: no platform imports, so this compiles natively (tests) and for js_wasm32.
package game

RUN_SECONDS :: 20.0

SCREEN_W :: 240
SCREEN_H :: 192

PLAYER_SIZE  :: 8
PLAYER_SPEED :: 36.0 // logical pixels per second; tuned so a good route fits 4 of 5 items

ITEM_COUNT   :: 5
ITEM_REACH   :: 14.0 // player centre must be this close to an item to work on it
FLASH_SECONDS :: 1.5 // white fade after the meteor lands, before the epilogue

Item_Kind :: enum {
	Hug,
	Dog,
	Cake,
	Sky,
	Call,
}

// Static description of each bucket-list item: where it is and how long to hold.
Item_Def :: struct {
	name:     string,
	epilogue: string,
	x, y:     f32,
	hold:     f32, // seconds of uninterrupted holding to complete
}

ITEM_DEFS := [Item_Kind]Item_Def {
	.Hug  = {"Hug someone", "You hugged someone, and they hugged back.", 170, 90, 1.5},
	.Dog  = {"Pet the dog", "The dog was a very good dog.", 50, 60, 1.0},
	.Cake = {"Eat the cake", "The cake was exactly as good as it looked.", 60, 150, 2.0},
	.Sky  = {"Watch the sky", "The sky was lovely, right up to the end.", 200, 30, 1.0},
	.Call = {"Call mum", "Mum picked up on the first ring.", 215, 170, 1.5},
}

Phase :: enum {
	Playing,
	Ended, // the meteor has landed
}

// Held directions this frame; the platform layer fills it in.
Input :: struct {
	left, right, up, down: bool,
	action:                bool,
}

Game :: struct {
	phase:    Phase,
	clock:    f64, // seconds of gameplay so far
	after:    f64, // seconds since the meteor landed
	x, y:     f32, // player centre
	done:     [Item_Kind]bool,
	progress: [Item_Kind]f32, // seconds held on the item being worked on
}

init :: proc() -> Game {
	return Game{phase = .Playing, x = SCREEN_W / 2, y = SCREEN_H / 2}
}

items_done :: proc(g: Game) -> (n: int) {
	for d in g.done {
		if d { n += 1 }
	}
	return
}

// The unfinished item closest to the player and within reach, if any.
item_in_reach :: proc(g: Game) -> (kind: Item_Kind, ok: bool) {
	best := f32(ITEM_REACH * ITEM_REACH)
	for def, k in ITEM_DEFS {
		if g.done[k] { continue }
		dx, dy := def.x - g.x, def.y - g.y
		d2 := dx * dx + dy * dy
		if d2 <= best {
			best, kind, ok = d2, k, true
		}
	}
	return
}

// Seconds left, never negative.
time_left :: proc(g: Game) -> f64 {
	return max(0, RUN_SECONDS - g.clock)
}

// dt is in seconds. Only gameplay time counts toward the 20 seconds.
step :: proc(g: ^Game, in_: Input, dt: f64) {
	if g.phase != .Playing {
		g.after += dt
		return
	}
	g.clock += dt
	if g.clock >= RUN_SECONDS {
		g.clock = RUN_SECONDS
		g.phase = .Ended
		return
	}

	dx, dy: f32
	if in_.left { dx -= 1 }
	if in_.right { dx += 1 }
	if in_.up { dy -= 1 }
	if in_.down { dy += 1 }
	// Normalise so diagonals are not faster.
	if dx != 0 && dy != 0 {
		dx *= 0.70710678
		dy *= 0.70710678
	}
	half := f32(PLAYER_SIZE) / 2
	g.x = clamp(g.x + dx * PLAYER_SPEED * f32(dt), half, SCREEN_W - half)
	g.y = clamp(g.y + dy * PLAYER_SPEED * f32(dt), half, SCREEN_H - half)

	// Hold-to-complete: only the nearest unfinished item progresses, and any
	// interruption (release, or walking out of reach) resets its progress.
	target, near := item_in_reach(g^)
	for k in Item_Kind {
		if !near || k != target || !in_.action {
			g.progress[k] = 0
		}
	}
	if near && in_.action {
		g.progress[target] += f32(dt)
		if g.progress[target] >= ITEM_DEFS[target].hold {
			g.done[target] = true
			g.progress[target] = 0
		}
	}
}
