local M = {}

function M._get_filename_relative_path(fullpath, path_to_remove)
	fullpath = fullpath:gsub("\\", "/")
	path_to_remove = path_to_remove:gsub("\\", "/")

	fullpath = fullpath:gsub("/$", "")
	path_to_remove = path_to_remove:gsub("/$", "")

	local fullpath_len = #fullpath
	local path_to_remove_len = #path_to_remove

	local i = 1
	while i <= fullpath_len and i <= path_to_remove_len do
		if fullpath:sub(i, i) == path_to_remove:sub(i, i) then
			i = i + 1
		else
			break
		end
	end

	if i > path_to_remove_len then
		return fullpath:sub(i + 1)
	else
		return fullpath
	end
end

function M.get_symbol(filename)
	local devicons = pcall(require, "nvim-web-devicons")
	if not devicons then
		return "", nil
	end

	local ext = string.match(filename, "%.([^%.]*)$")

	if ext then
		ext = ext:gsub("%s+", "")
	end

	local symbol, hl = require("nvim-web-devicons").get_icon(filename, ext, { default = false })

	if symbol == nil then
		if filename:match("^term://") then
			symbol = " "
		else
			if vim.fn.isdirectory(filename) then
				symbol = " "
			else
				symbol = " "
			end
		end
	end

	return symbol, hl
end

local function get_folders_in_path(path)
	local folders = {}

	for folder in path:gmatch("([^/]+)") do
		table.insert(folders, folder)
	end

	return folders
end

local function get_n_last_folders_in_path(path, n)
	local paths = get_folders_in_path(path)
	local nFolders = #paths

	if nFolders > n then
		local last = ""

		for i = n, 0, -1 do
			last = table.concat({ last, paths[nFolders - i] }, "/")
		end

		return string.sub(last, 2)
	else
		return path
	end
end

function M.format_filename(filename, filename_max_length)
	local function trunc_filename(fn, fn_max)
		if string.len(fn) <= fn_max then
			return fn
		end

		local substr_length = fn_max - string.len("...")
		if substr_length <= 0 then
			return string.rep(".", fn_max)
		end

		return "..." .. string.sub(fn, -substr_length)
	end

	if string.match(filename, "^term://") then
		return ""
	end

	filename = string.gsub(filename, "term://", "Terminal: ", 1)
	filename = get_n_last_folders_in_path(filename, 1)
	filename = trunc_filename(filename, filename_max_length)

	filename = string.match(filename, "(.*[/\\])")

	if filename then
		return filename
	end

	return ""
	-- return filename
end

function M._get_filename(fullpath)
	return fullpath:match("([^/]+)$")
end

M.get_list_buffers = function()
	local buffer_list = ""
	buffer_list = vim.fn.execute("ls t")

	local buf_names = vim.split(buffer_list, "\n")

	table.remove(buf_names, 1)

	if #buf_names >= 2 then
		local temp = buf_names[1]
		buf_names[1] = buf_names[2]
		buf_names[2] = temp
	end

	local buffer_names = {}
	for _, line in ipairs(buf_names) do
		local name = line:match('"([^"]+)"')
		local id = tonumber(line:match("([0-9]+) "))

		if name then
			local buf_modified = vim.api.nvim_get_option_value("modified", {
				buf = id,
			})

			local path = name
			local formatted_filename = M.format_filename(path, 45)
			local icon, icon_color = M.get_symbol(path)
			local path_color = nil
			local status_color = nil
			local status_icon = ""
			local modified = false

			if buf_modified then
				-- path_color = "NeoTreeModified"
				modified = true
				status_icon = require("config.icons").signs.file.not_saved
				status_color = "SwitchBufferStatusColor"
			end

			if vim.fn.getbufvar(id, "bufpersist") ~= 1 then
				path_color = "Comment"
			end

			table.insert(buffer_names, {
				icon = icon,
				formatted_path = formatted_filename,
				path = path,
				icon_color = icon_color,
				path_color = path_color,
				status_icon = status_icon,
				status_color = status_color,
				filename = M._get_filename(path),
				filename_color = "TelescopeSelection",
				modified = modified,
				id = id,
			})
		end
	end

	return buffer_names
end

return M
