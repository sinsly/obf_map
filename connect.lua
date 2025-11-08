-- detect whether obf_string and rev_mapping look valid
local function has_valid_obf()
    if type(obf_string) ~= "string" or #obf_string == 0 then return false end
    if type(rev_mapping) ~= "table" then return false end
    if (#obf_string % 3) ~= 0 then return false end
    return true
end

-- build obf_string + rev_mapping from src
local function generate_from_src(s)
    local seen = {}
    local chars = {}
    for i = 1, #s do
        local c = s:sub(i,i)
        if not seen[c] then
            seen[c] = true
            table.insert(chars, c)
        end
    end

    local mapping = {}
    local rev = {}
    for i, ch in ipairs(chars) do
        local token = string.format("~%02X", i)
        mapping[ch] = token
        rev[token] = ch
    end

    local obf_parts = {}
    for i = 1, #s do
        local c = s:sub(i,i)
        obf_parts[#obf_parts+1] = mapping[c]
    end
    local obf = table.concat(obf_parts)

    return obf, rev
end

local function try_setclipboard(text)
    pcall(function()
        if type(setclipboard) == "function" then
            setclipboard(text)
        elseif type(syn) == "table" and type(syn.set_clipboard) == "function" then
            syn.set_clipboard(text)
        end
    end)
end

if not has_valid_obf() then
    local obf, rev = generate_from_src(src)
    obf_string = obf
    rev_mapping = rev
    try_setclipboard(obf)
end

local function decompile_to_string()
    if type(obf_string) ~= "string" or type(rev_mapping) ~= "table" then
        return nil
    end

    local parts = {}
    local i = 1
    local len = #obf_string
    while i <= len do
        local token = obf_string:sub(i, i+2)
        local ch = rev_mapping[token]
        if ch == nil then
            table.insert(parts, ("<UNKNOWN:%s>"):format(token))
        else
            parts[#parts+1] = ch
        end
        i = i + 3
    end

    return table.concat(parts)
end

local function run_decompiled()
    local reconstructed = decompile_to_string()
    if not reconstructed then return nil end

    local loader = load or loadstring
    if not loader then return nil end

    local chunk, compile_err = loader(reconstructed, "decompiled_chunk")
    if not chunk then return nil end

    pcall(chunk)
end

run_decompiled()
