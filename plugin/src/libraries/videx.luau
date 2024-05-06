--------------------------------------------------------------------------------
-- videx/store.luau
--------------------------------------------------------------------------------

local vide = require(script.Parent.Parent.Parent.vide)
local source = vide.source

local NULL = newproxy()

local Store = {}

function Store.new<T, U>(initial_state: () -> T & {}, mutations: (T) -> U): T & U
	local sources = {}

	for i, v in next, initial_state() do
		local src = source(v ~= NULL and v or nil)
		sources[i] = src
	end

	local internal_proxy = {}

	setmetatable(internal_proxy, {
		__index = function(_, index)
			return sources[index]()
		end,
		__newindex = function(_, index, value)
			sources[index](value)
		end,
	})

	local external_proxy = {}

	for i, v in next, mutations(internal_proxy :: any) :: any do
		if external_proxy[i] then
			error(`duplicate field "{i}"`, 2)
		end
		external_proxy[i] = v
	end

	setmetatable(external_proxy :: any, {
		__index = function(_, index)
			local src = sources[index]
			if src == nil then
				error(`invalid index {index}`, 2)
			end
			return src()
		end,

		__newindex = function(_, index, value)
			sources[index](value)
		end,
	})

	return external_proxy :: T & U & {}
end

Store.null = NULL :: nil

return Store
