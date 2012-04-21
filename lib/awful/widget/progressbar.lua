---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

local setmetatable = setmetatable
local ipairs = ipairs
local math = math
local capi = { image = image,
               widget = widget }
local layout = require("awful.widget.layout")

--- A progressbar widget.
module("awful.widget.progressbar")

local data = setmetatable({}, { __mode = "k" })

--- Set the progressbar border color.
-- If the value is nil, no border will be drawn.
-- @name set_border_color
-- @class function
-- @param progressbar The progressbar.
-- @param color The border color to set.

--- Set the progressbar foreground color as a gradient.
-- @name set_gradient_colors
-- @class function
-- @param progressbar The progressbar.
-- @param gradient_colors A table with gradients colors. The distance between each color
-- can also be specified. Example: { "red", "blue" } or { "red", "green",
-- "blue", blue = 10 } to specify blue distance from other colors.

--- Set the progressbar foreground color.
-- @name set_color
-- @class function
-- @param progressbar The progressbar.
-- @param color The progressbar color.

--- Set the progressbar background color.
-- @name set_background_color
-- @class function
-- @param progressbar The progressbar.
-- @param color The progressbar background color.

--- Set the progressbar to draw vertically. Default is false.
-- @name set_vertical
-- @class function
-- @param progressbar The progressbar.
-- @param vertical A boolean value.

--- Set the progressbar to draw ticks. Default is false.
-- @name set_ticks
-- @class function
-- @param progressbar The progressbar.
-- @param ticks A boolean value.

--- Set the progressbar ticks gap.
-- @name set_ticks_gap
-- @class function
-- @param progressbar The progressbar.
-- @param value The value.

--- Set the progressbar ticks size.
-- @name set_ticks_size
-- @class function
-- @param progressbar The progressbar.
-- @param value The value.

--- Set the maximum value the progressbar should handle.
-- @name set_max_value
-- @class function
-- @param progressbar The progressbar.
-- @param value The value.

local properties = { "width", "height", "border_color",
                     "gradient_colors", "color", "background_color",
                     "vertical", "value", "max_value",
                     "ticks", "ticks_gap", "ticks_size" }

local function update(pbar)
    local width = data[pbar].width or 100
    local height = data[pbar].height or 20
    local ticks_gap = data[pbar].ticks_gap or 1
    local ticks_size = data[pbar].ticks_size or 4

    -- Create new empty image
    local img = capi.image.argb32(width, height, nil)

    local value = data[pbar].value
    local max_value = data[pbar].max_value
    if value >= 0 then
        value = value / max_value
    end

    local over_drawn_width = width
    local over_drawn_height = height
    local border_width = 0
    if data[pbar].border_color then
        -- Draw border
        img:draw_rectangle(0, 0, width, height, false, data[pbar].border_color)
        over_drawn_width = width - 2 -- remove 2 for borders
        over_drawn_height = height - 2 -- remove 2 for borders
        border_width = 1
    end

    local angle = 270
    if data[pbar].vertical then
        angle = 180
    end

    -- Draw full gradient
    if data[pbar].gradient_colors then
        img:draw_rectangle_gradient(border_width, border_width,
                                    over_drawn_width, over_drawn_height,
                                    data[pbar].gradient_colors, angle)
    else
        img:draw_rectangle(border_width, border_width,
                           over_drawn_width, over_drawn_height,
                           true, data[pbar].color or "red")
    end

    -- Cover the part that is not set with a rectangle
    if data[pbar].vertical then
        local rel_height = math.floor(over_drawn_height * (1 - value))
        img:draw_rectangle(border_width,
                           border_width,
                           over_drawn_width,
                           rel_height,
                           true, data[pbar].background_color or "#000000aa")

        -- Place smaller pieces over the gradient if ticks are enabled
        if data[pbar].ticks then
            for i=0, height / (ticks_size+ticks_gap)-border_width do
                local rel_offset = over_drawn_height / 1 - (ticks_size+ticks_gap) * i

                if rel_offset >= rel_height then
                    img:draw_rectangle(border_width,
                                       rel_offset,
                                       over_drawn_width,
                                       ticks_gap,
                                       true, data[pbar].background_color or "#000000aa")
                end
            end
        end
    else
        local rel_x = math.ceil(over_drawn_width * value)
        img:draw_rectangle(border_width + rel_x,
                           border_width,
                           over_drawn_width - rel_x,
                           over_drawn_height,
                           true, data[pbar].background_color or "#000000aa")

        if data[pbar].ticks then
            for i=0, width / (ticks_size+ticks_gap)-border_width do
                local rel_offset = over_drawn_width / 1 - (ticks_size+ticks_gap) * i

                if rel_offset <= rel_x then
                    img:draw_rectangle(rel_offset,
                                       border_width,
                                       ticks_gap,
                                       over_drawn_height,
                                       true, data[pbar].background_color or "#000000aa")
                end
            end
        end
    end

    -- Update the image
    pbar.widget.image = img
end

--- Set the progressbar value.
-- @param pbar The progress bar.
-- @param value The progress bar value between 0 and 1.
function set_value(pbar, value)
    local value = value or 0
    local max_value = data[pbar].max_value
    data[pbar].value = math.min(max_value, math.max(0, value))
    update(pbar)
    return pbar
end

--- Set the progressbar height.
-- @param progressbar The progressbar.
-- @param height The height to set.
function set_height(progressbar, height)
    data[progressbar].height = height
    update(progressbar)
    return progressbar
end

--- Set the progressbar width.
-- @param progressbar The progressbar.
-- @param width The width to set.
function set_width(progressbar, width)
    data[progressbar].width = width
    update(progressbar)
    return progressbar
end

-- Build properties function
for _, prop in ipairs(properties) do
    if not _M["set_" .. prop] then
        _M["set_" .. prop] = function(pbar, value)
            data[pbar][prop] = value
            update(pbar)
            return pbar
        end
    end
end

--- Create a progressbar widget.
-- @param args Standard widget() arguments. You should add width and height
-- key to set progressbar geometry.
-- @return A progressbar widget.
function new(args)
    local args = args or {}
    local width = args.width or 100
    local height = args.height or 20

    args.type = "imagebox"

    local pbar = {}

    pbar.widget = capi.widget(args)
    pbar.widget.resize = false

    data[pbar] = { width = width, height = height, value = 0, max_value = 1 }

    -- Set methods
    for _, prop in ipairs(properties) do
        pbar["set_" .. prop] = _M["set_" .. prop]
    end

    pbar.layout = args.layout or layout.horizontal.leftright

    return pbar
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
