--[[
 _   __ _____ _   _   ___   _   _ 
| | / /|  ___| | | | / _ \ | \ | |
| |/ / | |__ | |_| |/ /_\ \|  \| |
|    \ |  __||  _  ||  _  || . ` |
| |\  \| |___| | | || | | || |\  |
\_| \_/\____/\_| |_/\_| |_/\_| \_/

InventoryPopUp API
--]]

-- InventoryPopUp
-- Author: Kehan (Discord: @Kehan, GitHub: https://github.com/kehan8)
-- Version: 1.0.0

-- Please don't modify or copy-paste from this file unless you know Lua -
-- see README.md for setup instead.
-- GitHub Guide: https://github.com/kehan8/InventoryPopUp
-- Questions? Ask Kehan on Discord - include as much detail as you can.

---@class InventoryPopUp
---@field phase string
local InventoryPopUp = {}
InventoryPopUp.__index = InventoryPopUp

local instanceCount = 0

-- Non-container screens missed by isContainerOpen() - opt-in via enable* options.
local MODDED_SCREENS = {
	createBlocks = "com.simibubi.create.foundation.blockentity.behaviour.valuesettingsscreen", -- Create: all "value setting" blocks
    cobblemonPC = "com.cobblemon.mod.common.client.gui.pc.pcgui", -- Cobblemon: all PC screens
}

-- Container screens already caught by isContainerOpen() - opt-out via
-- enable* options (set to false to exclude just that one).
local EXCLUDABLE_CONTAINER_SCREENS = {
    waystones = "net.blay09.mods.waystones.client.gui.screen.waystoneselectionscreen",
}

-- Debug: uncomment to print the screen class name on change.
-- if host:isHost() then
--     local lastScreenClass = nil
--     events.TICK:register(function()
--         local screenClass = host:getScreen()
--         if screenClass ~= lastScreenClass then
--             lastScreenClass = screenClass
--             log("InventoryPopUp debug | class=" .. tostring(screenClass) .. " isContainerOpen=" .. tostring(host:isContainerOpen()))
--         end
--     end)
-- end

-- Checks if a screen class is a known modded screen the user has enabled.
local function isKnownModdedScreen(enabledScreens, screenClass)
    if screenClass == nil then return false end
    screenClass = screenClass:lower()
    for key, className in pairs(MODDED_SCREENS) do
        if enabledScreens[key] and screenClass == className then
            return true
        end
    end
    return false
end

-- Checks if a screen class is a container the user has explicitly disabled.
local function isExcludedContainerScreen(enabledScreens, screenClass)
    if screenClass == nil then return false end
    screenClass = screenClass:lower()
    for key, className in pairs(EXCLUDABLE_CONTAINER_SCREENS) do
        if not enabledScreens[key] and screenClass == className then
            return true
        end
    end
    return false
end

---@param config table startAnim, loopAnim, endAnim required; priority, enableFiguraMenu, enableCreateBlocks, enableCobblemonPC, enableWaystones optional
---@return InventoryPopUp
function InventoryPopUp.new(config)
    config = config or {}
    assert(config.startAnim, "InventoryPopUp: startAnim is required")
    assert(config.loopAnim, "InventoryPopUp: loopAnim is required")
    assert(config.endAnim, "InventoryPopUp: endAnim is required")

    instanceCount = instanceCount + 1
    local pingName = "InventoryPopUp_setGuiOpen_" .. instanceCount

    local self = setmetatable({}, InventoryPopUp)
    self.startAnim = config.startAnim
    self.loopAnim = config.loopAnim
    self.endAnim = config.endAnim
    self.priority = config.priority or 6

    -- GUI-open state, synced from host to all viewers via ping
    self.guiOpen = false
    self.guiOpenStable = false -- only trusted after a few stable ticks
    self.guiOpenStableCount = 0
    self.debounceTicks = 3 -- ticks the raw state must hold before we trust it
    self.wasGuiOpen = false
    self.phase = "idle" -- idle | starting | looping | ending
    self.timer = 0

    -- Read animation lengths directly so this always matches Blockbench
    self.startTicks = math.max(1, math.ceil(self.startAnim:getLength() * 20))
    self.endTicks = math.max(1, math.ceil(self.endAnim:getLength() * 20))

    self.enabledModdedScreens = {
        cobblemonPC = config.enableCobblemonPC ~= false,
        createBlocks = config.enableCreateBlocks ~= false,
    }
    self.enabledContainerScreens = {
        waystones = config.enableWaystones ~= false,
    }
    -- Default OFF: looping tends to look disrupted in Figura's own menu.
    self.enableFiguraMenu = config.enableFiguraMenu == true

    -- Receives the synced open/closed state (runs on host and all viewers)
    pings[pingName] = function(state)
        self.guiOpen = state
    end

    -- Only the host can query the actual screen state
    if host:isHost() then
        local lastSentState = false

        local function isFiguraOwnScreen(screenClass)
            if not self.enableFiguraMenu then return false end
            return screenClass ~= nil and screenClass:lower():find("figura", 1, true) ~= nil
        end

        -- Detects the current screen and pings the result on change only
        events.TICK:register(function()
            local screenClass = host:getScreen()
            local isOpen = (host:isContainerOpen() or isFiguraOwnScreen(screenClass) or isKnownModdedScreen(self.enabledModdedScreens, screenClass))
                and not isExcludedContainerScreen(self.enabledContainerScreens, screenClass)

            if isOpen ~= lastSentState then
                lastSentState = isOpen
                pings[pingName](isOpen)
            end
        end)
    end

    -- Main state machine: idle -> starting -> looping -> ending -> idle
    events.TICK:register(function()
        -- Debounce: ignore a single bad tick reading
        if self.guiOpen == self.guiOpenStable then
            self.guiOpenStableCount = 0
        else
            self.guiOpenStableCount = self.guiOpenStableCount + 1
            if self.guiOpenStableCount >= self.debounceTicks then
                self.guiOpenStable = self.guiOpen
                self.guiOpenStableCount = 0
            end
        end

        if self.guiOpenStable and not self.wasGuiOpen then
            -- Screen just opened
            self.endAnim:stop()
            self.loopAnim:stop()
            self.startAnim:setPriority(self.priority)
            self.startAnim:play()
            self.phase = "starting"
            self.timer = self.startTicks
        elseif not self.guiOpenStable and self.wasGuiOpen then
            -- Screen just closed
            self.startAnim:stop()
            self.loopAnim:stop()
            self.endAnim:setPriority(self.priority)
            self.endAnim:play()
            self.phase = "ending"
            self.timer = self.endTicks
        end

        -- Advance the current phase's timer
        if self.phase == "starting" then
            self.timer = self.timer - 1
            if self.timer <= 0 then
                self.loopAnim:setPriority(self.priority)
                self.loopAnim:play()
                self.startAnim:stop(true)
                self.phase = "looping"
            end
        elseif self.phase == "ending" then
            self.timer = self.timer - 1
            if self.timer <= 0 then
                self.endAnim:stop(true)
                self.phase = "idle"
            end
        end

        -- Debug: uncomment to trace the state machine tick by tick
        -- log("InventoryPopUp debug | phase=" .. self.phase .. " timer=" .. self.timer .. " guiOpen=" .. tostring(self.guiOpen) .. " guiOpenStable=" .. tostring(self.guiOpenStable))

        self.wasGuiOpen = self.guiOpenStable
    end)

    return self
end

-- Returns "idle", "starting", "looping", or "ending"
---@return string
function InventoryPopUp:getPhase()
    return self.phase
end

return InventoryPopUp
