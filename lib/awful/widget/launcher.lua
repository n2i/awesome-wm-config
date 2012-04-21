---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

local setmetatable = setmetatable
local util = require("awful.util")
local wbutton = require("awful.widget.button")
local button = require("awful.button")

module("awful.widget.launcher")

--- Create a button widget which will launch a command.
-- @param args Standard widget table arguments, plus image for the image path
-- and command for the command to run on click, or either menu to create menu.
-- @return A launcher widget.
function new(args)
    if not args.command and not args.menu then return end
    local w = wbutton(args)
    if not w then return end

    if args.command then
       b = util.table.join(w:buttons(), button({}, 1, nil, function () util.spawn(args.command) end))
    elseif args.menu then
       b = util.table.join(w:buttons(), button({}, 1, nil, function () args.menu:toggle() end))
    end

    w:buttons(b)
    return w
end

setmetatable(_M, { __call = function (_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
