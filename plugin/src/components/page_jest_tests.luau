local vide = require(script.Parent.Parent.Parent.vide)
local videkit = require(script.Parent.Parent.Parent.videkit)
local assets = require(script.Parent.Parent.assets)
local effects = require(script.Parent.Parent.effects)
local settings = require(script.Parent.Parent.settings)
local state = require(script.Parent.Parent.state)

local create = vide.create

return function()
	return videkit.list {
		list = { Padding = UDim.new() },

		videkit.row {
			list = { VerticalAlignment = Enum.VerticalAlignment.Center },
			layout = { Size = UDim2.new(1, 0, 0, 24) },

			create "UIStroke" {
				Color = videkit.color "Border",
			},

			videkit.button {
				text = "Run Tests",

				_nocorner = true,

				layout = {
					Size = UDim2.fromOffset(0, 24),
					AutomaticSize = Enum.AutomaticSize.X,
				},

				activated = function()
					local selected = state.selected
					local test_runner = selected[1] :: ModuleScript
					effects.test_run(test_runner)
				end,

				disabled = function()
					local selected = state.selected
					return not (
						#selected == 1 and selected[1]:IsA "ModuleScript"
					)
				end,
			},

			videkit.toggle {
				toggled = function() return settings.find_all_tests end,
				update_toggle = function(new) settings.find_all_tests = new end,
			},

			videkit.text { Text = "Discover All Tests" },
		},

		videkit.infinite_list {

			layout = {
				Position = UDim2.fromOffset(0, 24),
				Size = UDim2.new(1, 0, 1, -24),
			},

			item_size = 32,
			max_items = function() return #state.stored_test_results end,

			item = function(index)
				local function value()
					local results = state.stored_test_results
					return results[index() :: number]
						or { name = "", status = "" }
				end

				return videkit.row {

					layout = {
						Name = function() return value().name end,

						Size = UDim2.new(1, 0, 0, 31),
					},

					list = {
						VerticalAlignment = Enum.VerticalAlignment.Center,
					},

					videkit.padding { x = UDim.new(0, 8), y = UDim.new() },

					videkit.image {

						Size = UDim2.fromOffset(16, 16),

						Image = function()
							local status = value().status
							return if status == "passed"
								then assets.check["check.png"]
								elseif
									status == "failed"
								then assets.check["error.png"]
								elseif
									status == "skipped"
								then assets.check["skip.png"]
								elseif
									status == "pending"
								then assets.check["skip.png"]
								elseif
									status == "todo"
								then assets.check["todo.png"]
								else ""
						end,
					},

					videkit.text {
						Text = function() return value().name end,
					},

					create "UIStroke" {
						Color = videkit.color "Border",
					},
				}
			end,
		},
	}
end
