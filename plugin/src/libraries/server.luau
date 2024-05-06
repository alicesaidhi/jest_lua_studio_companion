local HttpService = game:GetService "HttpService"

local vide = require(script.Parent.Parent.Parent.vide)
local jest_result_to_state = require(script.Parent.Parent.jest_result_to_state)
local settings = require(script.Parent.Parent.settings)
local videx = require(script.Parent.videx)

local plugin_guid = HttpService:GenerateGUID(false)

local server_data = videx.new(
	vide.source {
		--- tells if the plugin connected to a jest companion server
		is_connected = false,
		--- tells if the plugin is currently polling the server
		performing_request = false,
	},
	vide.source {}
)

type ServerCommand = "request_start_tests"

local callbacks: { [ServerCommand]: (...unknown) -> () } = {}
local bundled = {}

return {

	state = server_data,

	bind_to_command = function(
		command: ServerCommand,
		callback: (...unknown) -> ()
	)
		assert(callbacks[command] == nil, "callback is already bound to")
		callbacks[command] = callback
	end,

	poll = function()
		server_data.performing_request = true

		local ok, response = pcall(HttpService.RequestAsync, HttpService, {
			Url = `http://{settings.url}:{settings.port}`,
			Method = "GET",

			Headers = {
				["place-id"] = tostring(game.PlaceId),
				["place-guid"] = plugin_guid,
				["Content-Type"] = "application/json",
			},
		})

		server_data.performing_request = false

		if ok and response.StatusCode == 200 then
			server_data.is_connected = true

			local body: { ServerCommand } =
				HttpService:JSONDecode(response.Body)

			for _, command in body do
				if callbacks[command[1]] == nil then
					warn(
						`expected "{command[1]}" to be bound to, but no binding exists`
					)
					continue
				end
				print("command received", command)
				-- we spawn threads so that commands dont yield eachother
				task.spawn(callbacks[command[1]], unpack(command, 2))
			end
		else
			server_data.is_connected = false
		end
	end,

	-- defers the request
	log = function(input: string)
		if server_data.is_connected == false then return end

		table.insert(bundled, input)

		if #bundled ~= 1 then return end
		task.defer(function()
			local stored = bundled
			bundled = {}

			pcall(HttpService.RequestAsync, HttpService, {
				Url = `http://{settings.url}:{settings.port}/log`,
				Method = "POST",

				Headers = {
					["place-id"] = tostring(game.PlaceId),
					["place-guid"] = plugin_guid,
					["Content-Type"] = "application/json",
				},

				Body = HttpService:JSONEncode(stored),
			})
		end)
	end,

	report_test_results = function(
		results: jest_result_to_state.AggregatedTestResult
	)
		if server_data.is_connected == false then return end

		local ok, err = pcall(HttpService.RequestAsync, HttpService, {
			Url = `http://{settings.url}:{settings.port}/results`,
			Method = "POST",

			Headers = {
				["place-id"] = tostring(game.PlaceId),
				["place-guid"] = plugin_guid,
				["Content-Type"] = "application/json",
			},

			Body = HttpService:JSONEncode(results),
		})

		if not ok then warn(err) end
	end,

	report_error = function(err: string)
		if server_data.is_connected == false then return end

		local ok, err = pcall(HttpService.RequestAsync, HttpService, {
			Url = `http://{settings.url}:{settings.port}/fail`,
			Method = "POST",

			Headers = {
				["place-id"] = tostring(game.PlaceId),
				["place-guid"] = plugin_guid,
				["Content-Type"] = "application/json",
			},

			Body = HttpService:JSONEncode(err),
		})

		if not ok then warn(err) end
	end,
}
