local mod = ...

-- -----------------------------------------------------------------------------
-- 1. State Management
-- -----------------------------------------------------------------------------
mod.repelEnabled = mod.repelEnabled or false
mod.doubleExpEnabled = mod.doubleExpEnabled or false

local function isRepelEnabled() return mod.repelEnabled end
local function setRepelEnabled(enabled) mod.repelEnabled = enabled end

local function isDoubleExpEnabled() return mod.doubleExpEnabled end
local function setDoubleExpEnabled(enabled) mod.doubleExpEnabled = enabled end

-- -----------------------------------------------------------------------------
-- 2. Game Hooks
-- -----------------------------------------------------------------------------
-- Intercept Encounters
mod.hooks:wrap("encounter.roll", function(next, encDef, ctx)
  if isRepelEnabled() then
    return nil
  end
  return next(encDef, ctx)
end)

-- Intercept Experience Gains
mod.hooks:wrap("exp.gain", function(next, ctx)
  local gained = next(ctx)
  if not gained then return gained end

  if isDoubleExpEnabled() then
    return math.floor(gained * 2)
  end

  return gained
end)

-- -----------------------------------------------------------------------------
-- 3. QOL Submenu UI
-- -----------------------------------------------------------------------------
local function openQOLMenu(game)
  local Menu = require("src.ui.Menu")
  local Screens = require("src.ui.Screens")

  -- Repel Toggle Button
  local repelItem
  repelItem = {
    label = isRepelEnabled() and "REPEL ON" or "REPEL OFF",
    keepOpen = true,
    onSelect = function()
      local newState = not isRepelEnabled()
      setRepelEnabled(newState)
      repelItem.label = newState and "REPEL ON" or "REPEL OFF"
      if mod.log and mod.log.info then
        mod.log:info("Infinite Repel: %s", newState and "ON" or "OFF")
      end
    end,
  }

  -- 2X EXP Toggle Button
  local expItem
  expItem = {
    label = isDoubleExpEnabled() and "2X EXP ON" or "2X EXP OFF",
    keepOpen = true,
    onSelect = function()
      local newState = not isDoubleExpEnabled()
      setDoubleExpEnabled(newState)
      expItem.label = newState and "2X EXP ON" or "2X EXP OFF"
      if mod.log and mod.log.info then
        mod.log:info("Double EXP: %s", newState and "ON" or "OFF")
      end
    end,
  }

  -- Combine both toggles into the submenu items table
  local items = { repelItem, expItem }

  game.stack:push(Menu.new(game, items, {
    tx = 9,
    ty = 0,
    tw = 11,
    th = 8,
    maxVisible = 8,
    anchor = "topright",
    onCancel = function()
      Screens.push(game, "StartMenu")
    end,
  }))
end

-- -----------------------------------------------------------------------------
-- 4. Start Menu Injection
-- -----------------------------------------------------------------------------
mod.hooks:wrap("ui.start_menu.items", function(next_, game, items)
  local out = next_(game, items)
  if type(out) ~= "table" then return out end

  -- Prevent adding duplicate menu entries if already present
  for _, item in ipairs(out) do
    if tostring(item.label):upper() == "QOL" then 
      return out 
    end
  end

  return mod.ui.insertBefore(out, "SAVE", {
    label = "QOL",
    onSelect = function()
      openQOLMenu(game)
    end,
  })
end)
