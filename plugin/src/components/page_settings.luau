--!strict

local vide = require(script.Parent.Parent.Parent.vide)
local videkit = require(script.Parent.Parent.Parent.videkit)
local settings = require(script.Parent.Parent.settings)

local create = vide.create

return function()
	return videkit.scroll_frame {

		create "UIListLayout" { Padding = UDim.new(0, 8) },

		videkit.padding {},

		videkit.text { Text = "Polling Cooldown while Disconnected" },
		videkit.text_input {
			text = function() return settings.polling_cooldown_disconnected end,
			focus_lost = function(new, enter)
				if not enter then return end
				settings.polling_cooldown_disconnected = tonumber(new) or 5
			end,

			placeholder = "5",
		},

		videkit.text { Text = "Polling Cooldown while Connected" },
		videkit.text_input {
			text = function() return settings.polling_cooldown_connected end,
			focus_lost = function(new, enter)
				if not enter then return end
				settings.polling_cooldown_connected = tonumber(new) or 1
			end,

			placeholder = "1",
		},

		videkit.text { Text = "URL" },
		videkit.text_input {
			text = function() return settings.url end,
			focus_lost = function(new, enter)
				if not enter then return end
				settings.url = new
			end,

			placeholder = "localhost",
		},

		videkit.text { Text = "Port" },
		videkit.text_input {
			text = function() return settings.port end,
			focus_lost = function(new, enter)
				if not enter then return end
				settings.port = new
			end,

			placeholder = "21356",
		},
	}
end
