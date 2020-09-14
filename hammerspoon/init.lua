local hyper = {"ctrl", "alt", "shift"}
local cmdHyper = {"cmd", "ctrl", "alt", "shift"}

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

---------------------------------------------------------
-- SCREENS
---------------------------------------------------------

hs.hotkey.bind(hyper, "z", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToScreen(win:screen():previous(), false, true, .1)
  end
  appStates:save()
end)

---------------------------------------------------------
-- APP HOTKEYS
---------------------------------------------------------

hs.hotkey.bind(hyper, "1", launchOrCycleFocus("com.agilebits.onepassword7"))
hs.hotkey.bind(hyper, "a", launchOrCycleFocus("com.apple.Safari"))
hs.hotkey.bind(hyper, "c", launchOrCycleFocus("com.bohemiancoding.sketch3"))
hs.hotkey.bind(hyper, "d", launchOrCycleFocus("com.google.Chrome"))
hs.hotkey.bind(hyper, "e", launchOrCycleFocus("com.tinyspeck.slackmacgap"))
-- hs.hotkey.bind(hyper, "f", launchOrCycleFocus("Emacs"))
hs.hotkey.bind(hyper, "f", launchOrCycleFocus("com.googlecode.iterm2"))
-- hs.hotkey.bind(hyper, "g", launchOrCycleFocus("Microsoft Remote Desktop"))
-- hs.hotkey.bind(hyper, "i", launchOrCycleFocus("Safari Technology Preview"))
hs.hotkey.bind(hyper, "n", launchOrCycleFocus("com.spotify.client"))
hs.hotkey.bind(hyper, "o", launchOrCycleFocus("com.google.Chrome.canary"))
hs.hotkey.bind(hyper, "p", launchOrCycleFocus("ru.keepcoder.Telegram"))
hs.hotkey.bind(hyper, "r", launchOrCycleFocus("notion.id"))
hs.hotkey.bind(hyper, "s", launchOrCycleFocus("com.apple.iphonesimulator"))
hs.hotkey.bind(hyper, "t", launchOrCycleFocus("com.apple.iChat"))
hs.hotkey.bind(hyper, "y", launchOrCycleFocus("com.linear"))
hs.hotkey.bind(hyper, "u", launchOrCycleFocus("com.flexibits.fantastical2.mac"))
hs.hotkey.bind(hyper, "w", launchOrCycleFocus("com.apple.Dictionary"))
hs.hotkey.bind(hyper, "x", launchOrCycleFocus("com.apple.dt.Xcode"))
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

  if boundApplication then
    boundApplication:disable()
  end

  boundApplication = hs.hotkey.bind(hyper, "V", launchOrCycleFocus(appName))

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
local resizeMappings = {
  h=hs.layout.left50,
  j={x=0, y=0.5, w=1, h=0.5},
  k={x=0, y=0, w=1, h=0.5},
  l=hs.layout.right50,
  m={x=0, y=0, w=1, h=1}
}

for key in pairs(resizeMappings) do
  hs.hotkey.bind(hyper, key, function()
    local win = hs.window.focusedWindow()
    if win then win:moveToUnit(resizeMappings[key], .1) end
    appStates:save()
  end)
end

local rightMode = hs.hotkey.modal.new(cmdHyper, 'l')
rightMode:bind('', 'escape', function() rightMode:exit() end)
rightMode:bind(cmdHyper, 'j', function()
    local win = hs.window.focusedWindow()
    if win then win:moveToUnit({x=0.5, y=0.5, w=0.5, h=0.5}, .1) end
    appStates:save()
    rightMode:exit()
end)
rightMode:bind(cmdHyper, 'k', function()
                 local win = hs.window.focusedWindow()
                 if win then win:moveToUnit({x=0.5, y=0, w=0.5, h=0.5}, .1) end
                 appStates:save()
                 rightMode:exit()
end)

local leftMode = hs.hotkey.modal.new(cmdHyper, 'h')
leftMode:bind('', 'escape', function() leftMode:exit() end)
leftMode:bind(cmdHyper, 'j', function()
                 local win = hs.window.focusedWindow()
                 if win then win:moveToUnit({x=0, y=0.5, w=0.5, h=0.5}, .1) end
                 appStates:save()
                 leftMode:exit()
end)
leftMode:bind(cmdHyper, 'k', function()
                 local win = hs.window.focusedWindow()
                 if win then win:moveToUnit({x=0, y=0, w=0.5, h=0.5}, .1) end
                 appStates:save()
                 leftMode:exit()
end)

hs.hotkey.bind(cmdHyper, 'm', function()
    local win = hs.window.focusedWindow()
    appStates:save()
    if win then win:moveToUnit({x=0.15, y=0.15, w=0.7, h=0.7}, .1) end
end)

---------------------------------------------------------
-- MISC
---------------------------------------------------------

hs.hotkey.bind(hyper, "0", function()
  hs.reload()
  hs.notify.new({title='Hammerspoon Reloaded'}):send()
end)
