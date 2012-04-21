---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local math = math
local image = image
local pairs = pairs
local type = type
local setmetatable = setmetatable
local type = type
local capi =
{
    awesome = awesome,
    wibox = wibox,
    widget = widget,
    client = client,
}
local abutton = require("awful.button")
local beautiful = require("beautiful")
local util = require("awful.util")
local widget = require("awful.widget")
local mouse = require("awful.mouse")
local client = require("awful.client")
local layout = require("awful.widget.layout")

--- Titlebar module for awful
module("awful.titlebar")

-- Privata data
local data = setmetatable({}, { __mode = 'k' })

-- Predeclaration for buttons
local button_groups

local function button_callback_focus_raise_move(w, t)
    capi.client.focus = t.client
    t.client:raise()
    mouse.client.move(t.client)
end

local function button_callback_move(w, t)
    return mouse.client.move(t.client)
end

local function button_callback_resize(w, t)
    return mouse.client.resize(t.client)
end

--- Create a standard titlebar.
-- @param c The client.
-- @param args Arguments.
-- modkey: the modkey used for the bindings.
-- fg: the foreground color.
-- bg: the background color.
-- fg_focus: the foreground color for focused window.
-- fg_focus: the background color for focused window.
-- width: the titlebar width
function add(c, args)
    if not c or (c.type ~= "normal" and c.type ~= "dialog") then return end
    if not args then args = {} end
    if not args.height then args.height = capi.awesome.font_height * 1.5 end
    local theme = beautiful.get()
    if not args.widget then customwidget = {} else customwidget = args.widget end
    -- Store colors
    data[c] = {}
    data[c].fg = args.fg or theme.titlebar_fg_normal or theme.fg_normal
    data[c].bg = args.bg or theme.titlebar_bg_normal or theme.bg_normal
    data[c].fg_focus = args.fg_focus or theme.titlebar_fg_focus or theme.fg_focus
    data[c].bg_focus = args.bg_focus or theme.titlebar_bg_focus or theme.bg_focus
    data[c].width = args.width
    data[c].font = args.font or theme.titlebar_font or theme.font

    local tb = capi.wibox(args)

    local title = capi.widget({ type = "textbox" })
    if c.name then
        title.text = "<span font_desc='" .. data[c].font .. "'> " ..
                     util.escape(c.name) .. " </span>"
    end

    -- Redirect relevant events to the client the titlebar belongs to
    local bts = util.table.join(
        abutton({ }, 1, button_callback_focus_raise_move),
        abutton({ args.modkey }, 1, button_callback_move),
        abutton({ args.modkey }, 3, button_callback_resize))
    title:buttons(bts)

    local appicon = capi.widget({ type = "imagebox" })
    appicon.image = c.icon

    -- for each button group, call create for the client.
    -- if a button set is created add the set to the
    -- data[c].button_sets for late updates and add the
    -- individual buttons to the array part of the widget
    -- list
    local widget_list = {
        layout = layout.horizontal.rightleft
    }
    local iw = 1
    local is = 1
    data[c].button_sets = {}
    for i = 1, #button_groups do
        local set = button_groups[i].create(c, args.modkey, theme)
        if (set) then
            data[c].button_sets[is] = set
            is = is + 1
            for n,b in pairs(set) do
                widget_list[iw] = b
                iw = iw + 1
            end
        end
    end

    tb.widgets = {
        widget_list,
        customwidget,
        {
            appicon = appicon,
            title = title,
            layout = layout.horizontal.flex
        },
        layout = layout.horizontal.rightleft
    }

    c.titlebar = tb

    c:add_signal("property::icon", update)
    c:add_signal("property::name", update)
    c:add_signal("property::sticky", update)
    c:add_signal("property::floating", update)
    c:add_signal("property::ontop", update)
    c:add_signal("property::maximized_vertical", update)
    c:add_signal("property::maximized_horizontal", update)
    update(c)
end

