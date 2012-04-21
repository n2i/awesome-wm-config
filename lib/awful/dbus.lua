---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local dbus = dbus

--- D-Bus module for awful.
-- This module simply request the org.naquadah.awesome.awful name on the D-Bus
-- for futur usage by other awful modules.
module("awful.dbus")

if dbus then
    dbus.request_name("session", "org.naquadah.awesome.awful")
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
