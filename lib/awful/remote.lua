---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
require("awful.dbus")
local loadstring = loadstring
local tostring = tostring
local ipairs = ipairs
local table = table
local dbus = dbus
local unpack = unpack
local type = type

--- Remote control module allowing usage of awesome-client.
module("awful.remote")

if dbus then
    dbus.add_signal("org.naquadah.awesome.awful.Remote", function(data, code)
        if data.member == "Eval" then
            local f, e = loadstring(code)
            if f then
                results = { f() }
                retvals = {}
                for _, v in ipairs(results) do
                    local t = type(v)
                    if t == "boolean" then
                        table.insert(retvals, "b")
                        table.insert(retvals, v)
                    elseif t == "number" then
                        table.insert(retvals, "d")
                        table.insert(retvals, v)
                    else
                        table.insert(retvals, "s")
                        table.insert(retvals, tostring(v))
                    end
                end
                return unpack(retvals)
            elseif e then
                return "s", e
            end
        end
    end)
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
