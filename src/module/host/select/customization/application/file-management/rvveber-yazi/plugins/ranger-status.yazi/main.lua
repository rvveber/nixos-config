local set_directory_size = ya.sync(function(state, cwd, value)
	if tostring(cx.active.current.cwd) == cwd then
		state.directory_size = value
		ui.render()
	end
end)

local set_disk = ya.sync(function(state, cwd, value)
	if tostring(cx.active.current.cwd) == cwd then
		state.disk = value
		ui.render()
	end
end)

local setup = ya.sync(function(state)
	if state.initialized then
		return
	end
	state.initialized = true

	state.disk = "Free: …"
	state.directory_size = "…"
	local request

	local function refresh(cwd)
		if request then
			request:abort()
		end

		local path = tostring(cwd)
		state.disk = "Free: …"
		state.directory_size = "…"
		ui.render()

		request = ya.async(function()
			local output = Command("df"):arg({ "-B1", "--output=size,avail", path }):output()
			local total, available = (output and output.stdout or ""):match("\n%s*(%d+)%s+(%d+)%s*$")

			if total and available then
				set_disk(path, string.format(
					"Free: %s / %s",
					ya.readable_size(tonumber(available)),
					ya.readable_size(tonumber(total))
				))
			else
				set_disk(path, "Free: ?")
			end

			local iterator = fs.calc_size(Url(path))
			if not iterator then
				return set_directory_size(path, "?")
			end

			local total_size = 0
			while true do
				local size = iterator:recv()
				if not size then
					break
				end
				total_size = total_size + size
			end

			set_directory_size(path, ya.readable_size(total_size))
		end)
	end

	ps.sub("cd", function()
		refresh(cx.active.current.cwd)
	end)

	Status:children_add(function()
		if not state.started then
			state.started = true
			refresh(cx.active.current.cwd)
		end

		return ui.Line("Dir: " .. state.directory_size .. "  " .. state.disk .. " ")
	end, 2900, Status.RIGHT)
end)

return {
	setup = setup,
}
