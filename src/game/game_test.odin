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

// Put the player on an item.
stand_on :: proc(g: ^Game, k: Item_Kind) {
	g.x, g.y = ITEM_DEFS[k].x, ITEM_DEFS[k].y
}

@(test)
holding_completes_item :: proc(t: ^testing.T) {
	g := init()
	stand_on(&g, .Dog)
	for _ in 0 ..< 59 { step(&g, {action = true}, 1.0 / 60) }
	testing.expect(t, !g.done[.Dog])
	for _ in 0 ..< 3 { step(&g, {action = true}, 1.0 / 60) }
	testing.expect(t, g.done[.Dog])
	testing.expect_value(t, items_done(g), 1)
}

@(test)
release_resets_progress :: proc(t: ^testing.T) {
	g := init()
	stand_on(&g, .Cake)
	for _ in 0 ..< 90 { step(&g, {action = true}, 1.0 / 60) }
	testing.expect(t, g.progress[.Cake] > 1)
	step(&g, {}, 1.0 / 60)
	testing.expect_value(t, g.progress[.Cake], 0)
	testing.expect(t, !g.done[.Cake])
}

@(test)
leaving_reach_resets_progress :: proc(t: ^testing.T) {
	g := init()
	stand_on(&g, .Hug)
	for _ in 0 ..< 60 { step(&g, {action = true}, 1.0 / 60) }
	g.x -= ITEM_REACH + 5
	step(&g, {action = true}, 1.0 / 60)
	testing.expect_value(t, g.progress[.Hug], 0)
}

@(test)
nothing_happens_out_of_reach :: proc(t: ^testing.T) {
	g := init()
	g.x, g.y = 120, 100 // away from every item
	for _ in 0 ..< 600 {
		step(&g, {action = true}, 1.0 / 60)
		if g.phase == .Ended { break }
	}
	testing.expect_value(t, items_done(g), 0)
}

@(test)
finished_item_stays_finished :: proc(t: ^testing.T) {
	g := init()
	stand_on(&g, .Sky)
	for _ in 0 ..< 70 { step(&g, {action = true}, 1.0 / 60) }
	testing.expect(t, g.done[.Sky])
	_, near := item_in_reach(g)
	testing.expect(t, !near)
	step(&g, {}, 1.0 / 60)
	testing.expect(t, g.done[.Sky])
}

@(test)
no_progress_after_meteor :: proc(t: ^testing.T) {
	g := init()
	step(&g, {}, RUN_SECONDS + 1)
	stand_on(&g, .Dog)
	for _ in 0 ..< 120 { step(&g, {action = true}, 1.0 / 60) }
	testing.expect_value(t, items_done(g), 0)
	testing.expect(t, g.after > 1)
}

@(test)
a_good_route_gets_four :: proc(t: ^testing.T) {
	// Tuning guard: walking straight between items, a decent run fits four of
	// five in 20 seconds, and all five do not fit.
	order := [?]Item_Kind{.Dog, .Cake, .Hug, .Sky, .Call}
	g := init()
	for k in order {
		def := ITEM_DEFS[k]
		for g.phase == .Playing {
			dx, dy := def.x - g.x, def.y - g.y
			if dx * dx + dy * dy <= 4 { break }
			step(&g, {left = dx < -1, right = dx > 1, up = dy < -1, down = dy > 1}, 1.0 / 60)
		}
		for g.phase == .Playing && !g.done[k] { step(&g, {action = true}, 1.0 / 60) }
	}
	n := items_done(g)
	testing.expect(t, n >= 3 && n <= 4, "route should land on 3 or 4 items")
}
