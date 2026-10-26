--!strict
--!optimize 2

local lobbyPlaceId = 2550463899
local targetItem = "GoldAbidaMark"
local fallbackLobbyButton = {477, 681}
local fallbackYesButton = {549, 642}
local visibleOffset = 0x595
local absolutePositionOffset = 0xF4
local stopFile = "abida_hunt_stop.txt"
local loadTimeout = 60
local settleTime = 3
local menuOpenTimeout = 10
local retryTime = 1
local selfLoader = 'luau.load(game:HttpGet("https://raw.githubusercontent.com/tester945/KdmFTiAR/refs/heads/main/AbidaAuto3.lua"))()'

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(.5)
    LocalPlayer = Players.LocalPlayer
end
local origin = {0, 0}

local function Log(text)
    print("[Gold hunt] " .. text)
end

local function Stopped()
    local ok, text = pcall(readfile, stopFile)
    return ok and type(text) == "string" and string.find(string.lower(text), "stop") ~= nil
end

local function Child(parent, name)
    return parent and parent:FindFirstChild(name)
end

local function Find(root, name)
    if not root then return nil end
    for _, d in root:GetDescendants() do
        if d.Name == name then return d end
    end
    return nil
end

local function Visible(inst)
    local ok, value = pcall(memory.readu8, inst, visibleOffset)
    return ok and value == 1
end

local function ButtonCentre(button, fallback)
    if button then
        local ok, data = pcall(memory.readbuffer, button, absolutePositionOffset, 16)
        if ok and data then
            local x, y = buffer.readf32(data, 0), buffer.readf32(data, 4)
            local w, h = buffer.readf32(data, 8), buffer.readf32(data, 12)
            if w > 1 and h > 1 and w < 4000 and h < 4000 and x > -10 and y > -10 and x < 8000 and y < 8000 then
                return {math.floor(x + w / 2 + .5), math.floor(y + h / 2 + .5)}
            end
        end
    end
    return fallback
end

local function Click(target)
    for _ = 1, 3 do
        mousemoveabs(target[1] + origin[1], target[2] + origin[2])
        task.wait(.1)
        local now = getmouseposition()
        local dx, dy = target[1] - now.X, target[2] - now.Y
        if math.abs(dx) <= 2 and math.abs(dy) <= 2 then
            mousemoveabs(target[1] + origin[1] + 1, target[2] + origin[2])
            task.wait(.03)
            mousemoveabs(target[1] + origin[1], target[2] + origin[2])
            task.wait(.03)
            mouse1click()
            return true
        end
        origin = {origin[1] + dx, origin[2] + dy}
    end
    Log("could not line the cursor up with the button")
    return false
end

local function CursorFree()
    local before = getmouseposition()
    mousemoverel(5, 0)
    task.wait(.1)
    local after = getmouseposition()
    mousemoverel(-5, 0)
    return after.X ~= before.X or after.Y ~= before.Y
end

local function PressKey(code)
    keypress(code)
    task.wait(.05)
    keyrelease(code)
end

local function ScanChests()
    local folder = Child(Child(workspace, "Scripted"), "ScavengingContainers")
    if not folder then return nil end
    local items, found, golds = 0, nil, {}
    for _, chest in folder:GetChildren() do
        local inventory = Child(Child(chest, "State"), "Inventory")
        if inventory then
            for _, item in inventory:GetChildren() do
                if item.Name == "PickUpItem" then
                    items += 1
                    local itemId = Child(Child(item, "Config"), "ItemId")
                    local value = itemId and tostring(itemId.Value) or ""
                    if string.find(value, "Gold") then golds[#golds + 1] = value end
                    if string.find(value, targetItem) then found = found or chest end
                end
            end
        end
    end
    return items, found, golds
end

local function RunPlace()
    local started = os.clock()
    local lastItems, stableSince = -1, os.clock()
    while true do
        local items, found, golds = ScanChests()
        if items and (found or (items > 0 and items == lastItems and os.clock() - stableSince >= settleTime) or os.clock() - started > loadTimeout) then
            if #golds > 0 then
                Log("gold items in this run: " .. table.concat(golds, ", "))
            else
                Log("no gold items in this run (" .. items .. " items)")
            end
            return found
        end
        if items and items ~= lastItems then
            lastItems, stableSince = items, os.clock()
        end
        if not items and os.clock() - started > loadTimeout then
            Log("chests never loaded, leaving anyway")
            return nil
        end
        task.wait(.5)
    end
end

local function LeaveRun()
    queue_on_teleport(selfLoader)
    Log("no " .. targetItem .. ", returning to the lobby")
    local menu = Child(LocalPlayer:WaitForChild("PlayerGui", loadTimeout), "Menu")
    local button = Find(menu, "ReturnToLobbyButton")

    while true do
        if Stopped() then return Log("stop file found, staying here") end

        local open = CursorFree()
        if not open then
            PressKey(0x4D)
            local waited = os.clock()
            repeat
                task.wait(.2)
                open = CursorFree()
            until open or os.clock() - waited >= menuOpenTimeout
        end

        if open then
            task.wait(.2)
            Click(ButtonCentre(button, fallbackLobbyButton))
            task.wait(retryTime)
        else
            Log("menu didn't open, retrying")
            task.wait(2)
        end
    end
end

local function InLobby()
    queue_on_teleport(selfLoader)
    while true do
        if Stopped() then return Log("stop file found, staying in the lobby") end
        local prompt = Find(LocalPlayer.PlayerGui, "JoinLastSessionPrompt")
        if prompt and Visible(prompt) then
            task.wait(.3)
            Log("joining the last session")
            Click(ButtonCentre(Find(prompt, "Yes"), fallbackYesButton))
            task.wait(retryTime)
        else
            task.wait(.3)
        end
    end
end

local waited = os.clock()
while game.PlaceId ~= lobbyPlaceId and not Child(workspace, "Scripted") and os.clock() - waited < loadTimeout do
    task.wait(1)
end

if game.PlaceId == lobbyPlaceId then
    LocalPlayer:WaitForChild("PlayerGui", loadTimeout)
    InLobby()
elseif Child(workspace, "Scripted") then
    Log("waiting for chests to load")
    local chest = RunPlace()
    if chest then
        Log("FOUND " .. targetItem .. " in chest " .. chest.Name .. ", stopping")
        local box = Child(Child(chest, "Model"), "Box")
        if box then Log("chest position: " .. tostring(box.Position)) end
    else
        LeaveRun()
    end
else
    Log("not in an Abida run or the lobby, PlaceId " .. tostring(game.PlaceId))
end
