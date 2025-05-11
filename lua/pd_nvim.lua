local pd = require("pd_nvim.pd")

local pd_nvim = {}

local function with_defaults(options)
  local retval = {
    pd = options.pd or { {
      pd_path = options.pd_path or os.getenv("PD"),
      rom_id = options.rom_id or "ntsc-final"
    } },
    pd_path = options.pd_path or os.getenv("PD"),
    rom_id = options.rom_id or "ntsc-final",
    plugin_leader = options.plugin_leader or "<leader><c-f>",
  }
  local keymap = {
    find_func = retval.plugin_leader .. "F",
    find_struct = retval.plugin_leader .. "S",
    find_define_typedef = retval.plugin_leader .. "T",
    find_func_under_cursor = retval.plugin_leader .. "f",
    find_struct_under_cursor = retval.plugin_leader .. "s",
    find_define_typedef_under_cursor = retval.plugin_leader .. "t",
    -- debug_perfect_dark = "<leader><c-f>d"
  }
  retval.keymap = keymap
  setmetatable(retval, { __index = options })
  return retval
end

local commands = {
  { name = "PdFindFuncUnderCursor",          func = "find_func_under_cursor",           type = "lua", desc = "Find function under cursor" },
  { name = "PdFindStructUnderCursor",        func = "find_struct_under_cursor",         type = "lua", desc = "Find struct under cursor" },
  { name = "PdFindDefineTypedefUnderCursor", func = "find_define_typedef_under_cursor", type = "lua", desc = "Find Define/Typedef under cursor" },
  { name = "PdFindFunc",                     func = "find_func",                        type = "vim", desc = "Find function" },
  { name = "PdFindStruct",                   func = "find_struct",                      type = "vim", desc = "Find struct" },
  { name = "PdFindDefineTypedef",            func = "find_define_typedef",              type = "vim", desc = "Find FindDefineTypedef" },
  -- { name = "PdDebugPerfectDark",             func = "debug_perfect_dark",               type = "lua", desc = "Debug Perfect Dark" }
}

function pd_nvim.setup_telescope_live_grep_args()
  local telescope = require("telescope")
  local lga_actions = require("telescope-live-grep-args.actions")
  require("telescope").load_extension("live_grep_args")
  telescope.setup {
    extensions = {
      live_grep_args = {
        auto_quoting = false, -- enable/disable auto-quoting
      }
    }
  }
end

function pd_nvim.enable_keybinds()
  local keymapOptions = {}

  for _, command in ipairs(commands) do
    if command.type == "lua" then
      keymapOptions[command.func] = {
        cmd = function() pd_nvim[command.func]() end,
        desc = command.desc
      }
    elseif command.type == "vim" then
      keymapOptions[command.func] = {
        cmd = ":" .. command.name .. " ",
        desc = command.desc
      }
    end
  end

  for key, value in pairs(pd_nvim.options.keymap) do
    if keymapOptions[key] then
      vim.keymap.set('n', value, keymapOptions[key].cmd, { buffer = 0, desc = keymapOptions[key].desc })
    end
  end
end

function pd_nvim.enable_commands()
  for _, command in ipairs(commands) do
    if command.type == "lua" then
      vim.api.nvim_create_user_command(command.name, pd_nvim[command.func], {})
    elseif command.type == "vim" then
      vim.cmd(string.format("command! -nargs=1 %s lua require('pd_nvim').%s(<f-args>)", command.name, command.func))
    end
  end
end

function pd_nvim.disable_commands()
  for _, command in ipairs(commands) do
    pcall(function() vim.cmd("delcommand " .. command.name) end)
  end
end

function pd_nvim.disable_keybinds()
  for key, _ in pairs(pd_nvim.options.keymap) do
    pcall(function()
      vim.api.nvim_buf_del_keymap(0, 'n', key)
    end)
  end
end

function pd_nvim.deactivate()
  pd_nvim.disable_commands()
  pd_nvim.disable_keybinds()
end

function pd_nvim.activate()
  pd_nvim.enable_commands()
  pd_nvim.enable_keybinds()
  require 'which-key'.add {
    { pd_nvim.options.plugin_leader, icon = "🧀", group = "Perfect Dark" } }
