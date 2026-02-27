local meta = { "cmd", "shift", "ctrl" }
local hyper = { "ctrl", "alt", "shift" }

-- stackline = require("stackline")
-- stacklineConf = require("stackline/conf")

-- stacklineConf.appearance.size = 24
-- stacklineConf.appearance.iconPadding = 0
-- stacklineConf.appearance.shouldFade = false
-- stacklineConf.appearance.radius = 3
-- stacklineConf.appearance.offset.x = 4
-- stackline:init(stacklineConf)

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

local fnutils = require("hs.fnutils")
local partial = fnutils.partial
local indexOf = fnutils.indexOf
local filter = fnutils.filter

local window = require("hs.window")
local alert = require("hs.alert")
local grid = require("hs.grid")

require("fntools")
require("extensions")

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
hs.hotkey.bind(hyper, "u", function()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToScreen(win:screen():previous(), false, true, 0.1)
  end
  appStates:save()
end)
-- hs.hotkey.bind(hyper, "i", function()
--   local win = hs.window.focusedWindow()
--   if win then
--     win:moveToScreen(win:screen():next(), false, true, 0.1)
--   end
--   appStates:save()
-- end)

---------------------------------------------------------
-- APP HOTKEYS
---------------------------------------------------------

hs.hotkey.bind(hyper, "1", launchOrCycleFocus("1Password"))
hs.hotkey.bind(hyper, "a", launchOrCycleFocus("Safari"))
hs.hotkey.bind(hyper, "b", launchOrCycleFocus("Preview"))
hs.hotkey.bind(hyper, "c", launchOrCycleFocus("cmux"))
hs.hotkey.bind(hyper, "d", launchOrCycleFocus("Google Chrome"))
hs.hotkey.bind(hyper, "e", launchOrCycleFocus("Slack"))
hs.hotkey.bind(hyper, "f", launchOrCycleFocus("Ghostty"))
hs.hotkey.bind(hyper, "g", launchOrCycleFocus("Discord"))
hs.hotkey.bind(hyper, "i", launchOrCycleFocus("Signal"))
hs.hotkey.bind(hyper, "n", launchOrCycleFocus("Spotify"))
hs.hotkey.bind(hyper, "o", launchOrCycleFocus("Superhuman"))
hs.hotkey.bind(hyper, "p", launchOrCycleFocus("Telegram"))
hs.hotkey.bind(hyper, "q", launchOrCycleFocus("Google Chrome Canary"))
hs.hotkey.bind(hyper, "r", launchOrCycleFocus("Brave Browser"))
hs.hotkey.bind(hyper, "s", launchOrCycleFocus("Postico 2"))
hs.hotkey.bind(hyper, "t", launchOrCycleFocus("Messages"))
hs.hotkey.bind(hyper, "w", launchOrCycleFocus("Dictionary"))
-- hs.hotkey.bind(hyper, "n", launchOrCycleFocus("com.spotify.client"))
-- hs.hotkey.bind(hyper, "s", launchOrCycleFocus("at.eggerapps.Postico"))
-- hs.hotkey.bind(hyper, "t", launchOrCycleFocus("com.apple.MobileSMS"))
hs.hotkey.bind(hyper, "y", launchOrCycleFocus("Linear"))
-- hs.hotkey.bind(hyper, "u", launchOrCycleFocus("com.flexibits.fantastical2.mac"))
-- hs.hotkey.bind(hyper, "w", launchOrCycleFocus("com.apple.Dictionary"))
hs.hotkey.bind(hyper, "x", launchOrCycleFocus("Xcode"))
-- hs.hotkey.bind(hyper, "z", launchOrCycleFocus("us.zoom.xos"))
hs.hotkey.bind(hyper, "`", function()
  os.execute("open ~")
end)

-- hs.hotkey.bind(hyper, "m", fullScreenCurrent)
-- hs.hotkey.bind(hyper, "D", screenToRight)
-- hs.hotkey.bind(hyper, "A", screenToLeft)

---------------------------------------------------------
-- ON-THE-FLY KEYBIND
---------------------------------------------------------

-- Temporarily bind an application to be toggled by the V key
-- useful for once-in-a-while applications like Preview
local boundApplication = nil

-- # RESIZE

---------------------------------------------------------
-- KEYBOARD SIZE MANIPULATION
---------------------------------------------------------
-- HJKL Resize
local resizeMappings = {
  h = hs.layout.left50,
  j = { x = 0, y = 0.5, w = 1, h = 0.5 },
  k = { x = 0, y = 0, w = 1, h = 0.5 },
  l = hs.layout.right50,
  m = { x = 0, y = 0, w = 1, h = 1 },
}

for key in pairs(resizeMappings) do
  hs.hotkey.bind(hyper, key, function()
    local win = hs.window.focusedWindow()
    if win then
      win:moveToUnit(resizeMappings[key], 0.1)
    end
    appStates:save()
  end)
end

---------------------------------------------------------
-- MISC
---------------------------------------------------------

hs.hotkey.bind(hyper, "0", function()
  hs.reload()
  hs.notify.new({ title = "Hammerspoon Reloaded" }):send()
end)

