local M = {}

-- FZF picker implementation extending base picker
function M.new(base_picker)
	local fzf_picker = base_picker or require("tiny-buffers-switcher.pickers.base").new()

	-- Override the show method for FZF-specific implementation
	function fzf_picker:show()
		local has_fzf, fzf_lua = pcall(require, "fzf-lua")
		if not has_fzf then
			vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
			return
		end

		self:_update_buffers_list()
		local buffers = self:get_buffers()

		if #buffers == 0 then
			vim.notify("No buffers available", vim.log.levels.INFO)
			return
		end

		-- Build entries for FZF
		local entries = {}
		for i, buffer in ipairs(buffers) do
			local formatted = self:format_buffer_entry(buffer, self.opts)
			local display_text = self:_build_fzf_display(formatted)
			table.insert(entries, {
				display = display_text,
				buffer_info = buffer,
				index = i,
			})
		end

		fzf_lua.fzf_exec(function(fzf_cb)
			for _, entry in ipairs(entries) do
				fzf_cb(entry.display)
			end
			fzf_cb()
		end, {
			prompt = "Buffers> ",
			winopts = self:_get_fzf_winopts(),
			previewer = self:_create_fzf_previewer(entries),
			actions = {
				["default"] = function(selected)
					if #selected > 0 then
						local selected_entry = self:_find_entry_by_display(entries, selected[1])
						if selected_entry and selected_entry.buffer_info then
							self:switch_to_buffer(selected_entry.buffer_info.id)
						end
					end
				end,
				["ctrl-d"] = function(selected)
					if #selected > 0 then
						local selected_entry = self:_find_entry_by_display(entries, selected[1])
						if selected_entry and selected_entry.buffer_info then
							self:delete_buffer(selected_entry.buffer_info.id)
						end
					end
				end,
			},
			fzf_opts = {
				["--cycle"] = "", -- Enable cyclic behavior in fzf
				["--preview-window"] = self:_get_fzf_preview_window(),
				["--bind"] = "tab:down,shift-tab:up", -- Tab for navigation within picker
			},
		})
	end

	-- Get FZF window options with custom dimensions
	function fzf_picker:_get_fzf_winopts()
		local dimensions = self:calculate_dimensions()
		return {
			width = dimensions.width,
			height = dimensions.height,
			row = dimensions.row,
			col = dimensions.col,
			preview = {
				layout = "vertical",
				vertical = "up:" .. math.floor(dimensions.preview_height / dimensions.height * 100) .. "%",
			},
		}
	end

	-- Get FZF preview window configuration
	function fzf_picker:_get_fzf_preview_window()
		local dimensions = self:calculate_dimensions()
		local preview_percentage = math.floor(dimensions.preview_height / dimensions.height * 100)
		return "up:" .. preview_percentage .. "%:wrap"
	end

	-- Create FZF previewer
	function fzf_picker:_create_fzf_previewer(entries)
		local builtin = require("fzf-lua.previewer.builtin")
		local buffer_previewer = builtin.buffer_or_file:extend()

		function buffer_previewer:new(o, opts, fzf_win)
			buffer_previewer.super.new(self, o, opts, fzf_win)
			setmetatable(self, buffer_previewer)
			return self
		end

		function buffer_previewer:parse_entry(entry_str)
			local selected_entry = fzf_picker:_find_entry_by_display(entries, entry_str)
			if selected_entry and selected_entry.buffer_info then
				local buffer_info = selected_entry.buffer_info

				-- For valid buffers, try to use buffer content
				if buffer_info.id and vim.api.nvim_buf_is_valid(buffer_info.id) then
					return {
						path = buffer_info.path,
						bufnr = buffer_info.id,
						line = 1,
						col = 1,
					}
				else
					-- For files, use file path
					return {
						path = buffer_info.path,
						line = 1,
						col = 1,
					}
				end
			end

			return {
				path = "",
				line = 1,
				col = 1,
			}
		end

		return buffer_previewer
	end

	-- Build display string for FZF with ANSI colors
	function fzf_picker:_build_fzf_display(formatted)
		local fzf_lua = require("fzf-lua")
		local display_parts = {}

		-- Status icon (modified indicator)
		if formatted.status_icon and formatted.status_icon ~= "" then
			local status_colored = fzf_lua.utils.ansi_codes.red(formatted.status_icon)
			table.insert(display_parts, status_colored)
		else
			table.insert(display_parts, "  ") -- Padding for alignment
		end

		-- File icon
		if formatted.icon and formatted.icon ~= "" then
			local icon_colored = formatted.icon_color
					and fzf_lua.utils.ansi_from_hl(formatted.icon_color, formatted.icon)
				or formatted.icon
			table.insert(display_parts, icon_colored)
		end

		-- File name
		table.insert(display_parts, formatted.name)

		-- Directory path
		if formatted.directory and formatted.directory ~= "" then
			local dir_colored = fzf_lua.utils.ansi_from_hl("Comment", formatted.directory)
			table.insert(display_parts, dir_colored)
		end

		return table.concat(display_parts, " ")
	end

	-- Find entry by display text
	function fzf_picker:_find_entry_by_display(entries, display_text)
		for _, entry in ipairs(entries) do
			-- Remove ANSI codes for comparison
			local clean_display = entry.display:gsub("\027%[[0-9;]*m", "")
			local clean_selected = display_text:gsub("\027%[[0-9;]*m", "")
			if clean_display == clean_selected then
				return entry
			end
		end
		return nil
	end

	return fzf_picker
end

return M
