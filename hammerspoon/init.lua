local meta = {"cmd", "shift", "ctrl"}
local hyper = {"ctrl", "alt", "shift"}

stackline = require "stackline"
stacklineConf = require 'stackline/conf'

stacklineConf.appearance.size = 24
stacklineConf.appearance.iconPadding = 0
stacklineConf.appearance.shouldFade = false
stacklineConf.appearance.radius = 3
stacklineConf.appearance.offset.x = 4
stackline:init(stacklineConf)

-- -- print('stackline!', stackline.config.set)
-- stackline.config:set('appearance.size', 20)
-- stackline.config:set('appearance.iconPadding', 0)
-- stackline.config:set('appearance.shouldFade', false)
-- stackline.config:set('appearance.radius', 1)
-- stackline.config:set('apperance.offset.x', 0)

-- stackline.config.set('paths.yabai', '/opt/homebrew/bin/yabai')

hs.ipc.cliInstall()

-- disable animations
hs.window.animationDuration = 0

-- hide window shadows
hs.window.setShadows(false)

local fnutils = require "hs.fnutils"
local partial = fnutils.partial
local indexOf = fnutils.indexOf
local filter = fnutils.filter

local window = require "hs.window"
local alert = require "hs.alert"
local grid = require "hs.grid"

require "fntools"
require "extensions"

hs.crash.crashLogToNSLog = true

------
-- Yabai
-----
-- hs.hotkey.bind(meta, "j", function() yabai({"-m", "window", "--focus", "north"}) end)
-- hs.hotkey.bind(meta, "k", function() yabai({"-m", "window", "--focus", "south"}) end)
-- hs.hotkey.bind(meta, "h", function() yabai({"-m", "window", "--focus", "west"}) end)
-- hs.hotkey.bind(meta, "l", function() yabai({"-m", "window", "--focus", "east"}) end)

-- hs.hotkey.bind(meta, '1', function() yabai({'-m','space','--focus','Work'}) end)
-- hs.hotkey.bind(meta, '2', function() yabai({'-m','space','--focus','Comms'}) end)
-- hs.hotkey.bind(meta, '3', function() yabai({'-m','space','--focus','Tools'}) end)
-- hs.hotkey.bind(meta, '4', function() yabai({'-m','space','--focus','Media'}) end)
-- hs.hotkey.bind(meta, '5', function() yabai({'-m','space','--focus','Social'}) end)

-- hs.hotkey.bind(meta, "s", function() yabai({'-m','window','--stack','prev'}) end)
-- hs.hotkey.bind(meta, 'p', function() yabai({'-m','window','--focus','stack.prev'}) end)
-- hs.hotkey.bind(meta, 'n', function() yabai({'-m','window','--focus','stack.next'}) end)


---------------------------------------------------------
-- SCREENS
---------------------------------------------------------

-- hs.hotkey.bind(hyper, "z", function()
--   local win = hs.window.focusedWindow()
--   if win then
--     win:moveToScreen(win:screen():previous(), false, true, .1)
--   end
--   appStates:save()
-- end)
-- hs.hotkey.bind(meta, "h", function()
--   local win = hs.window.focusedWindow()
--   if win then
--     win:moveToScreen(win:screen():previous(), false, true, .1)
--   end
--   appStates:save()
-- end)
-- hs.hotkey.bind(meta, "l", function()
--   local win = hs.window.focusedWindow()
--   if win then
--     win:moveToScreen(win:screen():next(), false, true, .1)
--   end
--   appStates:save()
-- end)

---------------------------------------------------------
-- APP HOTKEYS
---------------------------------------------------------

hs.hotkey.bind(hyper, "1", simpleLauncher("com.agilebits.onepassword7"))
hs.hotkey.bind(hyper, "a", simpleLauncher("com.apple.Safari"))
hs.hotkey.bind(hyper, "c", simpleLauncher("com.hnc.Discord"))
hs.hotkey.bind(hyper, "d", simpleLauncher("com.google.Chrome"))
hs.hotkey.bind(hyper, "e", simpleLauncher("com.tinyspeck.slackmacgap"))
hs.hotkey.bind(hyper, "r", simpleLauncher("com.brave.Browser"))
hs.hotkey.bind(hyper, "f", simpleLauncher("com.googlecode.iterm2"))
hs.hotkey.bind(hyper, "g", simpleLauncher("com.microsoft.VSCode"))
hs.hotkey.bind(hyper, "i", simpleLauncher("com.operasoftware.Opera"))
hs.hotkey.bind(hyper, "n", simpleLauncher("com.spotify.client"))
hs.hotkey.bind(hyper, "o", simpleLauncher("com.readdle.smartemail-Mac"))
hs.hotkey.bind(hyper, "p", simpleLauncher("ru.keepcoder.Telegram"))
hs.hotkey.bind(hyper, "s", simpleLauncher("at.eggerapps.Postico"))
hs.hotkey.bind(hyper, "t", simpleLauncher("com.apple.MobileSMS"))
hs.hotkey.bind(hyper, "y", simpleLauncher("org.mozilla.firefox"))
hs.hotkey.bind(hyper, "u", simpleLauncher("com.flexibits.fantastical2.mac"))
hs.hotkey.bind(hyper, "w", simpleLauncher("com.apple.Dictionary"))
hs.hotkey.bind(hyper, "x", simpleLauncher("com.apple.dt.Xcode"))
-- hs.hotkey.bind(hyper, "z", simpleLauncher("us.zoom.xos"))
hs.hotkey.bind(hyper, "`", function() os.execute( "open ~" ) end )

-- hs.hotkey.bind(hyper, "m", fullScreenCurrent)
-- hs.hotkey.bind(hyper, "D", screenToRight)
-- hs.hotkey.bind(hyper, "A", screenToLeft)

---------------------------------------------------------
-- ON-THE-FLY KEYBIND
---------------------------------------------------------

-- Temporarily bind an application to be toggled by the V key
-- useful for once-in-a-while applications like Preview
local boundApplication = nil

hs.hotkey.bind(hyper, "b", function()
  local appName = hs.window.focusedWindow():application():title()
  local bundleID = hs.window.focusedWindow():application():bundleID()

  if boundApplication then
    boundApplication:disable()
  end

  boundApplication = hs.hotkey.bind(hyper, "v", simpleLauncher(bundleID))

  -- https://github.com/Hammerspoon/hammerspoon/issues/184#issuecomment-102835860
  boundApplication:disable()
  boundApplication:enable()

  hs.alert(string.format("Binding: \"%s\" => ⌘ + V", appName))
end)

-- # RESIZE

---------------------------------------------------------
-- KEYBOARD SIZE MANIPULATION
---------------------------------------------------------
-- HJKL Resize
-- local resizeMappings = {
--   h=hs.layout.left50,
--   j={x=0, y=0.5, w=1, h=0.5},
--   k={x=0, y=0, w=1, h=0.5},
--   l=hs.layout.right50,
--   m={x=0, y=0, w=1, h=1}
-- }

-- for key in pairs(resizeMappings) do
--   hs.hotkey.bind(hyper, key, function()
--     local win = hs.window.focusedWindow()
--     if win then win:moveToUnit(resizeMappings[key], .1) end
--     appStates:save()
--   end)
-- end

---------------------------------------------------------
-- MISC
---------------------------------------------------------

hs.hotkey.bind(hyper, "0", function()
  hs.reload()
  hs.notify.new({title='Hammerspoon Reloaded'}):send()
end)

