--!strict

local vide = require(script.Parent.Parent.Parent.vide)
local videkit = require(script.Parent.Parent.Parent.videkit)
local assets = require(script.Parent.Parent.assets)
local server = require(script.Parent.Parent.libraries.server)
local settings = require(script.Parent.Parent.settings)
local state = require(script.Parent.Parent.state)
local loading = require(script.Parent.loading)
local page_jest_tests = require(script.Parent.page_jest_tests)
local page_settings = require(script.Parent.page_settings)

local changed = vide.changed
local untrack = vide.untrack
local source = vide.source
local effect = vide.effect

return function()
	return videkit.container {

		Name = "Main",

		videkit.tabs {

			selected = function() return settings.open_tab end,
			update_selected = function(index) settings.open_tab = index end,

			{
				name = "Jest Tests",
				child = page_jest_tests,
			},

			{
				name = "Benchmarker",
				child = function() end,
			},

			{
				name = "Settings",
				child = page_settings,
			},
		},

		videkit.row {

			layout = {
				Name = "Row",

				Position = UDim2.new(1, -8, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				Size = UDim2.new(1, -8, 0, 24),
			},

			list = {
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},

			loading {
				--todo: match theme
				color = videkit.color "TabBar",

				layout = {
					Size = UDim2.fromOffset(16, 16),
					Visible = function() return server.state.performing_request end,
				},
			},

			videkit.image {
				Size = UDim2.fromOffset(16, 16),

				Image = function()
					return if server.state.is_connected
						then assets.status["connected.png"]
						else assets.status["disconnected.png"]
				end,

				Visible = function() return not server.state.performing_request end,
			},
		},
	}
end
