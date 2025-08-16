local M = {}

function M.new(base_picker)
	local snacks_picker = base_picker or require("tiny-buffers-switcher.pickers.base").new()

	function snacks_picker:show()
		local has_snacks, snacks = pcall(require, "snacks")
		if not has_snacks then
			vim.notify("snacks is not installed", vim.log.levels.ERROR)
			return
		end

		self:_update_buffers_list()
		local buffers = self:get_buffers()

		if #buffers == 0 then
			vim.notify("No buffers available", vim.log.levels.INFO)
			return
		end

		local items = {}
		for i, buffer in ipairs(buffers) do
			local formatted = self:format_buffer_entry(buffer, self.opts)
			table.insert(items, {
				text = formatted.name,
				buffer_info = buffer,
				formatted = formatted,
				index = i,
			})
		end

		snacks.picker.pick({
			title = "Navigate to a Buffer",
			items = items,
			format = function(item)
				return self:_build_snacks_display(item.formatted)
			end,
			preview = function(item, ctx)
				return self:_create_snacks_preview(item, ctx)
			end,
			confirm = function(picker, item)
				if not item then
					return
				end
				if item.buffer_info and item.buffer_info.id then
					self:switch_to_buffer(item.buffer_info.id)
				end
			end,
			actions = {
				delete = {
					key = "<C-d>",
					desc = "Delete buffer",
					action = function(picker, item)
						if item and item.buffer_info and item.buffer_info.id then
							if self:delete_buffer(item.buffer_info.id) then
								picker:refresh()
							end
						end
					end,
				},
			},
			opts = self:_get_snacks_opts(),
		})
	end

	-- Get Snacks picker options with custom dimensions
	function snacks_picker:_get_snacks_opts()
		local config = self:get_window_config()
		return {
			wrap = true,
			layout = {
				preview = {
					height = config.preview_height,
					position = "top",
					border = "rounded",
				},
				box = {
					width = config.width,
					height = config.height,
				},
			},
		}
	end

	-- Create preview for Snacks picker
	function snacks_picker:_create_snacks_preview(item, ctx)
		if not item or not item.buffer_info then
			return { "No preview available" }
		end

		local buffer_info = item.buffer_info
		
		-- For valid buffer IDs, try to show buffer content
		if buffer_info.id and vim.api.nvim_buf_is_valid(buffer_info.id) then
			-- Get buffer lines
			local lines = vim.api.nvim_buf_get_lines(buffer_info.id, 0, 100, false)
			if #lines > 0 then
				return {
					lines = lines,
					ft = vim.api.nvim_buf_get_option(buffer_info.id, "filetype") or "text",
				}
			end
		end
		
		-- Fallback to file content
		local preview_content = self:get_preview_content(buffer_info)
		return {
			lines = preview_content,
			ft = vim.fn.fnamemodify(buffer_info.path or "", ":e") or "text",
		}
	end

	function snacks_picker:_build_snacks_display(formatted)
		local ret = {}

		if formatted.status_icon and formatted.status_icon ~= "" then
			table.insert(ret, { formatted.status_icon .. " ", formatted.status_color or "SwitchBufferStatusColor" })
		else
			table.insert(ret, { "  " })
		end

		if formatted.icon and formatted.icon ~= "" then
			table.insert(ret, { formatted.icon .. " ", formatted.icon_color })
		end

		table.insert(ret, { formatted.name })

		if formatted.directory and formatted.directory ~= "" then
			table.insert(ret, { " " .. formatted.directory, "Comment" })
		end

		return ret
	end

	return snacks_picker
end

return M
