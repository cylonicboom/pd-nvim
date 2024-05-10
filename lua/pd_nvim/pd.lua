local pd = {}

local telescope = require('telescope')


function pd.debug_perfect_dark()
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

function pd.find_func(word)
   require("telescope").extensions.live_grep_args.live_grep_args({
      default_text = '^\\w+\\W.*' ..
          word .. '\\(.*\\)'
   })
end

function pd.find_func_under_cursor()
   pd.find_func(vim.fn.expand '<cword>')
end

function pd.find_struct(word)
   require("telescope").extensions.live_grep_args.live_grep_args({
      default_text = '^struct\\W' ..
          word .. '\\W\\{'
   })
end

function pd.find_struct_under_cursor()
   pd.find_struct(vim.fn.expand '<cword>')
end

function pd.find_define_typedef(word)
   require("telescope").extensions.live_grep_args.live_grep_args({
      default_text = '^(typedef\\W\\w+\\W|#define\\W)' ..
          word .. '\\W'
   })
end

function pd.find_define_typedef_under_cursor()
   pd.find_define_typedef(vim.fn.expand '<cword>')
end

return pd
