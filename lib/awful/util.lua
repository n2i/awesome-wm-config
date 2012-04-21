---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local os = os
local io = io
local assert = assert
local loadstring = loadstring
local loadfile = loadfile
local debug = debug
local pairs = pairs
local ipairs = ipairs
local type = type
local rtable = table
local pairs = pairs
local string = string
local capi =
{
    awesome = awesome,
    mouse = mouse
}

--- Utility module for awful
module("awful.util")

table = {}

shell = os.getenv("SHELL") or "/bin/sh"

function deprecate(see)
    io.stderr:write("W: awful: function is deprecated")
    if see then
        io.stderr:write(", see " .. see)
    end
    io.stderr:write("\n")
    io.stderr:write(debug.traceback())
end

--- Strip alpha part of color.
-- @param color The color.
-- @return The color without alpha channel.
function color_strip_alpha(color)
    if color:len() == 9 then
        color = color:sub(1, 7)
    end
    return color
end

--- Make i cycle.
-- @param t A length.
-- @param i An absolute index to fit into #t.
-- @return The object at new index.
function cycle(t, i)
    while i > t do i = i - t end
    while i < 1 do i = i + t end
    return i
end

--- Create a directory
-- @param dir The directory.
-- @return mkdir return code
function mkdir(dir)
    return os.execute("mkdir -p " .. dir)
end

--- Spawn a program.
-- @param cmd The command.
-- @param sn Enable startup-notification.
-- @param screen The screen where to spawn window.
-- @return The awesome.spawn return value.
function spawn(cmd, sn, screen)
    if cmd and cmd ~= "" then
        if sn == nil then sn = true end
        return capi.awesome.spawn(cmd, sn, screen or capi.mouse.screen)
    end
end

--- Spawn a program using the shell.
-- @param cmd The command.
-- @param screen The screen where to run the command.
function spawn_with_shell(cmd, screen)
    if cmd and cmd ~= "" then
        cmd = shell .. " -c \"" .. cmd .. "\""
        return capi.awesome.spawn(cmd, false, screen or capi.mouse.screen)
    end
end

--- Read a program output and returns its output as a string.
-- @param cmd The command to run.
-- @return A string with the program output, or the error if one occured.
function pread(cmd)
    if cmd and cmd ~= "" then
        local f, err = io.popen(cmd, 'r')
        if f then
            local s = f:read("*all")
            f:close()
            return s
        else
            return err
        end
    end
end

--- Eval Lua code.
-- @return The return value of Lua code.
function eval(s)
    return assert(loadstring(s))()
end

