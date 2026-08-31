local function icon(self)
	local matched = th.icon:match(self._file, { hovered = self._file.is_hovered })
	return matched and matched.text .. " " or ""
end

return {
	setup = function()
		Entity.icon = icon
	end,
}
