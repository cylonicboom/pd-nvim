-- setup depednencies
local telescope = require('telescope')
local vim = _G['vim']
local project = {}

function project.setup()
    -- local lga_actions = require("telescope-live-grep-args.actions")
    telescope.load_extension("live_grep_args")
    telescope.setup {
        extensions = {
            live_grep_args = {
                auto_quoting = false, -- enable/disable auto-quoting
            }
        }
    }
end

-- project navigation functions
function project.find_func(word)
    telescope.extensions.live_grep_args.live_grep_args({
        default_text = '^\\w+\\W.*' ..
            word .. '\\(.*\\)'
    })
end

function project.find_func_under_cursor()
    project.find_func(vim.fn.expand '<cword>')
end

function project.find_struct(word)
    telescope.extensions.live_grep_args.live_grep_args({
        default_text = '^struct\\W' ..
            word .. '\\W\\{'
    })
end

function project.find_struct_under_cursor()
    project.find_struct(vim.fn.expand '<cword>')
end

function project.find_define_typedef(word)
    telescope.extensions.live_grep_args.live_grep_args({
        default_text = '^(typedef\\W\\w+\\W|#define\\W)' ..
            word .. '\\W'
    })
end

function project.find_define_typedef_under_cursor()
    project.find_define_typedef(vim.fn.expand '<cword>')
end

return project
