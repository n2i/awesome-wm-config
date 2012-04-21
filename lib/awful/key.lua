---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local setmetatable = setmetatable
local ipairs = ipairs
local capi = { key = key }
local util = require("awful.util")

--- Create easily new key objects ignoring certain modifiers.
module("awful.key")

--- Modifiers to ignore.
-- By default this is initialized as { "Lock", "Mod2" }
-- so the Caps Lock or Num Lock modifier are not taking into account by awesome
-- when pressing keys.
-- @name ignore_modifiers
-- @class table
ignore_modifiers = { "Lock", "Mod2" }

--- Create a new key to use as binding.
-- This function is useful to create several keys from one, because it will use
-- the ignore_modifier variable to create more key with or without the ignored
-- modifiers activated.
-- For example if you want to ignore CapsLock in your keybinding (which is
-- ignored by default by this function), creating key binding with this function
-- will return 2 key objects: one with CapsLock on, and the other one with
-- CapsLock off.
-- @see capi.key
-- @return A table with one or several key objects.
function new(mod, key, press, release)
    local ret = {}
    local subsets = util.subsets(ignore_modifiers)
    for _, set in ipairs(subsets) do
        ret[#ret + 1] = capi.key({ modifiers = util.table.join(mod, set),
                                   key = key })
        if press then
            ret[#ret]:add_signal("press", function(kobj, ...) press(...) end)
        end
        if release then
            ret[#ret]:add_signal("release", function(kobj, ...) release(...) end)
        end
    end
    return ret
end

--- Compare a key object with modifiers and key.
-- @param key The key object.
-- @param pressed_mod The modifiers to compare with.
-- @param pressed_key The key to compare with.
function match(key, pressed_mod, pressed_key)
    -- First, compare key.
    if pressed_key ~= key.key then return false end
    -- Then, compare mod
    local mod = key.modifiers
    -- For each modifier of the key object, check that the modifier has been
    -- pressed.
    for _, m in ipairs(mod) do
        -- Has it been pressed?
        if not util.table.hasitem(pressed_mod, m) then
            -- No, so this is failure!
            return false
        end
    end
    -- If the number of pressed modifier is ~=, it is probably >, so this is not
    -- the same, return false.
    if #pressed_mod ~= #mod then
        return false
    end
    return true
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
