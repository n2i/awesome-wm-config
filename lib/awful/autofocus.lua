---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

local client = client
local screen = screen
local aclient = require("awful.client")
local atag = require("awful.tag")

--- When loaded, this module makes sure that there's always a client that will have focus
-- on event such as tag switching, client unmanaging, etc.
module("awful.autofocus")

-- Give focus on tag selection change.
-- @param obj An object that should have a .screen property.
local function check_focus(obj)
    if not client.focus or not client.focus:isvisible() then
        local c = aclient.focus.history.get(obj.screen, 0)
        if c then client.focus = c end
    elseif client.focus and client.focus.screen ~= obj.screen then
        local c = aclient.focus.history.get(obj.screen, 0)
        if c then client.focus = c end
    end
end

atag.attached_add_signal(nil, "property::selected", check_focus)
client.add_signal("unmanage", check_focus)
client.add_signal("new", function(c)
    c:add_signal("untagged", check_focus)
    c:add_signal("property::hidden", check_focus)
    c:add_signal("property::minimized", check_focus)
end)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
