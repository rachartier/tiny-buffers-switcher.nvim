local M = {}

function M.new(base_picker)
	local buffer_picker = base_picker or require("tiny-buffers-switcher.pickers.base").new()
	local hotkeys = require("tiny-buffers-switcher.hotkeys")

	local buffer_state = {
		buf = nil,
		win = nil,
		buffers = {},
		hotkey_map = {},
		buffer_hotkeys = {},
	}

	function buffer_picker:show()
		self:_update_buffers_list()
		local buffers = self:get_buffers()

		if #buffers == 0 then
			vim.notify("No buffers available", vim.log.levels.INFO)
			return
		end

		buffer_state.buffers = buffers
		self:_generate_hotkeys()

		self:_create_buffer_window()
		self:_populate_buffer_content()
		self:_setup_buffer_keymaps()
		self:_setup_buffer_autocmds()
	end

	function buffer_picker:_generate_hotkeys()
		local hotkey_opts = self.opts and self.opts.hotkeys or {}
		local hotkey_mode = hotkey_opts.mode or "text_diff_based"
		local custom_keys = hotkey_opts.custom_keys or {}
		local enable_hotkeys = hotkey_opts.enable ~= false

		if not enable_hotkeys then
			buffer_state.hotkey_map = {}
			buffer_state.buffer_hotkeys = {}
			return
		end

		local buffer_names = {}
		for _, buffer in ipairs(buffer_state.buffers) do
			local formatted = self:format_buffer_entry(buffer, self.opts)
			table.insert(buffer_names, formatted.name)
		end

		hotkeys.add_config_keymaps_to_reserved(self.opts or {})

		local used_hotkeys = {}
		local generated_hotkeys = hotkeys.generate_hotkeys(buffer_names, hotkey_mode, custom_keys, used_hotkeys)

		buffer_state.hotkey_map = {}
		buffer_state.buffer_hotkeys = {}
		for i, hotkey in ipairs(generated_hotkeys) do
			if hotkey then
				buffer_state.hotkey_map[hotkey] = i
				buffer_state.buffer_hotkeys[i] = hotkey
			end
		end
	end

	function buffer_picker:_create_buffer_window()
		local dims = self:calculate_dimensions()
		local width = dims.width
		local height = dims.height
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		buffer_state.buf = vim.api.nvim_create_buf(false, false)

		vim.bo[buffer_state.buf].buftype = "nofile"
		vim.bo[buffer_state.buf].filetype = "tiny-buffer-picker"
		vim.bo[buffer_state.buf].swapfile = false
		vim.bo[buffer_state.buf].modifiable = false

		vim.api.nvim_buf_set_name(buffer_state.buf, "buffer://picker")

		buffer_state.win = vim.api.nvim_open_win(buffer_state.buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
			title = " Buffer Picker ",
			title_pos = "center",
		})

		vim.wo[buffer_state.win].wrap = false
		vim.wo[buffer_state.win].signcolumn = "no"
		vim.wo[buffer_state.win].cursorcolumn = false
		vim.wo[buffer_state.win].foldcolumn = "0"
		vim.wo[buffer_state.win].spell = false
		vim.wo[buffer_state.win].list = false
		vim.wo[buffer_state.win].conceallevel = 3
		vim.wo[buffer_state.win].concealcursor = "nvic"
	end

	function buffer_picker:_populate_buffer_content()
		local lines = {}
		local ns_id = vim.api.nvim_create_namespace("tiny-buffer-picker")

		vim.api.nvim_buf_set_lines(buffer_state.buf, 0, -1, false, {})
		vim.api.nvim_buf_clear_namespace(buffer_state.buf, ns_id, 0, -1)

		local max_hotkey_width = 0
		for i = 1, #buffer_state.buffers do
			local hotkey = buffer_state.buffer_hotkeys[i]
			if hotkey then
				max_hotkey_width = math.max(max_hotkey_width, vim.fn.strwidth(hotkey))
			end
		end

		for i, buffer in ipairs(buffer_state.buffers) do
			local formatted = self:format_buffer_entry(buffer, self.opts)
			local icon = formatted.icon or "󰈙"
			local name = formatted.name
			local directory = formatted.directory or ""
			local hotkey = buffer_state.buffer_hotkeys[i]

			local line = ""
			if hotkey then
				local padded_hotkey = hotkey .. string.rep(" ", max_hotkey_width - vim.fn.strwidth(hotkey))
				line = " [" .. padded_hotkey .. "] " .. icon .. " " .. name
			else
				local spacing = string.rep(" ", max_hotkey_width + 4)
				line = spacing .. icon .. " " .. name
			end

			if directory ~= "" and directory ~= "." then
				line = line .. "  " .. directory
			end

			table.insert(lines, line)
		end

		vim.api.nvim_buf_set_lines(buffer_state.buf, 0, -1, false, lines)

		for i, buffer in ipairs(buffer_state.buffers) do
			local line_idx = i - 1
			local formatted = self:format_buffer_entry(buffer, self.opts)
			local icon = formatted.icon or "󰈙"
			local name = formatted.name
			local directory = formatted.directory or ""
			local hotkey = buffer_state.buffer_hotkeys[i]

			local current_pos = 1

			if hotkey then
				local padded_hotkey = hotkey .. string.rep(" ", max_hotkey_width - vim.fn.strwidth(hotkey))

				vim.api.nvim_buf_set_extmark(buffer_state.buf, ns_id, line_idx, current_pos, {
					end_col = current_pos + 1,
					hl_group = "Special",
				})
				current_pos = current_pos + 1

				vim.api.nvim_buf_set_extmark(buffer_state.buf, ns_id, line_idx, current_pos, {
					end_col = current_pos + vim.fn.strlen(hotkey),
					hl_group = "Identifier",
				})
				current_pos = current_pos + vim.fn.strlen(padded_hotkey)

				vim.api.nvim_buf_set_extmark(buffer_state.buf, ns_id, line_idx, current_pos, {
					end_col = current_pos + 2,
					hl_group = "Special",
				})
				current_pos = current_pos + 2
			else
				current_pos = current_pos + max_hotkey_width + 3
			end

			local icon_start = current_pos
			local icon_end = icon_start + vim.fn.strlen(icon)
			if buffer.icon_color then
				vim.api.nvim_buf_set_extmark(buffer_state.buf, ns_id, line_idx, icon_start, {
					end_col = icon_end,
					hl_group = buffer.icon_color,
				})
			end
			current_pos = icon_end + 1

			current_pos = current_pos + vim.fn.strlen(name)

			if directory ~= "" and directory ~= "." then
				current_pos = current_pos + 2
				local dir_start = current_pos
				local dir_end = dir_start + vim.fn.strlen(directory)
				vim.api.nvim_buf_set_extmark(buffer_state.buf, ns_id, line_idx, dir_start, {
					end_col = dir_end,
					hl_group = "Comment",
				})
			end
		end
	end

	function buffer_picker:_setup_buffer_keymaps()
		local opts = { noremap = true, silent = true, buffer = buffer_state.buf }

		-- Navigation and selection
		vim.keymap.set("n", "<CR>", function()
			self:_select_entry()
		end, opts)
		vim.keymap.set("n", "<C-c>", function()
			self:_close()
		end, opts)
		vim.keymap.set("n", "q", function()
			self:_close()
		end, opts)
		vim.keymap.set("n", "<Esc>", function()
			self:_close()
		end, opts)

		-- Buffer deletion - simple and direct
		vim.keymap.set("n", "dd", function()
			self:_delete_buffer()
		end, opts)

		-- Refresh
		vim.keymap.set("n", "<C-l>", function()
			self:_refresh()
		end, opts)
		vim.keymap.set("n", "R", function()
			self:_refresh()
		end, opts)

		-- Tab navigation (configurable)
		local buffer_opts = self.opts and self.opts.buffer_opts or {}
		local enable_tab_navigation = buffer_opts.enable_tab_navigation ~= false -- Default to true

		if enable_tab_navigation then
			vim.keymap.set("n", "<Tab>", function()
				self:_move_cursor_down()
			end, opts)
			vim.keymap.set("n", "<S-Tab>", function()
				self:_move_cursor_up()
			end, opts)
		end

		-- Setup hotkey mappings for quick buffer selection
		for hotkey, buffer_index in pairs(buffer_state.hotkey_map) do
			vim.keymap.set("n", hotkey, function()
				self:_select_buffer_by_index(buffer_index)
			end, opts)
		end
	end

	function buffer_picker:_move_cursor_down()
		local current_line = vim.api.nvim_win_get_cursor(buffer_state.win)[1]
		local total_lines = #buffer_state.buffers
		local new_line = current_line + 1

		-- Wrap to top if at bottom
		if new_line > total_lines then
			new_line = 1
		end

		vim.api.nvim_win_set_cursor(buffer_state.win, { new_line, 0 })
	end

	function buffer_picker:_move_cursor_up()
		local current_line = vim.api.nvim_win_get_cursor(buffer_state.win)[1]
		local total_lines = #buffer_state.buffers
		local new_line = current_line - 1

		-- Wrap to bottom if at top
		if new_line < 1 then
			new_line = total_lines
		end

		vim.api.nvim_win_set_cursor(buffer_state.win, { new_line, 0 })
	end

	function buffer_picker:_select_buffer_by_index(index)
		local buffer = buffer_state.buffers[index]
		if buffer and buffer.id then
			local target_buffer_id = buffer.id

			self:_close()

			self:switch_to_buffer(target_buffer_id)
		end
	end

	function buffer_picker:_setup_buffer_autocmds()
		local augroup = vim.api.nvim_create_augroup("TinyBufferPicker", { clear = true })

		vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
			group = augroup,
			buffer = buffer_state.buf,
			callback = function()
				vim.schedule(function()
					if buffer_state.win and vim.api.nvim_win_is_valid(buffer_state.win) then
						local current_win = vim.api.nvim_get_current_win()
						if current_win ~= buffer_state.win then
							self:_close()
						end
					end
				end)
			end,
		})
	end

	function buffer_picker:_select_entry()
		local cursor_line = vim.api.nvim_win_get_cursor(buffer_state.win)[1]
		local buffer = buffer_state.buffers[cursor_line]

		if buffer and buffer.id then
			local target_buffer_id = buffer.id

			self:_close()

			self:switch_to_buffer(target_buffer_id)
		end
	end

	function buffer_picker:_delete_buffer()
		local cursor_line = vim.api.nvim_win_get_cursor(buffer_state.win)[1]
		local buffer = buffer_state.buffers[cursor_line]

		if not buffer or not buffer.id then
			return
		end

		local success = self:delete_buffer(buffer.id)

		if success then
			self:_refresh()
		else
			vim.notify("Failed to delete buffer", vim.log.levels.ERROR)
		end
	end

	function buffer_picker:_refresh()
		self:_update_buffers_list()
		buffer_state.buffers = self:get_buffers()

		if #buffer_state.buffers == 0 then
			vim.notify("No buffers available", vim.log.levels.INFO)
			self:_close()
			return
		end

		self:_generate_hotkeys()

		local cursor_pos = vim.api.nvim_win_get_cursor(buffer_state.win)

		self:_populate_buffer_content()

		cursor_pos[1] = math.min(cursor_pos[1], #buffer_state.buffers)
		cursor_pos[1] = math.max(cursor_pos[1], 1)
		vim.api.nvim_win_set_cursor(buffer_state.win, cursor_pos)

		self:_setup_buffer_keymaps()
	end

	function buffer_picker:_close()
		if buffer_state.win and vim.api.nvim_win_is_valid(buffer_state.win) then
			vim.api.nvim_win_close(buffer_state.win, true)
		end

		if buffer_state.buf and vim.api.nvim_buf_is_valid(buffer_state.buf) then
			vim.api.nvim_buf_delete(buffer_state.buf, { force = true })
		end

		buffer_state = {
			buf = nil,
			win = nil,
			buffers = {},
			hotkey_map = {},
			buffer_hotkeys = {},
		}
	end

	return buffer_picker
end

return M
