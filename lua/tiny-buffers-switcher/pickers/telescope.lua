local M = {}

function M.pick(buffers, config)
	local has_telescope, telescope = pcall(require, "telescope.builtin")
	if not has_telescope then
		vim.notify("Telescope is not installed", vim.log.levels.ERROR)
		return
	end

	local picker = require("tiny-buffers-switcher.pickers.base").new()
	local entries = {}

	for _, buf in ipairs(buffers) do
		local buf_info = picker:format_buffer(buf)
		table.insert(entries, {
			value = buf,
			display = picker:format_entry(buf_info, config),
			ordinal = buf_info.name,
		})
	end

	telescope.buffers()
end

return M
