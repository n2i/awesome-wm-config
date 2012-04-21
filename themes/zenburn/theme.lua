-------------------------------
--  "Zenburn" awesome theme  --
--    By Adrian C. (anrxc)   --
-------------------------------

-- Alternative icon sets and widget icons:
--  * http://awesome.naquadah.org/wiki/Nice_Icons

-- {{{ Main
theme = {}
theme.wallpaper_cmd = { "awsetbg /home/n2i/.config/awesome/wallpaper-1844673.jpg" }
-- theme.wallpaper_cmd = { "awsetbg /home/n2i/.config/awesome/themes/zenburn/zenburn-background.png" }
-- }}}

-- {{{ Styles
-- theme.font      = "Ubuntu Bold 8"
-- theme.font      = "Square Type B 9"
--theme.font      = "Kuro 8"
theme.font      = "JUICE Bold 7"

-- {{{ Colors
theme.fg_normal = "#dcdccc"
theme.fg_focus  = "#F0DFAF"
theme.fg_urgent = "#CC9393"
theme.bg_normal = "#3F3F3F"
theme.bg_focus  = "#1E2320"
theme.bg_urgent = "#3F3F3F"
-- }}}

-- {{{ Borders
theme.border_width  = "1"
theme.border_normal = "#c2d3d8" -- "#dcdcae"
theme.border_focus  = "#dcdcae"
theme.border_marked = "#CC9393"
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"
-- }}}
-- {{{ Icons
-- theme.widget_cpu    = theme.confdir .. "/icons/cpu.png"
-- theme.widget_bat    = theme.confdir .. "/icons/bat.png"
-- theme.widget_mem    = theme.confdir .. "/icons/mem.png"
-- theme.widget_fs     = theme.confdir .. "/icons/disk.png"
-- theme.widget_net    = theme.confdir .. "/icons/down.png"
-- theme.widget_netup  = theme.confdir .. "/icons/up.png"
-- theme.widget_wifi   = theme.confdir .. "/icons/wifi.png"
-- theme.widget_mail   = theme.confdir .. "/icons/mail.png"
-- theme.widget_mpd    = theme.confdir .. "/icons/music.png"
-- theme.widget_vol    = theme.confdir .. "/icons/vol.png"
-- theme.widget_org    = theme.confdir .. "/icons/cal.png"
-- theme.widget_date   = theme.confdir .. "/icons/time.png"
-- theme.widget_crypto = theme.confdir .. "/icons/crypto.png"
-- theme.widget_sep    = theme.confdir .. "/icons/separator.png"
-- }}}
-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- Example:
--theme.taglist_bg_focus = "#CC9393"
-- }}}

-- {{{ Widgets
-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.fg_widget        = "#AECF96"
--theme.fg_center_widget = "#88A175"
--theme.fg_end_widget    = "#FF5656"
--theme.bg_widget        = "#494B4F"
theme.border_widget    = "#3F3F3F"
-- }}}

-- {{{ Mouse finder
theme.mouse_finder_color = "#CC9393"
-- mouse_finder_[timeout|animate_timeout|radius|factor]
-- }}}

-- {{{ Menu
-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_border_color = "#dcdccc"
theme.menu_border_width= "1"
theme.menu_height = "15"
theme.menu_width  = "90"
-- }}}

-- {{{ Icons
-- {{{ Taglist
theme.taglist_squares_sel   = "/home/n2i/.config/awesome/themes/zenburn/taglist/squarefz.png"
theme.taglist_squares_unsel = "/home/n2i/.config/awesome/themes/zenburn/taglist/squarez.png"
--theme.taglist_squares_resize = "false"
-- }}}

-- {{{ Misc
-- theme.mpd_icon               = "/home/n2i/.config/awesome/icons/music.png"
theme.system_icon			 = "/home/n2i/.config/awesome/icons/power.png"
theme.n2i_icon				 = "/home/n2i/.config/awesome/n2i.png"
theme.awesome_icon           = "/home/n2i/.config/awesome/themes/zenburn/awesome-icon.png"
theme.menu_submenu_icon      = "/home/n2i/.config/awesome/themes/default/submenu.png"
theme.tasklist_floating_icon = "/home/n2i/.config/awesome/themes/default/tasklist/floatingw.png"
-- }}}

-- {{{ Layout
theme.layout_tile       = "/home/n2i/.config/awesome/themes/zenburn/layouts/tile.png"
theme.layout_tileleft   = "/home/n2i/.config/awesome/themes/zenburn/layouts/tileleft.png"
theme.layout_tilebottom = "/home/n2i/.config/awesome/themes/zenburn/layouts/tilebottom.png"
theme.layout_tiletop    = "/home/n2i/.config/awesome/themes/zenburn/layouts/tiletop.png"
theme.layout_fairv      = "/home/n2i/.config/awesome/themes/zenburn/layouts/fairv.png"
theme.layout_fairh      = "/home/n2i/.config/awesome/themes/zenburn/layouts/fairh.png"
theme.layout_spiral     = "/home/n2i/.config/awesome/themes/zenburn/layouts/spiral.png"
theme.layout_dwindle    = "/home/n2i/.config/awesome/themes/zenburn/layouts/dwindle.png"
theme.layout_max        = "/home/n2i/.config/awesome/themes/zenburn/layouts/max.png"
theme.layout_fullscreen = "/home/n2i/.config/awesome/themes/zenburn/layouts/fullscreen.png"
theme.layout_magnifier  = "/home/n2i/.config/awesome/themes/zenburn/layouts/magnifier.png"
theme.layout_floating   = "/home/n2i/.config/awesome/themes/zenburn/layouts/floating.png"
-- }}}

-- {{{ Titlebar
theme.titlebar_close_button_focus  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/close_focus.png"
theme.titlebar_close_button_normal = "/home/n2i/.config/awesome/themes/zenburn/titlebar/close_normal.png"

theme.titlebar_ontop_button_focus_active  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = "/home/n2i/.config/awesome/themes/zenburn/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = "/home/n2i/.config/awesome/themes/zenburn/titlebar/ontop_normal_inactive.png"

theme.titlebar_sticky_button_focus_active  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = "/home/n2i/.config/awesome/themes/zenburn/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = "/home/n2i/.config/awesome/themes/zenburn/titlebar/sticky_normal_inactive.png"

theme.titlebar_floating_button_focus_active  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = "/home/n2i/.config/awesome/themes/zenburn/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = "/home/n2i/.config/awesome/themes/zenburn/titlebar/floating_normal_inactive.png"

theme.titlebar_maximized_button_focus_active  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = "/home/n2i/.config/awesome/themes/zenburn/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = "/home/n2i/.config/awesome/themes/zenburn/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = "/home/n2i/.config/awesome/themes/zenburn/titlebar/maximized_normal_inactive.png"
-- }}}
-- }}}

return theme
