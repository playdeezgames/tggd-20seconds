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
	fill_rect :: proc(x, y, w, h: f32, rgb: u32, alpha: f32) ---
	// Draw a sprite from the atlas (build/web/art.png) with its top-left at x, y.
	blit :: proc(sprite: i32, x, y: f32, alpha: f32) ---
	play_sound :: proc(sound: i32) ---
	// Placeholder text until the bitmap font lands; x is the centre when centered.
	draw_text :: proc(x, y: f32, text: string, rgb: u32, size: f32, centered: bool) ---
}

ITEM_COLORS := [game.Item_Kind]u32 {
	.Hug  = 0xff77a8,
	.Dog  = 0xffa300,
	.Cake = 0xffec27,
	.Sky  = 0x29adff,
	.Call = 0xb13e53,
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
	if state.item_just_done { play_sound(i32(game.Sound.Done)) }
	if state.meteor_just_hit { play_sound(i32(game.Sound.Meteor)) }
	if state.epilogue_started { play_sound(i32(game.Sound.Epilogue)) }
	draw()
	free_all(context.temp_allocator)
	return true
}

draw :: proc() {
	fill_rect(0, 0, game.SCREEN_W, game.SCREEN_H, 0x1a1c2c, 1)
	if state.phase == .Ended && state.after >= game.FLASH_SECONDS {
		draw_epilogue()
		return
	}
	// Time bar: shrinks over the 20 seconds.
	frac := f32(game.time_left(state) / game.RUN_SECONDS)
	fill_rect(0, 0, game.SCREEN_W * frac, 4, 0xf4b41b, 1)
	draw_text(4, 13, "Arrows/WASD: move   Hold Space/Z: do it", 0x94b0c2, 7, false)

	for def, k in game.ITEM_DEFS {
		done := state.done[k]
		alpha := f32(done ? 0.35 : 1)
		blit(i32(game.ITEM_SPRITES[k]), def.x - 8, def.y - 8, alpha)
		draw_text(def.x, def.y + 16, def.name, done ? 0x566c86 : 0xf4f4f4, 7, true)
		if p := state.progress[k]; p > 0 {
			fill_rect(def.x - 8, def.y + 9, 16, 2, 0x333c57, 1)
			fill_rect(def.x - 8, def.y + 9, 16 * p / def.hold, 2, 0x38b764, 1)
		}
	}

	blit(i32(game.Sprite.Player), state.x - 8, state.y - 8, 1)

	if state.phase == .Ended {
		fill_rect(0, 0, game.SCREEN_W, game.SCREEN_H, 0xffffff, 1 - f32(state.after / game.FLASH_SECONDS))
	}
}

draw_epilogue :: proc() {
	draw_text(game.SCREEN_W / 2, 24, "The end of the world was nice.", 0xf4f4f4, 10, true)
	y := f32(56)
	for def, k in game.ITEM_DEFS {
		if state.done[k] {
			draw_text(game.SCREEN_W / 2, y, def.epilogue, ITEM_COLORS[k], 7, true)
			y += 14
		}
	}
	if game.items_done(state) == 0 {
		draw_text(game.SCREEN_W / 2, y, "You watched it come, and that was nice too.", 0xf4f4f4, 7, true)
	}
	draw_text(game.SCREEN_W / 2, 180, "R to go again", 0x566c86, 7, true)
}
