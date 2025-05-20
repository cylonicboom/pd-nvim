local debug = {}

local vim = _G['vim']

local dap = require 'dap'
local sign = vim.fn.sign_define

vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#FFB3BA" })
vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#FFFFBA" })
vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#BAE1FF" })
vim.api.nvim_set_hl(0, "DapStopped", { fg = "#BFFCC6", bold = true })

sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
sign('DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })

debug.getpdpath = function()
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

function debug.setup(opts)
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
                    program = debug.getpdpath,
                },
            },
        },
    }
    require("dap-lldb").setup(opts.cfg)
end

-- HACK: maybe I should use verylazy
local dapui = nil

local ensure_dapui = function()
    if dapui == nil then
        dapui = require 'dapui'
        dapui.setup()
    end
end

local dap = require('dap')
local vim = _G['vim']

-- TODO: eventually this should be moved into a sperate file or something?
local known_pd_exes = { 'pd.x86_64', 'pd.arm64', 'pd.exe' }

-- legacy GDB-based debugger which is not used anymore
-- since we moved to cmake
function debug._gdb_debug_perfect_dark(romid)
    if not romid then
        vim.cmd("echo 'romid is not set!'")
        return
    end
    local makefile_port = vim.fn.findfile("Makefile.port",
        vim.fn.getcwd() .. ";",
        -1)
    if #makefile_port > 0 then
        -- make a new tab
        vim.cmd("tabnew")
        local function split(s, delimiter)
            local result = {}
            for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
                table.insert(result, match)
            end
            return result
        end

        local rtp = vim.api.nvim_get_option('rtp')
        local rtp_paths = split(rtp, ',')

        local pd_nvim_path = ""
        for _, path in ipairs(rtp_paths) do
            print(path)
            if string.match(path, "/pd%-nvim") then
                pd_nvim_path = path
                break
            end
        end
        if pd_nvim_path == "" then
            vim.cmd("echo 'pd-nvim not found in rtp'")
            return
        end
        local gdb_script = pd_nvim_path .. "/lua/pd_nvim/pd.gdb"

        vim.cmd("echo 'Starting PD debug session with gdb script" .. gdb_script .. ".'")
        vim.cmd("GdbStart gdb -x " .. gdb_script .. " ~/src/pd/fgspd/build/" .. romid .. "-port/pd.exe")
    else
        vim.cmd("echo 'not in a PD project!'")
    end
end

function debug.pd_debug_toggle()
    ensure_dapui()
    dapui.toggle()
end

function debug.pd_debug_terminate()
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
end

function debug.pd_debug_pause()
    local function sigint(process_name)
        pcall(function()
            vim.fn.system('killall -s SIGINT ' .. process_name)
        end)
        pcall(function() vim.fn.system('pkill -SIGINT -i ' .. process_name) end)
    end

    for _, exe in ipairs(known_pd_exes) do
        sigint(exe)
    end
end

function debug.pd_debug_continue()
    dap.continue()
end

function debug.pd_debug_step_into()
    dap.step_into()
end

function debug.pd_debug_step_over()
    dap.step_over()
end

function debug.pd_debug_step_out()
    dap.step_out()
end

function debug.pd_debug_down()
    dap.down()
end

function debug.pd_debug_up()
    dap.up()
end

function debug.pd_debug_run_to_cursor()
    dap.run_to_cursor()
end

function debug.pd_debug_watch_under_cursor(opts)
    ensure_dapui()
    opts            = opts or {}
    local mode      = vim.fn.mode()
    local word      = opts.args
    -- we might be in command mode, so we need to check
    -- attempt to get the range
    -- if it fails,assume we're in normal mode
    -- and get the word under the cursor

    local start_pos = nil
    local end_pos   = nil
    -- unconditionally try to get the start and end positions
    -- in case we have something selected but we're not in visual mode
    pcall(function()
        start_pos = vim.fn.getpos("'<")
        end_pos = vim.fn.getpos("'>")
    end)

    local function shallow_equal(t1, t2)
        for k, v in pairs(t1) do
            if t2[k] ~= v then return false end
        end
        for k, v in pairs(t2) do
            if t1[k] ~= v then return false end
        end
        return true
    end

    if start_pos == nil or end_pos == nil then
        -- if we can't get the start and end positions, assume we're in normal mode
        -- and get the word under the cursor
        mode = "n"
    else
        if shallow_equal(start_pos, end_pos) then
            -- if the start and end positions are the same, fallback to normal mode
            mode = "n"
        else
            mode = "v"
        end
    end

    if mode == "v" or mode == "V" or mode == "\22" or mode == "c" then
        -- Visual mode: get selected range
        local lines = vim.fn.getline(start_pos[2], end_pos[2])
        if #lines == 0 then
            return
        end
        if #lines == 1 then
            word = string.sub(lines[1], start_pos[3], end_pos[3])
        else
            lines[1] = string.sub(lines[1], start_pos[3])
            lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
            word = table.concat(lines, "\n"):gsub("^%s*(.-)%s*$", "%1")
        end
    else
        -- Normal mode: get word under cursor
        -- or argument from command line
        word = word or vim.fn.expand("<cword>")
    end
    if word and word ~= "" then
        dapui.elements.watches.add(word)
    end

    --reset the start and end position
    pcall(function() vim.fn.setpos("'<", { 0, 0, 0, 0 }) end)
    pcall(function() vim.fn.setpos("'>", { 0, 0, 0, 0 }) end)
    -- reset the word
    pcall(function() vim.fn.setreg('<cword>', word) end)
end

local function find_project_root()
    local path = vim.fn.expand('%:p:h')
    while path and path ~= "/" do
        if vim.fn.isdirectory(path .. "/.git") == 1 then
            return path
        end
        local parent = vim.fn.fnamemodify(path, ":h")
        if parent == path then break end
        path = parent
    end
    return vim.fn.getcwd()
end

function debug.pd_save_dap_watches()
    ensure_dapui()
    local watches = dapui.elements.watches.get()
    local json = vim.fn.json_encode(watches)
    local root = find_project_root()
    local path = root .. "/dap-watches.json"
    local file = io.open(path, "w")
    if file then
        file:write(json)
        file:close()
        print("Watches saved to " .. path)
    else
        print("Failed to write dap-watches.json")
    end
end

function debug.pd_restore_dap_watches()
    ensure_dapui()
    local watches_file = find_project_root() .. "/dap-watches.json"
    local file = io.open(watches_file, "r")
    if not file then
        vim.notify("dap-watches.json not found", vim.log.levels.ERROR)
        return
    end
    local content = file:read("*a")
    file:close()
    local watches = vim.json.decode(content)
    for _, watch in ipairs(watches) do
        print("Restoring watch: " .. watch.expression)
        dapui.elements.watches.add(watch.expression)
    end
end

return debug
