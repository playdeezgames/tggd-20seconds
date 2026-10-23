#+build !js
package game

import "core:testing"

@(test)
run_ends_at_twenty_seconds :: proc(t: ^testing.T) {
	g := init()
	for _ in 0 ..< 1199 { // 19.98 s at 60 fps
		step(&g, {}, 1.0 / 60)
	}
	testing.expect_value(t, g.phase, Phase.Playing)
	step(&g, {}, 1.0 / 60)
	step(&g, {}, 1.0 / 60)
	testing.expect_value(t, g.phase, Phase.Ended)
	testing.expect_value(t, time_left(g), 0)
}

@(test)
ended_game_ignores_input :: proc(t: ^testing.T) {
	g := init()
	step(&g, {}, RUN_SECONDS + 1)
	x := g.x
	step(&g, {right = true}, 1)
	testing.expect_value(t, g.x, x)
}

@(test)
player_stays_on_screen :: proc(t: ^testing.T) {
	g := init()
	for _ in 0 ..< 600 {
		step(&g, {left = true, up = true}, 1.0 / 60)
		if g.phase == .Ended { break }
	}
	testing.expect(t, g.x >= PLAYER_SIZE / 2 && g.y >= PLAYER_SIZE / 2)
}

@(test)
diagonal_is_not_faster :: proc(t: ^testing.T) {
	a := init()
	b := init()
	step(&a, {right = true}, 0.1)
	step(&b, {right = true, down = true}, 0.1)
	da := a.x - SCREEN_W / 2
	db := b.x - SCREEN_W / 2
	testing.expect(t, db < da)
}
