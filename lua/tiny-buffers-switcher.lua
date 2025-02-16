local M = {}

local picker = nil

function M.setup(options)
	M.opts = {
		signs = {
			file = {
				not_saved = "󰉉 ",
			},
		},
	}

	if options then
		M.opts = vim.tbl_deep_extend("force", M.opts, options)
	end

	if pcall(require, "telescope") then
		picker = require("tiny-buffers-switcher.telescope_support")
		picker.setup(M.opts)
	elseif pcall(require, "fzf-lua") then
		picker = require("tiny-buffers-switcher.fzf_support")
		picker.setup(M.opts)
	elseif pcall(require, "snacks") then
		picker = require("tiny-buffers-switcher.snacks_support")
		picker.setup(M.opts)
	else
		error("No supported picker found")
	end
end

function M.switcher()
	if not picker then
		error("No picker found")
	end
	picker.switcher()
end

return M
