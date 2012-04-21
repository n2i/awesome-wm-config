---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local capi =
{
    awesome = awesome,
    screen = screen,
    wibox = wibox,
    client = client
}
local setmetatable = setmetatable
local tostring = tostring
local ipairs = ipairs
local table = table
local type = type
local image = image
local error = error

--- Wibox module for awful.
-- This module allows you to easily create wibox and attach them to the edge of
-- a screen.
module("awful.wibox")

-- Array of table with wiboxes inside.
-- It's an array so it is ordered.
local wiboxes = {}

--- Get a wibox position if it has been set, or return top.
-- @param wibox The wibox
-- @return The wibox position.
function get_position(wibox)
    for _, wprop in ipairs(wiboxes) do
        if wprop.wibox == wibox then
            return wprop.position
        end
    end
    return "top"
end

--- Put a wibox on a screen at this position.
-- @param wibox The wibox to attach.
-- @param position The position: top, bottom left or right.
-- @param screen If the wibox it not attached to a screen, specified on which
-- screen the position should be set.
function set_position(wibox, position, screen)
    local screen = screen or wibox.screen or 1
    local area = capi.screen[screen].geometry

    -- The "length" of a wibox is always chosen to be the optimal size
    -- (non-floating).
    -- The "width" of a wibox is kept if it exists.
    if position == "right" then
        wibox.x = area.x + area.width - (wibox.width + 2 * wibox.border_width)
    elseif position == "left" then
        wibox.x = area.x
    elseif position == "bottom" then
        wibox.y = (area.y + area.height) - (wibox.height + 2 * wibox.border_width)
    elseif position == "top" then
        wibox.y = area.y
    end

    for _, wprop in ipairs(wiboxes) do
        if wprop.wibox == wibox then
            wprop.position = position
            break
        end
    end
end

-- Reset all wiboxes positions.
local function update_all_wiboxes_position()
    for _, wprop in ipairs(wiboxes) do
        set_position(wprop.wibox, wprop.position)
    end
end

local function call_wibox_position_hook_on_prop_update(w)
    update_all_wiboxes_position()
end

local function wibox_update_strut(wibox)
    for _, wprop in ipairs(wiboxes) do
        if wprop.wibox == wibox then
            if not wibox.visible then
                wibox:struts { left = 0, right = 0, bottom = 0, top = 0 }
            elseif wprop.position == "top" then
                wibox:struts { left = 0, right = 0, bottom = 0, top = wibox.height + 2 * wibox.border_width }
            elseif wprop.position == "bottom" then
                wibox:struts { left = 0, right = 0, bottom = wibox.height + 2 * wibox.border_width, top = 0 }
            elseif wprop.position == "left" then
                wibox:struts { left = wibox.width + 2 * wibox.border_width, right = 0, bottom = 0, top = 0 }
            elseif wprop.position == "right" then
                wibox:struts { left = 0, right = wibox.width + 2 * wibox.border_width, bottom = 0, top = 0 }
            end
            break
        end
    end
end

--- Attach a wibox to a screen.
-- If a wibox is attached, it will be automatically be moved when other wiboxes
-- will be attached.
-- @param wibox The wibox to attach.
-- @param position The position of the wibox: top, bottom, left or right.
function attach(wibox, position)
    -- Store wibox as attached in a weak-valued table
    local wibox_prop_table
    -- Start from end since we sometimes remove items
    for i = #wiboxes, 1, -1 do
        -- Since wiboxes are stored as weak value, they can disappear.
        -- If they did, remove their entries
        if wiboxes[i].wibox == nil then
            table.remove(wiboxes, i)
        elseif wiboxes[i].wibox == wibox then
            wibox_prop_table = wiboxes[i]
            -- We could break here, but well, let's check if there is no other
            -- table with their wiboxes been garbage collected.
        end
    end

    if not wibox_prop_table then
        table.insert(wiboxes, setmetatable({ wibox = wibox, position = position }, { __mode = 'v' }))
    else
        wibox_prop_table.position = position
    end

    wibox:add_signal("property::width", wibox_update_strut)
    wibox:add_signal("property::height", wibox_update_strut)
    wibox:add_signal("property::visible", wibox_update_strut)

    wibox:add_signal("property::screen", call_wibox_position_hook_on_prop_update)
    wibox:add_signal("property::width", call_wibox_position_hook_on_prop_update)
    wibox:add_signal("property::height", call_wibox_position_hook_on_prop_update)
    wibox:add_signal("property::visible", call_wibox_position_hook_on_prop_update)
    wibox:add_signal("property::border_width", call_wibox_position_hook_on_prop_update)
end

