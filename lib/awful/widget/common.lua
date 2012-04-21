---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local math = math
local type = type
local pcall = pcall
local ipairs = ipairs
local setmetatable = setmetatable
local capi = { widget = widget, button = button }

--- Common widget code
module("awful.widget.common")

-- Private structures
tagwidgets = setmetatable({}, { __mode = 'k' })

function list_update(w, buttons, label, data, widgets, objects)
    -- Hack: if it has been registered as a widget in a wibox,
    -- it's w.len since __len meta does not work on table until Lua 5.2.
    -- Otherwise it's standard #w.
    local len = (w.len or #w) / 2
    -- Add more widgets
    if len < #objects then
        for i = len * 2 + 1, #objects * 2, 2 do
            local ib = capi.widget({ type = "imagebox", align = widgets.imagebox.align })
            local tb = capi.widget({ type = "textbox", align = widgets.textbox.align })

            w[i] = ib
            w[i + 1] = tb
            w[i + 1]:margin({ left = widgets.textbox.margin.left, right = widgets.textbox.margin.right })
            w[i + 1].bg_resize = widgets.textbox.bg_resize or false
            w[i + 1].bg_align = widgets.textbox.bg_align or ""

            if type(objects[math.floor(i / 2) + 1]) == "tag" then
                tagwidgets[ib] = objects[math.floor(i / 2) + 1]
                tagwidgets[tb] = objects[math.floor(i / 2) + 1]
            end
        end
    -- Remove widgets
    elseif len > #objects then
        for i = #objects * 2 + 1, len * 2, 2 do
            w[i] = nil
            w[i + 1] = nil
        end
    end

    -- update widgets text
    for k = 1, #objects * 2, 2 do
        local o = objects[(k + 1) / 2]
        if buttons then
            -- Use a local variable so that the garbage collector doesn't strike
            -- between now and the :buttons() call.
            local btns = data[o]
            if not btns then
                btns = {}
                data[o] = btns
                for kb, b in ipairs(buttons) do
                    -- Create a proxy button object: it will receive the real
                    -- press and release events, and will propagate them the the
                    -- button object the user provided, but with the object as
                    -- argument.
                    local btn = capi.button { modifiers = b.modifiers, button = b.button }
                    btn:add_signal("press", function () b:emit_signal("press", o) end)
                    btn:add_signal("release", function () b:emit_signal("release", o) end)
                    btns[#btns + 1] = btn
                end
            end
            w[k]:buttons(btns)
            w[k + 1]:buttons(btns)
        end

        local text, bg, bg_image, icon = label(o)

        -- Check if we got a valid text here, it might contain e.g. broken utf8.
        if not pcall(function() w[k + 1].text = text end) then
            w[k + 1].text = "<i>Invalid</i>"
        end

        w[k + 1].bg, w[k + 1].bg_image = bg, bg_image
        w[k].bg, w[k].image = bg, icon
        if not w[k + 1].text then
            w[k+1].visible = false
        else
            w[k+1].visible = true
        end
        if not w[k].image then
            w[k].visible = false
        else
            w[k].visible = true
        end
   end
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
