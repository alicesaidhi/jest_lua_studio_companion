local ChangeHistoryService = game:GetService "ChangeHistoryService"
local LogService = game:GetService "LogService"

local find_path = require(script.Parent.find_path)
local jest_result_to_state = require(script.Parent.jest_result_to_state)
local server = require(script.Parent.libraries.server)
local require_override = require(script.Parent.require_override)
local state = require(script.Parent.state)

local recording

return {

	test_run = function(test_runner: ModuleScript)
		assert(not recording, "test is already running")
		print "starting test run"

		state.stored_test_results = {}

		require_override.resetModules()

		recording = ChangeHistoryService:TryBeginRecording "jest_test_run"

		local connection = LogService.MessageOut:Connect(server.log)
		local ok, result = pcall(require_override.requireOverride, test_runner)

		-- cancel the recording so that all changes are reverted
		ChangeHistoryService:FinishRecording(
			recording,
			Enum.FinishRecordingOperation.Cancel
		)
		recording = nil
		connection:Disconnect()
		print("finished", ok)

		if ok and typeof(result) == "table" then
			state.jest_results = result
			state.stored_test_results = jest_result_to_state(result.results)
			server.report_test_results(result.results)
		end
	end,

	run_tests_remotely = function(jest_path: { string }, config)
		assert(not recording, "test is already running")

		state.stored_test_results = {}

		require_override.resetModules()
		recording = ChangeHistoryService:TryBeginRecording(
			`jest_test_run_{math.random(1e9)}`
		)

		local jest = find_path(jest_path, game)

		if not jest then warn(`unable to find jest at {jest_path}`) end

		local roots = {}

		for i, path: string in config.roots do
			roots[i] = find_path(string.split(path, "/"), game)
		end

		print "got roots"

		local connection = LogService.MessageOut:Connect(server.log)
		local ok, result = pcall(function()
			local status, results = require_override
				.requireOverride(jest)
				.runCLI(game, config.config or {}, roots)
				:awaitStatus()
			return {
				status = status,
				result = results,
			}
		end)

		print "received test results"

		if not ok then warn(result) end

		-- cancel the recording so that all changes are reverted
		ChangeHistoryService:FinishRecording(
			recording,
			Enum.FinishRecordingOperation.Cancel
		)
		recording = nil
		connection:Disconnect()
		print("finished", ok, result)

		if ok and result.status == "Resolved" then
			server.report_test_results(result.result.results)
			state.jest_results = result.result
			state.stored_test_results =
				jest_result_to_state(result.result.results)
		else
			server.report_error(tostring(result.result))
		end
	end,
}
