local pd = {}

local telescope = require('telescope')


function pd.debug_perfect_dark(romid)
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
