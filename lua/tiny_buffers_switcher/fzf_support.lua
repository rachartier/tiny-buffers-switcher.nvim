local M = {}

function M.switcher()
	local builtin = require("fzf-lua.previewer.builtin")

	local buffer_previewer = builtin.buffer_or_file:extend()

	function buffer_previewer:new(o, opts, fzf_win)
		buffer_previewer.super.new(self, o, opts, fzf_win)
		setmetatable(self, buffer_previewer)
		return self
	end

	function buffer_previewer:parse_entry(entry_str)
		local path, line = entry_str:match("%s+(.*)")
		return {
			path = path,
			line = tonumber(line) or 1,
			col = 1,
		}
	end

	local fzf_lua = require("fzf-lua")

	fzf_lua.fzf_exec(function(fzf_cb)
		local buffers = M.get_list_buffers()

		for _, buffer in ipairs(buffers) do
			local path = buffer.path
			local modified = buffer.modified
			local status_icon = buffer.status_icon

			local color_icon = fzf_lua.utils.ansi_codes.red
			local line = string.format("   %s", path)

			if modified then
				line = string.format("%s %s", fzf_lua.utils.ansi_codes.red(status_icon), path)
			end

			fzf_cb(line)
		end

		fzf_cb()
	end, {
		previewer = buffer_previewer,
		prompt = "Buffers> ",
		cwd_prompt_shorten_val = 1,
		winopts = {
			width = 0.6,
			height = 0.6,
			row = 0.5, -- window row position (0=top, 1=bottom)
			col = 0.5,
		},
		actions = {
			["default"] = function(selected)
				if #selected > 0 then
					local buf = selected[1]:match("%s+(.*)")
					vim.cmd("buffer " .. buf)
				end
			end,
			["ctrl-d"] = function(selected)
				if #selected > 0 then
					local buf = selected[1]:match("%s+(.*)")
					vim.cmd("bdelete " .. buf[1])
				end
			end,
		},
		fn_transform = function(x)
			return require("fzf-lua").make_entry.file(x, { file_icons = true, color_icons = true })
		end,
	})
end

return M
