---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local util = require("awful.util")
local tag = require("awful.tag")
local pairs = pairs
local type = type
local ipairs = ipairs
local table = table
local math = math
local setmetatable = setmetatable
local capi =
{
    client = client,
    mouse = mouse,
    screen = screen,
}

--- Useful client manipulation functions.
module("awful.client")

-- Private data
data = {}
data.focus = {}
data.urgent = {}
data.marked = {}
data.properties = setmetatable({}, { __mode = 'k' })

-- Functions
urgent = {}
focus = {}
focus.history = {}
swap = {}
floating = {}
dockable = {}
property = {}

--- Get the first client that got the urgent hint.
-- @return The first urgent client.
function urgent.get()
    if #data.urgent > 0 then
        return data.urgent[1]
    else
        -- fallback behaviour: iterate through clients and get the first urgent
        local clients = capi.client.get()
        for k, cl in pairs(clients) do
            if cl.urgent then
                return cl
            end
        end
    end
end

--- Jump to the client that received the urgent hint first.
function urgent.jumpto()
    local c = urgent.get()
    if c then
        local s = capi.client.focus and capi.client.focus.screen or capi.mouse.screen
        -- focus the screen
        if s ~= c.screen then
            capi.mouse.screen = c.screen
        end
        -- focus the tag only if the client is not sticky
        if not c.sticky then
           tag.viewonly(c:tags()[1])
        end
        -- focus the client
        capi.client.focus = c
        c:raise()
    end
end

--- Adds client to urgent stack.
-- @param c The client object.
-- @param prop The property which is updated.
function urgent.add(c, prop)
    if type(c) == "client" and prop == "urgent" and c.urgent then
        table.insert(data.urgent, c)
    end
end

--- Remove client from urgent stack.
-- @param c The client object.
function urgent.delete(c)
    for k, cl in ipairs(data.urgent) do
        if c == cl then
            table.remove(data.urgent, k)
            break
        end
    end
end

--- Remove a client from the focus history
-- @param c The client that must be removed.
function focus.history.delete(c)
    for k, v in ipairs(data.focus) do
        if v == c then
            table.remove(data.focus, k)
            break
        end
    end
end

--- Filter out window that we do not want handled by focus.
-- This usually means that desktop, dock and splash windows are
-- not registered and cannot get focus.
-- @param c A client.
-- @return The same client if it's ok, nil otherwise.
function focus.filter(c)
    if c.type == "desktop"
        or c.type == "dock"
        or c.type == "splash"
        or not c.focusable then
        return nil
    end
    return c
end

--- Update client focus history.
-- @param c The client that has been focused.
function focus.history.add(c)
    if focus.filter(c) then
        -- Remove the client if its in stack
        focus.history.delete(c)
        -- Record the client has latest focused
        table.insert(data.focus, 1, c)
    end
end

--- Get the latest focused client for a screen in history.
-- @param screen The screen number to look for.
-- @param idx The index: 0 will return first candidate,
-- 1 will return second, etc.
-- @return A client.
function focus.history.get(screen, idx)
    -- When this counter is equal to idx, we return the client
    local counter = 0
    local vc = visible(screen)
    for k, c in ipairs(data.focus) do
        if c.screen == screen then
            for j, vcc in ipairs(vc) do
                if vcc == c then
                    if counter == idx then
                        return c
                    end
                    -- We found one, increment the counter only.
                    counter = counter + 1
                    break
                end
            end
        end
    end
    -- Argh nobody found in history, give the first one visible if there is one
    -- that passes the filter.
    if counter == 0 then
        for k, v in ipairs(vc) do
            if focus.filter(v) then
                return v
            end
        end
    end
end

--- Focus the previous client in history.
function focus.history.previous()
    local sel = capi.client.focus
    local s
    if sel then
        s = sel.screen
    else
        s = capi.mouse.screen
    end
    local c = focus.history.get(s, 1)
    if c then capi.client.focus = c end
end

--- Get visible clients from a screen.
-- @param screen The screen number, or nil for all screens.
-- @return A table with all visible clients.
function visible(screen)
    local cls = capi.client.get(screen)
    local vcls = {}
    for k, c in pairs(cls) do
        if c:isvisible() then
            table.insert(vcls, c)
        end
    end
    return vcls
