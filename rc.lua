-- Standard awesome library
-- {{{ Libraries
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

require("vicious")
---}}}

-- awful.util.spawn_with_shell("xcompmgr -cF &")

-- local home = os.getenv("HOME")
local configdir = awful.util.getdir("config")
-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(configdir .. "/zenburn/zenburn.lua")
-- beautiful.init(home .. "/.config/awesome/zenburn/zenburn.lua")

-- This is used later as the default terminal and editor to run.
-- terminal = "uxterm"
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Scrot:

scrot_cmd = "scrot -q 80 '%Y-%m-%d-%H-%M-%S-$wx$h.png' -e 'mv $f ~/Pictures/scrot/'"
scrot_hq = "scrot -q 100 '%Y-%m-%d-%H-%M-%S-$wx$h.png' -e 'mv $f ~/Pictures/scrot/'"
scrot_delay = "scrot -d 3 -q 80 '%Y-%m-%d-%H-%M-%S-$wx$h.png' -e 'mv $f ~/Pictures/scrot/'"

-- System menu items

shutdowncmd = "sudo shutdown -hP now"
restartcmd = "sudo reboot"

-- FM menu items

ranger = "uxterm -e ranger"

-- Browser menu items

elinks = "uxterm -e elinks"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ '1 ⎈⚫', '2 ✎⚫', '3 ☏⚫', '4 ⇵⚫', '5 ⎆⚫',  '6 ⛃⚫', '7 ♫⚫', '8 ✵‡' }, s, layouts[2])
end
-- }}}

-- {{{ Menu

shutdownmenu = {
	{ "shutdown", shutdowncmd },
	{ "reboot", restartcmd },
	{ "logout", awesome.quit }
}

fm_menu = {
    { "pcmanfm", "pcmanfm" },
    { "thunar", "thunar" },
    { "nautilus", "nautilus" },
    { "ranger", ranger }
}

browsers_menu = {
    { "firefox", "firefox" },
    { "chromium", "chromium" },
    { "chrome", "google-chrome" },
    { "elinks", elinks }
}

utils_menu = {
	{ "ibus", "ibus-daemon" },
	{ "shutter", "shutter" }
}

editors = {
	{ "emacs", "emacs" }, 
	{ "gvim", "gvim" }
}
mymainmenu = awful.menu({ items = { { "terminal", terminal },
									{ "editors", editors }, 
                                    { "fileman", fm_menu },
                                    { "browsers", browsers_menu },
									{ "utils", utils_menu }, 
									{ "system", shutdownmenu, beautiful.widget_st }
                                  }
                        })

-- }}}


-- {{{ Menu Launcher
n2ilauncher = awful.widget.launcher({ image = image(beautiful.n2i), menu = mymainmenu })
-- }}


-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" }, "%a %b %d, %H:%M", 60)


separator = widget({ type = "textbox" })
separator.margin = "center"
separator.text  = " ‡ "
-- separator.text  = " || "

space = widget({ type = "textbox" })
space.text = " :-: "

-- n2i icon
n2iicon = widget({ type = "imagebox" })
n2iicon.image = image(beautiful.n2i)

-- {{{ Filesystem widget

fswidget = widget({ type = "textbox" })
vicious.register(fswidget, vicious.widgets.fs, " /: [${/ used_gb}|${/ size_gb}]GB - /home: [${/home used_gb}|${/home size_gb}]GB", 300)

diskicon = widget({ type = "imagebox" })
diskicon.image = image(beautiful.widget_fs)
-- fshomewidget = widget({ type = "textbox" })
-- vicious.register(fshomewidget, vicious.widgets.fs, "", 180)


--{{{ Mem Widget
memwidget = widget({ type = "textbox" })
vicious.cache(vicious.widgets.mem)
vicious.register(memwidget, vicious.widgets.mem, " $1% [$2|$3]MB", 10)

memicon = widget({ type = "imagebox" })
memicon.image = image(beautiful.widget_mem)
--}}}


-- {{{ CPU
cpuwidget = widget({ type = "textbox" })
vicious.register(cpuwidget, vicious.widgets.cpu, " [$2%] [$3%]")

cpuicon = widget({ type = "imagebox" })
cpuicon.image = image(beautiful.widget_cpu)
--}}}
-- cpuinfo = widget({ type = "textbox" })
-- vicious.register(cpuinfo, vicious.widgets.cpuinf, "cpu: ${cpu mhz}MHz")
-- OS
-- oswidget = widget({ type = "textbox"})
-- vicious.register(oswidget,vicious.widgets.os, "System: $1 $3 ")


--{{{ Disk I/O
diowidget = widget ({ type = "textbox"})
vicious.register(diowidget, vicious.widgets.dio, "sda I/O: [${sda write_kb}|${sda read_kb}]Kb" )
--}}}


--{{{ Uptime
uptime = widget ({ type = "textbox" })
vicious.register(uptime, vicious.widgets.uptime, " $2:$3' :-: $4 $5 $6", 10)

uptimeicon = widget({ type = "imagebox" })
uptimeicon.image = image(beautiful.widget_st)
--}}}


-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
-- wibox_bot = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    --mytasklist[s] = awful.widget.tasklist(function(c)
    --                                          return awful.widget.tasklist.label.currenttags(c, s)
    --                                     end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, opacity = 1 })
--    wibox_bot[s] = awful.wibox({ position = "bottom", screen = s, height = 12 })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            n2ilauncher,
            --n2iicon,
            separator,
            mytaglist[s],
            mypromptbox[s],
            -- separator,
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        separator, mytextclock, -- clockicon,
        separator,
        s == 1 and mysystray or nil,
        separator, fswidget, diskicon,
        separator, memwidget, memicon,
        separator, cpuwidget, cpuicon,
        separator, uptime, uptimeicon,
        separator, diowidget, separator, -- oswidget,
    --    mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
--    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ }, "Print", function () awful.util.spawn(scrot_cmd) end),
    awful.key({ modkey }, "Print", function () awful.util.spawn(scrot_cmd_hq) end),
    awful.key({ modkey, "Shift" }, "Print", function () awful.util.spawn(scrot_delay) end),
--	awful.key({ modkey,           }, "n",      function () awful.util.spawn("pcmanfm") end),
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
--  awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "File Operation Progress" },
      properties = { floating = true } },
    { rule = { class = "Dialog" },
      properties = { floating = true } },
    { rule = { class = "Lxappearance" },
      properties = { floating = true } },
    { rule = { class = "xterm" },
      properties = { floating = true, opacity = 0.8 } },
    { rule = { class = "Gvim" },
      properties = { tag = tags[1][2], switchtotag = true, opacity = 0.9 } },
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][4], switchtotag = true } },
    { rule = { class = "Pidgin" },
      properties = { tag = tags[1][3], opacity = 0.9 } },
    { rule = { class = "Audacious" },
      properties = { tag = tags[1][7] } },
	{ rule = { class = "Emacs" },
	  properties = { tag = tags[1][2], switchtotag = true } },
	{ rule = { class = "Evince" },
	  properties = { tag = tags[1][5], switchtotag = true } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
-- os.execute("volumeicon &")
-- os.execute("sleep 5 && nm-applet &")
-- os.execute("sleep 10 && ibus-daemon &")
