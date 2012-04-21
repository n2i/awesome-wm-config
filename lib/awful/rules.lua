---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2009 Julien Danjou
-- @release v3.4.9
---------------------------------------------------------------------------

-- Grab environment we need
local client = client
local table = table
local type = type
local ipairs = ipairs
local pairs = pairs
local aclient = require("awful.client")
local atag = require("awful.tag")

--- Apply rules to clients at startup.
module("awful.rules")

--- This is the global rules table.
-- <p>You should fill this table with your rule and properties to apply.
-- For example, if you want to set xterm maximized at startup, you can add:
-- <br/>
-- <code>
-- { rule = { class = "xterm" },
--   properties = { maximized_vertical = true, maximized_horizontal = true } }
-- </code>
-- </p>
-- <p>If you want to set mplayer floating at startup, you can add:
-- <br/>
-- <code>
-- { rule = { name = "MPlayer" },
--   properties = { floating = true } }
-- </code>
-- </p>
-- <p>If you want to put Firefox on a specific tag at startup, you
-- can add:
-- <br/>
-- <code>
-- { rule = { instance = "firefox" }
--   properties = { tag = mytagobject } }
-- </code>
-- </p>
-- <p>If you want to put Emacs on a specific tag at startup, and
-- immediately switch to that tag you can add:
-- <br/>
-- <code>
-- { rule = { class = "Emacs" }
--   properties = { tag = mytagobject, switchtotag = true } }
-- </code>
-- </p>
-- <p>If you want to apply a custom callback to execute when a rule matched, you
-- can add:
-- <br/>
-- <code>
-- { rule = { class = "dosbox" },
--   callback = awful.placement.centered }
-- </code>
-- </p>
-- <p>Note that all "rule" entries need to match. If any of the entry does not
-- match, the rule won't be applied.</p>
-- <p>If a client matches multiple rules, their applied in the order they are
-- put in this global rules table. If the value of a rule is a string, then the
-- match function is used to determine if the client matches the rule.</p>
--
-- <p> To match multiple clients to a rule one need to use slightly different 
-- syntax:
-- <br/>
-- <code>
-- { rule_any = { class = { "MPlayer", "Nitrogen" }, instance = { "xterm" } },
--   properties = { floating = true } }
-- </code>
-- </p>
--
-- @class table
-- @name rules
rules = {}

--- Check if a client match a rule.
-- @param c The client.
-- @param rule The rule to check.
-- @return True if it matches, false otherwise.
function match(c, rule)
    for field, value in pairs(rule) do
        if c[field] then
            if type(c[field]) == "string" then
                if not c[field]:match(value) and c[field] ~= value then
                    return false
                end
            elseif c[field] ~= value then
                return false
            end
        else
            return false
        end
    end
    return true
end

--- Check if a client match a rule. Multiple clients can be matched
-- @param c The client.
-- @param rules The rule to check.
-- @return True if at least one rule is matched, false otherwise.
function match_any(c, rule)
    for field, values in pairs(rule) do
        if c[field] then
            for _, value in ipairs(values) do
                if c[field] == value then
                    return true
                elseif type(c[field]) == "string" and c[field]:match(value) then
                    return true
                end
            end
        end
    end
    return false
end

--- Apply rules to a client.
-- @param c The client.
function apply(c)
    local props = {}
    local callbacks = {}
    for _, entry in ipairs(rules) do
        if  (entry.rule and match(c, entry.rule)) or
            (entry.rule_any and match_any(c, entry.rule_any)) then
            if entry.properties then
                for property, value in pairs(entry.properties) do
                    props[property] = value
                end
            end
            if entry.callback then
                table.insert(callbacks, entry.callback)
            end
        end
    end

    for property, value in pairs(props) do
        if property == "floating" then
            aclient.floating.set(c, value)
        elseif property == "tag" then
            c:tags({ value })
            c.screen = value.screen
        elseif property == "switchtotag" and value and props.tag then
            atag.viewonly(props.tag)
        elseif property == "height" or property == "width" or
                property == "x" or property == "y" then
            local geo = c:geometry();
            geo[property] = value
            c:geometry(geo);
        elseif type(c[property]) == "function" then
            c[property](c, value)
        else
            c[property] = value
        end
    end

    -- If untagged, stick the client on the current one.
    if #c:tags() == 0 then
        atag.withcurrent(c)
    end

    -- Apply all callbacks from matched rules.
    for i, callback in pairs(callbacks) do
        callback(c)
    end

    -- Do this at last so we do not erase things done by the focus
    -- signal.
    if props.focus then
        client.focus = c
    end
end

client.add_signal("manage", apply)
client.remove_signal("manage", atag.withcurrent)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
