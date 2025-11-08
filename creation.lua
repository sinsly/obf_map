--[[

    Author: sinsly
    License: MIT
    Github: https://github.com/sinsly

--]]

-- how to loadstring source / call obfuscation visit https://github.com/sinsly/m40fuscation/blob/main/example.lua
-- build an obfuscated string + reverse mapping 
-- prints them, and copies the same text to the clipboard
-- obf_string / rev_mapping have be marked nil if you want to create a script
-- replace src's [[ ]] with your script to create your string

_G.obf_string = nil
_G.rev_mapping = nil

_G.obf_level = 1

-- level 1 or 2 (just security values) 
-- doesn't matter unless creating a script

local src = [[ 
print('hi this test worked 24') 
]]

-- src is only accessed if string and mapping arent found

local env_fn = loadstring(game:HttpGet("https://raw.githubusercontent.com/sinsly/m40fuscation/main/env.lua"))

-- env and block logic only matter when creating a script
local block, obf_string, rev_mapping = env_fn(src, obf_level)

local connect_fn = loadstring(game:HttpGet("https://raw.githubusercontent.com/sinsly/m40fuscation/main/connect.lua"))
local dcm = connect_fn()
