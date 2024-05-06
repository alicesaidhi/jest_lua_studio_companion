local Selection = game:GetService "Selection"

local shared_toolbar = require(script.Parent.Parent.shared_toolbar)
local vide = require(script.Parent.Parent.vide)
local app = require(script.Parent.components.main)
local effects = require(script.Parent.effects)
local server = require(script.Parent.libraries.server)
local settings = require(script.Parent.settings)
local state = require(script.Parent.state)

local source = vide.source
local effect = vide.effect
local cleanup = vide.cleanup
local mount = vide.mount

return function(plugin: Plugin)
	local dock_widget_plugin_info = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		300,
		200,
		300,
		200
	)
	local dock_widget: DockWidgetPluginGui =
		plugin:CreateDockWidgetPluginGui("Output", dock_widget_plugin_info)

	dock_widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local activated = source(dock_widget.Enabled)

	dock_widget
		:GetPropertyChangedSignal("Enabled")
		:Connect(function() activated(dock_widget.Enabled) end)

	local shared_toolbar_settings = {
		CombinerName = "alice_plugins_1160098333",
		ToolbarName = "grandma's handy downs",

		ButtonName = "Jest Companion",
		ButtonIcon = "rbxassetid://17247723678",
		ButtonTooltip = "Opens the Jest Companion Widget.",
		ClickedFn = function() activated(not activated()) end,
	} :: shared_toolbar.SharedToolbarSettings

	shared_toolbar(plugin, shared_toolbar_settings)

	dock_widget.Name = "Jest Lua Companion"
	dock_widget.Title = "Jest Lua Companion"

	local unmount

	vide.strict = false

	effect(function()
		shared_toolbar_settings.Button:SetActive(activated())
		dock_widget.Enabled = activated()

		if unmount then
			unmount()
			unmount = nil
		end

		if activated() then
			unmount = mount(function()
				local app = app()
				cleanup(app)
				return app
			end, dock_widget)
		end
	end)

	-- polls the server
	local thread = coroutine.create(function()
		while true do
			server.poll()

			if server.state.is_connected then
				task.wait(settings.polling_cooldown_connected)
			else
				task.wait(settings.polling_cooldown_disconnected)
			end
		end
	end)

	coroutine.resume(thread)

	server.bind_to_command(
		"request_start_tests",
		function(path_to_jest, config)
			effects.run_tests_remotely(path_to_jest, config)
		end
	)

	cleanup(function() coroutine.close(thread) end)

	cleanup(
		Selection.SelectionChanged:Connect(
			function() state.selected = Selection:Get() end
		)
	)
end
