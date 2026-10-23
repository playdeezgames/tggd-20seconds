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
	// Bitmap text (m5x7). y is the baseline; scale is a whole number; x is the centre when centered.
	draw_text :: proc(x, y: f32, text: string, rgb: u32, scale: i32, centered: bool) ---
}

ITEM_COLORS := [game.Item_Kind]u32 {
	.Hug  = 0xff77a8,
	.Dog  = 0xffa300,
	.Cake = 0xffec27,
	.Sky  = 0x29adff,
	.Call = 0xb13e53,
}

state: game.Game
held: game.Input  // keyboard
touch: game.Input // on-screen buttons, set by the page through set_touch
touch_ui: bool    // the page is showing the on-screen buttons, so hints name them

main :: proc() {
	state = game.title()
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

// Title: any key or tap starts. After the epilogue: a tap or a key plays again.
start_or_restart :: proc() {
	switch state.phase {
	case .Title:
		game.begin(&state)
	case .Ended:
		if state.after >= game.FLASH_SECONDS {
			state = game.init()
		}
	case .Playing:
	}
}

on_key_down :: proc(e: js.Event) {
	if set_key(e.key.code, true) {
		js.event_prevent_default()
	}
	if e.key.repeat {
		return
	}
	switch e.key.code {
	case "ShiftLeft", "ShiftRight", "ControlLeft", "ControlRight", "AltLeft", "AltRight", "MetaLeft", "MetaRight":
		return // modifiers alone do not count as "any key"
	}
	start_or_restart()
}

// Called by the page on a tap of the canvas.
@(export)
tap :: proc "c" () {
	context = runtime.default_context()
	start_or_restart()
}

// QA hook for screenshots (index.html#play=SECONDS): run the game forward with no input.
@(export)
qa_advance :: proc "c" (seconds: f64) {
	context = runtime.default_context()
	for left := seconds; left > 0; left -= 0.05 {
		game.step(&state, {}, min(left, 0.05))
	}
}

// Called by the page when it shows (1) the on-screen buttons, so hints talk about them.
@(export)
set_touch_ui :: proc "c" (on: i32) {
	touch_ui = on != 0
}

// Called by the page whenever the on-screen buttons change. Bits: 1 left, 2 right, 4 up, 8 down, 16 action.
@(export)
set_touch :: proc "c" (bits: i32) {
	context = runtime.default_context()
	touch = {
		left   = bits & 1 != 0,
		right  = bits & 2 != 0,
		up     = bits & 4 != 0,
		down   = bits & 8 != 0,
		action = bits & 16 != 0,
	}
	if bits != 0 {
		start_or_restart()
	}
}

on_key_up :: proc(e: js.Event) {
	set_key(e.key.code, false)
}

@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	context = runtime.default_context()
	merged := game.Input {
		left   = held.left || touch.left,
		right  = held.right || touch.right,
		up     = held.up || touch.up,
		down   = held.down || touch.down,
		action = held.action || touch.action,
	}
	game.step(&state, merged, dt)
	if state.item_just_done { play_sound(i32(game.Sound.Done)) }
	if state.meteor_just_hit { play_sound(i32(game.Sound.Meteor)) }
	if state.epilogue_started { play_sound(i32(game.Sound.Epilogue)) }
	draw()
	free_all(context.temp_allocator)
	return true
}

draw :: proc() {
	fill_rect(0, 0, game.SCREEN_W, game.SCREEN_H, 0x1a1c2c, 1)
	if state.phase == .Title {
		draw_title()
		return
	}
	if state.phase == .Ended && state.after >= game.FLASH_SECONDS {
		draw_epilogue()
		return
	}
	// Time bar: shrinks over the 20 seconds.
	frac := f32(game.time_left(state) / game.RUN_SECONDS)
	fill_rect(0, 0, game.SCREEN_W * frac, 4, 0xf4b41b, 1)
	hint := touch_ui ? "D-pad: move   Hold DO IT: do it" : "Arrows/WASD: move   Hold Space/Z: do it"
	draw_text(4, 14, hint, 0x94b0c2, 1, false)

	for def, k in game.ITEM_DEFS {
		done := state.done[k]
		alpha := f32(done ? 0.35 : 1)
		blit(i32(game.ITEM_SPRITES[k]), def.x - 8, def.y - 8, alpha)
		draw_text(def.x, def.y + 18, def.name, done ? 0x566c86 : 0xf4f4f4, 1, true)
		if p := state.progress[k]; p > 0 {
			fill_rect(def.x - 8, def.y + 9, 16, 2, 0x333c57, 1)
			fill_rect(def.x - 8, def.y + 9, 16 * p / def.hold, 2, 0x38b764, 1)
		}
	}

	blit(i32(game.Sprite.Player), state.x - 8, state.y - 8, 1)

	if state.phase == .Ended {
		fill_rect(0, 0, game.SCREEN_W, game.SCREEN_H, 0xfff1e8, game.flash_alpha(state.after))
	}
}

draw_epilogue :: proc() {
	cx := f32(game.SCREEN_W / 2)
	draw_text(cx, 30, "The end of the", 0xf4f4f4, 2, true)
	draw_text(cx, 50, "world was nice.", 0xf4f4f4, 2, true)
	y := f32(80)
	for def, k in game.ITEM_DEFS {
		if state.done[k] {
			draw_text(cx, y, def.epilogue, ITEM_COLORS[k], 1, true)
			y += 14
		}
	}
	if game.items_done(state) == 0 {
		draw_text(cx, y, "You watched it come, and that was nice too.", 0xf4f4f4, 1, true)
	}
	draw_text(cx, 180, touch_ui ? "Tap to go again" : "R, or tap, to go again", 0x94b0c2, 1, true)
}

draw_title :: proc() {
	cx := f32(game.SCREEN_W / 2)
	draw_text(cx, 32, "The End of", 0xf4f4f4, 3, true)
	draw_text(cx, 56, "the World", 0xf4f4f4, 3, true)
	draw_text(cx, 80, "Was Nice", 0xffec27, 3, true)
	draw_text(cx, 98, "You have 20 seconds.", 0xf4f4f4, 1, true)
	draw_text(cx, 110, "Do what you can before the meteor lands.", 0x94b0c2, 1, true)
	// The cast, in a row.
	sprites := [?]game.Sprite{.Player, .Hug, .Dog, .Cake, .Sky, .Call}
	for sp, i in sprites {
		blit(i32(sp), cx - 3 * game.SPRITE_SIZE + f32(i) * game.SPRITE_SIZE, 120, 1)
	}
	if touch_ui {
		draw_text(cx, 152, "D-pad: move", 0x94b0c2, 1, true)
		draw_text(cx, 164, "Hold DO IT next to something", 0x94b0c2, 1, true)
		draw_text(cx, 184, "Tap to start", 0xf4b41b, 1, true)
	} else {
		draw_text(cx, 152, "Arrows / WASD: move", 0x94b0c2, 1, true)
		draw_text(cx, 164, "Hold Space / Z next to something", 0x94b0c2, 1, true)
		draw_text(cx, 184, "Press any key or tap to start", 0xf4b41b, 1, true)
	}
}
