---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local capi = { widget = widget,
               screen = screen,
               image = image,
               client = client }
local type = type
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local table = table
local common = require("awful.widget.common")
local util = require("awful.util")
local tag = require("awful.tag")
local beautiful = require("beautiful")
local layout = require("awful.widget.layout")

--- Taglist widget module for awful
module("awful.widget.taglist")

label = {}

local function taglist_update (screen, w, label, buttons, data, widgets)
    local tags = capi.screen[screen]:tags()
    local showntags = {}
    for k, t in ipairs(tags) do
        if not tag.getproperty(t, "hide") then
            table.insert(showntags, t)
        end
    end
    common.list_update(w, buttons, label, data, widgets, showntags)
end

--- Get the tag object the given widget appears on.
-- @param widget The widget the look for.
-- @return The tag object.
function gettag(widget)
    return common.tagwidgets[widget]
end

--- Create a new taglist widget.
-- @param screen The screen to draw tag list for.
-- @param label Label function to use.
-- @param buttons A table with buttons binding to set.
function new(screen, label, buttons)
    local w = {
        layout = layout.horizontal.leftright
    }
    local widgets = { }
    widgets.imagebox = { }
    widgets.textbox  = { ["margin"] = { ["left"]  = 0,
                                        ["right"] = 0},
                         ["bg_resize"] = true
                       }
    local data = setmetatable({}, { __mode = 'kv' })
    local u = function (s)
        if s == screen then
            taglist_update(s, w, label, buttons, data, widgets)
        end
    end
    local uc = function (c) return u(c.screen) end
    capi.client.add_signal("focus", uc)
    capi.client.add_signal("unfocus", uc)
    tag.attached_add_signal(screen, "property::selected", uc)
    tag.attached_add_signal(screen, "property::icon", uc)
    tag.attached_add_signal(screen, "property::hide", uc)
    tag.attached_add_signal(screen, "property::name", uc)
    capi.screen[screen]:add_signal("tag::attach", function(screen, tag)
            u(screen.index)
        end)
    capi.screen[screen]:add_signal("tag::detach", function(screen, tag)
            u(screen.index)
        end)
    capi.client.add_signal("new", function(c)
        c:add_signal("property::urgent", uc)
        c:add_signal("property::screen", function(c)
            -- If client change screen, refresh it anyway since we don't from
            -- which screen it was coming :-)
            u(screen)
        end)
        c:add_signal("tagged", uc)
        c:add_signal("untagged", uc)
    end)
    capi.client.add_signal("unmanage", uc)
    u(screen)
    return w
end

--- Return labels for a taglist widget with all tag from screen.
-- It returns the tag name and set a special
-- foreground and background color for selected tags.
-- @param t The tag.
-- @param args The arguments table.
-- bg_focus The background color for selected tag.
-- fg_focus The foreground color for selected tag.
-- bg_urgent The background color for urgent tags.
-- fg_urgent The foreground color for urgent tags.
-- squares_sel Optional: a user provided image for selected squares.
-- squares_unsel Optional: a user provided image for unselected squares.
-- squares_resize Optional: true or false to resize squares.
-- @return A string to print, a background color, a background image and a
-- background resize value.
function label.all(t, args)
    if not args then args = {} end
    local theme = beautiful.get()
    local fg_focus = args.fg_focus or theme.taglist_fg_focus or theme.fg_focus
    local bg_focus = args.bg_focus or theme.taglist_bg_focus or theme.bg_focus
    local fg_urgent = args.fg_urgent or theme.taglist_fg_urgent or theme.fg_urgent
    local bg_urgent = args.bg_urgent or theme.taglist_bg_urgent or theme.bg_urgent
    local taglist_squares_sel = args.squares_sel or theme.taglist_squares_sel
    local taglist_squares_unsel = args.squares_unsel or theme.taglist_squares_unsel
    local taglist_squares_resize = theme.taglist_squares_resize or args.squares_resize or "true"
    local font = args.font or theme.taglist_font or theme.font or ""
    local text = "<span font_desc='"..font.."'>"
    local sel = capi.client.focus
    local bg_color = nil
    local fg_color = nil
    local bg_image
    local icon
    local bg_resize = false
    local is_selected = false
    if t.selected then
        bg_color = bg_focus
        fg_color = fg_focus
    end
    if sel then
        if taglist_squares_sel then
            -- Check that the selected clients is tagged with 't'.
            local seltags = sel:tags()
            for _, v in ipairs(seltags) do
                if v == t then
                    bg_image = capi.image(taglist_squares_sel)
                    bg_resize = taglist_squares_resize == "true"
                    is_selected = true
                    break
                end
            end
        end
    end
    if not is_selected then
        local cls = t:clients()
        if #cls > 0 and taglist_squares_unsel then
            bg_image = capi.image(taglist_squares_unsel)
            bg_resize = taglist_squares_resize == "true"
        end
        for k, c in pairs(cls) do
            if c.urgent then
                if bg_urgent then bg_color = bg_urgent end
                if fg_urgent then fg_color = fg_urgent end
                break
            end
        end
    end
    if not tag.getproperty(t, "icon_only") then
        if fg_color then
            text = text .. "<span color='"..util.color_strip_alpha(fg_color).."'>"
            text = " " .. text.. (util.escape(t.name) or "") .." </span>"
        else
            text = text .. " " .. (util.escape(t.name) or "") .. " "
        end
    end
    text = text .. "</span>"
    if tag.geticon(t) and type(tag.geticon(t)) == "image" then
        icon = tag.geticon(t)
    elseif tag.geticon(t) then
        icon = capi.image(tag.geticon(t))
    end

    return text, bg_color, bg_image, icon
end

--- Return labels for a taglist widget with all *non empty* tags from screen.
-- It returns the tag name and set a special
-- foreground and background color for selected tags.
-- @param t The tag.
-- @param args The arguments table.
-- bg_focus The background color for selected tag.
-- fg_focus The foreground color for selected tag.
-- bg_urgent The background color for urgent tags.
-- fg_urgent The foreground color for urgent tags.
-- @return A string to print, a background color, a background image and a
-- background resize value.
function label.noempty(t, args)
    if #t:clients() > 0 or t.selected then
        return label.all(t, args)
    end
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
