local pd = {}

-- function pd.greeting(name)
--    return "Hello " .. name
-- end

local telescope = require('telescope')


function pd.find_func()
   require("telescope").extensions.live_grep_args.live_grep_args({
      default_text = '^\\w+\\W' ..
          vim.fn.expand '<cword>' .. '\\(.*\\)'
   })
end

function pd.find_struct()
   require("telescope").extensions.live_grep_args.live_grep_args({
      default_text = '^struct\\W' ..
          vim.fn.expand '<cword>' .. '\\W\\{$'
   })
end

return pd
