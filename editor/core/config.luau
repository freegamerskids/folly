local loaded_config = {
  user = {
    cursor = {
      -- BLOCK, LINE
      style = "LINE"
    },
    tab_spacing = 4,
  },
} 

-- replace loaded_config with the file read from disk, 
-- if not found, create new file with the config above

local config = {}
local metatable = {
  __index = function (t,k)
    return loaded_config[k]
  end,

  __newindex = function (t,k,v)
    loaded_config[k] = v
  end
}
setmetatable(config, metatable)

return config