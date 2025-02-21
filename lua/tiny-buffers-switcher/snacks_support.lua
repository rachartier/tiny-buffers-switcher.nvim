local M = {}

local utils = require("tiny-buffers-switcher.utils")
local snacks = require("snacks.picker")

local function create_picker_items()
	local buffers = utils.get_list_buffers(M.opts)
	local items = {}

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
		if not modified then
			status_icon = "  "
		end
		local icon = buffer.icon

		table.insert(items, {
			name = buffer_name,
			formatted_path = buffer.formatted_path,
			file = buffer.path,
			path = buffer_directory,
			modified = modified,
			icon = icon,
			icon_color = buffer.icon_color,
			status_icon = status_icon,
			status_color = buffer.status_color,
			filename = buffer_name,
			filename_color = buffer.filename_color,
		})
	end

	return items
end

function M.setup(opts)
	M.opts = opts
end

function M.switcher()
	snacks.pick({
		title = "Navigate to a Buffer",
		items = create_picker_items(),
		format = function(item)
			local ret = {}
			ret[#ret + 1] = { item.status_icon .. " ", item.status_color }
			ret[#ret + 1] = { item.icon .. " ", item.icon_color }
			ret[#ret + 1] = { item.name }
			ret[#ret + 1] = { " " .. item.formatted_path, "Comment" }
			return ret
		end,
		confirm = function(picker, item)
			if not item then
				return
			end

			local selected = item.file

			if selected ~= "" and selected ~= nil and selected ~= "[No Name]" then
				vim.cmd("buffer " .. selected)
			end
		end,
	})
end

return M
