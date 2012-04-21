---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

local setmetatable = setmetatable
local os = os
local capi = { widget = widget,
               timer = timer }

--- Text clock widget.
module("awful.widget.textclock")

--- Create a textclock widget. It draws the time it is in a textbox.
-- @param args Standard arguments for textbox widget.
-- @param format The time format. Default is " %a %b %d, %H:%M ".
-- @param timeout How often update the time. Default is 60.
-- @return A textbox widget.
function new(args, format, timeout)
    local args = args or {}
    local format = format or " %a %b %d, %H:%M "
    local timeout = timeout or 60
    args.type = "textbox"
    local w = capi.widget(args)
    local timer = capi.timer { timeout = timeout }
    w.text = os.date(format)
    timer:add_signal("timeout", function() w.text = os.date(format) end)
    timer:start()
    return w
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
