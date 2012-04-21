-------------------------------------------------
-- @author Gregor Best <farhaven@googlemail.com>
-- @copyright 2009 Gregor Best
-- @release v3.4.9
-------------------------------------------------

-- Grab environment
local ipairs = ipairs
local type = type
local table = table
local math = math
local util = require("awful.util")
local default = require("awful.widget.layout.default")

--- Vertical widget layout
module("awful.widget.layout.vertical")

function flex(bounds, widgets, screen)
    local geometries = {
        free = util.table.clone(bounds)
    }

    local y = 0

    -- we are only interested in tables and widgets
    local keys = util.table.keys_filter(widgets, "table", "widget")
    local nelements = 0
    for _, k in ipairs(keys) do
        local v = widgets[k]
        if type(v) == "table" then
            nelements = nelements + 1
        else
            local e = v:extents()
            if v.visible and e.width > 0 and e.height > 0 then
                nelements = nelements + 1
            end
        end
    end
    if nelements == 0 then return geometries end
    local height = math.floor(bounds.height / nelements)

    for _, k in ipairs(keys) do
        local v = widgets[k]
        if type(v) == "table" then
            local layout = v.layout or default
            -- we need to modify the height a bit because vertical layouts always span the
            -- whole height
            nbounds = util.table.clone(bounds)
            nbounds.height = height
            local g = layout(nbounds, v, screen)
            for _, w in ipairs(g) do
                w.y = w.y + y
                table.insert(geometries, w)
            end
            y = y + height
        elseif type(v) == "widget" then
            local g
            if v.visible then
                g = v:extents(screen)
            else
                g = {
                    ["width"] = 0,
                    ["height"] = 0
                }
            end

            g.ratio = 1
            if g.height > 0 and g.width > 0 then
                g.ratio = g.width / g.height
            end
            g.height = height
            if v.resize then
                g.width = g.height * g.ratio
            end
            g.width = math.min(g.width, bounds.width)
            geometries.free.x = math.max(geometries.free.x, g.width)

            g.x = 0
            g.y = y
            y = y + g.height
            bounds.height = bounds.height - g.height

            table.insert(geometries, g)
        end
    end

    local maxw = 0
    local maxx = 0
    for _, v in ipairs(geometries) do
        if v.width > maxw then maxw = v.width end
        if v.x > maxx then maxx = v.x end
    end

    geometries.free.width = geometries.free.width - maxw
    geometries.free.x = geometries.free.x + maxw

    geometries.free.height = nelements * height
    geometries.free.y = 0

    return geometries
end
