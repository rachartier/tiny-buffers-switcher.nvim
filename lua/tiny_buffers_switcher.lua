local M = {}

local telescope_support = require("tiny_buffers_switcher.telescope_support")
local fzf_support = require("tiny_buffers_switcher.fzf_support")

local use_fzf_lua = false

function M.setup(options)
	M.opts = options or {}

	if M.opts.use_fzf_lua then
		use_fzf_lua = true
		fzf_support.setup(M.opts.fzf_opts)
	else
		telescope_support.setup(M.opts.telescope_opts)
	end

	-- vim.api.nvim_set_hl(0, "SwitchBufferModified", options.hl_modified or { link = "NeoTreeModified" })
	-- vim.api.nvim_set_hl(0, "SwitchBufferNormal", options.hl_normal or { link = "Normal" })
end

function M.switcher()
	if use_fzf_lua then
		fzf_support.switcher()
	else
		telescope_support.switcher()
	end
end

return M
