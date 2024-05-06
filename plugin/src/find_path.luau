local function find_object(path: { string }, root: Instance)
	local obj = root

	for _, value in path do
		print("looking for", value, "in", obj.Name)
		local new = obj:FindFirstChild(value)
		obj = new

		if obj == nil then return nil end
	end

	return obj
end

return find_object
