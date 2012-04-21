---------------------------------------------------------------------------
-- @author Uli Schlachter &lt;psychon@znc.in&gt;
-- @copyright 2009 Uli Schlachter
-- @copyright 2008 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local ipairs = ipairs

module("awful.layout.suit.spiral")

local function spiral(p, spiral)
    local wa = p.workarea
    local cls = p.clients
    local n = #cls

    for k, c in ipairs(cls) do
        if k < n then
            if k % 2 == 0 then
                wa.height = wa.height / 2
            else
                wa.width = wa.width / 2
            end
        end

        if k % 4 == 0 and spiral then
            wa.x = wa.x - wa.width
        elseif k % 2 == 0 or
            (k % 4 == 3 and k < n and spiral) then
            wa.x = wa.x + wa.width
        end

        if k % 4 == 1 and k ~= 1 and spiral then
            wa.y = wa.y - wa.height
        elseif k % 2 == 1 and k ~= 1 or
            (k % 4 == 0 and k < n and spiral) then
            wa.y = wa.y + wa.height
        end

        c:geometry(wa)
    end
end

--- Dwindle layout
dwindle = {}
dwindle.name = "dwindle"
function dwindle.arrange(p)
    return spiral(p, false)
end

--- Spiral layout
name = "spiral"
function arrange(p)
    return spiral(p, true)
end

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
