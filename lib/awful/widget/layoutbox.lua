---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

local setmetatable = setmetatable
local ipairs = ipairs
local button = require("awful.button")
local layout = require("awful.layout")
local tag = require("awful.tag")
local beautiful = require("beautiful")
local capi = { image = image,
               screen = screen,
               widget = widget }

--- Layoutbox widget.
module("awful.widget.layoutbox")

local function update(w, screen)
    local layout = layout.getname(layout.get(screen))
    if layout and beautiful["layout_" ..layout] then
        w.image = capi.image(beautiful["layout_" ..layout])
    else
        w.image = nil
    end
end

--- Create a layoutbox widget. It draws a picture with the current layout
-- symbol of the current tag.
-- @param screen The screen number that the layout will be represented for.
-- @param args Standard arguments for an imagebox widget.
-- @return An imagebox widget configured as a layoutbox.
function new(screen, args)
    local screen = screen or 1
    local args = args or {}
    args.type = "imagebox"
    local w = capi.widget(args)
    update(w, screen)

    local function update_on_tag_selection(tag)
        return update(w, tag.screen)
    end

    tag.attached_add_signal(screen, "property::selected", update_on_tag_selection)
    tag.attached_add_signal(screen, "property::layout", update_on_tag_selection)

    return w
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
