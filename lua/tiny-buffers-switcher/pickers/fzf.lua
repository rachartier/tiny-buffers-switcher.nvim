local M = {}

function M.pick(buffers, config)
	local has_fzf, fzf = pcall(require, "fzf-lua")
	if not has_fzf then
		vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
		return
	end

	local picker = require("tiny-buffers-switcher.pickers.base").new()
	local entries = {}

	for _, buf in ipairs(buffers) do
		local buf_info = picker:format_buffer(buf)
		table.insert(entries, {
			buf = buf,
			display = picker:format_entry(buf_info, config),
		})
	end

	fzf.buffers({
		source = entries,
		actions = {
			["default"] = function(selected)
				if #selected == 0 then
					return
				end

				vim.api.nvim_set_current_buf(selected[1].buf)
			end,
		},
	})
end

return M