end

--- Get visible and tiled clients
-- @param screen The screen number, or nil for all screens.
-- @return A tabl with all visible and tiled clients.
function tiled(screen)
    local clients = visible(screen)
    local tclients = {}
    -- Remove floating clients
    for k, c in pairs(clients) do
        if not floating.get(c) then
            table.insert(tclients, c)
        end
    end
    return tclients
end

--- Get a client by its relative index to the focused window.
-- @usage Set i to 1 to get next, -1 to get previous.
-- @param i The index.
-- @param c Optional client.
-- @return A client, or nil if no client is available.
function next(i, c)
    -- Get currently focused client
    local sel = c or capi.client.focus
    if sel then
        -- Get all visible clients
        local cls = visible(sel.screen)
        local fcls = {}
        -- Remove all non-normal clients
        for idx, c in ipairs(cls) do
            if focus.filter(c) or c == sel then
                table.insert(fcls, c)
            end
        end
        cls = fcls
        -- Loop upon each client
        for idx, c in ipairs(cls) do
            if c == sel then
                -- Cycle
                return cls[util.cycle(#cls, idx + i)]
            end
        end
    end
end

-- Return true whether client B is in the right direction
-- compared to client A.
-- @param dir The direction.
-- @param cA The first client.
-- @param cB The second client.
-- @return True if B is in the direction of A.
local function is_in_direction(dir, cA, cB)
    local gA = cA:geometry()
    local gB = cB:geometry()
    if dir == "up" then
        return gA.y > gB.y
    elseif dir == "down" then
        return gA.y < gB.y
    elseif dir == "left" then
        return gA.x > gB.x
    elseif dir == "right" then
        return gA.x < gB.x
    end
    return false
end

-- Calculate distance between two points.
-- i.e: if we want to move to the right, we will take the right border
-- of the currently focused client and the left side of the checked client.
-- This avoid the focus of an upper client when you move to the right in a
-- tilebottom layout with nmaster=2 and 5 clients open, for instance.
-- @param dir The direction.
-- @param cA The first client.
-- @param cB The second client.
-- @return The distance between the clients.
local function calculate_distance(dir, cA, cB)
    local gA = cA:geometry()
    local gB = cB:geometry()

    if dir == "up" then
        gB.y = gB.y + gB.height
    elseif dir == "down" then
        gA.y = gA.y + gA.height
    elseif dir == "left" then
        gB.x = gB.x + gB.width
    elseif dir == "right" then
        gA.x = gA.x + gA.width
    end

    return math.sqrt(math.pow(gB.x - gA.x, 2) + math.pow(gB.y - gA.y, 2))
end

-- Get the nearest client in the given direction.
-- @param dir The direction, can be either "up", "down", "left" or "right".
-- @param c Optional client to get a client relative to. Else focussed is used.
local function get_client_in_direction(dir, c)
    local sel = c or capi.client.focus
    if sel then
        local geometry = sel:geometry()
        local dist, dist_min
        local target = nil
        local cls = visible(sel.screen)

        -- We check each client.
        for i, c in ipairs(cls) do
            -- Check geometry to see if client is located in the right direction.
            if is_in_direction(dir, sel, c) then

                -- Calculate distance between focused client and checked client.
                dist = calculate_distance(dir, sel, c)

                -- If distance is shorter then keep the client.
                if not target or dist < dist_min then
                    target = c
                    dist_min = dist
                end
            end
        end

        return target
    end
end

--- Focus a client by the given direction.
-- @param dir The direction, can be either "up", "down", "left" or "right".
-- @param c Optional client.
function focus.bydirection(dir, c)
    local sel = c or capi.client.focus
    if sel then
        local target = get_client_in_direction(dir, sel)

        -- If we found a client to focus, then do it.
        if target then
            capi.client.focus = target
        end
    end
end

--- Focus a client by its relative index.
-- @param i The index.
-- @param c Optional client.
function focus.byidx(i, c)
    local target = next(i, c)
    if target then
        capi.client.focus = target
    end
end

--- Swap a client with another client in the given direction
-- @param dir The direction, can be either "up", "down", "left" or "right".
-- @param c Optional client.
function swap.bydirection(dir, c)
    local sel = c or capi.client.focus
    if sel then
        local target = get_client_in_direction(dir, sel)

        -- If we found a client to swap with, then go for it
        if target then
            target:swap(sel)
        end
    end
end

--- Swap a client by its relative index.
-- @param i The index.
-- @param c Optional client, otherwise focused one is used.
function swap.byidx(i, c)
    local sel = c or capi.client.focus
    local target = next(i, sel)
    if target then
        target:swap(sel)
    end
end

--- Cycle clients.
-- @param clockwise True to cycle clients clockwise.
-- @param screen Optional screen where to cycle clients.
function cycle(clockwise, screen)
    local screen = screen or capi.mouse.screen
    local cls = visible(screen)
    -- We can't rotate without at least 2 clients, buddy.
    if #cls >= 2 then
        local c = table.remove(cls, 1)
        if clockwise then
            for i = #cls, 1, -1 do
                c:swap(cls[i])
            end
        else
            for _, rc in pairs(cls) do
                c:swap(rc)
            end
        end
    end
end

--- Get the master window.
-- @param screen Optional screen number, otherwise screen mouse is used.
-- @return The master window.
function getmaster(screen)
    local s = screen or capi.mouse.screen
    return visible(s)[1]
end

--- Set the client as slave: put it at the end of other windows.
-- @param c The window to set as slave.
function setslave(c)
    local cls = visible(c.screen)
    for k, v in pairs(cls) do
        c:swap(v)
    end
end

--- Move/resize a client relative to current coordinates.
-- @param x The relative x coordinate.
-- @param y The relative y coordinate.
-- @param w The relative width.
-- @param h The relative height.
-- @param c The optional client, otherwise focused one is used.
function moveresize(x, y, w, h, c)
    local sel = c or capi.client.focus
    local geometry = sel:geometry()
    geometry['x'] = geometry['x'] + x
    geometry['y'] = geometry['y'] + y
    geometry['width'] = geometry['width'] + w
    geometry['height'] = geometry['height'] + h
    sel:geometry(geometry)
end

--- Move a client to a tag.
-- @param target The tag to move the client to.
-- @param c Optional client to move, otherwise the focused one is used.
function movetotag(target, c)
    local sel = c or capi.client.focus
    if sel and target.screen then
        -- Set client on the same screen as the tag.
        sel.screen = target.screen
        sel:tags({ target })
    end
end

--- Toggle a tag on a client.
-- @param target The tag to toggle.
-- @param c Optional client to toggle, otherwise the focused one is used.
function toggletag(target, c)
    local sel = c or capi.client.focus
    -- Check that tag and client screen are identical
    if sel and sel.screen == target.screen then
        local tags = sel:tags()
        local index = nil;
        for i, v in ipairs(tags) do
            if v == target then
                index = i
                break
            end
        end
        if index then
            -- If it's the only tag for the window, stop.
            if #tags == 1 then return end
            tags[index] = nil
        else
            tags[#tags + 1] = target
        end
        sel:tags(tags)
    end
end

--- Move a client to a screen. Default is next screen, cycling.
-- @param c The client to move.
-- @param s The screen number, default to current + 1.
function movetoscreen(c, s)
    local sel = c or capi.client.focus
    if sel then
        local sc = capi.screen.count()
        if not s then
            s = sel.screen + 1
        end
        if s > sc then s = 1 elseif s < 1 then s = sc end
        sel.screen = s
        capi.mouse.coords(capi.screen[s].geometry)
        capi.client.focus = sel
    end
end

--- Mark a client, and then call 'marked' hook.
-- @param c The client to mark, the focused one if not specified.
-- @return True if the client has been marked. False if the client was already marked.
function mark(c)
    local cl = c or capi.client.focus
    if cl then
        for k, v in pairs(data.marked) do
            if cl == v then
                return false
            end
        end

        table.insert(data.marked, cl)

        -- Call callback
        cl:emit_signal("marked")
        return true
    end
end

--- Unmark a client and then call 'unmarked' hook.
-- @param c The client to unmark, or the focused one if not specified.
-- @return True if the client has been unmarked. False if the client was not marked.
function unmark(c)
    local cl = c or capi.client.focus

    for k, v in pairs(data.marked) do
        if cl == v then
            table.remove(data.marked, k)
            cl:emit_signal("unmarked")
            return true
        end
    end

    return false
end

--- Check if a client is marked.
-- @param c The client to check, or the focused one otherwise.
function ismarked(c)
    local cl = c or capi.client.focus
    if cl then
        for k, v in pairs(data.marked) do
            if cl == v then
                return true
            end
        end
    end
    return false
end

--- Toggle a client as marked.
-- @param c The client to toggle mark.
function togglemarked(c)
    local cl = c or capi.client.focus

    if not mark(c) then
        unmark(c)
    end
end

--- Return the marked clients and empty the marked table.
-- @return A table with all marked clients.
function getmarked()
    for k, v in pairs(data.marked) do
        v:emit_signal("unmarked")
    end

    t = data.marked
    data.marked = {}
    return t
end

--- Set a client floating state, overriding auto-detection.
-- Floating client are not handled by tiling layouts.
-- @param c A client.
-- @param s True or false.
function floating.set(c, s)
    local c = c or capi.client.focus
    if c and property.get(c, "floating") ~= s then
        property.set(c, "floating", s)
        local screen = c.screen
        if s == true then
            c:geometry(property.get(c, "floating_geometry"))
        end
        c.screen = screen
    end
end

local function store_floating_geometry(c)
    if floating.get(c) then
        property.set(c, "floating_geometry", c:geometry())
    end
end

-- Store the initial client geometry.
capi.client.add_signal("new", function(c)
    local function store_init_geometry(c)
        property.set(c, "floating_geometry", c:geometry())
        c:remove_signal("property::geometry", store_init_geometry)
    end
    c:add_signal("property::geometry", store_init_geometry)
end)

capi.client.add_signal("manage", function(c)
    c:add_signal("property::geometry", store_floating_geometry)
end)

--- Return if a client has a fixe size or not.
-- @param c The client.
function isfixed(c)
    local c = c or capi.client.focus
    if not c then return end
    local h = c.size_hints
    if h.min_width and h.max_width
        and h.max_height and h.min_height
        and h.min_width > 0 and h.max_width > 0
        and h.max_height > 0 and h.min_height > 0
        and h.min_width == h.max_width
        and h.min_height == h.max_height then
        return true
    end
    return false
end

--- Get a client floating state.
-- @param c A client.
-- @return True or false. Note that some windows might be floating even if you
-- did not set them manually. For example, windows with a type different than
-- normal.
function floating.get(c)
    local c = c or capi.client.focus
    if c then
        local value = property.get(c, "floating")
        if value ~= nil then
            return value
        end
        if c.type ~= "normal"
            or c.fullscreen
            or c.maximized_vertical
            or c.maximized_horizontal
            or isfixed(c) then
            return true
        end
        return false
    end
end

--- Toggle the floating state of a client between 'auto' and 'true'.
-- @param c A client.
function floating.toggle(c)
    local c = c or capi.client.focus
    -- If it has been set to floating
    if property.get(c, "floating") then
        floating.set(c, nil)
    else
        floating.set(c, true)
    end
end

--- Remove the floating information on a client.
-- @param c The client.
function floating.delete(c)
    floating.set(c, nil)
end

-- Normalize a set of numbers to 1
-- @param set the set of numbers to normalize
-- @param num the number of numbers to normalize
local function normalize(set, num)
    local num = num or #set
    local total = 0
    if num then
        for i = 1,num do
            total = total + set[i]
        end
        for i = 1,num do
            set[i] = set[i] / total
        end
    else
        for i,v in ipairs(set) do
            total = total + v
        end

        for i,v in ipairs(set) do
            set[i] = v / total
        end
    end
end

--- Calculate a client's column number, index in that column, and
-- number of visible clients in this column.
-- @param c the client
-- @return col the column number
-- @return idx index of the client in the column
-- @return num the number of visible clients in the column
function idx(c)
    local c = c or capi.client.focus
    if not c then return end

    local clients = tiled(c.screen)
    local idx = nil
    for k, cl in ipairs(clients) do
        if cl == c then
            idx = k
            break
        end
    end

    local t = tag.selected(c.screen)
    local nmaster = tag.getnmaster(t)
    if idx <= nmaster then
        return {idx = idx, col=0, num=nmaster}
    end
    local nother = #clients - nmaster
    idx = idx - nmaster

    -- rather than regenerate the column number we can calculate it
    -- based on the how the tiling algorithm places clients we calculate
    -- the column, we could easily use the for loop in the program but we can
    -- calculate it.
    local ncol = tag.getncol(t)
    -- minimum number of clients per column
    local percol = math.floor(nother / ncol)
    -- number of columns with an extra client
    local overcol = math.mod(nother, ncol)
    -- number of columns filled with [percol] clients
    local regcol = ncol - overcol

    local col = math.floor( (idx - 1) / percol) + 1
    if  col > regcol then
        -- col = math.floor( (idx - (percol*regcol) - 1) / (percol + 1) ) + regcol + 1
        -- simplified
        col = math.floor( (idx + regcol + percol) / (percol+1) )
        -- calculate the index in the column
        idx = idx - percol*regcol - (col - regcol - 1) * (percol+1)
        percol = percol+1
    else
        idx = idx - percol*(col-1)
    end

    return {idx = idx, col=col, num=percol}
end


--- Set the window factor of a client
-- @param wfact the window factor value
-- @param c the client
function setwfact(wfact, c)
    -- get the currently selected window
    local c = c or capi.client.focus
    if not c or not c:isvisible() then return end

    local t = tag.selected(c.screen)
    local w = idx(c)

    local cls = tiled(t.screen)
    local nmaster = tag.getnmaster(t)

    -- n is the number of windows currently visible for which we have to be concerned with the properties
    local data = tag.getproperty(t, "windowfact") or {}
    local colfact = data[w.col]

    colfact[w.idx] = wfact
    rest = 1-wfact

    -- calculate the current denominator
    local total = 0
    for i = 1,w.num do
        if i ~= w.idx then
            total = total + colfact[i]
        end
    end

    -- normalize the windows
    for i = 1,w.num do
        if i ~= w.idx then
            colfact[i] = (colfact[i] * rest) / total
        end
    end

    t:emit_signal("property::windowfact")
end

--- Increment a client's window factor
-- @param add amount to increase the client's window
-- @param c the client
function incwfact(add, c)
    local c = c or capi.client.focus
    if not c then return end

    local t = tag.selected(c.screen)

    local w = idx(c)

    local nmaster = tag.getnmaster(t)
    local data = tag.getproperty(t, "windowfact") or {}
    local colfact = data[w.col]
    curr = colfact[w.idx] or 1
    colfact[w.idx] = curr + add

    -- keep our ratios normalized
    normalize(colfact, w.num)

    t:emit_signal("property::windowfact")
end

--- Get a client dockable state.
-- @param c A client.
-- @return True or false. Note that some windows might be dockable even if you
-- did not set them manually. For example, windows with a type "utility", "toolbar" 
-- or "dock"
function dockable.get(c)
    local value = property.get(c, "dockable")

    -- Some sane defaults
    if value == nil then
        if (c.type == "utility" or c.type == "toolbar" or c.type == "dock") then
            value = true
        else
            value = false
        end
    end

    return value
end

--- Set a client dockable state, overriding auto-detection.
-- With this enabled you can dock windows by moving them from the center
-- to the edge of the workarea.
-- @param c A client.
-- @param value True or false.
function dockable.set(c, value)
    property.set(c, "dockable", value)
end

--- Get a client property.
-- @param c The client.
-- @param prop The property name.
-- @return The property.
function property.get(c, prop)
    if data.properties[c] then
        return data.properties[c][prop]
    end
end

--- Set a client property.
-- This properties are internal to awful. Some are used to move clients, etc.
-- @param c The client.
-- @param prop The property name.
-- @param value The value.
function property.set(c, prop, value)
    if not data.properties[c] then
        data.properties[c] = {}
    end
    data.properties[c][prop] = value
    c:emit_signal("property::" .. prop)
end

-- Register standards signals
capi.client.add_signal("focus", focus.history.add)
capi.client.add_signal("unmanage", focus.history.delete)

capi.client.add_signal("manage", function(c) c:add_signal("property::urgent", urgent.add) end)
capi.client.add_signal("focus", urgent.delete)
capi.client.add_signal("unmanage", urgent.delete)

capi.client.add_signal("unmanage", floating.delete)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