local CMUX_BUNDLE_ID = "com.cmuxterm.app"
local cmuxPrefixActive = false
local cmuxPrefixTimer = nil
local cmuxPrefixTimeoutSeconds = 1.0

local function isCmuxFrontmost()
  local app = hs.application.frontmostApplication()
  if app == nil then
    return false
  end

  local bundleId = app:bundleID() or ""
  if bundleId == CMUX_BUNDLE_ID then
    return true
  end

  return bundleId:match("^com%.cmuxterm%.app") ~= nil
end

local function eventKey(event)
  local keyCode = event:getKeyCode()
  if keyCode == 4 then
    return "h"
  elseif keyCode == 38 then
    return "j"
  elseif keyCode == 40 then
    return "k"
  elseif keyCode == 37 then
    return "l"
  elseif keyCode == 0 then
    return "a"
  elseif keyCode == 1 then
    return "s"
  elseif keyCode == 9 then
    return "v"
  elseif keyCode == 8 then
    return "c"
  elseif keyCode == 45 then
    return "n"
  elseif keyCode == 35 then
    return "p"
  elseif keyCode == 13 then
    return "w"
  elseif keyCode == 34 then
    return "i"
  elseif keyCode == 32 then
    return "u"
  elseif keyCode == 43 then
    return ","
  end

  local chars = event:getCharacters(true)
  if not chars or #chars ~= 1 then
    return nil
  end
  return string.lower(chars)
end

local function clearCmuxPrefix()
  cmuxPrefixActive = false
  if cmuxPrefixTimer then
    cmuxPrefixTimer:stop()
    cmuxPrefixTimer = nil
  end
end

local function armCmuxPrefix()
  clearCmuxPrefix()
  cmuxPrefixActive = true
  cmuxPrefixTimer = hs.timer.doAfter(cmuxPrefixTimeoutSeconds, clearCmuxPrefix)
end

local function cmuxPrefixDispatch(key)
  if key == "h" then
    hs.eventtap.keyStroke({ "cmd", "alt" }, "left", 0)
    return true
  elseif key == "j" then
    hs.eventtap.keyStroke({ "cmd", "alt" }, "down", 0)
    return true
  elseif key == "k" then
    hs.eventtap.keyStroke({ "cmd", "alt" }, "up", 0)
    return true
  elseif key == "l" then
    hs.eventtap.keyStroke({ "cmd", "alt" }, "right", 0)
    return true
  elseif key == "a" then
    hs.eventtap.keyStroke({ "cmd" }, "d", 0)
    return true
  elseif key == "v" then
    hs.eventtap.keyStroke({ "cmd" }, "d", 0)
    return true
  elseif key == "s" then
    hs.eventtap.keyStroke({ "cmd", "shift" }, "d", 0)
    return true
  elseif key == "c" then
    hs.eventtap.keyStroke({ "cmd" }, "t", 0)
    return true
  elseif key == "n" then
    hs.eventtap.keyStroke({ "ctrl", "cmd" }, "]", 0)
    return true
  elseif key == "p" then
    hs.eventtap.keyStroke({ "ctrl", "cmd" }, "[", 0)
    return true
  elseif key == "," then
    hs.eventtap.keyStroke({ "cmd" }, "r", 0)
    return true
  elseif key == "w" then
    hs.eventtap.keyStroke({ "cmd" }, "w", 0)
    return true
  elseif key == "i" then
    hs.eventtap.keyStroke({ "cmd" }, "i", 0)
    return true
  elseif key == "u" then
    hs.eventtap.keyStroke({ "cmd", "shift" }, "u", 0)
    return true
  end

  return false
end

local cmuxPrefixTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  if not isCmuxFrontmost() then
    clearCmuxPrefix()
    return false
  end

  local key = eventKey(event)
  if not key then
    return false
  end
  local flags = event:getFlags()

  if not cmuxPrefixActive then
    if key == "a" and flags.ctrl and not flags.cmd and not flags.alt and not flags.shift then
      armCmuxPrefix()
      return true
    end
    return false
  end

  clearCmuxPrefix()
  return cmuxPrefixDispatch(key)
end)

cmuxPrefixTap:start()

local cmuxDirectNavTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  if not isCmuxFrontmost() then
    return false
  end

  local key = eventKey(event)
  if not key then
    return false
  end
  local flags = event:getFlags()
  if not (flags.ctrl and not flags.cmd and not flags.alt and not flags.shift) then
    return false
  end

  if key == "h" then
    hs.eventtap.keyStroke({ "cmd", "alt" }, "left", 0)
    return true
  elseif key == "j" then
    hs.eventtap.keyStroke({ "cmd", "alt" }, "down", 0)
    return true
  elseif key == "k" then
    hs.eventtap.keyStroke({ "cmd", "alt" }, "up", 0)
    return true
  elseif key == "l" then
    hs.eventtap.keyStroke({ "cmd", "alt" }, "right", 0)
    return true
  end

  return false
end)

cmuxDirectNavTap:start()
