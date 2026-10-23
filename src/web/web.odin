// Thin browser layer: input, drawing, and the frame loop. Everything else is in package game.
#+build js
package main

import "base:runtime"
import "core:sys/wasm/js"
import "tggd:game"

foreign import canvas "canvas"
@(default_calling_convention = "contextless")
foreign canvas {
	// rgb is 0xRRGGBB; coordinates are logical pixels, y down.
	fill_rect :: proc(x, y, w, h: f32, rgb: u32) ---
}

state: game.Game
held: game.Input

main :: proc() {
	state = game.init()
	js.add_window_event_listener(.Key_Down, nil, on_key_down)
	js.add_window_event_listener(.Key_Up, nil, on_key_up)
}

set_key :: proc(code: string, down: bool) -> bool {
	switch code {
	case "ArrowLeft", "KeyA":  held.left = down
	case "ArrowRight", "KeyD": held.right = down
	case "ArrowUp", "KeyW":    held.up = down
	case "ArrowDown", "KeyS":  held.down = down
	case "Space", "KeyZ":      held.action = down
	case:
		return false
	}
	return true
}

on_key_down :: proc(e: js.Event) {
	if set_key(e.key.code, true) {
		js.event_prevent_default()
	}
	if e.key.code == "KeyR" && state.phase == .Ended {
		state = game.init()
	}
}

on_key_up :: proc(e: js.Event) {
	set_key(e.key.code, false)
}

@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	context = runtime.default_context()
	game.step(&state, held, dt)
	draw()
	free_all(context.temp_allocator)
	return true
}

draw :: proc() {
	fill_rect(0, 0, game.SCREEN_W, game.SCREEN_H, 0x1a1c2c)
	// Time bar: shrinks over the 20 seconds.
	frac := f32(game.time_left(state) / game.RUN_SECONDS)
	fill_rect(0, 0, game.SCREEN_W * frac, 4, 0xf4b41b)
	half := f32(game.PLAYER_SIZE) / 2
	fill_rect(state.x - half, state.y - half, game.PLAYER_SIZE, game.PLAYER_SIZE, 0x73eff7)
	if state.phase == .Ended {
		fill_rect(0, 0, game.SCREEN_W, game.SCREEN_H, 0xffffff)
	}
}