local xml_entity_names = { ["'"] = "&apos;", ["\""] = "&quot;", ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;" };
--- Escape a string from XML char.
-- Useful to set raw text in textbox.
-- @param text Text to escape.
-- @return Escape text.
function escape(text)
    return text and text:gsub("['&<>\"]", xml_entity_names) or nil
end

local xml_entity_chars = { lt = "<", gt = ">", nbsp = " ", quot = "\"", apos = "'", ndash = "-", mdash = "-", amp = "&" };
--- Unescape a string from entities.
-- @param text Text to unescape.
-- @return Unescaped text.
function unescape(text)
    return text and text:gsub("&(%a+);", xml_entity_chars) or nil
end

--- Check if a file is a Lua valid file.
-- This is done by loading the content and compiling it with loadfile().
-- @param path The file path.
-- @return A function if everything is alright, a string with the error
-- otherwise.
function checkfile(path)
    local f, e = loadfile(path)
    -- Return function if function, otherwise return error.
    if f then return f end
    return e
end

--- Try to restart awesome.
-- It checks if the configuration file is valid, and then restart if it's ok.
-- If it's not ok, the error will be returned.
-- @return Never return if awesome restart, or return a string error.
function restart()
    local c = checkfile(capi.awesome.conffile)

    if type(c) ~= "function" then
        return c
    end

    capi.awesome.restart()
end

--- Get the user's config or cache dir.
-- It first checks XDG_CONFIG_HOME / XDG_CACHE_HOME, but then goes with the
-- default paths.
-- @param d The directory to get (either "config" or "cache").
-- @return A string containing the requested path.
function getdir(d)
    if d == "config" then
        local dir = os.getenv("XDG_CONFIG_HOME")
        if dir then
            return dir .. "/awesome"
        end
        return os.getenv("HOME") .. "/.config/awesome"
    elseif d == "cache" then
        local dir = os.getenv("XDG_CACHE_HOME")
        if dir then
            return dir .. "/awesome"
        end
        return os.getenv("HOME").."/.cache/awesome"
    end
end

--- Check if file exists and is readable.
-- @param filename The file path
-- @return True if file exists and readable.
function file_readable(filename)
    local file = io.open(filename)
    if file then
        io.close(file)
        return true
    end
    return false
end

local function subset_mask_apply(mask, set)
    local ret = {}
    for i = 1, #set do
        if mask[i] then
            rtable.insert(ret, set[i])
        end
    end
    return ret
end

local function subset_next(mask)
    local i = 1
    while i <= #mask and mask[i] do
        mask[i] = false
        i = i + 1
    end

    if i <= #mask then
        mask[i] = 1
        return true
    end
    return false
end

--- Return all subsets of a specific set.
-- This function, giving a set, will return all subset it.
-- For example, if we consider a set with value { 10, 15, 34 },
-- it will return a table containing 2^n set:
-- { }, { 10 }, { 15 }, { 34 }, { 10, 15 }, { 10, 34 }, etc.
-- @param set A set.
-- @return A table with all subset.
function subsets(set)
    local mask = {}
    local ret = {}
    for i = 1, #set do mask[i] = false end

    -- Insert the empty one
    rtable.insert(ret, {})

    while subset_next(mask) do
        rtable.insert(ret, subset_mask_apply(mask, set))
    end
    return ret
end

--- Join all tables given as parameters.
-- This will iterate all tables and insert all their keys into a new table.
-- @param args A list of tables to join
-- @return A new table containing all keys from the arguments.
function table.join(...)
    local ret = {}
    for i, t in ipairs({...}) do
        if t then
            for k, v in pairs(t) do
                if type(k) == "number" then
                    rtable.insert(ret, v)
                else
                    ret[k] = v
                end
            end
        end
    end
    return ret
end

--- Check if a table has an item and return its key.
-- @param t The table.
-- @param item The item to look for in values of the table.
-- @return The key were the item is found, or nil if not found.
function table.hasitem(t, item)
    for k, v in pairs(t) do
        if v == item then
            return k
        end
    end
end

--- Split a string into multiple lines
-- @param text String to wrap.
-- @param width Maximum length of each line. Default: 72.
-- @param indent Number of spaces added before each wrapped line. Default: 0.
-- @return The string with lines wrapped to width.
function linewrap(text, width, indent)
    local text = text or ""
    local width = width or 72
    local indent = indent or 0

    local pos = 1
    return text:gsub("(%s+)()(%S+)()",
        function(sp, st, word, fi)
            if fi - pos > width then
                pos = st
                return "\n" .. string.rep(" ", indent) .. word
            end
        end)
end

--- Get a sorted table with all integer keys from a table
-- @param t the table for which the keys to get
-- @return A table with keys
function table.keys(t)
    local keys = { }
    for k, _ in pairs(t) do
        rtable.insert(keys, k)
    end
    rtable.sort(keys, function (a, b)
        return type(a) == type(b) and a < b or false
    end)
    return keys
end

--- Filter a tables keys for certain content types
-- @param t The table to retrieve the keys for
-- @param ... the types to look for
-- @return A filtered table with keys
function table.keys_filter(t, ...)
    local keys = table.keys(t)
    local keys_filtered = { }
    for _, k in pairs(keys) do
        for _, et in pairs({...}) do
            if type(t[k]) == et then
                rtable.insert(keys_filtered, k)
                break
            end
        end
    end
    return keys_filtered
end

--- Reverse a table
-- @param t the table to reverse
-- @return the reversed table
function table.reverse(t)
    local tr = { }
    -- reverse all elements with integer keys
    for _, v in ipairs(t) do
        rtable.insert(tr, 1, v)
    end
    -- add the remaining elements
    for k, v in pairs(t) do
        if type(k) ~= "number" then
            tr[k] = v
        end
    end
    return tr
end

--- Clone a table
-- @param t the table to clone
-- @return a clone of t
function table.clone(t)
    local c = { }
    for k, v in pairs(t) do
        c[k] = v
    end
    return c
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
