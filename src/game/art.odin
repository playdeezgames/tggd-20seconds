package game

// Order must match the sprite order in assets/art/world.json (see tools/gen_atlas.py).
Sprite :: enum i32 {
	Player,
	Hug,
	Dog,
	Cake,
	Sky,
	Call,
}

SPRITE_SIZE :: 16

ITEM_SPRITES := [Item_Kind]Sprite {
	.Hug  = .Hug,
	.Dog  = .Dog,
	.Cake = .Cake,
	.Sky  = .Sky,
	.Call = .Call,
}

// Order must match SOUND_FILES in web/index.html (assets/sfx/<name>.wav).
Sound :: enum i32 {
	Done,
	Meteor,
	Epilogue,
}
