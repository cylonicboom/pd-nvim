-- top-level pd module
local pd = {}
-- subcomponents of pd module
pd.project = require('pd_nvim.project')
pd.debug = require('pd_nvim.debug')

-- use functions from debug or project modules
setmetatable(pd, {
    __index = function(_, key)
        if pd.debug[key] then
            return pd.debug[key]
        elseif pd.project[key] then
            return pd.project[key]
        else
            return nil
        end
    end,
})

return pd
