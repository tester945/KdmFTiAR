--!strict
--!optimize 2

local RobloxVersion = _G.RobloxVersion or game:GetClientVersion()
local O = crypt.json.decode(game:HttpGet("https://offsets.imtheo.lol/" .. RobloxVersion .. "/offsets.json")).Offsets

if game.GameId == 6739698191 then

local UI = loadstring(game:HttpGet("https://gitlab.com/okdude42/severe-scripts/-/raw/main/uilib2/SevereUI.luau?ref_type=heads"))()
local h = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
while not Players.LocalPlayer do task.wait(.1) end
local LocalPlayer = Players.LocalPlayer

local guiLayouts = {}
local guiLayout
for _, visible in {O.GuiObject and O.GuiObject.Visible, 0x575, 0x595} do
    local known = false
    for _, layout in guiLayouts do
        if layout.Visible == visible then known = true end
    end
    if visible and not known then
        guiLayouts[#guiLayouts + 1] = {Visible = visible, Rotation = visible - 0x19, Hits = 0}
    end
end
local spaceKey = 0x20
local guiRefreshInterval = 1
local attributeRootOffset = 0x38
local attributeStride = 0x58
local attributeValueOffset = 0x18
local generatorScanInterval = 2
local progressInterval = .25
local nodeRetryInterval = 2
local generatorTextSize = 16
local generatorFolders = {"Gens", "Generators", "newGenerators", "new Generators", "Generator"}
local palletFolders = {"Pallets", "pallets"}

local bAutoSkillCheck = false
local bGeneratorESP = true
local hitAngle = 107
local bParryDetect = false
local activeAnimationsOffset = O.Animator.ActiveAnimations
local trackAnimationOffset = O.AnimationTrack.Animation
local animationIdOffset = O.Misc.AnimationId
local attackAnimations = {
    ["129626174716003"] = {Name = "Slash"}, -- Slasher
    ["135002183282873"] = {Name = "Slash"}, -- Cure
    ["125430111937587"] = {Name = "Slash"}, -- Abysswalker
    ["100014992013740"] = {Name = "Lunge", Linger = 1.1},
    ["104540716539347"] = {Name = "Slash"}, -- Killer2
    ["93902163029544"] = {Name = "Slash"}, -- Killer
    ["83333467665074"] = {Name = "Slash"}, -- Butcher
    ["105374834496520"] = {Name = "Slash"}, -- Masked1
    ["115244153053858"] = {Name = "Slash"}, -- Masked2
    ["117042998468241"] = {Name = "Slash"}, -- Stalker
    ["84926129581106"] = {Name = "Slash"}, -- Veil
    ["113255068724446"] = {Name = "Slash"}, -- Hidden
}
local attackDefaults = {Windup = 0, Linger = .8, Length = 5.4, Height = 7}
local parrySafety = .1
local localRadius = 1.5
local parryHistoryTime = .3
local parryHistory = {}
local localHalfHeight = 2.5
local bShowParryRange = false
local parryRangeColor = Color3.fromRGB(255, 255, 255)
local parryAttackColor = Color3.fromRGB(255, 70, 70)
local activeAttack
local parryLocalRoot
local parryHasDagger = false
local parryCooldown = 1
local parryFlashTime = .6
local killerRefreshInterval = .5
local parryKiller
local nextKillerRefresh = 0
local lastParry = 0
local parryFlashUntil = 0
local parryText = ""
local screenCentre
local animationIds = {}
local playerScanInterval = .5
local toolRefreshInterval = 1
local nextPlayerScan = 0
local localTeam
local parryLocalTeam
local teamNames = {}
local teamOffsets = {O.Player.Team, 0x2D0}
local tracked = {}
local itemNames = {"Adrenaline Shot", "Bandage", "Flashlight", "Holy Water", "Monkey Paw", "Motion Tracker", "Parrying Dagger", "Riot Shield", "Shadow Clone", "Twist of Fate", "WaxBound Candle", "Gate"}
local bPalletESP = true
local palletColor = Color3.fromRGB(255, 140, 0)
local pallets = {}
local palletsAddress
local nextPalletScan = 0
local palletScanInterval = 2
local generatorColor = Color3.fromRGB(157, 159, 255)
local completedColor = Color3.fromRGB(90, 220, 90)
local regressingColor = Color3.fromRGB(255, 60, 60)
local gui, check, line, goal, trapPerfect
local needleAngle
local needleMovedAt = 0
local nextGuiRefresh = 0
local wasVisible = false
local pressed = false
local lastAngle, lastTime, lastGoal, needleSpeed
local frameTime = 1 / 60
local generators = {}
local gensAddress
local nextGeneratorScan = 0
local nextProgressRead = 0
local FlagSetters = {}
local AppliedFlags = {}
local window
local renderConnect
local camera
local runId = os.clock()
_G.ViolenceDistrictRunId = runId
if isfile("ViolenceDistrict.lua") then
    queue_on_teleport('luau.load(game:HttpGet("https://raw.githubusercontent.com/tester945/KdmFTiAR/refs/heads/main/VD.lua"))()')
end

local function IsHeapPointer(value)
    return type(value) == "number" and value >= 0x10000000000 and value < 0x70000000000
end

local function ReadU64(address, offset)
    local ok, value = pcall(memory.readu64, address, offset)
    return ok and value or nil
end

local function RawChildren(address)
    local list = address and ReadU64(address, O.Instance.ChildrenStart)
    local first = list and ReadU64(list, 0)
    local last = list and ReadU64(list, O.Instance.ChildrenEnd)
    if not first or not last or last < first or last - first > 0x10 * 5000 then
        return nil
    end

    local addresses = {}
    local size = last - first
    if size <= 0 then return addresses end
    local ok, data = pcall(memory.readbuffer, first, 0, size)
    if not ok or not data then return nil end
    for offset = 0, size - 0x10, 0x10 do
        local child = buffer.readu32(data, offset) + buffer.readu32(data, offset + 4) * 0x100000000
        if child ~= 0 then addresses[child] = true end
    end
    return addresses
end

local function PartPose(part)
    local primitive = part and ReadU64(tonumber(part.Data), O.BasePart.Primitive)
    if not IsHeapPointer(primitive) then return nil end
    local okRotation, rotation = pcall(memory.readbuffer, primitive, O.Primitive.Rotation, 36)
    local okPosition, position = pcall(memory.readbuffer, primitive, O.Primitive.Position, 12)
    local okSize, size = pcall(memory.readbuffer, primitive, O.Primitive.Size, 12)
    if not okRotation or not okPosition or not okSize or not rotation or not position or not size then return nil end
    local sizeVector = vector.create(buffer.readf32(size, 0), buffer.readf32(size, 4), buffer.readf32(size, 8))
    local positionVector = vector.create(buffer.readf32(position, 0), buffer.readf32(position, 4), buffer.readf32(position, 8))
    local right = vector.create(buffer.readf32(rotation, 0), buffer.readf32(rotation, 12), buffer.readf32(rotation, 24))
    local up = vector.create(buffer.readf32(rotation, 4), buffer.readf32(rotation, 16), buffer.readf32(rotation, 28))
    local look = -vector.create(buffer.readf32(rotation, 8), buffer.readf32(rotation, 20), buffer.readf32(rotation, 32))
    local rightLength = vector.magnitude(right)
    if rightLength ~= rightLength or math.abs(rightLength - 1) > .05 or math.abs(vector.magnitude(look) - 1) > .05 then return nil end
    if sizeVector.X <= 0 or sizeVector.Y <= 0 or sizeVector.Z <= 0 or vector.magnitude(sizeVector) > 5000 or vector.magnitude(positionVector) > 1e6 then return nil end
    return {Parent = true, PartSize = sizeVector, Position = positionVector, RightVector = right, UpVector = up, LookVector = look}
end

local function ReadStdString(address, maxSize)
    local size = ReadU64(address, 0x10)
    local capacity = ReadU64(address, 0x18)
    if not size or not capacity or size <= 0 or size > maxSize or capacity < size then return "" end

    local stringAddress = address
    if capacity >= 16 then
        stringAddress = ReadU64(address, 0)
        if not IsHeapPointer(stringAddress) then return "" end
    end

    local ok, data = pcall(memory.readbuffer, stringAddress, 0, size)
    return ok and data and buffer.tostring(data) or ""
end

local function SearchEntries(first, packed, wantedName)
    if not IsHeapPointer(first) or not packed then return nil, false end

    local count = packed % 0x100000000
    local capacity = math.floor(packed / 0x100000000)
    if count <= 0 or count > capacity or capacity > 256 then return nil, false end

    local valid = false
    for i = 0, count - 1 do
        local entry = first + i * attributeStride
        local namePointer = ReadU64(entry, 0)
        if IsHeapPointer(namePointer) then
            local name = ReadStdString(namePointer, 64)
            if name == "" then name = ReadStdString(namePointer + 0x8, 64) end
            if name ~= "" then
                valid = true
                if name == wantedName then return entry, true end
            end
        end
    end

    return nil, valid
end

local function SearchNode(node, wantedName)
    local first, packed = ReadU64(node, 0x8), ReadU64(node, 0x10)
    if first and packed then
        local entry, valid = SearchEntries(first, packed, wantedName)
        if entry or valid then return entry, valid end
    end

    packed, first = ReadU64(node, 0x8), ReadU64(node, 0x18)
    if first and packed then
        return SearchEntries(first, packed, wantedName)
    end

    return nil, false
end

local function FindAttributeNode(address, anchor)
    local root = ReadU64(address, attributeRootOffset)
    if not IsHeapPointer(root) then return nil end

    local queue = {root}
    local visited = {}
    local index = 1

    while index <= #queue and index <= 64 do
        local node = queue[index]
        index += 1

        if not visited[node] then
            visited[node] = true
            if SearchNode(node, anchor) then return node end

            for _, offset in {0x0, 0x10} do
                local pointer = ReadU64(node, offset)
                if IsHeapPointer(pointer) and not visited[pointer] then
                    queue[#queue + 1] = pointer
                end
            end
        end
    end

    return nil
end

local function GuiValid(playerGui)
    if not gui or not check or not line or not goal then return false end
    local guiChildren = RawChildren(tonumber(playerGui.Data))
    if not guiChildren or not guiChildren[gui] then return false end
    local checkChildren = RawChildren(gui)
    if not checkChildren or not checkChildren[check] then return false end
    local parts = RawChildren(check)
    return parts ~= nil and parts[line] == true and parts[goal] == true
end

local function RefreshGui()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        gui, check, line, goal, trapPerfect = nil, nil, nil, nil, nil
        return
    end
    if GuiValid(playerGui) then return end

    gui, check, line, goal, trapPerfect = nil, nil, nil, nil, nil
    wasVisible, pressed = false, false
    local found = playerGui:FindFirstChild("SkillCheckPromptGui")
    local foundCheck = found and found:FindFirstChild("Check")
    local foundLine = foundCheck and foundCheck:FindFirstChild("Line")
    local foundGoal = foundCheck and foundCheck:FindFirstChild("Goal")
    local foundTrap = foundCheck and foundCheck:FindFirstChild("TrapPerfect")
    if foundLine and foundGoal then
        gui, check = tonumber(found.Data), tonumber(foundCheck.Data)
        line, goal = tonumber(foundLine.Data), tonumber(foundGoal.Data)
        trapPerfect = foundTrap and tonumber(foundTrap.Data)
    end
end

local function DetectGuiLayout()
    for _, layout in guiLayouts do
        local okVisible, visibleByte = pcall(memory.readu8, check, layout.Visible)
        local okAngle, angle = pcall(memory.readf32, line, layout.Rotation)
        if okVisible and okAngle and visibleByte == 1 then
            if layout.LastAngle and angle > layout.LastAngle + .2 and angle < layout.LastAngle + 40 then
                layout.Hits += 1
            else
                layout.Hits = 0
            end
            layout.LastAngle = angle
            if layout.Hits >= 3 then
                guiLayout = layout
                print(string.format("Skill check offsets: visible +0x%X, rotation +0x%X", layout.Visible, layout.Rotation))
                return
            end
        else
            layout.Hits, layout.LastAngle = 0, nil
        end
    end
end

local function PressSpace()
    keypress(spaceKey)
    task.wait(.03)
    keyrelease(spaceKey)
end

local function UpdateSkillCheck()
    local now = os.clock()
    if now >= nextGuiRefresh then
        nextGuiRefresh = now + guiRefreshInterval
        RefreshGui()
    end
    if not check or not line or not goal then return end

    if not guiLayout then
        DetectGuiLayout()
        return
    end

    local okVisible, visibleByte = pcall(memory.readu8, check, guiLayout.Visible)
    local okAngle, angle = pcall(memory.readf32, line, guiLayout.Rotation)
    local okGoal, goalAngle = pcall(memory.readf32, goal, guiLayout.Rotation)
    if not okVisible or not okAngle or not okGoal then
        nextGuiRefresh = 0
        return
    end

    if angle ~= needleAngle then
        needleAngle, needleMovedAt = angle, now
    end
    if visibleByte ~= 1 or now - needleMovedAt > 1.5 then
        wasVisible = false
        return
    end

    local restarted = lastAngle and (angle < lastAngle - 30 or math.abs(goalAngle - lastGoal) > 1)
    if not wasVisible or restarted then
        wasVisible, pressed = true, false
        lastAngle, lastTime, lastGoal, needleSpeed = angle, now, goalAngle, nil
        return
    end

    if lastAngle and now - lastTime < .1 then
        local dt = now - lastTime
        frameTime = frameTime * .9 + dt * .1
        if angle > lastAngle then
            local speed = (angle - lastAngle) / dt
            needleSpeed = needleSpeed and needleSpeed * .7 + speed * .3 or speed
        end
    end
    lastAngle, lastTime, lastGoal = angle, now, goalAngle

    if pressed then return end
    local zoneAngle = goalAngle
    local okGoalVisible, goalVisible = pcall(memory.readu8, goal, guiLayout.Visible)
    if okGoalVisible and goalVisible ~= 1 and goalAngle < 1 then
        local okTrapVisible, trapVisible = false, 0
        local okTrapAngle, trapAngle = false, 0
        if trapPerfect then
            okTrapVisible, trapVisible = pcall(memory.readu8, trapPerfect, guiLayout.Visible)
            okTrapAngle, trapAngle = pcall(memory.readf32, trapPerfect, guiLayout.Rotation)
        end
        if not okTrapVisible or not okTrapAngle or trapVisible ~= 1 then
            pressed = true
            print("[skill check] no goal or trap zone, not pressing")
            return
        end
        zoneAngle = trapAngle
    end
    local target = zoneAngle + hitAngle
    if angle >= target then
        pressed = true
        task.spawn(PressSpace)
        return
    end
    if not needleSpeed or needleSpeed <= 0 then return end

    local remaining = (target - angle) / needleSpeed
    if remaining <= math.min(frameTime * 1.2, .03) then
        pressed = true
        local pressAt = now + remaining
        task.spawn(function()
            while os.clock() < pressAt do end
            PressSpace()
        end)
    end
end

local function FindMapFolder(map, names, childName)
    if not map then return nil end
    for _, parent in {map, map:FindFirstChild("resources")} do
        for _, name in names do
            local folder = parent:FindFirstChild(name)
            if folder and folder:FindFirstChild(childName) then
                return folder
            end
        end
    end
    return nil
end

local function ClearGenerators()
    generators = {}
    gensAddress = nil
end

local function ScanGenerators()
    local map = workspace:FindFirstChild("Map")
    local gens = FindMapFolder(map, generatorFolders, "Generator")
    if not gens then
        ClearGenerators()
        return
    end

    local address = tonumber(gens.Data)
    if address ~= gensAddress then
        generators = {}
        gensAddress = address
    end

    local raw = RawChildren(address)
    if not raw then return end
    for id, entry in generators do
        if not raw[entry.Address] then generators[id] = nil end
    end

    for _, generator in gens:GetChildren() do
        local generatorAddress = tonumber(generator.Data)
        local id = tostring(generatorAddress)
        if generatorAddress and raw[generatorAddress] and not generators[id] then
            local pose = PartPose(generator:FindFirstChild("GeneratorBody"))
            if pose then
                generators[id] = {
                    Address = generatorAddress,
                    Pose = pose,
                    Progress = -1,
                    Completed = false,
                    Text = "",
                    NextNodeTry = 0,
                }
            end
        end
    end
end

local function SetProgress(entry, progress, completed)
    if progress == entry.Progress and completed == entry.Completed then return end
    entry.Progress, entry.Completed = progress, completed
    entry.Text = if completed then "100%" else string.format("%d%%", progress)
end

local function ReadProgress(now)
    for _, entry in generators do
        if entry.Completed then continue end
        if not entry.Node and now >= entry.NextNodeTry then
            entry.NextNodeTry = now + nodeRetryInterval
            entry.Node = FindAttributeNode(entry.Address, "RepairProgress")
            entry.Layout = nil
        end

        local node = entry.Node
        if node then
            local okLayout, layout = pcall(memory.readbuffer, node, 0x8, 0x18)
            local key = okLayout and layout and buffer.tostring(layout)
            if not key or key ~= entry.Layout then
                local progressEntry, valid = SearchNode(node, "RepairProgress")
                if not valid or not progressEntry or not key then
                    entry.Node, entry.Layout = nil, nil
                    continue
                end
                entry.Layout = key
                entry.ProgressEntry = progressEntry
                entry.CompletedEntry = SearchNode(node, "Completed")
                entry.RegressingEntry = SearchNode(node, "Regressing")
                entry.RepairersEntry = SearchNode(node, "PlayersRepairingCount")
            end

            local ok, progress = pcall(memory.readf64, entry.ProgressEntry, attributeValueOffset)
            local completed, regressing, repairing = false, false, false
            if entry.CompletedEntry then
                local okCompleted, value = pcall(memory.readu8, entry.CompletedEntry, attributeValueOffset)
                completed = okCompleted and value == 1
            end
            if entry.RegressingEntry then
                local okRegressing, value = pcall(memory.readu8, entry.RegressingEntry, attributeValueOffset)
                regressing = okRegressing and value == 1
            end
            if entry.RepairersEntry then
                local okRepairers, value = pcall(memory.readf64, entry.RepairersEntry, attributeValueOffset)
                repairing = okRepairers and value == value and value > 0
            end
            entry.Regressing, entry.Repairing = regressing, repairing
            if ok and progress == progress then
                local whole = math.floor(progress)
                if entry.Progress >= 0 and whole > entry.Progress then entry.LastRise = now end
                SetProgress(entry, whole, completed or progress >= 100)
            end
        end
    end
end

local function UpdateGenerators()
    local now = os.clock()
    if now >= nextGeneratorScan then
        nextGeneratorScan = now + generatorScanInterval
        ScanGenerators()
    end
    if now >= nextProgressRead then
        nextProgressRead = now + progressInterval
        ReadProgress(now)
    end
end

local function ReadMatrix(data, offset)
    local m = table.create(12)
    for i = 0, 11 do
        local value = buffer.readf32(data, offset + i * 4)
        if value ~= value or math.abs(value) > 1e4 then return nil end
        m[i + 1] = value
    end
    return m
end

local function MulMatrix(a, b)
    local m = table.create(12)
    for row = 0, 2 do
        for col = 0, 2 do
            m[row * 3 + col + 1] = a[row * 3 + 1] * b[col + 1] + a[row * 3 + 2] * b[col + 4] + a[row * 3 + 3] * b[col + 7]
        end
        m[10 + row] = a[row * 3 + 1] * b[10] + a[row * 3 + 2] * b[11] + a[row * 3 + 3] * b[12] + a[10 + row]
    end
    return m
end

local function InvMatrix(a)
    local m = {a[1], a[4], a[7], a[2], a[5], a[8], a[3], a[6], a[9], 0, 0, 0}
    for row = 0, 2 do
        m[10 + row] = -(m[row * 3 + 1] * a[10] + m[row * 3 + 2] * a[11] + m[row * 3 + 3] * a[12])
    end
    return m
end

local function RotateLocal(m, v)
    return vector.create(m[1] * v.x + m[2] * v.y + m[3] * v.z, m[4] * v.x + m[5] * v.y + m[6] * v.z, m[7] * v.x + m[8] * v.y + m[9] * v.z)
end

local function UpdatePalletPose(entry)
    local ok, data = pcall(memory.readbuffer, entry.Bone, 0xF8, 0xA0)
    if not ok or not data then return end
    local raw = buffer.tostring(data)
    local now = os.clock()
    if raw == entry.LastBone then
        if entry.Dropped and now - entry.ChangedAt > 1 then entry.Settled = true end
        return
    end
    entry.LastBone, entry.ChangedAt = raw, now

    local current = ReadMatrix(data, 0)
    local transform = current and ReadMatrix(data, 0x70)
    if not transform then return end

    local rest = MulMatrix(current, InvMatrix(transform))
    local delta = MulMatrix(current, InvMatrix(rest))
    local right, up, back = entry.RootRight, entry.RootUp, -entry.RootLook

    local function ToLocal(v)
        return vector.create(vector.dot(v, right), vector.dot(v, up), vector.dot(v, back))
    end
    local function ToWorld(v)
        return right * v.x + up * v.y + back * v.z
    end

    local position = RotateLocal(delta, ToLocal(entry.RestPosition - entry.RootPosition)) + vector.create(delta[10], delta[11], delta[12])
    local pose = entry.Pose
    pose.Position = entry.RootPosition + ToWorld(position)
    pose.RightVector = ToWorld(RotateLocal(delta, ToLocal(entry.RestRight)))
    pose.UpVector = ToWorld(RotateLocal(delta, ToLocal(entry.RestUp)))
    pose.LookVector = ToWorld(RotateLocal(delta, ToLocal(entry.RestLook)))
    entry.Dropped = vector.magnitude(pose.Position - entry.RestPosition) > 1.5
end

local function ClearPallets()
    pallets = {}
    palletsAddress = nil
end

local function ScanPallets()
    local map = workspace:FindFirstChild("Map")
    local folder = FindMapFolder(map, palletFolders, "Newpallet")
    if not folder then
        ClearPallets()
        return
    end

    local address = tonumber(folder.Data)
    if address ~= palletsAddress then
        pallets = {}
        palletsAddress = address
    end

    local raw = RawChildren(address)
    if not raw then return end
    for id, entry in pallets do
        if not raw[entry.Address] then pallets[id] = nil end
    end

    for _, pallet in folder:GetChildren() do
        local palletAddress = tonumber(pallet.Data)
        if palletAddress and raw[palletAddress] then
            local id = tostring(palletAddress)
            local entry = pallets[id]
            if not entry then
                local intact = pallet:FindFirstChild("Intact")
                local part = intact and intact:FindFirstChild("Pallet")
                local root = intact and intact:FindFirstChild("RootPart")
                local bone = root and root:FindFirstChild("Bone")
                local partPose = part and bone and PartPose(part)
                local rootPose = partPose and PartPose(root)
                if rootPose then
                    local hitboxPose = PartPose(pallet:FindFirstChild("hitbox"))
                    if hitboxPose then hitboxPose.Size = hitboxPose.PartSize end
                    entry = {
                        Hitbox = hitboxPose,
                        Address = palletAddress,
                        Part = part,
                        Bone = bone,
                        RootPosition = rootPose.Position,
                        RootRight = rootPose.RightVector,
                        RootUp = rootPose.UpVector,
                        RootLook = rootPose.LookVector,
                        RestPosition = partPose.Position,
                        RestRight = partPose.RightVector,
                        RestUp = partPose.UpVector,
                        RestLook = partPose.LookVector,
                        Pose = partPose,
                    }
                    pallets[id] = entry
                end
            end
            if entry and not entry.Hidden then
                local ok, transparency = pcall(memory.readf32, entry.Part, O.BasePart.Transparency)
                entry.Hidden = ok and transparency > .99
            end
        end
    end
end

local function RefreshTeamNames()
    teamNames = {}
    local teams = game:FindFirstChild("Teams")
    if not teams then return end
    for _, team in teams:GetChildren() do
        teamNames[tonumber(team.Data)] = team.Name
    end
end

local function PlayerTeam(player)
    local address = tonumber(player.Data)
    for _, offset in teamOffsets do
        local name = teamNames[ReadU64(address, offset)]
        if name then return name end
    end
    local team = player.Team
    return team and team.Name
end

local function RemoveTracked(id)
    tracked[id] = nil
    ESP.RemovePlayer(id)
end

local function ClearPlayers()
    for id in tracked do
        ESP.RemovePlayer(id)
    end
    tracked = {}
end

local function ReadAttributeString(node, name)
    local entry = SearchNode(node, name)
    if not entry then return nil end
    local text = ReadStdString(entry + attributeValueOffset, 64)
    return if text ~= "" then text else nil
end

local function BuildTool(info, now)
    local character = info.Character
    if info.Team == "Killer" then
        if not info.Node and now >= info.NextNodeTry then
            info.NextNodeTry = now + nodeRetryInterval
            info.Node = FindAttributeNode(info.Address, "HookCount")
        end
        local killer = info.Node and ReadAttributeString(info.Node, "MorphedKiller")
        return killer or "Killer"
    end

    if info.Team ~= "Survivors" then return "" end

    for _, name in itemNames do
        if character:FindFirstChild(name) then
            return name
        end
    end
    return ""
end

local function ScanPlayers()
    local now = os.clock()
    RefreshTeamNames()
    localTeam = PlayerTeam(LocalPlayer)
    local current = {}

    for _, player in Players:GetChildren() do
        local character = player.Character
        local ok, className = pcall(memory.rtti, character)
        local team = PlayerTeam(player)
        if character and ok and className == "RBX::ModelInstance" and team and team ~= "Spectator" then
            local address = tonumber(character.Data)
            local id = tostring(address)
            local info = tracked[id]

            if not info then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    info = {Character = character, Address = address, Team = team, Tool = "", NextTool = 0, NextNodeTry = 0}
                    tracked[id] = info
                    ESP.AddPlayer(character, {
                        Player = player,
                        TeamType = "Manual",
                        HealthSource = humanoid,
                        ExternalRemoval = true,
                        GetTeam = function()
                            return info.Team
                        end,
                        GetLocalTeam = function()
                            return localTeam
                        end,
                        GetTool = function()
                            return info.Tool
                        end,
                    })
                end
            end

            if info then
                current[id] = true
                if info.Team ~= team then
                    info.Team, info.Node, info.NextTool = team, nil, 0
                end
                if now >= info.NextTool then
                    info.NextTool = now + toolRefreshInterval
                    info.Tool = BuildTool(info, now)
                end
            end
        end
    end

    for id in tracked do
        if not current[id] then RemoveTracked(id) end
    end
end

local function RefreshParryKiller()
    parryKiller = nil
    RefreshTeamNames()
    parryLocalTeam = PlayerTeam(LocalPlayer)
    local localCharacter = LocalPlayer.Character
    local okLocal, localClass = pcall(memory.rtti, localCharacter)
    parryLocalRoot = localCharacter and okLocal and localClass == "RBX::ModelInstance" and localCharacter:FindFirstChild("HumanoidRootPart") or nil
    parryHasDagger = parryLocalRoot ~= nil and (localCharacter:FindFirstChild("Parrying Dagger") ~= nil or LocalPlayer:GetAttribute("EquippedItem") == "Parrying Dagger")
    for _, player in Players:GetChildren() do
        if player ~= LocalPlayer and PlayerTeam(player) == "Killer" then
            local character = player.Character
            local ok, className = pcall(memory.rtti, character)
            if character and ok and className == "RBX::ModelInstance" then
                local humanoid = character:FindFirstChild("Humanoid")
                local animator = humanoid and humanoid:FindFirstChild("Animator")
                local root = character:FindFirstChild("HumanoidRootPart")
                if animator and root then
                    parryKiller = {Animator = tonumber(animator.Data), Root = root}
                end
            end
            return
        end
    end
end

local function PressParry()
    local offset = (math.random(-80, 80)) / 1000
    local delayVal = math.max(0, offset)
    if delayVal > 0 then
        task.wait(delayVal)
    end
    mouse2press()
    task.wait(.1)
    mouse2release()
end

local function PastLocalPosition(now)
    local chosen = parryHistory[1]
    for i = #parryHistory, 1, -1 do
        local sample = parryHistory[i]
        if now - sample.Time >= parryHistoryTime then
            chosen = sample
            break
        end
    end
    return chosen and chosen.Position
end

local function BuildParryTest(origin, look, config)
    local forward = vector.create(look.x, 0, look.z)
    local magnitude = vector.magnitude(forward)
    if magnitude == 0 then return end
    forward /= magnitude

    local right = vector.create(-forward.z, 0, forward.x)
    local radius = (config.Length or attackDefaults.Length) + localRadius
    local height = config.Height or attackDefaults.Height

    local function Inside(point)
        local offset = point - origin
        if math.abs(offset.y) > height / 2 + localHalfHeight then return false end
        return vector.magnitude(vector.create(offset.x, 0, offset.z)) <= radius
    end

    return Inside, forward, right, radius + 1
end

local function UpdateKillerVelocity(killer, pos, now)
    local dt = killer.LastTime and now - killer.LastTime
    if not dt or dt > .5 then
        killer.LastPos, killer.LastTime, killer.LastMove = pos, now, now
        killer.Velocity = vector.create(0, 0, 0)
        return
    end
    if dt < .05 then return end

    local delta = pos - killer.LastPos
    if vector.magnitude(delta) > .03 then
        killer.Velocity = killer.Velocity * .5 + (delta / dt) * .5
        killer.LastMove = now
    elseif now - killer.LastMove > .25 then
        killer.Velocity *= .7
        if vector.magnitude(killer.Velocity) < .5 then killer.Velocity = vector.create(0, 0, 0) end
    end
    killer.LastPos, killer.LastTime = pos, now
end

local function StartAttack(config, now)
    if activeAttack and now - activeAttack.Started < .2 and activeAttack.Config == config then return end
    local ping = game:GetPing() / 1000
    local windup = config.Windup or attackDefaults.Windup
    local linger = config.Linger or attackDefaults.Linger
    activeAttack = {
        Config = config,
        Started = now,
        Starts = now + windup - ping - parrySafety,
        Ends = now + windup + linger - ping - parrySafety - .05,
    }
end

local function CheckAttack(now)
    if not activeAttack then return end
    if now > activeAttack.Ends then
        activeAttack = nil
        return
    end
    if now < activeAttack.Starts or now - lastParry < parryCooldown or not parryLocalRoot then return end

    local killerRoot = parryKiller.Root
    local killerPos = killerRoot.Position
    local localPos = PastLocalPosition(now) or parryLocalRoot.Position
    local Inside = BuildParryTest(killerPos, killerRoot.LookVector, activeAttack.Config)
    if not Inside or not Inside(localPos) then return end

    local attack = activeAttack
    activeAttack = nil
    lastParry = now
    parryFlashUntil = now + parryFlashTime
    parryText = "PARRY"
    print(string.format("[parry] %s d=%.1f after %.2fs", attack.Config.Name, vector.magnitude(localPos - killerPos), now - attack.Started))
    task.spawn(PressParry)
end

local function UpdateParry(now)
    if now >= nextKillerRefresh then
        nextKillerRefresh = now + killerRefreshInterval
        local old = parryKiller
        RefreshParryKiller()
        if parryKiller and old and parryKiller.Animator == old.Animator then
            parryKiller.Tracks = old.Tracks
            parryKiller.LastPos, parryKiller.LastTime, parryKiller.LastMove = old.LastPos, old.LastTime, old.LastMove
            parryKiller.Velocity = old.Velocity
        else
            activeAttack = nil
        end
    end
    if not parryKiller or parryLocalTeam ~= "Survivors" then
        activeAttack = nil
        return
    end

    UpdateKillerVelocity(parryKiller, parryKiller.Root.Position, now)

    if parryLocalRoot then
        local last = parryHistory[#parryHistory]
        if last and now - last.Time > .5 then table.clear(parryHistory) end
        parryHistory[#parryHistory + 1] = {Time = now, Position = parryLocalRoot.Position}
        while #parryHistory > 2 and now - parryHistory[2].Time >= parryHistoryTime do
            table.remove(parryHistory, 1)
        end
    end

    local head = ReadU64(parryKiller.Animator, activeAnimationsOffset)
    local count = ReadU64(parryKiller.Animator, activeAnimationsOffset + 0x8)
    if not IsHeapPointer(head) or not count or count > 256 then return end

    local previous = parryKiller.Tracks
    local current = {}
    local node = ReadU64(head, 0)
    for _ = 1, count do
        if not IsHeapPointer(node) or node == head then break end
        local track = ReadU64(node, 0x10)
        if IsHeapPointer(track) then
            current[track] = true
            if previous and not previous[track] then
                local animation = ReadU64(track, trackAnimationOffset)
                local id = animation and animationIds[animation]
                if animation and not id then
                    local ok, raw = pcall(memory.readstring, animation, animationIdOffset)
                    id = ok and raw and string.match(raw, "%d+") or ""
                    animationIds[animation] = id
                end
                local attack = id and attackAnimations[id]
                if attack then
                    StartAttack(attack, now)
                end
            end
        end
        node = ReadU64(node, 0)
    end
    parryKiller.Tracks = current

    if activeAttack and now > activeAttack.Ends then activeAttack = nil end
    if bParryDetect and parryHasDagger then CheckAttack(now) end
end

local function RenderParryRange()
    local killer = parryKiller
    if not killer or not parryLocalRoot or not killer.Velocity or parryLocalTeam ~= "Survivors" then return end

    local killerPos = killer.Root.Position
    local origin = killerPos
    local config = activeAttack and activeAttack.Config or attackDefaults
    local radius = (config.Length or attackDefaults.Length) + localRadius

    local color = if activeAttack then parryAttackColor else parryRangeColor
    local centreScreen, centreVisible = camera:WorldToScreenPoint(origin)
    local first, previous
    for i = 0, 36 do
        local angle = (i % 36 / 36) * math.pi * 2
        local screen, visible = camera:WorldToScreenPoint(origin + vector.create(math.cos(angle) * radius, 0, math.sin(angle) * radius))
        local point = visible and vector.create(screen.X, screen.Y, 0) or nil
        if i == 0 then first = point end
        if i == 36 then point = first end
        if point and previous then
            if centreVisible then
                DrawingImmediate.FilledTriangle(vector.create(centreScreen.X, centreScreen.Y, 0), previous, point, color, .15)
            end
            DrawingImmediate.Line(previous, point, color, 1, 2, 1)
        end
        previous = point
    end

    if activeAttack then
        local killerScreen, killerVisible = camera:WorldToScreenPoint(killerPos + vector.create(0, 4, 0))
        if killerVisible then
            DrawingImmediate.OutlinedText(vector.create(killerScreen.X, killerScreen.Y - 8, 0), 16, parryAttackColor, 1, activeAttack.Config.Name, true, "Nunito")
        end
    end
end

local bDaggerTrajectory = true
local daggerColor = Color3.fromRGB(170, 120, 255)
local daggerEndColor = Color3.fromRGB(255, 80, 80)
local UpdateDaggerAim, RenderDaggerTrajectory, BuildDaggerGradient, UpdateThrownDaggers, RenderThrownDaggers

do
    local aimAnimations = {
        ["77303734522729"] = "Hold",
        ["87436543050891"] = "Hold",
        ["79809716042968"] = "Hold",
        ["122765810542358"] = "Hold",
        ["101443662521580"] = "Throw",
        ["127622545856523"] = "Throw",
    }
    local daggerSpeed = 163.5
    local daggerGravity = 96.5
    local daggerLag = .0375
    local aimTimeout = 1
    local daggerHeight = 1.6
    local daggerStep = .02
    local daggerMaxTime = 6
    local daggerMaxDrop = 80
    local groundOffset = 3
    local localRightOffset = 1.5
    local localForwardOffset = .1
    local gradientSteps = 32
    local gradient = {}
    local hitGradient = {}
    local missGradient = {}
    local hitRadius = 1.8
    local legHalfHeight = 1
    local headTop = .5
    local motions = {}
    local hitSamples = 4
    local refreshInterval = .5
    local throwers = {}
    local targets = {}
    local arcPoints = {}
    local ownRoot, ownIsSurvivor
    local nextRefresh = 0

    local function AnimatorOf(character)
        local ok, className = pcall(memory.rtti, character)
        if not character or not ok or className ~= "RBX::ModelInstance" then return end
        local humanoid = character:FindFirstChild("Humanoid")
        local animator = humanoid and humanoid:FindFirstChild("Animator")
        local root = character:FindFirstChild("HumanoidRootPart")
        if animator and root then return tonumber(animator.Data), root end
    end

    local function Refresh()
        local list, roots, newMotions = {}, {}, {}
        local states = {}
        for _, thrower in throwers do states[thrower.Animator] = thrower.State end
        local animator, root = AnimatorOf(LocalPlayer.Character)
        ownRoot = root
        ownIsSurvivor = PlayerTeam(LocalPlayer) == "Survivors"
        if animator then list[#list + 1] = {Animator = animator, Root = root, IsLocal = true, State = states[animator] or {}} end
        for _, player in Players:GetChildren() do
            local team = player ~= LocalPlayer and PlayerTeam(player)
            if team and team ~= "Spectator" then
                local otherAnimator, otherRoot = AnimatorOf(player.Character)
                if otherAnimator then
                    local character = player.Character
                    local id = tonumber(otherRoot.Data)
                    local motion = motions[id] or {}
                    newMotions[id] = motion
                    roots[#roots + 1] = {
                        Team = team,
                        Motion = motion,
                        Root = otherRoot,
                        Head = character:FindFirstChild("Head") or otherRoot,
                        LeftLeg = character:FindFirstChild("Left Leg") or otherRoot,
                        RightLeg = character:FindFirstChild("Right Leg") or otherRoot,
                    }
                    if team == "Killer" then list[#list + 1] = {Animator = otherAnimator, Root = otherRoot, State = states[otherAnimator] or {}} end
                end
            end
        end
        throwers, targets, motions = list, roots, newMotions
    end

    local function UpdateAimState(state, animator, now)
        local head = ReadU64(animator, activeAnimationsOffset)
        local count = ReadU64(animator, activeAnimationsOffset + 0x8)
        if not IsHeapPointer(head) or not count or count > 256 then return end
        local previous = state.Tracks
        local current = {}
        local holding = false
        local node = ReadU64(head, 0)
        for _ = 1, count do
            if not IsHeapPointer(node) or node == head then break end
            local track = ReadU64(node, 0x10)
            if IsHeapPointer(track) then
                current[track] = true
                local animation = ReadU64(track, trackAnimationOffset)
                local id = animation and animationIds[animation]
                if animation and not id then
                    local ok, raw = pcall(memory.readstring, animation, animationIdOffset)
                    id = ok and raw and string.match(raw, "%d+") or ""
                    animationIds[animation] = id
                end
                local kind = id and aimAnimations[id]
                local isNew = not previous or not previous[track]
                if kind == "Hold" then
                    holding = true
                    if isNew then state.Aiming = true end
                elseif kind == "Throw" and isNew then
                    state.Aiming = false
                    state.ThrownAt = now
                end
            end
            node = ReadU64(node, 0)
        end
        if state.ThrownAt == now then state.Aiming = false end
        if holding then
            state.LastHold = now
        elseif state.Aiming and (not state.LastHold or now - state.LastHold > aimTimeout) then
            state.Aiming = false
        end
        state.Tracks = current
    end

    local function LaunchAngle(distance, rise)
        if distance < .5 then return 0 end
        local speedSquared = daggerSpeed * daggerSpeed
        local angle = 0
        local adjustedRise = rise
        for _ = 1, 3 do
            local discriminant = speedSquared * speedSquared - daggerGravity * (daggerGravity * distance * distance + 2 * adjustedRise * speedSquared)
            if discriminant < 0 then return math.pi / 4 end
            angle = math.atan((speedSquared - math.sqrt(discriminant)) / (daggerGravity * distance))
            local flightTime = distance / (daggerSpeed * math.cos(angle))
            adjustedRise = rise - daggerGravity * daggerLag * flightTime / 2
        end
        return angle
    end

    BuildDaggerGradient = function()
        for i = 0, gradientSteps do
            local fraction = i / gradientSteps
            gradient[i] = daggerColor:Lerp(daggerEndColor, fraction)
            hitGradient[i] = Color3.fromRGB(255, 120, 50):Lerp(Color3.fromRGB(255, 30, 30), fraction)
            missGradient[i] = Color3.fromRGB(255, 250, 170):Lerp(Color3.fromRGB(255, 215, 30), fraction)
        end
    end
    BuildDaggerGradient()

    local function BodyShape(target, t)
        local head = target.Head.Position
        local left, right = target.LeftLeg.Position, target.RightLeg.Position
        local feet = (left + right) / 2
        local bottom = math.min(left.Y, right.Y) - legHalfHeight
        local velocity = target.Motion.Velocity
        if t and velocity then
            local shift = vector.create(velocity.X, 0, velocity.Z) * t
            head += shift
            feet += shift
        end
        return head, feet, bottom, head.Y + headTop
    end

    local function PointInBody(point, head, feet, bottom, top)
        if point.Y < bottom or point.Y > top then return false end
        local ax, az = feet.X, feet.Z
        local dx, dz = head.X - ax, head.Z - az
        local lengthSquared = dx * dx + dz * dz
        local s = 0
        if lengthSquared > 0 then
            s = math.clamp(((point.X - ax) * dx + (point.Z - az) * dz) / lengthSquared, 0, 1)
        end
        local offX, offZ = point.X - (ax + dx * s), point.Z - (az + dz * s)
        return offX * offX + offZ * offZ <= hitRadius * hitRadius
    end

    local function SegmentHits(a, b, target, t)
        local head, feet, bottom, top = BodyShape(target, t)
        for i = 0, hitSamples do
            if PointInBody(a + (b - a) * (i / hitSamples), head, feet, bottom, top) then return true end
        end
        return false
    end

    local function TargetBody()
        if not screenCentre then return end
        local best, bestDistance
        local centreX = screenCentre.X
        for _, target in targets do
            local screen, visible = camera:WorldToScreenPoint(target.Root.Position)
            if visible then
                local distance = math.abs(screen.X - centreX)
                if not bestDistance or distance < bestDistance then
                    best, bestDistance = target, distance
                end
            end
        end
        return best
    end

    local function DrawArc(origin, velocity, startOffset, endY, checkHits, projection)
        local rise = velocity.Y + daggerGravity * daggerLag / 2
        local drop = if endY then origin.Y - endY else daggerMaxDrop
        local discriminant = rise * rise + 2 * daggerGravity * drop
        if discriminant < 0 then return end
        local endTime = math.min(daggerMaxTime, (rise + math.sqrt(discriminant)) / daggerGravity)
        local steps = math.max(1, math.ceil(endTime / daggerStep))
        local hit = false
        for i = 0, steps do
            local t = endTime * i / steps
            arcPoints[i] = origin + velocity * t - vector.create(0, daggerGravity * t * (t - daggerLag) / 2, 0)
            if checkHits == "Compute" and i > 0 and not hit then
                for _, target in targets do
                    if SegmentHits(arcPoints[i - 1], arcPoints[i], target, t) then
                        hit = true
                        break
                    end
                end
            end
        end
        if checkHits == "Compute" then return hit end
        local colors = if checkHits == nil then gradient elseif checkHits then hitGradient else missGradient
        local look, right, up = camera.LookVector, camera.RightVector, camera.UpVector
        local previous
        for i = 0, steps do
            local fraction = i / steps
            local point = arcPoints[i]
            if startOffset then point += startOffset * (1 - fraction) end
            local current
            if projection then
                local relative = point - origin
                local depth = vector.dot(relative, look)
                if depth > .05 then
                    current = projection.Centre + vector.create(vector.dot(relative, right) / depth * projection.Focal, -vector.dot(relative, up) / depth * projection.Focal, 0)
                end
            else
                local screen, visible = camera:WorldToScreenPoint(point)
                current = visible and vector.create(screen.X, screen.Y, 0) or nil
            end
            if current and previous then
                DrawingImmediate.Line(previous, current, colors[math.floor(fraction * gradientSteps)], 1, 2, 1)
            end
            previous = current
        end
    end

    local pastGradient = {}
    for i = 0, gradientSteps do
        pastGradient[i] = Color3.fromRGB(230, 110, 0):Lerp(Color3.fromRGB(255, 200, 130), i / gradientSteps)
    end
    local thrown = {}
    local workspaceChildren = {}
    local workspaceAddress
    local maxPathPoints = 400

    local function SpearPosition(primitive)
        local okX, x = pcall(memory.readf32, primitive, O.Primitive.Position)
        local okY, y = pcall(memory.readf32, primitive, O.Primitive.Position + 4)
        local okZ, z = pcall(memory.readf32, primitive, O.Primitive.Position + 8)
        if okX and okY and okZ and x == x and y == y and z == z then return vector.create(x, y, z) end
    end

    UpdateThrownDaggers = function(now)
        workspaceAddress = workspaceAddress or tonumber(workspace.Data)
        local raw = RawChildren(workspaceAddress)
        if not raw then return end

        for address in raw do
            if not workspaceChildren[address] then
                workspaceChildren[address] = true
                local inst = pointer_to_userdata(address)
                if inst.Name == "Spear" then
                    thrown[address] = {Model = inst, Path = {}, Started = now}
                end
            end
        end
        for address in workspaceChildren do
            if not raw[address] then
                workspaceChildren[address] = nil
                thrown[address] = nil
            end
        end

        for _, spear in thrown do
            if not spear.Primitive then
                local part = spear.Model:FindFirstChild("Spear1")
                local primitive = part and ReadU64(tonumber(part.Data), O.BasePart.Primitive)
                if IsHeapPointer(primitive) then spear.Primitive = primitive end
            end
            local position = spear.Primitive and SpearPosition(spear.Primitive)
            if position then
                local path = spear.Path
                local last = path[#path]
                if (not last or vector.magnitude(position - last) > .05) and #path < maxPathPoints then
                    path[#path + 1] = position
                end
            end
        end
    end

    local function DrawPath(path, count, colors)
        local previous
        for i = 1, count do
            local screen, visible = camera:WorldToScreenPoint(path[i])
            local current = visible and vector.create(screen.X, screen.Y, 0) or nil
            if current and previous then
                DrawingImmediate.Line(previous, current, colors[math.floor((i - 1) / math.max(1, count - 1) * gradientSteps)], 1, 2, 1)
            end
            previous = current
        end
    end

    RenderThrownDaggers = function()
        for _, spear in thrown do
            local path = spear.Path
            if #path > 1 then DrawPath(path, #path, pastGradient) end
        end
    end

    UpdateDaggerAim = function(now)
        if now >= nextRefresh then
            nextRefresh = now + refreshInterval
            Refresh()
        end
        local pressed = isleftpressed()
        local leftHeld = pressed == true or pressed == "true"
        for _, thrower in throwers do
            UpdateAimState(thrower.State, thrower.Animator, now)
            thrower.Aiming = thrower.State.Aiming == true and (not thrower.IsLocal or leftHeld)
            if thrower.IsLocal and thrower.Aiming and camera then
                local base = camera.Position + camera.LookVector * 100
                local centre, onScreen = camera:WorldToScreenPoint(base)
                local above = camera:WorldToScreenPoint(base + camera.UpVector * 10)
                if onScreen and centre.Y - above.Y > 0 then
                    thrower.Centre = vector.create(centre.X, centre.Y, 0)
                    thrower.Focal = (centre.Y - above.Y) * 10
                end
                local target = TargetBody()
                local endY
                if target then
                    local _, _, bottom = BodyShape(target)
                    endY = bottom
                elseif ownRoot then
                    endY = ownRoot.Position.Y - groundOffset
                end
                thrower.EndY = endY
                thrower.Hit = DrawArc(camera.Position, camera.LookVector * daggerSpeed, nil, endY, "Compute") == true
            end
        end
        for _, target in targets do
            UpdateKillerVelocity(target.Motion, target.Root.Position, now)
        end
    end

    RenderDaggerTrajectory = function()
        for _, thrower in throwers do
            if thrower.Aiming then
                if thrower.IsLocal then
                    DrawArc(camera.Position, camera.LookVector * daggerSpeed, camera.RightVector * localRightOffset + camera.LookVector * localForwardOffset, thrower.EndY, thrower.Hit == true, if thrower.Focal then thrower else nil)
                else
                    local origin = thrower.Root.Position + vector.create(0, daggerHeight, 0)
                    local look = thrower.Root.LookVector
                    local flat = vector.create(look.X, 0, look.Z)
                    if vector.magnitude(flat) > .01 then
                        flat = vector.normalize(flat)
                        local bestRoot, bestEndY, bestDot
                        local function Consider(root, endY)
                            local offset = root.Position - origin
                            local flatOffset = vector.create(offset.X, 0, offset.Z)
                            if vector.magnitude(flatOffset) < .5 then return end
                            local dot = vector.dot(vector.normalize(flatOffset), flat)
                            if not bestDot or dot > bestDot then
                                bestRoot, bestEndY, bestDot = root, endY, dot
                            end
                        end
                        for _, target in targets do
                            if target.Team == "Survivors" then
                                local _, _, bottom = BodyShape(target)
                                Consider(target.Root, bottom)
                            end
                        end
                        if ownIsSurvivor and ownRoot then Consider(ownRoot, ownRoot.Position.Y - groundOffset) end
                        local angle, endY = 0, nil
                        if bestRoot then
                            local aim = bestRoot.Position
                            angle = LaunchAngle(vector.magnitude(vector.create(aim.X - origin.X, 0, aim.Z - origin.Z)), aim.Y - origin.Y)
                            endY = bestEndY
                        end
                        DrawArc(origin, (flat * math.cos(angle) + vector.create(0, math.sin(angle), 0)) * daggerSpeed, nil, endY)
                    end
                end
            end
        end
    end
end

local bTrapESP = true
local trapColor = Color3.fromRGB(255, 70, 70)
local UpdateTraps, RenderTraps, ClearTraps

do
    local trapScanInterval = .5
    local armedInterval = 1
    local trapTextSize = 14
    local traps = {}
    local mapChildren = {}
    local mapAddress
    local nextScan = 0
    local nextArmed = 0

    ClearTraps = function()
        traps = {}
        mapChildren = {}
        mapAddress = nil
    end

    UpdateTraps = function(now)
        if now >= nextScan then
            nextScan = now + trapScanInterval
            local map = workspace:FindFirstChild("Map")
            local address = map and tonumber(map.Data)
            if address ~= mapAddress then
                traps, mapChildren, mapAddress = {}, {}, address
            end
            local raw = address and RawChildren(address)
            if raw then
                for child in raw do
                    if mapChildren[child] == nil then
                        local inst = pointer_to_userdata(child)
                        local isTrap = inst.Name == "BearTrap"
                        mapChildren[child] = isTrap
                        if isTrap then
                            local cubePose = PartPose(inst:FindFirstChild("Cube"))
                            if cubePose then
                                traps[child] = {Model = inst, Position = cubePose.Position, Armed = inst:GetAttribute("Armed")}
                            else
                                mapChildren[child] = nil
                            end
                        end
                    end
                end
                for child in mapChildren do
                    if not raw[child] then
                        mapChildren[child] = nil
                        traps[child] = nil
                    end
                end
            end
        end
        if now >= nextArmed then
            nextArmed = now + armedInterval
            for _, trap in traps do
                if trap.Armed ~= false and trap.Armed ~= "false" then
                    trap.Armed = trap.Model:GetAttribute("Armed")
                end
            end
        end
    end

    RenderTraps = function()
        for _, trap in traps do
            if trap.Armed == true or trap.Armed == "true" then
                local screen, visible = camera:WorldToScreenPoint(trap.Position)
                if visible then
                    DrawingImmediate.OutlinedText(vector.create(screen.X, screen.Y - trapTextSize / 2, 0), trapTextSize, trapColor, 1, "Bear Trap", true, "Nunito")
                end
            end
        end
    end
end

local view = {}
local highlightDistance = 1000
local bHighlightFill = false
local bHighlightOutline = true

local function MarkInFront(pose, anyDistance)
    if not view.Position then return end
    local size = pose.PartSize
    local reach = math.max(size.X, size.Y, size.Z) + 2
    local offset = pose.Position - view.Position
    if not anyDistance and vector.magnitude(offset) >= highlightDistance then
        pose.InFront = false
        return
    end
    local depth = vector.dot(offset, view.Look)
    if depth < -reach then
        pose.InFront = false
        return
    end
    local spread = math.max(depth, 0) + reach
    pose.InFront = math.abs(vector.dot(offset, view.Right)) - reach <= spread * view.TanX and math.abs(vector.dot(offset, view.Up)) - reach <= spread * view.TanY
end

local bWindowESP = true
local windowColor = Color3.fromRGB(204, 184, 184)
local UpdateWindows, RenderWindows, ClearWindows

do
    local windowCheckInterval = .5
    local fullScanInterval = 2
    local scanYieldEvery = 500
    local windows = {}
    local mapAddress
    local nextFullScan = 0
    local nextCheck = 0

    ClearWindows = function()
        windows, mapAddress, nextFullScan = {}, nil, 0
    end

    local function FullScan(map, address)
        local found = {}
        local count = 0
        for index, descendant in map:GetDescendants() do
            if descendant.Name == "Window" then
                local pose = PartPose(descendant:FindFirstChild("Bottom"))
                if pose then
                    found[tonumber(descendant.Data)] = pose
                    count += 1
                end
            end
            if index % scanYieldEvery == 0 then
                task.wait()
                if mapAddress ~= address then return end
            end
        end
        if mapAddress ~= address then return end
        local before = 0
        for _ in windows do before += 1 end
        windows = found
        if count ~= before then print(string.format("[windows] %d found", count)) end
    end

    UpdateWindows = function(now)
        for _, pose in windows do MarkInFront(pose) end
        if now < nextCheck then return end
        nextCheck = now + windowCheckInterval

        local map = workspace:FindFirstChild("Map")
        local address = map and tonumber(map.Data)
        if address ~= mapAddress then
            ClearWindows()
            mapAddress, nextFullScan = address, now + fullScanInterval
        end
        if address and now >= nextFullScan then
            nextFullScan = now + fullScanInterval
            task.spawn(FullScan, map, address)
        end
    end

    RenderWindows = function()
        for _, pose in windows do
            if pose.InFront ~= false and (bHighlightFill or bHighlightOutline) then
                pcall(h.Highlight, pose, windowColor, if bHighlightFill then .35 else 0, if bHighlightOutline then 1 else 0, 1.5)
            end
        end
    end
end

local bZombieESP = true
local UpdateZombies, ClearZombies

do
    local zombieScanInterval = .5
    local classifyWindow = 3
    local zombies = {}
    local ignored = {}
    local firstSeen = {}
    local mapAddress
    local nextScan = 0

    ClearZombies = function()
        for id in zombies do ESP.RemovePlayer(id) end
        zombies, ignored, firstSeen, mapAddress = {}, {}, {}, nil
    end

    UpdateZombies = function(now)
        if now < nextScan then return end
        nextScan = now + zombieScanInterval

        local map = workspace:FindFirstChild("Map")
        local address = map and tonumber(map.Data)
        if address ~= mapAddress then
            ClearZombies()
            mapAddress = address
        end
        local raw = address and RawChildren(address)
        if not raw then return end

        for child in raw do
            local id = tostring(child)
            if not zombies[id] and not ignored[child] then
                firstSeen[child] = firstSeen[child] or now
                local inst = pointer_to_userdata(child)
                local ok, className = pcall(memory.rtti, inst)
                if not ok or className ~= "RBX::ModelInstance" then
                    ignored[child] = true
                else
                    local humanoid = inst:FindFirstChildOfClass("Humanoid")
                    if humanoid and inst:FindFirstChild("HumanoidRootPart") and inst:FindFirstChild("RagdollConstraints") then
                        zombies[id] = child
                        ESP.AddPlayer(inst, {
                            TeamType = "Manual",
                            TeamName = "Zombies",
                            Username = "Zombie",
                            DisplayName = "Zombie",
                            UserId = 1,
                            HealthSource = humanoid,
                            ExternalRemoval = true,
                        })
                    elseif now - firstSeen[child] > classifyWindow then
                        ignored[child] = true
                    end
                end
            end
        end

        for id, child in zombies do
            if not raw[child] then
                zombies[id] = nil
                ESP.RemovePlayer(id)
            end
        end
        for child in ignored do
            if not raw[child] then ignored[child] = nil end
        end
        for child in firstSeen do
            if not raw[child] then firstSeen[child] = nil end
        end
    end
end

local bAutoCrouch = false
local UpdateAutoCrouch, ReleaseCrouch

do
    local crouchKey = 0xA2
    local waveSpeed = 70
    local waveLead = .35
    local waveHalfWidth = 6
    local waveHalfDepth = 3.1
    local waveMargin = 1.5
    local waveHeight = 6
    local releaseDelay = .15
    local refreshInterval = .5
    local waves = {}
    local workspaceChildren = {}
    local crouching = false
    local lastThreat = -math.huge
    local nextRefresh = 0
    local localRoot, isSurvivor

    local function WavePosition(primitive)
        local okX, x = pcall(memory.readf32, primitive, O.Primitive.Position)
        local okY, y = pcall(memory.readf32, primitive, O.Primitive.Position + 4)
        local okZ, z = pcall(memory.readf32, primitive, O.Primitive.Position + 8)
        if okX and okY and okZ and x == x and y == y and z == z then return vector.create(x, y, z) end
    end

    ReleaseCrouch = function()
        if crouching then keyrelease(crouchKey) end
        crouching = false
    end

    UpdateAutoCrouch = function(now)
        if now >= nextRefresh then
            nextRefresh = now + refreshInterval
            isSurvivor = PlayerTeam(LocalPlayer) == "Survivors"
            local character = LocalPlayer.Character
            local ok, className = false, nil
            if character then ok, className = pcall(memory.rtti, character) end
            localRoot = ok and className == "RBX::ModelInstance" and character:FindFirstChild("HumanoidRootPart") or nil
        end

        local raw = RawChildren(tonumber(workspace.Data))
        if raw then
            for address in raw do
                if not workspaceChildren[address] then
                    workspaceChildren[address] = true
                    local inst = pointer_to_userdata(address)
                    if inst.Name == "Wave" then
                        local part = inst:FindFirstChild("Part")
                        local primitive = part and ReadU64(tonumber(part.Data), O.BasePart.Primitive)
                        if IsHeapPointer(primitive) then waves[address] = {Primitive = primitive} end
                    end
                end
            end
            for address in workspaceChildren do
                if not raw[address] then
                    workspaceChildren[address] = nil
                    waves[address] = nil
                end
            end
        end

        if not isSurvivor or not localRoot then
            ReleaseCrouch()
            return
        end

        local me = localRoot.Position
        for _, wave in waves do
            local position = WavePosition(wave.Primitive)
            if position then
                wave.First = wave.First or position
                if not wave.Direction then
                    local moved = vector.create(position.X - wave.First.X, 0, position.Z - wave.First.Z)
                    if vector.magnitude(moved) > 1 then wave.Direction = vector.normalize(moved) end
                end
                local direction = wave.Direction
                if direction and math.abs(me.Y - position.Y) <= waveHeight then
                    local offset = vector.create(me.X - position.X, 0, me.Z - position.Z)
                    local along = vector.dot(offset, direction)
                    local lateral = math.abs(vector.dot(offset, vector.create(-direction.Z, 0, direction.X)))
                    if lateral <= waveHalfWidth + waveMargin and along >= -(waveHalfDepth + waveMargin) and along <= waveSpeed * waveLead + waveHalfDepth then
                        lastThreat = now
                    end
                end
            end
        end

        local shouldCrouch = now - lastThreat < releaseDelay
        if shouldCrouch and not crouching then
            keypress(crouchKey)
            crouching = true
        elseif not shouldCrouch and crouching then
            ReleaseCrouch()
        end
    end
end

local bAutoPallet = false
local UpdateAutoPallet

do
    local palletReach = 10
    local hitboxMargin = .5
    local droppedShift = 1.5
    local pressInterval = .05
    local refreshInterval = .5
    local nextRefresh = 0
    local nextPress = 0
    local killerRoot, localRoot, localIsSurvivor

    local function ValidRoot(character)
        local ok, className = pcall(memory.rtti, character)
        if not character or not ok or className ~= "RBX::ModelInstance" then return nil end
        return character:FindFirstChild("HumanoidRootPart")
    end

    local function Refresh()
        killerRoot = nil
        localIsSurvivor = PlayerTeam(LocalPlayer) == "Survivors"
        localRoot = ValidRoot(LocalPlayer.Character)
        for _, player in Players:GetChildren() do
            if player ~= LocalPlayer and PlayerTeam(player) == "Killer" then
                killerRoot = ValidRoot(player.Character)
                if killerRoot then break end
            end
        end
    end

    local function InsideHitbox(box, point)
        local offset = point - box.Position
        local size = box.Size
        return math.abs(vector.dot(offset, box.RightVector)) <= size.X / 2 + hitboxMargin
            and math.abs(vector.dot(offset, box.UpVector)) <= size.Y / 2 + hitboxMargin
            and math.abs(vector.dot(offset, box.LookVector)) <= size.Z / 2 + hitboxMargin
    end

    local function PressSpaceOnce()
        keypress(spaceKey)
        task.wait(.02)
        keyrelease(spaceKey)
    end

    UpdateAutoPallet = function(now)
        if now >= nextRefresh then
            nextRefresh = now + refreshInterval
            Refresh()
        end
        if not localIsSurvivor or not killerRoot or not localRoot or now < nextPress then return end

        local killerPos, localPos = killerRoot.Position, localRoot.Position

        for _, entry in pallets do
            local box = entry.Hitbox
            if box and not entry.Hidden and vector.magnitude(entry.Pose.Position - entry.RestPosition) < droppedShift
                and vector.magnitude(box.Position - localPos) <= palletReach and InsideHitbox(box, killerPos) then
                nextPress = now + pressInterval
                task.spawn(PressSpaceOnce)
                return
            end
        end
    end
end

local bInfoHud = true
local UpdateInfoHud, RenderInfoHud

do
    local style = {
        File = "vd_hud.txt",
        TitleHeight = 18,
        LineHeight = 16,
        TextSize = 14,
        CharWidth = 7,
        Padding = 6,
        GripSize = 10,
        MinWidth = 140,
        MinHeight = 80,
        KillerRefresh = .5,
        WorkingWindow = 1.5,
        Background = Color3.fromRGB(20, 20, 24),
        Bar = Color3.fromRGB(45, 45, 55),
        TextColor = Color3.fromRGB(235, 235, 235),
        Heading = Color3.fromRGB(160, 170, 190),
        Idle = Color3.fromRGB(255, 255, 255),
        Working = Color3.fromRGB(255, 220, 60),
        Failing = Color3.fromRGB(255, 60, 60),
        Done = Color3.fromRGB(90, 220, 90),
    }
    style.KillerAttributes = {
        Veil = {
            {Attribute = "spearmode", Name = "Spear equipped", Kind = "Bool", TrueColor = style.Failing},
            {Attribute = "Spears", Name = "Spears", Kind = "Number"},
            {Attribute = "special", Name = "Special spear ready", Kind = "Bool", TrueColor = style.Working},
        },
        Slasher = {
            {Attribute = "LakeMist", Name = "Invisible", Kind = "Bool", TrueColor = style.Failing},
            {Attribute = "Pursuit", Name = "Pursuiting", Kind = "Bool", TrueColor = style.Failing},
        },
        Butcher = {
            {Attribute = "beartraps", Name = "Bear traps available", Kind = "Number"},
        },
        Killer = {
            {Attribute = "Frenzy", Name = "Killer frenzy", Kind = "Bool", TrueColor = style.Failing},
        },
        Masked = {
            {Attribute = "Mask", Name = "Mask type", Kind = "Text", OtherColor = style.Working, Values = {
                Tony = {Text = "Lethal punches", Color = style.Working},
                Richard = {Text = "Basic"},
                Cobra = {Text = "Extended lunge", Color = style.Working},
                Rabbit = {Text = "Faster vaults", Color = style.Working},
                Brandon = {Text = "Walk faster", Color = style.Working},
                Richter = {Text = "Complete stealth", Color = style.Working},
                Alex = {Text = "Chainsaw time", Color = style.Working},
            }},
        },
    }
    style.CommonAttributes = {
        {Attribute = "Immobile", Name = "Stunned", Kind = "Bool", TrueColor = style.Working},
        {Attribute = "IsCarrying", Name = "Carrying survivor", Kind = "Bool", TrueColor = style.Working},
        {Attribute = "IsChasing", Name = "Chasing survivor", Kind = "Bool", TrueColor = style.Working},
        {Attribute = "speedboost", Name = "Speed multiplier", Kind = "Number", Prefix = "x", Decimals = 2, NormalValue = 1, ChangedColor = style.Working},
    }
    local position = vector.create(40, 200, 0)
    local size = vector.create(230, 300, 0)
    local dragMode, dragOffset
    local wasDown = false
    local nextKillerRefresh = 0
    local killerAddress, killerNode
    local nextNodeTry = 0
    local killerName = ""
    local generatorLines = {}
    local attributeLines = {}

    if isfile(style.File) then
        local x, y, w, h = string.match(readfile(style.File), "(%-?%d+) (%-?%d+) (%d+) (%d+)")
        if x then
            position = vector.create(tonumber(x), tonumber(y), 0)
            size = vector.create(math.max(tonumber(w), style.MinWidth), math.max(tonumber(h), style.MinHeight), 0)
        end
    end

    local function Entries(node)
        for _, layout in {{0x8, 0x10}, {0x18, 0x8}} do
            local first, packed = ReadU64(node, layout[1]), ReadU64(node, layout[2])
            if IsHeapPointer(first) and packed then
                local count = packed % 0x100000000
                local capacity = math.floor(packed / 0x100000000)
                if count > 0 and count <= capacity and capacity <= 256 then
                    local list = {}
                    for i = 0, count - 1 do
                        local entry = first + i * attributeStride
                        local namePointer = ReadU64(entry, 0)
                        if IsHeapPointer(namePointer) then
                            local name = ReadStdString(namePointer, 64)
                            if name == "" then name = ReadStdString(namePointer + 0x8, 64) end
                            if name ~= "" then list[#list + 1] = {Name = name, Entry = entry} end
                        end
                    end
                    if #list > 0 then
                        table.sort(list, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
                        return list
                    end
                end
            end
        end
        return nil
    end

    local function ValueText(entry)
        local text = ReadStdString(entry + attributeValueOffset, 64)
        if text ~= "" and not string.find(text, "[^\32-\126]") then return text end
        local okNumber, number = pcall(memory.readf64, entry, attributeValueOffset)
        if not okNumber or number ~= number then return "?" end
        if number ~= 0 and math.abs(number) < 1e-300 then
            local okByte, byte = pcall(memory.readu8, entry, attributeValueOffset)
            return if okByte and byte == 1 then "true" else "false"
        end
        if number == math.floor(number) and math.abs(number) < 1e9 then return string.format("%d", number) end
        return string.format("%.4g", number)
    end

    local function RefreshKiller(now)
        local character
        for _, player in Players:GetChildren() do
            if PlayerTeam(player) == "Killer" then
                character = player.Character
                break
            end
        end
        local ok, className = false, nil
        if character then ok, className = pcall(memory.rtti, character) end
        local address = ok and className == "RBX::ModelInstance" and tonumber(character.Data) or nil
        if address ~= killerAddress then
            killerAddress, killerNode, nextNodeTry = address, nil, 0
        end
        if killerAddress and not killerNode and now >= nextNodeTry then
            nextNodeTry = now + nodeRetryInterval
            killerNode = FindAttributeNode(killerAddress, "HookCount")
        end

        local lines = {}
        killerName = ""
        local entries = killerNode and Entries(killerNode)
        if killerNode and not entries then killerNode = nil end
        local byName = {}
        for _, item in entries or {} do
            byName[string.lower(item.Name)] = item.Entry
            if item.Name == "MorphedKiller" then killerName = ValueText(item.Entry) end
        end
        local function Show(shown)
            local entry = byName[string.lower(shown.Attribute)]
            local value, color = "?", style.TextColor
            if shown.Kind == "Bool" then
                local state = false
                if entry then
                    local okByte, byte = pcall(memory.readu8, entry, attributeValueOffset)
                    state = okByte and byte == 1
                end
                value = if state then "true" else "false"
                if state and shown.TrueColor then color = shown.TrueColor end
            elseif entry and shown.Kind == "Text" then
                value = ValueText(entry)
                local mapped = shown.Values and shown.Values[value]
                if mapped then
                    value = mapped.Text
                    color = mapped.Color or style.TextColor
                elseif shown.OtherColor then
                    color = shown.OtherColor
                end
            elseif entry then
                value = ValueText(entry)
                local number = tonumber(value)
                if shown.NormalValue and number and number > shown.NormalValue + 1e-6 then color = shown.ChangedColor end
                if shown.Decimals and number then
                    local scale = 10 ^ shown.Decimals
                    value = string.format("%." .. shown.Decimals .. "f", math.floor(number * scale + 1e-9) / scale)
                end
                if shown.Prefix then value = shown.Prefix .. value end
            end
            lines[#lines + 1] = {Text = shown.Name .. ": " .. value, Color = color}
        end
        for _, shown in style.KillerAttributes[killerName] or {} do Show(shown) end
        for _, shown in style.CommonAttributes do Show(shown) end
        attributeLines = lines
    end

    local function RefreshGenerators(now)
        local list = {}
        for _, entry in generators do list[#list + 1] = entry end
        table.sort(list, function(a, b) return a.Address < b.Address end)
        local lines = {}
        for index, entry in list do
            local color = style.Idle
            if entry.Completed then
                color = style.Done
            elseif entry.Regressing then
                color = style.Failing
            elseif entry.Repairing or (entry.LastRise and now - entry.LastRise < style.WorkingWindow) then
                color = style.Working
            end
            lines[index] = {Text = string.format("Generator: %s", if entry.Text ~= "" then entry.Text else "?"), Color = color}
        end
        generatorLines = lines
    end

    local function Inside(point, corner, width, height)
        return point.X >= corner.X and point.Y >= corner.Y and point.X <= corner.X + width and point.Y <= corner.Y + height
    end

    local function HandleMouse()
        local pressed = isleftpressed()
        local down = pressed == true or pressed == "true"
        local mouse = getmouseposition()
        if down and not wasDown then
            local grip = position + size - vector.create(style.GripSize, style.GripSize, 0)
            if Inside(mouse, grip, style.GripSize, style.GripSize) then
                dragMode, dragOffset = "resize", position + size - mouse
            elseif Inside(mouse, position, size.X, style.TitleHeight) then
                dragMode, dragOffset = "move", position - mouse
            end
        elseif not down and dragMode then
            dragMode = nil
            writefile(style.File, string.format("%d %d %d %d", math.floor(position.X), math.floor(position.Y), math.floor(size.X), math.floor(size.Y)))
        end
        wasDown = down

        if dragMode == "move" then
            position = mouse + dragOffset
        elseif dragMode == "resize" then
            local corner = mouse + dragOffset - position
            size = vector.create(math.max(corner.X, style.MinWidth), size.Y, 0)
        end
    end

    UpdateInfoHud = function(now)
        HandleMouse()
        if now >= (style.NextGenerators or 0) then
            style.NextGenerators = now + .25
            RefreshGenerators(now)
        end
        if now >= nextKillerRefresh then
            nextKillerRefresh = now + style.KillerRefresh
            RefreshKiller(now)
        end
    end

    RenderInfoHud = function()
        local lineCount = 2 + math.max(#generatorLines, 1) + (if killerAddress then #attributeLines else 1)
        size = vector.create(size.X, style.TitleHeight + 8 + lineCount * style.LineHeight + style.Padding, 0)
        DrawingImmediate.FilledRectangle(position, size, style.Background, .85, 4)
        DrawingImmediate.FilledRectangle(position, vector.create(size.X, style.TitleHeight, 0), style.Bar, 1, 4)
        DrawingImmediate.OutlinedText(position + vector.create(style.Padding, 2, 0), style.TextSize, style.TextColor, 1, "Info", false, "Nunito")
        DrawingImmediate.FilledRectangle(position + size - vector.create(style.GripSize, style.GripSize, 0), vector.create(style.GripSize, style.GripSize, 0), style.Bar, 1, 0)

        local maxChars = math.max(math.floor((size.X - style.Padding * 2) / style.CharWidth), 4)
        local x = position.X + style.Padding
        local y = position.Y + style.TitleHeight + 4
        local bottom = position.Y + size.Y - style.LineHeight

        local function Line(text, color, indent)
            if y > bottom then return false end
            if #text > maxChars then text = string.sub(text, 1, maxChars - 2) .. ".." end
            DrawingImmediate.OutlinedText(vector.create(x + indent, y, 0), style.TextSize, color, 1, text, false, "Nunito")
            y += style.LineHeight
            return true
        end

        if not Line("Generators", style.Heading, 0) then return end
        if #generatorLines == 0 and not Line("none found", style.TextColor, 0) then return end
        for _, line in generatorLines do
            if not Line(line.Text, line.Color, 0) then return end
        end

        y += 4
        if not Line(if killerName ~= "" then "Killer: " .. killerName else "Killer", style.Heading, 0) then return end
        if not killerAddress then
            Line("no killer found", style.TextColor, 0)
            return
        end
        for _, line in attributeLines do
            if not Line(line.Text, line.Color, 0) then return end
        end
    end
end

local function Render()
    if bInfoHud then RenderInfoHud() end
    if not camera then return end

    if bDaggerTrajectory then
        RenderDaggerTrajectory()
        RenderThrownDaggers()
    end
    if bTrapESP then RenderTraps() end

    local flashLeft = parryFlashUntil - os.clock()
    if screenCentre and flashLeft > 0 then
        local shake = 8 * flashLeft / parryFlashTime
        local offset = vector.create((math.random() * 2 - 1) * shake, (math.random() * 2 - 1) * shake - 26, 0)
        DrawingImmediate.OutlinedText(screenCentre + offset, 52, parryAttackColor, 1, parryText, true, "Nunito")
    end

    if bShowParryRange then RenderParryRange() end

    if bPalletESP then
        for _, entry in pallets do
            if not entry.Hidden and entry.Pose.InFront ~= false and (bHighlightFill or bHighlightOutline) then
                pcall(h.Highlight, entry.Pose, palletColor, if bHighlightFill then .35 else 0, if bHighlightOutline then 1 else 0, 1.5)
            end
        end
    end

    if bWindowESP then RenderWindows() end

    if not bGeneratorESP then return end
    for _, entry in generators do
        local color = if entry.Completed then completedColor elseif entry.Regressing then regressingColor else generatorColor
        local pose = entry.Pose
        if pose.InFront == false then continue end
        if bHighlightFill or bHighlightOutline then
            pcall(h.Highlight, pose, color, if bHighlightFill then .2 else 0, if bHighlightOutline then .7 else 0, 1)
        end
        local screen, visible = camera:WorldToScreenPoint(pose.Position)
        if visible then
            DrawingImmediate.OutlinedText(vector.create(screen.X, screen.Y - generatorTextSize / 2, 0), generatorTextSize, color, 1, entry.Text, true, "Nunito")
        end
    end
end

local function SyncFlags()
    for flag, apply in FlagSetters do
        local value = window:get(flag)
        if value ~= AppliedFlags[flag] then
            AppliedFlags[flag] = value
            apply(value)
        end
    end
end

window = UI.new({
    Title = "Andris: Violence District",
    Subtitle = "Skill check & ESP",
    Version = "2.0.0",
    Folder = "AndrisViolenceDistrict",
    UpdateNotice = {"V2.0.0", "Auto dagger fixed", "Added abysswalker auto crouch", "Added info HUD", "Added more highlighter customizability"},
    Footer = "Veil is the stupidest fucking killer ever",
    OnUnload = function()
        if _G.ViolenceDistrictRunId == runId then _G.ViolenceDistrictRunId = nil end
        if renderConnect then renderConnect:Disconnect() end
        ClearGenerators()
        ClearPallets()
        ClearPlayers()
        ClearZombies()
        ReleaseCrouch()
    end,
})

do
    local mainTab = window:tab("Main")
    local mainSection = mainTab:section("Main")

    mainSection:label("Auto skill check")

    mainSection:toggle({Name = "Auto skill check", Flag = "AutoSkillCheck", Default = true})
    FlagSetters.AutoSkillCheck = function(val)
        bAutoSkillCheck = val
    end

    mainSection:label("Auto parry")

    mainSection:toggle({Name = "Auto parry", Flag = "ParryDetect", Default = true})
    FlagSetters.ParryDetect = function(val)
        bParryDetect = val
        parryKiller = nil
        activeAttack = nil
    end

    mainSection:toggle({Name = "Show parry range", Flag = "ShowParryRange", Default = true})
    FlagSetters.ShowParryRange = function(val)
        bShowParryRange = val
    end

    mainSection:label("Auto pallet")

    mainSection:toggle({Name = "Auto pallet", Flag = "AutoPallet", Default = true})
    FlagSetters.AutoPallet = function(val)
        bAutoPallet = val
        if not val and not bPalletESP then ClearPallets() end
    end

    mainSection:label("Auto crouch")

    mainSection:toggle({Name = "Crouch under Abysswalker waves", Flag = "AutoCrouch", Default = true})
    FlagSetters.AutoCrouch = function(val)
        bAutoCrouch = val
        if not val then ReleaseCrouch() end
    end
end

do
    local visualTab = window:tab("Visual")
    local esp = visualTab:section("ESP")

    esp:toggle({Name = "Generator ESP", Flag = "GeneratorESP", Default = true})
    FlagSetters.GeneratorESP = function(val)
        bGeneratorESP = val
        if not val then ClearGenerators() end
    end

    esp:toggle({Name = "Info HUD", Flag = "InfoHud", Default = true})
    FlagSetters.InfoHud = function(val)
        bInfoHud = val
    end

    esp:toggle({Name = "Pallet ESP", Flag = "PalletESP", Default = true})
    FlagSetters.PalletESP = function(val)
        bPalletESP = val
        if not val and not bAutoPallet then ClearPallets() end
    end

    esp:toggle({Name = "Veil dagger trajectory", Flag = "DaggerTrajectory", Default = true})
    FlagSetters.DaggerTrajectory = function(val)
        bDaggerTrajectory = val
    end

    esp:toggle({Name = "Cure zombie ESP", Flag = "ZombieESP", Default = true})
    FlagSetters.ZombieESP = function(val)
        bZombieESP = val
        if not val then ClearZombies() end
    end

    esp:toggle({Name = "Window ESP", Flag = "WindowESP", Default = true})
    FlagSetters.WindowESP = function(val)
        bWindowESP = val
        if not val then ClearWindows() end
    end

    esp:toggle({Name = "Bear trap ESP", Flag = "TrapESP", Default = true})
    FlagSetters.TrapESP = function(val)
        bTrapESP = val
        if not val then ClearTraps() end
    end

    local highlighting = visualTab:section("HIGHLIGHTING")

    highlighting:slider({Name = "Highlight render distance", Flag = "HighlightDistance", Min = 25, Max = 1000, Default = highlightDistance, Step = 25})
    FlagSetters.HighlightDistance = function(val)
        highlightDistance = tonumber(val) or 1000
    end

    highlighting:toggle({Name = "Highlight fill", Flag = "HighlightFill", Default = false})
    FlagSetters.HighlightFill = function(val)
        bHighlightFill = val
    end

    highlighting:toggle({Name = "Highlight outline", Flag = "HighlightOutline", Default = true})
    FlagSetters.HighlightOutline = function(val)
        bHighlightOutline = val
    end

    local colors = visualTab:section("COLORS")

    colors:color({Name = "Pallet color", Flag = "PalletColor", Default = palletColor})
    FlagSetters.PalletColor = function(val)
        palletColor = val
    end

    colors:color({Name = "Window color", Flag = "WindowColor", Default = windowColor})
    FlagSetters.WindowColor = function(val)
        windowColor = val
    end

    colors:color({Name = "Generator color", Flag = "GeneratorColor", Default = generatorColor})
    FlagSetters.GeneratorColor = function(val)
        generatorColor = val
    end

    colors:color({Name = "Completed generator color", Flag = "CompletedColor", Default = completedColor})
    FlagSetters.CompletedColor = function(val)
        completedColor = val
    end

    colors:color({Name = "Kicked generator color", Flag = "RegressingColor", Default = regressingColor})
    FlagSetters.RegressingColor = function(val)
        regressingColor = val
    end

    colors:color({Name = "Bear trap color", Flag = "TrapColor", Default = trapColor})
    FlagSetters.TrapColor = function(val)
        trapColor = val
    end

    colors:color({Name = "Veil dagger trajectory start color", Flag = "DaggerColor", Default = daggerColor})
    FlagSetters.DaggerColor = function(val)
        daggerColor = val
        BuildDaggerGradient()
    end

    colors:color({Name = "Veil dagger trajectory end color", Flag = "DaggerEndColor", Default = daggerEndColor})
    FlagSetters.DaggerEndColor = function(val)
        daggerEndColor = val
        BuildDaggerGradient()
    end
end

window:start()

task.spawn(function()
    while _G.ViolenceDistrictRunId == runId do
        SyncFlags()
        if isrbxactive() then
            camera = workspace.CurrentCamera
            if camera then
                local viewport = camera.ViewportSize
                screenCentre = vector.create(viewport.X / 2, viewport.Y / 2, 0)
                local tanY = math.tan(math.rad(camera.FieldOfView) / 2) * 1.3
                view.Position, view.Look, view.Right, view.Up = camera.Position, camera.LookVector, camera.RightVector, camera.UpVector
                view.TanY, view.TanX = tanY, tanY * viewport.X / math.max(viewport.Y, 1)
            end
            if bParryDetect or bShowParryRange then UpdateParry(os.clock()) end
            if bDaggerTrajectory then
                UpdateDaggerAim(os.clock())
                UpdateThrownDaggers(os.clock())
            end
            if bAutoSkillCheck then UpdateSkillCheck() end
            if bGeneratorESP or bInfoHud then UpdateGenerators() end
            if bInfoHud then UpdateInfoHud(os.clock()) end
            if os.clock() >= nextPlayerScan then
                nextPlayerScan = os.clock() + playerScanInterval
                ScanPlayers()
            end
            if (bPalletESP or bAutoPallet) and os.clock() >= nextPalletScan then
                nextPalletScan = os.clock() + palletScanInterval
                ScanPallets()
            end
            if bPalletESP or bAutoPallet then
                local now = os.clock()
                for _, entry in pallets do
                    if not entry.Hidden then
                        if not entry.Settled and (now >= (entry.NextPose or 0) or (camera and vector.magnitude(entry.Pose.Position - camera.Position) <= 60)) then
                            entry.NextPose = now + .25
                            UpdatePalletPose(entry)
                        end
                        MarkInFront(entry.Pose)
                    end
                end
            end
            if bGeneratorESP then
                for _, entry in generators do MarkInFront(entry.Pose, true) end
            end
            if bAutoPallet then UpdateAutoPallet(os.clock()) end
            if bAutoCrouch then UpdateAutoCrouch(os.clock()) end
            if bTrapESP then UpdateTraps(os.clock()) end
            if bWindowESP then UpdateWindows(os.clock()) end
            if bZombieESP then UpdateZombies(os.clock()) end
        end
        task.wait()
    end
end)

renderConnect = RunService.Render:Connect(Render)

print("Loaded")

else
    print("Not in Violence District")
end
