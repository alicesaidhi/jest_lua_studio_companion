local vide = require(script.Parent.Parent.vide)
local videx = require(script.Parent.libraries.videx)

local source = vide.source

local base_settings = {
	open_tab = 1,

	polling_cooldown_connected = 1,
	polling_cooldown_disconnected = 1,

	url = "127.0.0.1",
	port = "21356",

	find_all_tests = false,
}

local settings = videx.new(source(base_settings), source {})

return settings
