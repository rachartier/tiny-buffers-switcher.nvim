local M = {}

local utils = require("tiny-buffers-switcher.utils")

local buffer_state = {
	last_buffer = nil,
	current_buffer = nil,
	selection_index = 1,
	buffers_list = {},
}

function M.new()
	local picker = {}

	function picker:init()
		buffer_state.current_buffer = vim.api.nvim_get_current_buf()

		if not buffer_state.last_buffer then
			local alt_buf = vim.fn.bufnr("#")
			if
				alt_buf
				and alt_buf ~= -1
				and alt_buf ~= buffer_state.current_buffer
				and vim.api.nvim_buf_is_valid(alt_buf)
			then
				buffer_state.last_buffer = alt_buf
			end
		end
		self:_update_buffers_list()
	end

	function picker:_track_buffer_change()
		local new_current_buffer = vim.api.nvim_get_current_buf()

		if
			new_current_buffer ~= buffer_state.current_buffer
			and vim.api.nvim_buf_is_valid(new_current_buffer)
			and vim.api.nvim_buf_get_option(new_current_buffer, "buflisted")
		then
			buffer_state.last_buffer = buffer_state.current_buffer
			buffer_state.current_buffer = new_current_buffer
		end
	end

	function picker:_update_buffers_list()
		buffer_state.buffers_list = utils.get_list_buffers(self.opts or {})

		if #buffer_state.buffers_list >= 2 then
			local current_buf_id = vim.api.nvim_get_current_buf()
			local current_buf_index = nil
			local last_buf_index = nil

			for i, buf in ipairs(buffer_state.buffers_list) do
				if buf.id == current_buf_id then
					current_buf_index = i
				elseif buffer_state.last_buffer and buf.id == buffer_state.last_buffer then
					last_buf_index = i
				end
			end

			if current_buf_index and last_buf_index and current_buf_index ~= last_buf_index then
				local current_buf = buffer_state.buffers_list[current_buf_index]
				local last_buf = buffer_state.buffers_list[last_buf_index]
				local remaining_buffers = {}

				for i, buf in ipairs(buffer_state.buffers_list) do
					if i ~= current_buf_index and i ~= last_buf_index then
						table.insert(remaining_buffers, buf)
					end
				end

				buffer_state.buffers_list = { last_buf, current_buf }
				for _, buf in ipairs(remaining_buffers) do
					table.insert(buffer_state.buffers_list, buf)
				end
			elseif current_buf_index then
				local current_buf = buffer_state.buffers_list[current_buf_index]
				if current_buf_index == 1 and #buffer_state.buffers_list >= 2 then
					local first_buf = buffer_state.buffers_list[2]
					buffer_state.buffers_list[1] = first_buf
					buffer_state.buffers_list[2] = current_buf
				end
			end
		end
	end

	function picker:handle_tab()
		if #buffer_state.buffers_list >= 1 then
			local target_buffer = buffer_state.buffers_list[1]
			if target_buffer and target_buffer.id and target_buffer.id ~= vim.api.nvim_get_current_buf() then
				vim.api.nvim_set_current_buf(target_buffer.id)
				return true
			end
		end
		return false
	end

	function picker:next_buffer()
		if #buffer_state.buffers_list == 0 then
			return nil
		end

		buffer_state.selection_index = buffer_state.selection_index + 1
		if buffer_state.selection_index > #buffer_state.buffers_list then
			buffer_state.selection_index = 1
		end

		return buffer_state.buffers_list[buffer_state.selection_index]
	end

	function picker:prev_buffer()
		if #buffer_state.buffers_list == 0 then
			return nil
		end

		buffer_state.selection_index = buffer_state.selection_index - 1
		if buffer_state.selection_index < 1 then
			buffer_state.selection_index = #buffer_state.buffers_list
		end

		return buffer_state.buffers_list[buffer_state.selection_index]
	end

	function picker:get_current_selection()
		if #buffer_state.buffers_list == 0 then
			return nil
		end
		return buffer_state.buffers_list[buffer_state.selection_index] or buffer_state.buffers_list[1]
	end

	function picker:reset_selection()
		buffer_state.selection_index = 1
	end

	function picker:get_buffers()
		return buffer_state.buffers_list
	end

	function picker:format_buffer_entry(buf_info, config)
		local icon = buf_info.icon or ""
		local status_icon = buf_info.status_icon or ""
		local name = buf_info.filename or "[No Name]"
		local directory = buf_info.formatted_path or ""

		return {
			icon = icon,
			icon_color = buf_info.icon_color,
			status_icon = status_icon,
			status_color = buf_info.status_color,
			name = name,
			directory = directory,
			path = buf_info.path,
			id = buf_info.id,
			modified = buf_info.modified,
		}
	end

	-- Get preview content for a buffer
	function picker:get_preview_content(buffer_info)
		if not buffer_info or not buffer_info.path then
			return { "No preview available" }
		end
		
		local path = buffer_info.path
		
		-- Handle special buffers
		if path:match("^term://") then
			return { "Terminal buffer", "Path: " .. path }
		end
		
		-- Check if file exists and is readable
		if vim.fn.filereadable(path) == 0 then
			return { "File not readable: " .. path }
		end
		
		-- Try to read file content for preview
		local ok, content = pcall(function()
			local lines = {}
			local file = io.open(path, "r")
			if not file then
				return { "Could not open file: " .. path }
			end
			
			local line_count = 0
			local max_lines = 100  -- Limit preview to first 100 lines
			
			for line in file:lines() do
				line_count = line_count + 1
				if line_count > max_lines then
					table.insert(lines, "... (truncated)")
					break
				end
				table.insert(lines, line)
			end
			
			file:close()
			return lines
		end)
		
		if ok and content then
			return content
		else
			return { "Error reading file: " .. path }
		end
	end

	-- Get buffer information suitable for preview
	function picker:get_buffer_for_preview(buffer_info)
		if not buffer_info then
			return nil
		end
		
		-- For valid buffer IDs, we can use the buffer directly
		if buffer_info.id and vim.api.nvim_buf_is_valid(buffer_info.id) then
			return {
				bufnr = buffer_info.id,
				path = buffer_info.path,
				name = buffer_info.filename,
			}
		end
		
		-- For files, return path information
		return {
			path = buffer_info.path,
			name = buffer_info.filename,
		}
	end

	-- Get window dimensions from configuration
	function picker:get_window_config()
		local opts = self.opts or {}
		local window = opts.window or {}
		
		return {
			width = window.width or 0.8,
			height = window.height or 0.8,
			preview_height = window.preview_height or 0.4,
		}
	end

	-- Calculate actual window dimensions
	function picker:calculate_dimensions()
		local config = self:get_window_config()
		local vim_width = vim.o.columns
		local vim_height = vim.o.lines
		
		local width = config.width
		local height = config.height
		
		-- Convert percentage to actual dimensions if needed
		if width <= 1.0 then
			width = math.floor(vim_width * width)
		end
		
		if height <= 1.0 then
			height = math.floor(vim_height * height)
		end
		
		-- Calculate preview height
		local preview_height = math.floor(height * config.preview_height)
		local list_height = height - preview_height
		
		return {
			width = width,
			height = height,
			preview_height = preview_height,
			list_height = list_height,
			row = 0.5,
			col = 0.5,
		}
	end

	function picker:switch_to_buffer(buffer_id)
		if buffer_id and vim.api.nvim_buf_is_valid(buffer_id) then
			buffer_state.last_buffer = buffer_state.current_buffer
			buffer_state.current_buffer = buffer_id

			vim.api.nvim_set_current_buf(buffer_id)
			return true
		end
		return false
	end

	function picker:delete_buffer(buffer_id)
		if buffer_id and vim.api.nvim_buf_is_valid(buffer_id) then
			local success, _ = pcall(vim.api.nvim_buf_delete, buffer_id, { force = false })
			if success then
				self:_update_buffers_list()
				self:reset_selection()
				return true
			end
		end
		return false
	end

	function picker:setup(opts)
		self.opts = opts or {}
		self:init()
	end

	function picker:show()
		error("show() method must be implemented by picker subclass")
	end

	return picker
