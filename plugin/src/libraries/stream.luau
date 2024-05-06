local MAX_SIZE = 199_999

local stream = buffer.create(MAX_SIZE)
local n = 0

local function push_string(input: string)
	local length = #input
	local input_b = buffer.fromstring(input)

	-- move the buffer back
	buffer.copy(stream, 0, stream, math.min(length, MAX_SIZE))
	buffer.copy(
		stream,
		math.max(0, MAX_SIZE - length),
		input_b,
		math.max(0, length - MAX_SIZE),
		math.min(MAX_SIZE, length)
	)
	n += math.min(length, MAX_SIZE)
end

local function clear()
	buffer.fill(stream, 0, 0)
	n = 0
end

local function get_string() return string.sub(buffer.tostring(stream), -n) end

return {
	push_string = push_string,
	get_string = get_string,
	clear = clear,
}
