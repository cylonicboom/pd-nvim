local pd = {}

local telescope = require('telescope')

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
