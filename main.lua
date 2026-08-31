local mod = ...

-- Store the active state in a local variable or inside the mod table
mod.repelEnabled = mod.repelEnabled or false

local function isRepelEnabled()
  return mod.repelEnabled
end

local function setRepelEnabled(enabled)
  mod.repelEnabled = enabled
end

-- 1. Prevent encounters if Repel is toggled ON
mod.hooks:wrap("encounter.roll", function(next, encDef, ctx)
  if isRepelEnabled() then
    return nil
  end
  return next(encDef, ctx)
end)

-- 2. Repel Menu UI (Opens when selecting REPEL from the Start Menu)
local function openRepelMenu(game)
  local Menu = require("src.ui.Menu")
  local Screens = require("src.ui.Screens")

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

  local items = { repelItem }

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

-- 3. Inject "REPEL" into the Start Menu before "SAVE"
mod.hooks:wrap("ui.start_menu.items", function(next_, game, items)
  local out = next_(game, items)
  if type(out) ~= "table" then return out end

  -- Prevent adding duplicate menu entries if already present
  for _, item in ipairs(out) do
    if tostring(item.label):upper() == "REPEL" then 
      return out 
    end
  end

  return mod.ui.insertBefore(out, "SAVE", {
    label = "REPEL",
    onSelect = function()
      openRepelMenu(game)
    end,
  })
end)
