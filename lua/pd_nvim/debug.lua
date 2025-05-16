local debug = {}

local vim = _G['vim']

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

return debug
