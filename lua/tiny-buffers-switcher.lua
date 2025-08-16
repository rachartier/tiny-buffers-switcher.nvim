local M = {}

local picker_instance = nil

function M.setup(options)
	M.opts = {
		signs = {
			file = {
				not_saved = "󰉉 ",
			},
		},
		window = {
			width = 0.8, -- Window width (0.0 to 1.0 or absolute number)
			height = 0.8, -- Window height (0.0 to 1.0 or absolute number)
			preview_height = 0.4, -- Preview height as ratio of total height
		},
		-- Picker-specific options
		buffer_opts = {
			select_icon = "► ",
		},
		telescope_opts = {},
		fzf_opts = {},
		snacks_opts = {},
	}

	if options then
		M.opts = vim.tbl_deep_extend("force", M.opts, options)
	end

	local base_picker = require("tiny-buffers-switcher.pickers.base")
	picker_instance = base_picker.create_picker(M.opts)

	local augroup = vim.api.nvim_create_augroup("TinyBuffersSwitcher", { clear = true })
	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		callback = function()
			if picker_instance then
				picker_instance:_track_buffer_change()
			end
		end,
	})
end

function M.switcher()
	if not picker_instance then
		error("Plugin not initialized. Call setup() first.")
	end

	picker_instance:show()
end

function M.alternate_buffer()
	if not picker_instance then
		error("Plugin not initialized. Call setup() first.")
	end

	return picker_instance:handle_tab()
end

function M.buffer_picker()
	if not picker_instance then
		error("Plugin not initialized. Call setup() first.")
	end

	-- Force use of the buffer picker
	local base_picker = require("tiny-buffers-switcher.pickers.base")
	local buffer_picker = require("tiny-buffers-switcher.pickers.buffer")
	local picker = base_picker.new()
	picker:setup(M.opts)
	local buffer_ui = buffer_picker.new(picker)
	buffer_ui:show()
end

function M.get_picker()
	return picker_instance
end

return M