--- Align a wibox.
-- @param wibox The wibox.
-- @param align The alignment: left, right or center.
-- @param screen If the wibox is not attached to any screen, you can specify the
-- screen where to align. Otherwise 1 is assumed.
function align(wibox, align, screen)
    local position = get_position(wibox)
    local screen = screen or wibox.screen or 1
    local area = capi.screen[screen].workarea

    if position == "right" then
        if align == "right" then
            wibox.y = area.y
        elseif align == "left" then
            wibox.y = area.y + area.height - (wibox.height + 2 * wibox.border_width)
        elseif align == "center" then
            wibox.y = area.y + (area.height - wibox.height) / 2
        end
    elseif position == "left" then
        if align == "right" then
            wibox.y = (area.y + area.height) - (wibox.height + 2 * wibox.border_width)
        elseif align == "left" then
            wibox.y = area.y
        elseif align == "center" then
            wibox.y = area.y + (area.height - wibox.height) / 2
        end
    elseif position == "bottom" then
        if align == "right" then
            wibox.x = area.x + area.width - (wibox.width + 2 * wibox.border_width)
        elseif align == "left" then
            wibox.x = area.x
        elseif align == "center" then
            wibox.x = area.x + (area.width - wibox.width) / 2
        end
    elseif position == "top" then
        if align == "right" then
            wibox.x = area.x + area.width - (wibox.width + 2 * wibox.border_width)
        elseif align == "left" then
            wibox.x = area.x
        elseif align == "center" then
            wibox.x = area.x + (area.width - wibox.width) / 2
        end
    end

    -- Update struts regardless of changes
    wibox_update_strut(wibox)
end

--- Stretch a wibox so it takes all screen width or height.
-- @param wibox The wibox.
-- @param screen The screen to stretch on, or the wibox screen.
function stretch(wibox, screen)
    local screen = screen or wibox.screen
    if screen then
        local position = get_position(wibox)
        local area = capi.screen[screen].workarea
        if position == "right" or position == "left" then
            wibox.height = area.height - (2 * wibox.border_width)
            wibox.y = area.y
        else
            wibox.width = area.width - (2 * wibox.border_width)
            wibox.x = area.x
        end
    end
end

--- Create a new wibox and attach it to a screen edge.
-- @see capi.wibox
-- @param args A table with standard arguments to wibox() creator.
-- You can add also position key with value top, bottom, left or right.
-- You can also use width or height in % and set align to center, right or left.
-- You can also set the screen key with a screen number to attach the wibox.
-- If not specified, 1 is assumed.
-- @return The wibox created.
function new(arg)
    local arg = arg or {}
    local position = arg.position or "top"
    local has_to_stretch = true
    -- Empty position and align in arg so we are passing deprecation warning
    arg.position = nil

    if position ~= "top" and position ~="bottom"
            and position ~= "left" and position ~= "right" then
        error("Invalid position in awful.wibox(), you may only use"
            .. " 'top', 'bottom', 'left' and 'right'")
    end

    -- Set default size
    if position == "left" or position == "right" then
        arg.width = arg.width or capi.awesome.font_height * 1.5
        if arg.height then
            has_to_stretch = false
            if arg.screen then
                local hp = tostring(arg.height):match("(%d+)%%")
                if hp then
                    arg.height = capi.screen[arg.screen].geometry.height * hp / 100
                end
            end
        end
    else
        arg.height = arg.height or capi.awesome.font_height * 1.5
        if arg.width then
            has_to_stretch = false
            if arg.screen then
                local wp = tostring(arg.width):match("(%d+)%%")
                if wp then
                    arg.width = capi.screen[arg.screen].geometry.width * wp / 100
                end
            end
        end
    end

    local w = capi.wibox(arg)

    if position == "left" then
        w.orientation = "north"
    elseif position == "right" then
        w.orientation = "south"
    end

    w.screen = arg.screen or 1

    attach(w, position)
    if has_to_stretch then
        stretch(w)
    else
        align(w, arg.align)
    end

    set_position(w, position)

    return w
end

local function do_rounded_corners(width, height, corner)
    local img = image.argb32(width, height, nil)

    -- The image starts completely black which is fully opaque for our use

    local function transp_rect(x, y)
        img:draw_rectangle(x, y, corner, corner, true, "#ffffff")
    end
    local function opaque_circle(x, y)
        -- x, y are the center of the circle
        img:draw_circle(x, y, corner, corner, true, "#000000")
    end

    -- Upper left corner
    -- First make a 'corner times corner' rectangle transparent
    transp_rect(0, 0)
    -- Then add the rounded corner
    opaque_circle(corner, corner)

    -- Upper right corner
    transp_rect(width - corner, 0)
    opaque_circle(width - corner - 1, corner)

    -- Bottom left corner
    transp_rect(0, height - corner)
    opaque_circle(corner, height - corner - 1)

    -- Bottom right corner
    transp_rect(width - corner, height - corner)
    opaque_circle(width - corner - 1, height - corner - 1)

    return img
end

--- Add rounded corners to a wibox
-- @param wibox The wibox.
-- @param corner_size The size in pixel of the rounded corners.
function rounded_corners(wibox, corner_size)
    local border = wibox.border_width

    -- Corners can't be larger than half the wibox' space
    if wibox.width / 2 < corner_size then
        corner_size = wibox.width / 2
    end
    if wibox.height / 2 < corner_size then
        corner_size = wibox.height / 2
    end

    wibox.shape_clip = do_rounded_corners(wibox.width, wibox.height, corner_size)
    wibox.shape_bounding = do_rounded_corners(wibox.width + border * 2, wibox.height + border * 2, corner_size + border)
end

local function update_wiboxes_on_struts(c)
    local struts = c:struts()
    if struts.left ~= 0 or struts.right ~= 0
       or struts.top ~= 0 or struts.bottom ~= 0 then
        update_all_wiboxes_position()
    end
end

-- Hook registered to reset all wiboxes position.
capi.client.add_signal("manage", function(c)
    update_wiboxes_on_struts(c)
    c:add_signal("property::struts", update_wiboxes_on_struts)
end)
capi.client.add_signal("unmanage", update_wiboxes_on_struts)

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
