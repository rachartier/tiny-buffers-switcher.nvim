# tiny-buffers-switcher

![image](https://github.com/rachartier/tiny-buffers-switcher.nvim/assets/2057541/fe6b9c50-d85d-4f66-9217-f6c2114794f2)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "rachartier/tiny-buffers-switcher.nvim",
  config = function()
    require("tiny-buffers-switcher").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "rachartier/tiny-buffers-switcher.nvim",
  config = function()
    require("tiny-buffers-switcher").setup()
  end,
}
```

## Dependencies

You need at least one of the following pickers installed:

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (preferred)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- **Native Buffer Picker** (built-in, no dependencies required)

## Configuration

```lua
require("tiny-buffers-switcher").setup({
  signs = {
    file = {
      not_saved = "󰉉 ",  -- Icon for modified buffers
    },
  },
  window = {
    width = 0.8,          -- Window width (0.0-1.0 as percentage or absolute number)
    height = 0.8,         -- Window height (0.0-1.0 as percentage or absolute number)
    preview_height = 0.4, -- Preview height as ratio of total height (0.0-1.0)
  },
  picker = "auto",        -- Picker to use: "auto", "telescope", "fzf", "snacks", "buffer"

  -- Buffer picker specific options
  buffer_opts = {
    enable_tab_navigation = true,  -- Enable Tab/Shift-Tab navigation
  },

  -- Hotkey configuration for buffer picker
  hotkeys = {
    enable = true,                 -- Enable hotkeys for quick buffer selection
    mode = "text_diff_based",      -- Hotkey generation: "sequential", "text_based", "text_diff_based"
    custom_keys = {                -- Custom hotkey mappings
      { key = "m", pattern = "main" },
      { key = "r", pattern = "README" },
      { key = "c", pattern = "config" },
    },
  },
})
```

### Configuration Options

#### `signs.file.not_saved`
- **Type**: `string`
- **Default**: `"󰉉 "`
- **Description**: Icon displayed next to modified buffers

#### `window.width`
- **Type**: `number`
- **Default**: `0.8`
- **Description**: Window width. Values 0.0-1.0 are treated as percentage of screen width, values > 1.0 as absolute width in columns

#### `window.height`
- **Type**: `number`
- **Default**: `0.8`
- **Description**: Window height. Values 0.0-1.0 are treated as percentage of screen height, values > 1.0 as absolute height in lines

#### `window.preview_height`
- **Type**: `number`
- **Default**: `0.4`
- **Description**: Preview section height as a ratio of total window height (0.0-1.0). The preview appears above the file list

#### `picker`
- **Type**: `string`
- **Default**: `"auto"`
- **Description**: Picker to use. Options: `"auto"` (auto-detect), `"telescope"`, `"fzf"`, `"snacks"`, `"buffer"` (native)

#### `buffer_opts.enable_tab_navigation`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable Tab/Shift-Tab navigation in native buffer picker

#### `hotkeys.enable`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable hotkey system for quick buffer selection in native buffer picker

#### `hotkeys.mode`
- **Type**: `string`
- **Default**: `"text_diff_based"`
- **Description**: Hotkey generation strategy. Options: `"sequential"`, `"text_based"`, `"text_diff_based"`

#### `hotkeys.custom_keys`
- **Type**: `table`
- **Default**: `{}`
- **Description**: Custom hotkey mappings for specific buffer patterns

### Example Configurations

```lua
-- Smaller window with minimal preview
require("tiny-buffers-switcher").setup({
  window = {
    width = 0.6,
    height = 0.6,
    preview_height = 0.3,
  },
})

-- Full screen with large preview
require("tiny-buffers-switcher").setup({
  window = {
    width = 0.95,
    height = 0.95,
    preview_height = 0.5,
  },
})

-- Fixed size window (absolute values)
require("tiny-buffers-switcher").setup({
  window = {
    width = 120,  -- 120 columns
    height = 30,  -- 30 lines
    preview_height = 0.4,
  },
})

-- Native buffer picker with hotkeys
require("tiny-buffers-switcher").setup({
  picker = "buffer",
  buffer_opts = {
    enable_tab_navigation = true,
  },
  hotkeys = {
    enable = true,
    mode = "text_diff_based",
    custom_keys = {
      { key = "m", pattern = "main" },
      { key = "t", pattern = "test" },
      { key = "c", pattern = "config" },
    },
  },
})

-- Disable hotkeys but keep Tab navigation
require("tiny-buffers-switcher").setup({
  picker = "buffer",
  buffer_opts = {
    enable_tab_navigation = true,
  },
  hotkeys = {
    enable = false,
  },
})
```

## Usage

### Basic Buffer Switching

```lua
-- Open buffer switcher
vim.keymap.set("n", "<leader>b", require("tiny-buffers-switcher").switcher, { desc = "Buffer Switcher" })
```

### Tab Alternation

```lua
-- Quick alternate between current and last buffer
vim.keymap.set("n", "<leader><Tab>", require("tiny-buffers-switcher").alternate_buffer, { desc = "Alternate Buffer" })
```


## API

### Functions

- `setup(options)`: Initialize the plugin with configuration
- `switcher()`: Open the buffer switcher
- `alternate_buffer()`: Switch to the last used buffer
- `get_picker()`: Get the current picker instance for advanced usage

## License

MIT License
