local M = {}

local utils = require("tiny-buffers-switcher.utils")

local fzf_lua = require("fzf-lua")

local builtin = require("fzf-lua.previewer.builtin")
local buffer_previewer = builtin.buffer_or_file:extend()

function buffer_previewer:new(o, opts, fzf_win)
	buffer_previewer.super.new(self, o, opts, fzf_win)
	setmetatable(self, buffer_previewer)
	return self
end

local function get_buf_infos(entry)
	local pattern = ".+ ([%w_.-]+)%s+([%w/.-]*).*$"
	local buf_name, buf_path = entry:match(pattern)
	local buf_id = nil

	if buf_name and buf_path then
		buf_id = vim.fn.bufnr(buf_path .. "/" .. buf_name)
	end

	return buf_name, buf_path, buf_id
end

function buffer_previewer:parse_entry(entry_str)
	local buf_name, buf_path, buf_id = get_buf_infos(entry_str)

	if not buf_path or buf_path == "" then
		buf_path = "."
	end

	return {
		path = buf_path .. "/" .. buf_name,
		line = 1,
		col = 1,
	}
end

function M.setup() end

function M.switcher(opts)
	fzf_lua.fzf_exec(function(fzf_cb)
		local buffers = utils.get_list_buffers()

		for _, buffer in ipairs(buffers) do
			local buffer_name = vim.fn.fnamemodify(buffer.path, ":t")
			local buffer_directory = vim.fn.fnamemodify(buffer.path, ":h")

			if buffer_name == "" then
				buffer_name = "[No Name]"
			end

			if buffer_directory == "." then
				buffer_directory = ""
			end

			local modified = buffer.modified
			local status_icon = buffer.status_icon

			buffer_directory = fzf_lua.utils.ansi_from_hl("Comment", buffer_directory)
			local icon = fzf_lua.utils.ansi_from_hl(buffer.icon_color, buffer.icon)

			local line = string.format("   %s %s %s", icon, buffer_name, buffer_directory)

			if modified then
				line = string.format(
					"%s %s %s %s",
					fzf_lua.utils.ansi_codes.red(status_icon),
					icon,
					buffer_name,
					buffer_directory
				)
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
			row = 0.5,
			col = 0.5,
		},
		actions = {
			["default"] = function(selected)
				if #selected > 0 then
					local buf_name, buf_path, buf_id = get_buf_infos(selected[1])
					if buf_id == nil then
						if buf_name then
							vim.cmd("buffer " .. buf_name)
						else
							vim.notify("Buffer not found", vim.log.levels.ERROR)
						end
					else
						vim.cmd("buffer " .. buf_id)
					end
				end
			end,
			["ctrl-d"] = function(selected)
				if #selected > 0 then
					local buf_name, buf_path, buf_id = get_buf_infos(selected[1])
					vim.cmd("bdelete " .. buf_id)
				end
			end,
		},
	})
end
