---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

local setmetatable = setmetatable
local type = type
local button = require("awful.button")
local capi = { image = image,
               widget = widget,
               mouse = mouse }

module("awful.widget.button")

--- Create a button widget. When clicked, the image is deplaced to make it like
-- a real button.
-- @param args Standard widget table arguments, plus image for the image path or
-- the image object.
-- @return A textbox widget configured as a button.
function new(args)
    if not args or not args.image then return end
    local img_release
    if type(args.image) == "string" then
        img_release = capi.image(args.image)
    elseif type(args.image) == "image" then
        img_release = args.image
    else
        return
    end
    local img_press = img_release:crop(-2, -2, img_release.width, img_release.height)
    args.type = "imagebox"
    local w = capi.widget(args)
    w.image = img_release
    w:buttons(button({}, 1, function () w.image = img_press end, function () w.image = img_release end))
    w:add_signal("mouse::leave", function () w.image = img_release end)
    w:add_signal("mouse::enter", function ()
                                     if capi.mouse.coords().buttons[1] then w.image = img_press end
                                 end)
    return w
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
