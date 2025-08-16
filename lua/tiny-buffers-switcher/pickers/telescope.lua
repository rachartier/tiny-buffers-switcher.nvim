local M = {}

function M.new(base_picker)
	local telescope_picker = base_picker or require("tiny-buffers-switcher.pickers.base").new()

	function telescope_picker:show()
		local has_telescope, telescope = pcall(require, "telescope")
		if not has_telescope then
			vim.notify("Telescope is not installed", vim.log.levels.ERROR)
			return
		end

		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		self:_update_buffers_list()
		local buffers = self:get_buffers()

		if #buffers == 0 then
			vim.notify("No buffers available", vim.log.levels.INFO)
			return
		end

		local picker = pickers.new(self:_get_telescope_theme(), {
			prompt_title = "Navigate to a Buffer",
			finder = self:_create_telescope_finder(buffers),
			sorter = conf.generic_sorter({}),
			previewer = self:_create_telescope_previewer(),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection and selection.buffer_info and selection.buffer_info.id then
						self:switch_to_buffer(selection.buffer_info.id)
					end
				end)

				map("i", "<Tab>", function()
					actions.move_selection_next(prompt_bufnr)
				end)

				map("i", "<S-Tab>", function()
					actions.move_selection_previous(prompt_bufnr)
				end)

				map("i", "<C-d>", function()
					local selection = action_state.get_selected_entry()
					if selection and selection.buffer_info and selection.buffer_info.id then
						if self:delete_buffer(selection.buffer_info.id) then
							local current_picker = action_state.get_current_picker(prompt_bufnr)
							current_picker:refresh(self:_create_telescope_finder(self:get_buffers()), {})
						end
					end
				end)

				map("i", "<Down>", actions.move_selection_next)
				map("i", "<Up>", actions.move_selection_previous)
				map("n", "j", actions.move_selection_next)
				map("n", "k", actions.move_selection_previous)

				return true
			end,
		})

		picker:find()
	end

	-- Create custom Telescope previewer for buffer content
	function telescope_picker:_create_telescope_previewer()
		local previewers = require("telescope.previewers")
		local conf = require("telescope.config").values

		return previewers.new_buffer_previewer({
			title = "Buffer Preview",
			define_preview = function(telescope_self, entry, status)
				if not entry or not entry.buffer_info then
					vim.api.nvim_buf_set_lines(telescope_self.state.bufnr, 0, -1, false, { "No preview available" })
					return
				end

				local buffer_info = entry.buffer_info
				
				-- For valid buffer IDs, show buffer content
				if buffer_info.id and vim.api.nvim_buf_is_valid(buffer_info.id) then
					-- Get buffer lines
					local lines = vim.api.nvim_buf_get_lines(buffer_info.id, 0, -1, false)
					vim.api.nvim_buf_set_lines(telescope_self.state.bufnr, 0, -1, false, lines)
					
					-- Set filetype for syntax highlighting
					local filetype = vim.api.nvim_buf_get_option(buffer_info.id, "filetype")
					if filetype and filetype ~= "" then
						vim.api.nvim_buf_set_option(telescope_self.state.bufnr, "filetype", filetype)
					end
				else
					-- Fallback to file content
					local preview_content = telescope_picker:get_preview_content(buffer_info)
					vim.api.nvim_buf_set_lines(telescope_self.state.bufnr, 0, -1, false, preview_content)
					
					-- Set filetype based on file extension
					local extension = vim.fn.fnamemodify(buffer_info.path or "", ":e")
					if extension and extension ~= "" then
						vim.api.nvim_buf_set_option(telescope_self.state.bufnr, "filetype", extension)
					end
				end
			end,
		})
	end

	function telescope_picker:_create_telescope_finder(buffers)
		local finders = require("telescope.finders")

		return finders.new_table({
			results = buffers,
			entry_maker = function(buffer)
				local formatted = self:format_buffer_entry(buffer, self.opts)
				return {
					value = buffer,
					buffer_info = buffer,
					ordinal = formatted.name .. " " .. (formatted.directory or ""),
					display = function(entry)
						return self:_build_telescope_display(entry.buffer_info)
					end,
					path = buffer.path,
				}
			end,
		})
	end

	function telescope_picker:_build_telescope_display(buffer)
		local formatted = self:format_buffer_entry(buffer, self.opts)
		local entry_display = require("telescope.pickers.entry_display")

		local displayer = entry_display.create({
			separator = " ",
			items = {
				{ width = 2 },
				{ width = 2 },
				{ width = nil },
				{ remaining = true },
			},
		})

		return displayer({
			{ formatted.status_icon or "  ", formatted.status_color },
			{ formatted.icon or "  ", formatted.icon_color },
			{ formatted.name },
			{ formatted.directory or "", "Comment" },
		})
	end

	function telescope_picker:_get_telescope_theme()
		local config = self:get_window_config()
		local themes = require("telescope.themes")
		return themes.get_dropdown({
			layout_strategy = "vertical",
			layout_config = {
				prompt_position = "bottom",
				vertical = {
					width = config.width,
					height = config.height,
					preview_height = config.preview_height,
					mirror = true,  -- Preview on top
				},
			},
			sorting_strategy = "ascending",
			scroll_strategy = "cycle",
		})
	end

	return telescope_picker
end

return M
