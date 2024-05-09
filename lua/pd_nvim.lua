local pd = require("pd_nvim.pd")

local pd_nvim = {}

local function with_defaults(options)
  local retval = {
    pd_path = options.pd_path ~= nil or "~/src/fgspd",
    rom_id = options.rom_id ~= nil or "ntsc-final",
    keymap = {
      find_func = "<leader><c-f>F",
      find_struct = "<leader><c-f>S",
      find_define_typedef = "<leader><c-f>T",
      find_func_under_cursor = "<leader><c-f>f",
      find_struct_under_cursor = "<leader><c-f>s",
      find_define_typedef_under_cursor = "<leader><c-f>t",
      debug_perfect_dark = "<leader><c-f>d"
    }
  }
  setmetatable(retval, { __index = options })
  return retval
end

local function debug_perfect_dark()
  local makefile_port = vim.fn.findfile("Makefile.port",
    vim.fn.getcwd() .. ";",
    -1)
  if #makefile_port > 0 then
    -- make a new tab
    vim.cmd("tabnew")
    -- TODO: use paths from config
    -- TODO: move gdb scripts to a better location
    vim.cmd("GdbStart gdb -x ~/src/pd/fgspd/pd.gdb ~/src/pd/fgspd/build/ntsc-final-port/pd.exe")
  else
    vim.cmd("echo 'not in a PD project!'")
  end
end


-- This function is supposed to be called explicitly by users to configure this
-- plugin
function pd_nvim.setup(options)
  -- avoid setting global values outside of this function. Global state
  -- mutations are hard to debug and test, so having them in a single
  -- function/module makes it easier to reason about all possible changes
  options = options or {}
  pd_nvim.options = with_defaults(options)

  -- register commands
  -- cheese asii art:
  --
  -- find under cursor
  vim.api.nvim_create_user_command("PdFindFuncUnderCursor", pd_nvim.find_func_under_cursor, {})
  vim.api.nvim_create_user_command("PdFindStructUnderCursor", pd_nvim.find_struct_under_cursor, {})
  vim.api.nvim_create_user_command("PdFindDefineTypedefUnderCursor", pd_nvim.find_define_typedef_under_cursor, {})

  -- for cmdline searches
  vim.cmd("command! -nargs=1 PdFindFunc lua require('pd_nvim').find_func(<f-args>)")
  vim.cmd("command! -nargs=1 PdFindStruct lua require('pd_nvim').find_struct(<f-args>)")
  vim.cmd("command! -nargs=1 PdFindDefineTypedef lua require('pd_nvim').find_define_typedef(<f-args>)")

  -- disable when leaving fgspd project
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" },
    {
      callback = function()
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
        if project_name ~= "fgspd" then
          local retval = pcall(function()
            vim.api.nvim_buf_del_keymap(0, 'n', pd_nvim.options.keymap.find_func)
            vim.api.nvim_buf_del_keymap(0, 'n', pd_nvim.options.keymap.find_struct)
            vim.api.nvim_buf_del_keymap(0, 'n', pd_nvim.options.keymap.find_define_typedef)
            vim.api.nvim_buf_del_keymap(0, 'n', pd_nvim.options.keymap.find_func_under_cursor)
            vim.api.nvim_buf_del_keymap(0, 'n', pd_nvim.options.keymap.find_struct_under_cursor)
            vim.api.nvim_buf_del_keymap(0, 'n', pd_nvim.options.keymap.find_define_typedef_under_cursor)
            vim.api.nvim_buf_del_keymap(0, 'n', pd_nvim.options.keymap.debug_perfect_dark)
          end)
        end
      end
    }
  )
  -- enable when entering pd project
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    -- TODO: this should be the basename of the project dir in our config
    pattern = "*/fgspd*",
    callback = function()
      vim.keymap.set('n', pd_nvim.options.keymap.find_func, ":PdFindFunc ",
        { buffer = 0, desc = "Find function" })
      vim.keymap.set('n', pd_nvim.options.keymap.find_struct, ":PdFindStruct ",
        { buffer = 0, desc = "Find struct" })
      vim.keymap.set('n', pd_nvim.options.keymap.find_define_typedef, ":PdFindDefineTypedef ",
        { buffer = 0, desc = "Find define/typedef" })
      vim.keymap.set('n', pd_nvim.options.keymap.find_func_under_cursor, function() pd_nvim.find_func_under_cursor() end,
        { buffer = 0, desc = "Find function under cursor" })
      vim.keymap.set('n', pd_nvim.options.keymap.find_struct_under_cursor,
        function() pd_nvim.find_struct_under_cursor() end,
        { buffer = 0, desc = "Find struct under cursor" })
      vim.keymap.set('n', pd_nvim.options.keymap.find_define_typedef_under_cursor,
        function() pd_nvim.find_define_typedef_under_cursor() end,
        { buffer = 0, desc = "Find define/typedef under cursor" })
      vim.keymap.set('n', pd_nvim.options.keymap.debug_perfect_dark, function() debug_perfect_dark() end,
        { buffer = 0, desc = "Debug Perfect Dark" })
    end
  })
end

function pd_nvim.is_configured()
  return pd_nvim.options ~= nil
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
