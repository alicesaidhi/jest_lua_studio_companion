--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

type CleanupFn = () -> any
type Function = (...any) -> any

local requiredModules: { [ModuleScript]: any } = {}
local moduleCleanup: { [ModuleScript]: (() -> any)? } = {}
local mocks: { [ModuleScript]: CleanupFn } = {}

local function requireOverride(scriptInstance: ModuleScript): any
	-- This is crucial! We need to have an early out here so that we don't
	-- override requires of ourself; this would result in the module cache
	-- deviating into a bunch of separate ones.
	--
	-- TODO: This is a little janky, so we should find a way to do this that's a
	-- little more robust. We may want to apply it to anything in RobloxJest?
	if scriptInstance == script then return require(scriptInstance) :: any end
	-- FIXME: an extra special hack that prevents us from frequently reloading
	-- `jest-roblox`, and therefore dodges the expensive modules found in:
	-- jest-roblox -> luau-polyfill@0.1.5 -> RegExp
	if
		scriptInstance.Name == "RegExp"
		or scriptInstance.Name == "luau-regexp"
	then
		return require(scriptInstance) :: any
	end

	-- If already loaded and cached, return cached module. This should behave
	-- similarly to normal `require` behavior
	if requiredModules[scriptInstance] ~= nil then
		return requiredModules[scriptInstance]
	end

	local moduleResult
	-- First, check the mock cache and see if this is being mocked
	if typeof(mocks[scriptInstance]) == "function" then
		-- ROBLOX FIXME: Luau flow analysis bug workaround
		moduleResult = (mocks[scriptInstance] :: Function)()

		if moduleResult == nil then
			error(
				string.format(
					"[Mock Error]: %s did not return a valid result\n\tmocks must return a non-nil value",
					tostring(scriptInstance)
				)
			)
		end
	else
		-- Narrowing this type here lets us appease the type checker while still
		-- counting on types for the rest of this file
		local loadmodule: (ModuleScript) -> (any, string, CleanupFn) =
			debug["loadmodule"]
		local moduleFunction, errorMessage, cleanup = loadmodule(scriptInstance)
		assert(moduleFunction ~= nil, errorMessage)

		getfenv(moduleFunction).require = requireOverride
		-- getfenv(moduleFunction).delay = FakeTimers.delayOverride
		-- getfenv(moduleFunction).tick = FakeTimers.tickOverride
		-- getfenv(moduleFunction).task = FakeTimers.taskOverride
		moduleResult = moduleFunction()

		if moduleResult == nil then
			error(
				string.format(
					"[Module Error]: %s did not return a valid result\n\tModuleScripts must return a non-nil value",
					tostring(scriptInstance)
				)
			)
		end
		moduleCleanup[scriptInstance] = cleanup
	end

	-- Load normally into the require cache
	requiredModules[scriptInstance] = moduleResult

	return moduleResult
end

local function resetModules()
	-- Clear all modules in the override require cache
	requiredModules = {}

	for script, cleanup in pairs(moduleCleanup) do
		(cleanup :: CleanupFn)()
	end

	moduleCleanup = {}
end

return {
	requireOverride = requireOverride,
	resetModules = resetModules,
}
