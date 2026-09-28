-- ~/.config/swayimg/init.lua
-- Colors are 0xAARRGGBB. 0xA6 alpha ≈ 65%, same as kitty's background_opacity.

local GLASS = 0xA61e1e2e -- translucent window background
local TILE = 0x26ffffff -- frosted thumbnail tile
local TILE_S = 0x4dffffff -- selected tile
local BORDER = 0xccffffff -- white border, like your niri border
local TEXT_BG = 0x991e1e2e -- glass chip behind overlay text

---------------------------------------------------------------- general
swayimg.decoration = false
swayimg.antialiasing = true
swayimg.exif_orientation = true -- phone photos show the right way up

---------------------------------------------------------------- image list
swayimg.imagelist.adjacent = true -- open one image → browse the whole folder
swayimg.imagelist.order = "numeric" -- img2 before img10
swayimg.imagelist.fsmon = true -- picks up new/deleted files live

---------------------------------------------------------------- text overlay
swayimg.text.font = "JetBrainsMono Nerd Font"
swayimg.text.size = 15
swayimg.text.color = 0xffe0e0e0
swayimg.text.background = TEXT_BG
swayimg.text.shadow = 0x00000000 -- no shadow, the chip handles contrast
swayimg.text.padding = 12
swayimg.text.timeout = 3 -- fades after 3s
swayimg.text.status_timeout = 2

---------------------------------------------------------------- viewer
swayimg.viewer.default_scale = "optimal" -- shrink big images, never upscale small ones
swayimg.viewer.loop = true
swayimg.viewer.preload = 2
swayimg.viewer.set_window_background(GLASS)
swayimg.viewer.set_image_chessboard(16, 0x33ffffff, 0x1affffff)
swayimg.viewer.text = {
	topleft = { "{name}" },
	topright = { "{list.index}/{list.total}" },
	bottomleft = { "{scale}" },
}

---------------------------------------------------------------- slideshow
swayimg.slideshow.timeout = 4
swayimg.slideshow.set_window_background(GLASS)
swayimg.slideshow.text = {
	topright = { "{list.index}/{list.total}" },
}

---------------------------------------------------------------- gallery
swayimg.gallery.aspect = "fill"
swayimg.gallery.thumb_size = 200
swayimg.gallery.padding_size = 8
swayimg.gallery.border_size = 2
swayimg.gallery.selected_scale = 1.08
swayimg.gallery.window_color = GLASS
swayimg.gallery.unselected_color = TILE
swayimg.gallery.selected_color = TILE_S
swayimg.gallery.border_color = BORDER
swayimg.gallery.pstore = true -- cache thumbnails on disk
swayimg.gallery.preload = true
swayimg.gallery.text = {
	topleft = { "{name}" },
	topright = { "{list.index}/{list.total}" },
}

---------------------------------------------------------------- extra keys
-- Delete = trash, y = copy image, Shift-y = copy path, t = toggle overlay
local function q(s)
	return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function trash(img)
	if not img then
		return
	end
	os.execute("gio trash " .. q(img.path))
	swayimg.imagelist.remove(img.path)
	swayimg.text.status = "Trashed"
end

local function copy_img(img)
	if img then
		os.execute("wl-copy < " .. q(img.path))
		swayimg.text.status = "Image copied"
	end
end

local function copy_path(img)
	if img then
		os.execute("printf %s " .. q(img.path) .. " | wl-copy")
		swayimg.text.status = "Path copied"
	end
end

for _, m in ipairs({ "viewer", "gallery" }) do
	local mode = swayimg[m]
	mode.on_key("Delete", function()
		trash(mode.get_image())
	end)
	mode.on_key("y", function()
		copy_img(mode.get_image())
	end)
	mode.on_key("Shift-y", function()
		copy_path(mode.get_image())
	end)
	mode.on_key("t", function()
		swayimg.text.visible = not swayimg.text.visible
	end)
end

---------------------------------------------------------------- vim panning
-- h/j/k/l pan the zoomed image, Shift = bigger jump, 0 = reset zoom and position
local STEP, BIG = 80, 300

local function pan(dx, dy)
	local p = swayimg.viewer.get_position()
	swayimg.viewer.set_abs_position(p.x + dx, p.y + dy)
end

-- "look right" (l) moves the image left, like scrolling a page
local moves = {
	h = { 1, 0 },
	l = { -1, 0 },
	k = { 0, 1 },
	j = { 0, -1 },
}

for key, d in pairs(moves) do
	swayimg.viewer.on_key(key, function()
		pan(d[1] * STEP, d[2] * STEP)
	end)
	swayimg.viewer.on_key("Shift-" .. key, function()
		pan(d[1] * BIG, d[2] * BIG)
	end)
end

swayimg.viewer.on_key("0", function()
	swayimg.viewer.reset()
end)

---------------------------------------------------------------- zoom
-- i = zoom in, o = zoom out (around the window centre)
local ZOOM = 1.2 -- 20% per press

swayimg.viewer.on_key("i", function()
	swayimg.viewer.set_abs_scale(swayimg.viewer.scale * ZOOM)
end)

swayimg.viewer.on_key("o", function()
	swayimg.viewer.set_abs_scale(swayimg.viewer.scale / ZOOM)
end)
