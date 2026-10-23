// Pure rules: no platform imports, so this compiles natively (tests) and for js_wasm32.
package game

RUN_SECONDS :: 20.0

SCREEN_W :: 240
SCREEN_H :: 192

PLAYER_SIZE  :: 8
PLAYER_SPEED :: 60.0 // logical pixels per second

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
	phase: Phase,
	clock: f64, // seconds of gameplay so far
	x, y:  f32, // player centre
}

init :: proc() -> Game {
	return Game{phase = .Playing, x = SCREEN_W / 2, y = SCREEN_H / 2}
}

// Seconds left, never negative.
time_left :: proc(g: Game) -> f64 {
	return max(0, RUN_SECONDS - g.clock)
}

// dt is in seconds. Only gameplay time counts toward the 20 seconds.
step :: proc(g: ^Game, in_: Input, dt: f64) {
	if g.phase != .Playing {
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
}
