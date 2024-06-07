local M = {}

local utils = require("tiny-buffers-switcher.utils")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function displayer(filename, picker)
	local display = require("telescope.pickers.entry_display").create({
		separator = " ",
		items = {
			{ width = 2 },
			{ width = 2 },
			{ width = #filename },
			{ remaining = true },
		},
	})
	return display(picker)
end

local make_display = function(entry)
	return displayer(entry.filename, {
		{ entry.icon, entry.icon_color },
		{ entry.status_icon, entry.status_color },
		{ entry.filename, entry.filename_color },
		{ entry.formatted_path, entry.path_color },
	})
end

local function create_finders_table()
	return finders.new_table({
		results = utils.get_list_buffers(),
		entry_maker = function(entry)
			return {
				value = entry,
				ordinal = entry.path,
				path_color = entry.path_color,
				icon_color = entry.icon_color,
				formatted_path = entry.formatted_path,
				path = entry.path,
				icon = entry.icon,
				filename = entry.filename,
				filename_color = entry.filename_color,
				status_icon = entry.status_icon,
				status_color = entry.status_color,
				display = make_display,
			}
		end,
	})
end

local function create_picker(opts)
	return pickers.new(opts, {
		prompt_title = "Navigate to a Buffer",
		finder = create_finders_table(),
		sorter = conf.generic_sorter(opts),
		previewer = require("telescope.config").values.file_previewer({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				local selected = selection.value.path

				if selected ~= "" and selected ~= nil and selected ~= "[No Name]" then
					vim.cmd("buffer " .. selected)
				end
			end)

			map("i", "<Tab>", actions.move_selection_next)
			map("i", "<S-Tab>", actions.move_selection_previous)
			map("i", "<Esc>", actions.close)
			map("i", "<C-d>", function()
				local selection = action_state.get_selected_entry()
				local selected = selection.value.path

				if selected ~= "" and selected ~= nil and selected ~= "[No Name]" then
					vim.cmd("bdelete " .. selected)

					local current_picker = action_state.get_current_picker(prompt_bufnr)
					current_picker:refresh(create_finders_table(), {})
				end
			end)

			return true
		end,
	})
end

function M.setup(opts)
	M.opts = opts
		or require("telescope.themes").get_dropdown({
			layout_strategy = "horizontal",
			-- borderchars = "rounded",
			layout_config = {
				prompt_position = "top",
				horizontal = {
					width = 0.6,
					height = 0.6,
					preview_height = 0.6,
					preview_cutoff = 200,
				},
			},
			set_style = {
				result = {
					spacing = 0,
					indentation = 2,
					dynamic_width = true,
				},
			},
		})
	M.picker = create_picker(opts)
end

function M.switcher()
	local telescope_ok = pcall(require, "telescope")

	if not telescope_ok then
		require("tiny-buffers-switcher.fzf_support").switcher()
		return
	end

	create_picker(M.opts):find()
end

return M
