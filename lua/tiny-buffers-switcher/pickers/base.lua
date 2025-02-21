local M = {}

-- Base picker class
function M.new()
	local picker = {}

	function picker:format_buffer(buf)
		local fullpath = vim.api.nvim_buf_get_name(buf)
		local name, directory = require("tiny-buffers-switcher.utils").get_buf_name_and_path(fullpath)
		local icon, hl = require("tiny-buffers-switcher.utils").get_icon_for_file(fullpath)
		local modified = vim.api.nvim_buf_get_option(buf, "modified")

		return {
			buf = buf,
			name = name,
			directory = directory,
			fullpath = fullpath,
			icon = icon,
			icon_hl = hl,
			modified = modified,
		}
	end

	function picker:format_entry(buf_info, config)
		local entry = buf_info.icon and (buf_info.icon .. " ") or ""
		entry = entry .. buf_info.name

		if buf_info.modified then
			entry = entry .. " " .. config.signs.file.not_saved
		end

		if buf_info.directory ~= "" then
			entry = entry .. " (" .. buf_info.directory .. ")"
		end

		return entry
	end

	return picker
end

return M