end

function M.create_picker(opts)
	local picker = M.new()
	picker:setup(opts)

	-- If user explicitly specified a picker, use it
	if opts and opts.picker then
		local picker_name = opts.picker
		if picker_name == "telescope" and pcall(require, "telescope") then
			local telescope_picker = require("tiny-buffers-switcher.pickers.telescope")
			return telescope_picker.new(picker)
		elseif picker_name == "fzf" and pcall(require, "fzf-lua") then
			local fzf_picker = require("tiny-buffers-switcher.pickers.fzf")
			return fzf_picker.new(picker)
		elseif picker_name == "snacks" and pcall(require, "snacks") then
			local snacks_picker = require("tiny-buffers-switcher.pickers.snacks")
			return snacks_picker.new(picker)
		elseif picker_name == "buffer" then
			local buffer_picker = require("tiny-buffers-switcher.pickers.buffer")
			return buffer_picker.new(picker)
		else
			error("Invalid or unavailable picker: " .. picker_name)
		end
	end

	-- Auto-detect available pickers if no preference specified
	if pcall(require, "telescope") then
		local telescope_picker = require("tiny-buffers-switcher.pickers.telescope")
		return telescope_picker.new(picker)
	elseif pcall(require, "fzf-lua") then
		local fzf_picker = require("tiny-buffers-switcher.pickers.fzf")
		return fzf_picker.new(picker)
	elseif pcall(require, "snacks") then
		local snacks_picker = require("tiny-buffers-switcher.pickers.snacks")
		return snacks_picker.new(picker)
	else
		-- Fallback to native buffer picker
		local buffer_picker = require("tiny-buffers-switcher.pickers.buffer")
		return buffer_picker.new(picker)
	end
end

return M
