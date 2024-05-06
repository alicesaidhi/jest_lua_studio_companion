local function create_profiler()

	local profiler = {}

	local public = {}
	local labels = {}
	local results = {}

	function public.begin(label: string)
		table.insert(labels, {name = label, time = os.clock()})
	end

	function public.finish()
		local result = table.remove(labels)
		if not result then error("no label to end") end
		local t = os.clock() - result.time
		table.insert(results, {
			name = result.name,
			time = t
		})
	end

	-- alias
	public.Begin = public.begin
	public.Finish = public.finish

	profiler.public = public

	return profiler
	
end

return create_profiler