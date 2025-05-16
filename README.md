# pd-nvim

A very opinionated neovim helper for Perfect Dark PC port modding

## Features

- Find functions, structs, and typedefs by name
- Find functions, structs, and typedefs under the cursor
- lldb-dap helpers for debugging
  - `PdDebugPause`
  - `PdDebugContinue`
  - `PdDebugStepOver`
  - `PdDebugStepDown`
  - `PdDebugRunToCursor`
  - `PdDebugTerminate`
  - `PdDebugBreakpoint`

## Installation

You can install `pd-nvim` using your favorite plugin manager. For example, if you're using `vim-plug`, add the following line to your `init.vim`:

```lua
  {
    'pd-nvim',
    config = true,
    dev = true
  },
```

Then run `:Lazy install pd-nvim`.

## Usage

First, you need to set up the plugin with your preferences:

```lua
require('pd_nvim').setup({
  pd_path = "~/src/fgspd",  -- path to your Perfect Dark source code, or set PD environment variable
  rom_id = "ntsc-final",  -- ROM ID
  -- keymap = {  -- custom key mappings
  --   find_func = "<leader><c-f>F",
  --   find_struct = "<leader><c-f>S",
  --   find_define_typedef = "<leader><c-f>T",
  --   find_func_under_cursor = "<leader><c-f>f",
  --   find_struct_under_cursor = "<leader><c-f>s",
  --   find_define_typedef_under_cursor = "<leader><c-f>t",
  -- }
})
```

Then, you can use the following commands:

- `:PdFindFunc <func_name>`: Find a function by name
- `:PdFindStruct <struct_name>`: Find a struct by name
- `:PdFindDefineTypedef <typedef_name>` Find a typedef by name
- `:PdFindFuncUnderCursor`: Find the function under the cursor
- `:PdFindStructUnderCursor`: Find the struct under the cursor
- `:PdFindDefineTypedefUnderCursor`: Find the typedef under the cursor
- `:PdDebugPerfectDark`: Debug a Perfect Dark project

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
