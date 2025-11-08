--[[ 
    Author: sinsly
    License: MIT
    Github: https://github.com/sinsly
--]]

-- safe helpers for building an obfuscated string + reverse mapping
local M = {}

-- detect whether obf_string and rev_mapping look valid
function M.has_valid_obf(obf_string, rev_mapping)
    if type(obf_string) ~= "string" then
        return false
    end
    if obf_string == "" then
        return false
    end
    if type(rev_mapping) ~= "table" then
        return false
    end

    -- quick sanity: tokens are "~XX" repeated so string length should be a multiple of 3
    -- (guarded with explicit string type check above so '#' is safe)
    if (#obf_string % 3) ~= 0 then
        return false
    end

    -- basic consistency check: every token (~NN) should exist in rev_mapping
    for i = 1, #obf_string, 3 do
        local token = obf_string:sub(i, i+2)
        if type(rev_mapping[token]) ~= "string" then
            -- token not mapped back, not valid
            return false
        end
    end

    return true
end

-- build obf_string + rev_mapping from src (returns obf, rev_table)
function M.generate_from_src(src)
    if type(src) ~= "string" or #src == 0 then
        error("generate_from_src: src must be a non-empty string")
    end

    local seen = {}
    local chars = {}
    for i = 1, #src do
        local c = src:sub(i,i)
        if not seen[c] then
            seen[c] = true
            table.insert(chars, c)
        end
    end

    -- build mapping and reverse mapping
    local mapping = {}
    local rev = {}
    for i, ch in ipairs(chars) do
        -- token format ~01, ~02, ..., up to ~FF if needed
        local token = string.format("~%02X", i)
        mapping[ch] = token
        rev[token] = ch
    end

    -- encode the whole src
    local parts = {}
    for i = 1, #src do
        local c = src:sub(i,i)
        parts[#parts+1] = mapping[c]
    end
    local obf = table.concat(parts)

    return obf, rev
end

-- build a pasteable Lua block containing obf_string + rev_mapping
function M.build_pasteable_block(obf, rev)
    -- defensive checks
    if type(obf) ~= "string" then
        error("build_pasteable_block: obf must be a string")
    end
    if type(rev) ~= "table" then
        error("build_pasteable_block: rev must be a table")
    end

    local out_lines = {}
    table.insert(out_lines, "--[[")
    table.insert(out_lines, "    Author: sinsly")
    table.insert(out_lines, "    License: MIT")
    table.insert(out_lines, "    Github: https://github.com/sinsly")
    table.insert(out_lines, "--]]")
    table.insert(out_lines, 'obf_string = ' .. string.format("%q", obf))
    table.insert(out_lines, "rev_mapping = {")

    -- sort tokens for deterministic output
    local tokens = {}
    for token in pairs(rev) do table.insert(tokens, token) end
    table.sort(tokens)
    for _, token in ipairs(tokens) do
        local orig = rev[token]
        -- %q safely quotes string values (handles newlines, backslashes)
        table.insert(out_lines, string.format("  [%q] = %s,", token, string.format("%q", orig)))
    end

    table.insert(out_lines, "}")
    return table.concat(out_lines, "\n")
end

-- attempt to copy text to clipboard in common exploit environments
function M.try_setclipboard(text)
    local ok, err = pcall(function()
        if type(setclipboard) == "function" then
            setclipboard(text)
            return true
        end
        if type(syn) == "table" and type(syn.set_clipboard) == "function" then
            syn.set_clipboard(text)
            return true
        end
        error("setclipboard not available in this environment")
    end)
    return ok, err
end

-- convenience: run the full process given a src and optional pre-existing obf/rev
-- returns true + pasteable_block on success, false + err on failure
function M.run(src, existing_obf, existing_rev)
    -- if existing mapping is valid, use it; otherwise generate from src
    if M.has_valid_obf(existing_obf, existing_rev) then
        return true, M.build_pasteable_block(existing_obf, existing_rev)
    end

    -- generate from src (guarded)
    local ok, obf, rev = pcall(function() return M.generate_from_src(src) end)
    if not ok then
        return false, tostring(obf)
    end

    local paste_block = M.build_pasteable_block(obf, rev)

    -- attempt clipboard (ignore error, return result to caller)
    local ok_clip, clip_err = M.try_setclipboard(paste_block)
    if ok_clip then
        -- successful copy
    end

    return true, paste_block
end

-- expose module table as result of the loadstring(...)() call
return M
