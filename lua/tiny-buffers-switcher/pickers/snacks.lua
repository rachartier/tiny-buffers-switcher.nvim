local M = {}

function M.pick(buffers, config)
	local has_snacks, snacks = pcall(require, "snacks")
	if not has_snacks then
		vim.notify("snacks is not installed", vim.log.levels.ERROR)
		return
	end

	local picker = require("tiny-buffers-switcher.pickers.base").new()
	local entries = {}

	for _, buf in ipairs(buffers) do
		local buf_info = picker:format_buffer(buf)
		table.insert(entries, {
			value = buf,
			display = picker:format_entry(buf_info, config),
		})
	end

	snacks.select("Switch Buffer", entries, {
		on_select = function(selected)
			if selected then
				vim.api.nvim_set_current_buf(selected.value)
			end
		end,
	})
end

return M
