---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local pairs = pairs
local table = table
local ipairs = ipairs
local type = type
local math = math
local capi =
{
    hooks = hooks
}
local util = require("awful.util")

--- Hooks module for awful.
-- This module is deprecated and should not be used anymore. You are encouraged
-- to use signals.
module("awful.hooks")

-- User hook functions
user = {}

--- Create a new userhook (for external libs).
-- @param name Hook name.
function user.create(name)
    _M[name] = {}
    _M[name].callbacks = {}
    _M[name].register = function (f)
        table.insert(_M[name].callbacks, f)
    end
    _M[name].unregister = function (f)
        for k, h in ipairs(_M[name].callbacks) do
            if h == f then
                table.remove(_M[name].callbacks, k)
                break
            end
        end
    end
end

--- Call a created userhook (for external libs).
-- @param name Hook name.
function user.call(name, ...)
    for name, callback in pairs(_M[name].callbacks) do
        callback(...)
    end
end

-- Autodeclare awful.hooks.* functions
-- mapped to awesome hooks.* functions
for name, hook in pairs(capi.hooks) do
    _M[name] = {}
    if name == 'timer' then
        _M[name].register = function (time, f, runnow)
            util.deprecate("timer object")
            if type(time) ~= 'number' or type(f) ~= 'function' or time <= 0 then
                return
            end

            if not _M[name].callbacks then
                _M[name].callbacks = {}
            end

            for k, v in pairs(_M[name].callbacks) do
                if v.callback == f then
                    _M[name].unregister(f)
                    _M[name].register(time, f, runnow)
                    return
                end
            end

            local new_timer
            if _M[name].timer then
                -- Take the smallest between current and new
                new_timer = math.min(time, _M[name].timer)
            else
                new_timer = time
            end

            if _M[name].timer ~= new_timer then
                _M[name].timer = new_timer
            end

            hook(_M[name].timer, function (...)
                for i, callback in ipairs(_M[name].callbacks) do
                    callback['counter'] = callback['counter'] + _M[name].timer
                    if callback['counter'] >= callback['timer'] then
                        callback['callback'](...)
                        callback['counter'] = 0
                    end
                 end
            end)

            if runnow then
                table.insert(_M[name].callbacks, { callback = f, timer = time, counter = time })
            else
                table.insert(_M[name].callbacks, { callback = f, timer = time, counter = 0 })
            end
        end
        _M[name].unregister = function (f)
            if _M[name].callbacks then
                for k, h in ipairs(_M[name].callbacks) do
                    if h.callback == f then
                        table.remove(_M[name].callbacks, k)
                        break
                    end
                end
                local delays = { }
                for k, h in ipairs(_M[name].callbacks) do
                    table.insert(delays, h.timer)
                end
                table.sort(delays)
                _M[name].timer = delays[1]
                if not delays[1] then delays[1] = 0 end
                hook(delays[1], function (...)
                    for i, callback in ipairs(_M[name].callbacks) do
                        callback['counter'] = callback['counter'] + _M[name].timer
                        if callback['counter'] >= callback['timer'] then
                            callback['callback'](...)
                            callback['counter'] = 0
                        end
                    end
                end)
            end
        end
    else
        _M[name].register = function (f)
            util.deprecate("signals")
            if not _M[name].callbacks then
                _M[name].callbacks = {}
                hook(function (...)
                    for i, callback in ipairs(_M[name].callbacks) do
                       callback(...)
                    end
                end)
            end

            table.insert(_M[name].callbacks, f)
        end
    end

    if name ~= "timer" then
        _M[name].unregister = function (f)
            if _M[name].callbacks then
                for k, h in ipairs(_M[name].callbacks) do
                    if h == f then
                        table.remove(_M[name].callbacks, k)
                        break
                    end
                end
            end
        end
    end
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
