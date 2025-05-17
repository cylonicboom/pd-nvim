local pd = require("pd_nvim.pd")

local pd_nvim = {}

local vim = _G["vim"]

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
    retval.debug_leader = options.debug_leader or "<leader>" .. "d"
    local keymap = {
        -- project navigation keymaps
        find_func = retval.plugin_leader .. "F",
        find_struct = retval.plugin_leader .. "S",
        find_define_typedef = retval.plugin_leader .. "T",
        find_func_under_cursor = retval.plugin_leader .. "f",
        find_struct_under_cursor = retval.plugin_leader .. "s",
        find_define_typedef_under_cursor = retval.plugin_leader .. "t",

        -- debugger keymaps
        pd_debug_terminate = retval.debug_leader .. "t",
        pd_debug_breakpoint = retval.debug_leader .. "b",
        pd_debug_pause = retval.debug_leader .. "p",
        pd_debug_continue = retval.debug_leader .. "c",
        pd_debug_step_over = retval.debug_leader .. "s",
        pd_debug_step_into = retval.debug_leader .. "i",
        pd_debug_step_out = retval.debug_leader .. "f",
        pd_debug_step_down = retval.debug_leader .. "d",
        pd_debug_step_up = retval.debug_leader .. "u",
        pd_debug_run_to_cursor = retval.debug_leader .. "r",
        pd_debug_toggle = retval.debug_leader .. "o",
    }
    retval.keymap = keymap
    setmetatable(retval, { __index = options })
    return retval
end

local commands = {
    -- navigation
    { name = "PdFindFuncUnderCursor",          func = "find_func_under_cursor",           type = "lua",  desc = "Find function under cursor" },
    { name = "PdFindStructUnderCursor",        func = "find_struct_under_cursor",         type = "lua",  desc = "Find struct under cursor" },
    { name = "PdFindDefineTypedefUnderCursor", func = "find_define_typedef_under_cursor", type = "lua",  desc = "Find Define/Typedef under cursor" },
    { name = "PdFindFunc",                     func = "find_func",                        type = "vim",  desc = "Find function" },
    { name = "PdFindStruct",                   func = "find_struct",                      type = "vim",  desc = "Find struct" },
    { name = "PdFindDefineTypedef",            func = "find_define_typedef",              type = "vim",  desc = "Find FindDefineTypedef" },

    -- debugger
    -- set global to true so we can use them even if we get jumped outside the project
    -- by DAP
    { name = "PdDebugPause",                   func = "pd_debug_pause",                   global = true, type = "lua",                             desc = "[D]ebug [P]ause" },
    { name = "PdDebugContinue",                func = "pd_debug_continue",                global = true, type = "lua",                             desc = "[D]ebug [C]ontinue" },
    { name = "PdDebugStepOver",                func = "pd_debug_step_over",               global = true, type = "lua",                             desc = "[D]ebug [S]tep Over" },
    { name = "PdDebugStepDown",                func = "pd_debug_step_down",               global = true, type = "lua",                             desc = "[D]ebug Step [D]own" },
    { name = "PdDebugStepUp",                  func = "pd_debug_step_up",                 global = true, type = "lua",                             desc = "[D]ebug Step [U]p" },
    { name = "PdDebugStepInto",                func = "pd_debug_step_into",               global = true, type = "lua",                             desc = "[D]ebug Step [I]nto" },
    { name = "PdDebugStepOut",                 func = "pd_debug_step_out",                global = true, type = "lua",                             desc = "[D]ebug [F]inish Function (Step Out)" },
    { name = "PdDebugRunToCursor",             func = "pd_debug_run_to_cursor",           global = true, type = "lua",                             desc = "[D]ebug [R]un to cursor" },
    { name = "PdDebugTerminate",               func = "pd_debug_terminate",               global = true, type = "lua",                             desc = "[D]ebug [T]erminate" },
    { name = "PdDebugBreakpoint",              func = "pd_debug_breakpoint",              global = true, type = "lua",                             desc = "[D]ebug [B]reakpoint" },
    { name = "PdDebugUIToggle",                func = "pd_debug_toggle",                  global = true, type = "lua",                             desc = "[D]ebug UI Toggle" },
}

