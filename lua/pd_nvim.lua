local pd = require("pd_nvim.pd")

local pd_nvim = {}

local function with_defaults(options)
  return {
    pd_path = options.pd_path ~= nil or "~/src/fgspd",
    rom_id = options.rom_id ~= nil or "ntsc-final"
  }
end

local function debug_perfect_dark()
  local makefile_port = vim.fn.findfile("Makefile.port",
    vim.fn.getcwd() .. ";",
    -1)
  if #makefile_port > 0 then
    -- make a new tab
    vim.cmd("tabnew")
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

  -- print(pd_nvim.options.rom_id)
  -- print(pd_nvim.options.pd_path)

  local perfect_dark_mappings = {
    P = {
      name = "Perfect Dark",
      d = { function() debug_perfect_dark() end, "Debug Perfect Dark" },
    }
  }

  local non_pd_mappings = {
    P = {
      name = "No PD Project",
    }
  }

  -- do here any startup your plugin needs, like creating commands and
  -- mappings that depend on values passed in options
  vim.api.nvim_create_user_command("PdFindFunc", pd_nvim.find_func, {})
  vim.api.nvim_create_user_command("PdFindStruct", pd_nvim.find_struct, {})

  -- disable when leaving fgspd project
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" },
    {
      callback = function()
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
        if project_name ~= "fgspd" then
          pcall(function()
            local mymap = non_pd_mappings
            require 'which-key'.register(
              mymap,
              which_key_prefix)
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
      pcall(function()
        require 'which-key'.register(
          perfect_dark_mappings,
          which_key_prefix
        )
      end)
    end
  })
end

function pd_nvim.is_configured()
  return pd_nvim.options ~= nil
end

-- This is a function that will be used outside this plugin code.
-- Think of it as a public API
function pd_nvim.make_docker()
  if not pd_nvim.is_configured() then
    return
  end

  -- try to keep all the heavy logic on pure functions/modules that do not
  -- depend on Neovim APIs. This makes them easy to test
  local make_docker = pd.make_docker()
end

function pd_nvim.make_perfect_dark(romid, path)
  if not pd_nvim.is_configured() then
    return
  end

  romid, path = pd_nvim.options.rom_id, pd_nvim.options.pd_path

  -- try to keep all the heavy logic on pure functions/modules that do not
  -- depend on Neovim APIs. This makes them easy to test
  local make_pd = pd.make_perfect_dark(romid, path)
end

function pd_nvim.find_func()
  if not pd_nvim.is_configured() then
    return
  end

  local find_func = pd.find_func()
end

function pd_nvim.find_struct()
  if not pd_nvim.is_configured() then
    return
  end

  local find_struct = pd.find_struct()
end

return pd_nvim
