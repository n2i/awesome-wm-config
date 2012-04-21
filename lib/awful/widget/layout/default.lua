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
local setmetatable = setmetatable
local util = require("awful.util")

--- Simple default layout, emulating the fallback C layout
module("awful.widget.layout.default")

local function default(bounds, widgets, screen)
    local geometries = {
        free = { x = 0, y = 0, width = 0, height = bounds.height }
    }

    local width = 0

    local keys = util.table.keys_filter(widgets, "table", "widget")

    for _, k in ipairs(keys) do
        local v = widgets[k]
        if type(v) == "table" then
            local layout = v.layout or default
            local nbounds = util.table.clone(bounds)
            local g = layout(nbounds, v, screen)
            for _, w in ipairs(g) do
                table.insert(geometries, w)
            end
        else
            if v.visible then
                local e = v:extents(screen)
                e.x = 0
                e.y = 0
                e.width = math.min(e.width, bounds.width)
                e.height = bounds.height
                width = math.max(e.width, width)

                table.insert(geometries, e)
            else
                table.insert(geometries, { x = 0, y = 0, width = 0, height = 0 })
            end
        end
    end

    geometries.free.width = bounds.width - width
    geometries.free.x = width

    return geometries
end

setmetatable(_M, { __call = function(_, ...) return default(...) end })