--- Update a titlebar. This should be called in some hooks.
-- @param c The client to update.
-- @param prop The property name which has changed.
function update(c)
     if c.titlebar and data[c] then
        local widgets = c.titlebar.widgets
        if widgets[3].title then
            widgets[3].title.text = "<span font_desc='" .. data[c].font ..
            "'> ".. util.escape(c.name or "<unknown>") .. " </span>"
        end
        if widgets[3].appicon then
            widgets[3].appicon.image = c.icon
        end
        if capi.client.focus == c then
            c.titlebar.fg = data[c].fg_focus
            c.titlebar.bg = data[c].bg_focus
        else
            c.titlebar.fg = data[c].fg
            c.titlebar.bg = data[c].bg
        end

        -- iterated of all registered button_sets and update
        local sets = data[c].button_sets
        for i = 1, #sets do
            sets[i].update(c,prop)
        end
    end
end

--- Remove a titlebar from a client.
-- @param c The client.
function remove(c)
    c.titlebar = nil
    data[c] = nil
end

-- Create a new button for the toolbar
-- @param c      The client of the titlebar
-- @param name   The base name of the button (i.e. close)
-- @param modkey ... you know that one, don't you?
-- @param theme  The theme from beautifull. Used to get the image paths
-- @param state  The state the button is associated to. Containse path the action and info about the image
local function button_new(c, name, modkey, theme, state)
    local bts = abutton({ }, 1, nil,  state.action)

    -- get the image path from the theme. Only return a button if we find an image
    local img
    img = "titlebar_" .. name .. "_button_" .. state.img
    img = theme[img]
    if not img then return end
    img = image(img)
    if not img then return end

    -- now create the button
    local bname = name .. "_" .. state.idx
    local button = widget.button({ image = img })
    if not button then return end
    local rbts = button:buttons()

    for k, v in pairs(rbts) do
        bts[#bts + 1] = v
    end

    button:buttons(bts)
    button.visible = false
    return button
end

-- Update the buttons in a button group
-- @param s      The button group to update
-- @param c      The client of the titlebar
-- @param p      The property that has changed
local function button_group_update(s,c,p)
    -- hide the currently active button, get the new state and show the new button
    local n = s.select_state(c,p)
    if n == nil then return end
    if (s.active ~= nil) then  s.active.visible = false end
    s.active = s.buttons[n]
    s.active.visible = true
end

-- Create all buttons in a group
-- @param c      The client of the titlebar
-- @param group  The button group to create the buttons for
-- @param modkey ...
-- @param theme  Theme for the image paths
local function button_group_create(c, group, modkey, theme )
    local s = {}
    s.name = group.name
    s.select_state = group.select_state
    s.buttons = {
        layout = layout.horizontal.rightleft
    }
    for n,state in pairs(group.states) do
        s.buttons[n] = button_new(c, s.name, modkey, theme, state)
        if (s.buttons[n] == nil) then return end
        for a,v in pairs(group.attributes) do
            s.buttons[n][a] = v
        end
    end
    function s.update(c,p) button_group_update(s,c,p) end
    return s
end

-- Builds a new button group
-- @param name   The base name for the buttons in the group (i.e. "close")
-- @param attrs  Common attributes for the buttons (i.e. {align = "right")
-- @param sfn    State select function.
-- @param args   The states of the button
local function button_group(name, attrs, sfn, ...)
    local s = {}
    s.name = name
    s.select_state = sfn
    s.attributes = attrs
    s.states = {}

    for i, state in pairs({...}) do
        s.states[state.idx] = state
    end

    function s.create(c,modkey, theme) return button_group_create(c,s,modkey, theme) end
    return s
end

-- Select a state for a client based on an attribute of the client and whether it has focus
-- @param c      The client of the titlebar
-- @param p      The property that has changed
-- @param a      The property to check
local function select_state(c,p,a)
    if (c == nil) then return "n/i" end
    if capi.client.focus == c then
        if c[a] then
            return "f/a"
        else
            return "f/i"
        end
    else
        if c[a] then
            return "n/a"
        else
            return "n/i"
        end
    end
end

-- Select a state for a client based on whether it's floating or not
-- @param c      The client of the titlebar
-- @param p      The property that has changed
local function select_state_floating(c,p)
    if not c then return end
    if capi.client.focus == c then
        if client.floating.get(c) then
            return "f/a"
        end
        return "f/i"
    end
    if client.floating.get(c) then
        return "n/a"
    end
    return "n/i"
end

-- Select a state for a client based on whether it's maximized or not
-- @param c      The client of the titlebar
-- @param p      The property that has changed
local function select_state_maximized(c,p)
    if (c == nil) then return "n/i" end
    if capi.client.focus == c then
        if c.maximized_horizontal or c.maximized_vertical then
            return "f/a"
        else
            return "f/i"
        end
    else
        if c.maximized_horizontal or c.maximized_vertical then
            return "n/a"
        else
            return "n/i"
        end
    end
end

-- Select a state for a client based on whether it has focus or not
-- @param c      The client of the titlebar
-- @param p      The property that has changed
local function select_state_focus(c,p)
    if c and capi.client.focus == c then
        return "f"
    end
    return "n"
end

-- These are the predefined button groups
-- A short explanation using 'close_buttons' as an example:
-- "close" : name of the button, the images for this button are taken from the
--           theme variables titlebar_close_button_...
-- { align ... :  attributes of all the buttons
-- select_state_focus : This function returns a short string used to describe
--                      the state. In this case either "n" or "f" depending on
--                      the focus state of the client. These strings can be
--                      choosen freely but the< must match one of the idx fuekds
--                      of the states below
--  { idx = "n" ... : This is the state of the button for the 'unfocussed'
--                    (normal) state. The idx = "n" parameter connects this
--                    button to the return value of the 'select_state_focus'
--                    function. The img = "normal" parameter is used to
--                    determine its image. In this case the iamge is taken from
--                    the theme variable "titlebar_close_button_normal".
--                    Finally the last parameter is the action for mouse
--                    button 1

local ontop_buttons = button_group("ontop",
                                   { align = "right" },
                                   function(c,p) return select_state(c, p, "ontop") end,
                                   { idx = "n/i", img = "normal_inactive",
                                     action = function(w, t) t.client.ontop = true end },
                                   { idx = "f/i", img = "focus_inactive",
                                     action = function(w, t) t.client.ontop = true end },
                                   { idx = "n/a", img = "normal_active",
                                     action = function(w, t) t.client.ontop = false end },
                                   { idx = "f/a", img = "focus_active",
                                     action = function(w, t) t.client.ontop = false end })

local sticky_buttons = button_group("sticky",
                                    { align = "right" },
                                    function(c,p) return select_state(c,p,"sticky") end,
                                    { idx = "n/i", img = "normal_inactive",
                                      action = function(w, t) t.client.sticky = true end },
                                    { idx = "f/i", img = "focus_inactive",
                                      action = function(w, t) t.client.sticky = true end },
                                    { idx = "n/a", img = "normal_active",
                                      action = function(w, t) t.client.sticky = false end },
                                    { idx = "f/a", img = "focus_active",
                                      action = function(w, t) t.client.sticky = false end })

local maximized_buttons = button_group("maximized",
                                     { align = "right" },
                                     select_state_maximized,
                                     { idx = "n/i", img = "normal_inactive",
                                       action = function(w, t) t.client.maximized_horizontal = true
                                                               t.client.maximized_vertical = true end },
                                     { idx = "f/i", img = "focus_inactive",
                                       action = function(w, t) t.client.maximized_horizontal = true
                                                               t.client.maximized_vertical = true end },
                                     { idx = "n/a", img = "normal_active",
                                       action = function(w, t) t.client.maximized_horizontal = false
                                                               t.client.maximized_vertical = false end },
                                     { idx = "f/a", img = "focus_active",
                                       action = function(w, t) t.client.maximized_horizontal = false
                                                               t.client.maximized_vertical = false end })

local close_buttons = button_group("close",
                                   { align = "left" },
                                   select_state_focus,
                                   { idx = "n", img = "normal",
                                     action = function (w, t) t.client:kill() end },
                                   { idx = "f", img = "focus",
                                     action = function (w, t) t.client:kill() end })

local function floating_update(w, t)
    client.floating.toggle(t.client)
end

local floating_buttons = button_group("floating",
                                     { align = "right"},
                                     select_state_floating,
                                     { idx = "n/i", img = "normal_inactive", action = floating_update },
                                     { idx = "f/i", img = "focus_inactive", action = floating_update },
                                     { idx = "n/a", img = "normal_active", action = floating_update },
                                     { idx = "f/a", img = "focus_active", action = floating_update })

button_groups = { close_buttons,
                  ontop_buttons,
                  sticky_buttons,
                  maximized_buttons,
                  floating_buttons }

-- Register standards hooks
capi.client.add_signal("focus", update)
capi.client.add_signal("unfocus", update)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