-- helpful lookup table to find commands by name or function
setmetatable(commands, {
    __index = function(_, key)
        -- then try to lookup by function
        for _, command in ipairs(commands) do
            if command.func == key then
                return command
            end
        end

        -- then try to lookup by name
        for _, command in ipairs(commands) do
            if command.name == key then
                return command
            end
        end
        -- idk you figure it out
        return nil
    end,
})


-- enable / disable command / keybinds respects the global flag
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
        local command = commands[key]
        if command ~= nil and command.global then
            buffer = nil
        end
        if keymapOptions[key] then
            vim.keymap.set('n', value, keymapOptions[key].cmd, { buffer = buffer, desc = keymapOptions[key].desc })
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
        local command = commands[command.name]
        if command ~= nil and command.global then
            goto continue
        end
        pcall(function()
            vim.cmd("delcommand " .. command.name)
        end)
        ::continue::
    end
end

function pd_nvim.disable_keybinds()
    for key, _ in pairs(pd_nvim.options.keymap) do
        local command = commands[key]
        if command ~= nil and command.global then
            goto continue
        end
        pcall(function()
            vim.api.nvim_buf_del_keymap(0, 'n', key)
        end)
        ::continue::
    end
end

function pd_nvim.deactivate()
    pd_nvim.disable_commands()
    pd_nvim.disable_keybinds()
    -- require 'which-key'.remove_group("Perfect Dark")
    -- we want the debug to enabled if we seem to have left the project
    -- in case dap watch jumped us outside the project
end

function pd_nvim.activate()
    pd_nvim.enable_commands()
    pd_nvim.enable_keybinds()
    require 'which-key'.add {
        { pd_nvim.options.plugin_leader, icon = "🧀", group = "Perfect Dark" },
        { pd_nvim.options.debug_leader, icon = "🔭🦝", group = "Debug Perfect Dark" }, }
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function pd_nvim.setup(options)
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

    pd.project.setup()
    pd.debug.setup(pd_nvim.options)

    -- setup syntax automatically for modconfig files
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "modconfig.txt",
        callback = function()
            vim.bo.filetype = "modconfig"
        end,
    })


    vim.api.nvim_create_user_command('Dprint', function(opts)
        local result = {}
        for _, word in ipairs(opts.fargs) do
            for char in word:gmatch('.') do
                table.insert(result, string.format("'%s'", char))
            end
            table.insert(result, "' '") -- Add a space between words
        end
        result[#result] = nil           -- Remove the trailing space
        table.insert(result, "'\\n'")
        table.insert(result, "0")
        local dprint_statement = "dprint " .. table.concat(result, ",") .. ","
        vim.api.nvim_put({ dprint_statement }, 'l', true, true)
    end, { nargs = '+', complete = nil })
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

function pd_nvim.pd_debug_terminate()
    if not pd_nvim.is_configured() then
        return
    end

    local pd_debug_terminate = pd.pd_debug_terminate()
end

function pd_nvim.pd_debug_breakpoint()
    if not pd_nvim.is_configured() then
        return
    end

    local pd_debug_breakpoint = pd.pd_debug_breakpoint()
end

function pd_nvim.pd_debug_pause()
    if not pd_nvim.is_configured() then
        return
    end

    local pd_debug_pause = pd.pd_debug_pause()
end

function pd_nvim.pd_debug_continue()
    if not pd_nvim.is_configured() then
        return
    end

    local pd_debug_continue = pd.pd_debug_continue()
end

function pd_nvim.pd_debug_step_over()
    if not pd_nvim.is_configured() then
        return
    end

    local pd_debug_step_over = pd.pd_debug_step_over()
end

function pd_nvim.pd_debug_step_down()
    if not pd_nvim.is_configured() then
        return
    end

    local pd_debug_step_down = pd.pd_debug_down()
end

function pd_nvim.pd_debug_step_up()
    if not pd_nvim.is_configured() then
        return
    end

    local pd_debug_step_up = pd.pd_debug_up()
end

function pd_nvim.pd_debug_run_to_cursor()
    if not pd_nvim.is_configured() then
        return
    end

    local pd_debug_run_to_cursor = pd.pd_debug_run_to_cursor()
end

setmetatable(pd_nvim, {
    __index = function(_, key)
        if pd[key] then
            return pd[key]
        else
            return nil
        end
    end,
})

return pd_nvim