end

pd_nvim.getpdpath = function()
  local arm64_path = "build/pd.arm64"
  local x86_64_path = "build/pd.x86_64"
  if vim.fn.filereadable(arm64_path) == 1 then
    return arm64_path
  elseif vim.fn.filereadable(x86_64_path) == 1 then
    return x86_64_path
  else
    return nil
  end
end

pd_nvim.pd_setup_lldb = function(opts)
  opts = opts or {}

  opts.cfg = opts.cfg or {
    configurations = {
      -- C lang configurations
      c = {
        -- sensible default for the pc port
        {
          name = "Debug Perfect Dark (PC Port, log to stdout/stderr)",
          type = "lldb",
          request = "launch",
          cwd = "${workspaceFolder}",
          program = pd.getpdpath,
        },
      },
    },
  }
  require("dap-lldb").setup(opts.cfg)

  -- HACK: maybe I should use verylazy
  local dapui = nil

  local ensure_dapui = function()
    if dapui == nil then
      dapui = require 'dapui'
      dapui.setup()
    end
  end

  local pd_setup_debugger_keybinds = function()
    local dap = require 'dap'

    local known_pd_exes = { 'pd.x86_64', 'pd.arm64', 'pd.exe' }


    vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end,
      { desc = '[D]ebug [B]reakpoint' })
    vim.keymap.set('n', '<leader>do', function()
        ensure_dapui()
        if dapui then dapui.toggle() end
      end,
      { desc = '[D]ap UI' })
    vim.keymap.set('n', '<leader>dc', function()
        dap.continue()
      end,
      { desc = '[D]ebug Continue' })
    vim.keymap.set('n', '<leader>dT', function()
      local function sigterm(process_name)
        pcall(function()
          vim.fn.system('killall -9 ' .. process_name)
        end)
        pcall(function() vim.fn.system('pkill -SIGTERM -i ' .. process_name) end)
      end
      pcall(function()
        dap.terminate()
      end)
      for _, exe in ipairs(known_pd_exes) do
        sigterm(exe)
      end
    end, { desc = '[D]ebug [T]erminate' })
    -- debug
    vim.keymap.set('n', '<leader>dp', function()
      local function sigint(process_name)
        pcall(function()
          vim.fn.system('killall -s SIGINT ' .. process_name)
        end)
        pcall(function() vim.fn.system('pkill -SIGINT -i ' .. process_name) end)
      end

      for _, exe in ipairs(known_pd_exes) do
        sigint(exe)
      end
    end, { desc = '[D]ebug [P]ause' })
    -- debug step over
    vim.keymap.set('n', '<leader>ds', function() dap.step_over() end,
      { desc = '[D]ebug [S]tep Over' })
    -- debug step into
    vim.keymap.set('n', '<leader>di', function() dap.step_into() end,
      { desc = '[D]ebug [I]nto' })
    -- debug step out (gdb finish)
    vim.keymap.set('n', '<leader>df', function() dap.step_out() end,
      { desc = '[D]ebug [F]out' })
    -- debug up
    vim.keymap.set('n', '<leader>du', function() dap.up() end,
      { desc = '[D]ebug [U]p' })
    -- debug down
    vim.keymap.set('n', '<leader>dd', function() dap.down() end,
      { desc = '[D]ebug [D]own' })
    -- debug run to cursor
    vim.keymap.set('n', '<leader>dr', function() dap.run_to_cursor() end,
      { desc = '[D]ebug [R]un to cursor' })
    require 'which-key'.add {
      { "<leader>d", icon = "🔭🦝", group = "debug" },
    }
  end
  pd_setup_debugger_keybinds()
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function pd_nvim.setup(options)
  -- avoid setting global values outside of this function. Global state
  -- mutations are hard to debug and test, so having them in a single
  -- function/module makes it easier to reason about all possible changes
  options = options or {}
  pd_nvim.options = with_defaults(options)
  for _, pd_config in ipairs(pd_nvim.options.pd) do
    local targetleaf = vim.fn.fnamemodify(pd_config.pd_path, ":t")
    local targetsleaves = {}
    for _, pd_config in ipairs(pd_nvim.options.pd) do
      table.insert(targetsleaves, vim.fn.fnamemodify(pd_config.pd_path, ":t"))
    end
    -- enable when entering pd project
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      -- TODO: this should be the basename of the project dir in our config
      pattern = "*/" .. targetleaf .. "*",
      callback = pd_nvim.activate
    })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" },
      {
        callback = function()
          local leaf = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
          if not vim.tbl_contains(targetsleaves, leaf) then
            pd_nvim.deactivate()
          end
        end
      }
    )
  end

  pd_nvim.setup_telescope_live_grep_args()


  local modconfig_syntax = function()
    vim.bo.filetype = "modconfig"
    -- Define syntax matches
    vim.cmd([[
    syntax keyword ModconfigStageKeyword stage
    syntax keyword ModconfigStageProperty bgfile tilesfile padsfile setupfile alarm
    syntax keyword ModconfigMusicKeyword music primarytrack xtrack
    syntax keyword ModconfigWeatherKeyword weather exclude_rooms clear
    syntax match ModconfigComment /^#.*$/
    syntax match ModconfigHexValue /0x[0-9a-fA-F]\+/
    syntax region ModconfigString start=/"/ end=/"/
    ]])
    -- Syntax highlighting for modconfig.txt files
    vim.api.nvim_set_hl(0, "ModconfigStageKeyword", { link = "Keyword" })
    vim.api.nvim_set_hl(0, "ModconfigStageProperty", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "ModconfigMusicKeyword", { link = "Keyword" })
    vim.api.nvim_set_hl(0, "ModconfigWeatherKeyword", { link = "Keyword" })
    vim.api.nvim_set_hl(0, "ModconfigHexValue", { link = "Tag" })
    vim.api.nvim_set_hl(0, "ModconfigString", { link = "String" })
    vim.api.nvim_set_hl(0, "ModconfigComment", { link = "Comment" })
  end
  -- Associate modconfig.txt with the modconfig filetype
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "modconfig.txt",
    callback = modconfig_syntax,
  })

  -- setup lldb for perfect dark
  pd_nvim.pd_setup_lldb(pd_nvim.options)

  vim.api.nvim_create_user_command('Dprint', function(opts)
    local result = {}
    for _, word in ipairs(opts.fargs) do
      for char in word:gmatch('.') do
        table.insert(result, string.format("'%s'", char))
      end
      table.insert(result, "' '") -- Add a space between words
    end
    result[#result] = nil         -- Remove the trailing space
    table.insert(result, "'\\n'")
    table.insert(result, "0")
    local dprint_statement = "dprint " .. table.concat(result, ",") .. ","
    vim.api.nvim_put({ dprint_statement }, 'l', true, true)
  end, { nargs = '+', complete = nil })
end

function pd_nvim.is_configured()
  return pd_nvim.options ~= nil
end

function pd_nvim.debug_perfect_dark()
  if not pd_nvim.is_configured() then
    return
  end
  pd.debug_perfect_dark(pd_nvim.options.rom_id)
end

function pd_nvim.find_func(func_name)
  if not pd_nvim.is_configured() then
    return
  end

  local find_func = pd.find_func(func_name)
end

function pd_nvim.find_func_under_cursor()
  if not pd_nvim.is_configured() then
    return
  end

  local find_func_under_cursor = pd.find_func_under_cursor()
end

function pd_nvim.find_struct(struct_name)
  if not pd_nvim.is_configured() then
    return
  end

  local find_struct = pd.find_struct(struct_name)
end

function pd_nvim.find_define_typedef(define_typedef_name)
  if not pd_nvim.is_configured() then
    return
  end

  local find_define_typedef = pd.find_define_typedef(define_typedef_name)
end

function pd_nvim.find_struct_under_cursor()
  if not pd_nvim.is_configured() then
    return
  end

  local find_struct = pd.find_struct_under_cursor()
end

function pd_nvim.find_define_typedef_under_cursor()
  if not pd_nvim.is_configured() then
    return
  end

  local find_define_typedef = pd.find_define_typedef_under_cursor()
end

return pd_nvim
