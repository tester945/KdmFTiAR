if game.GameId == 6739698191 then

local generatorColor = Color3.fromRGB(157, 159, 255)
local palletColor = Color3.fromRGB(255, 140, 0)
local windowColor = Color3.fromRGB(204, 184, 184)
local completedColor = Color3.fromRGB(80, 220, 100)
local repairingColor = Color3.fromRGB(255, 220, 60)
local regressingColor = Color3.fromRGB(255, 60, 60)
local textSize = 14
local textFont = Drawing.Fonts and (Drawing.Fonts.SystemBold or Drawing.Fonts.System)
local bGeneratorESP = true
local bPalletESP = true
local bWindowESP = true
local bAutoSkillCheck = true
local bAutoParry = true
local bShowParryRange = true
local bDaggerTrajectory = true
local daggerColor = Color3.fromRGB(170, 120, 255)
local daggerEndColor = Color3.fromRGB(255, 80, 80)
local bTrapESP = true
local bZombieESP = true
local bAutoPallet = true
local bAutoCrouch = true
local bInfoHud = true
local bKickedColor = true
local bHighlightFill = true
local bHighlightOutline = true
local highlightDistance = 1000
local fillOpacity = .35
local trapColor = Color3.fromRGB(255, 70, 70)
local zombieColor = Color3.fromRGB(120, 255, 120)
local skillCheckAngle = 108
local outlineThickness = 1.5
local palletNearDistance = 150
local progressPollInterval = .5
local progressStateTime = 1.5
local palletSize = Vector3.new(6.0, 7.4, 1.3)
local generatorSize = Vector3.new(8.19, 5.24, 5.10)
local generatorFolders = {"Gens", "Generators", "newGenerators", "new Generators", "Generator"}
local palletFolders = {"Pallets", "pallets"}
local windowScanInterval = 2
local windowStableScans = 1
local minimumWindows = 3
local palletPollInterval = .125
local loopInterval = 1 / 60
local bDebugStats = false
local vault = {Enabled = false}
local bMoonwalk = false

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local function FetchOffsets()
    local urls = {"https://offsets.imtheo.lol/" .. tostring(getrbxversion()) .. "/offsets.json", "https://offsets.imtheo.lol/offsets.json"}
    for _, url in urls do
        local body = httpget(url)
        if type(body) == "string" and string.sub(body, 1, 1) == "{" then
            local decoded = HttpService:JSONDecode(body)
            if type(decoded) == "table" and type(decoded.Offsets) == "table" then return decoded.Offsets end
        end
    end
    print("[MatchaVD] couldn't load offsets, auto parry off")
    return {}
end

local O = FetchOffsets()
local visibleOffset = tonumber(O.GuiObject and O.GuiObject.Visible) or 0x575
local activeAnimationsOffset = tonumber(O.Animator and O.Animator.ActiveAnimations)
local trackAnimationOffset = tonumber(O.AnimationTrack and O.AnimationTrack.Animation)
local animationIdOffset = tonumber(O.Misc and O.Misc.AnimationId)
local childrenStartOffset = tonumber(O.Instance and O.Instance.ChildrenStart)
local childrenEndOffset = tonumber(O.Instance and O.Instance.ChildrenEnd)
local nameOffset = tonumber(O.Instance and O.Instance.Name)
local primitiveOffset = tonumber(O.BasePart and O.BasePart.Primitive)
local primitivePositionOffset = tonumber(O.Primitive and O.Primitive.Position)
local memoryReady = childrenStartOffset and childrenEndOffset and nameOffset and primitiveOffset and primitivePositionOffset and true or false

local Players = game:GetService("Players")
local attackAnimations = {
    ["129626174716003"] = {Name = "Slasher"},
    ["135002183282873"] = {Name = "Cure"},
    ["125430111937587"] = {Name = "Abysswalker"},
    ["100014992013740"] = {Name = "Abysswalker lunge", Linger = 1.1},
    ["104540716539347"] = {Name = "Killer special"},
    ["93902163029544"] = {Name = "Killer"},
    ["83333467665074"] = {Name = "Butcher"},
    ["105374834496520"] = {Name = "Masked bat"},
    ["115244153053858"] = {Name = "Masked knife"},
    ["117042998468241"] = {Name = "Stalker"},
    ["84926129581106"] = {Name = "Veil"},
    ["113255068724446"] = {Name = "Hidden"},
}
local attackDefaults = {Windup = 0, Linger = .8, Length = 5.4, Height = 7}
local parrySafety = .1
local localRadius = 1.5
local localHalfHeight = 2.5
local parryHistoryTime = .3
local parryCooldown = 1
local parryRangeColor = Color3.fromRGB(255, 255, 255)
local parryAttackColor = Color3.fromRGB(255, 70, 70)
local parryCircleSegments = 36

local runId = tick()
_G.MatchaVDRunId = runId
if _G.MatchaVDConnection then _G.MatchaVDConnection:Disconnect() end
for _, object in _G.MatchaVDDrawings or {} do
    if type(object) == "table" then (object.Square or object.Object):Remove() else object:Remove() end
end
local allDrawings = {}
_G.MatchaVDDrawings = allDrawings

local frame = {}
local stats = {Loops = 0, LoopTime = 0, Renders = 0, RenderTime = 0, Writes = 0, Lines = 0, Next = 0, Skill = 0, Scans = 0, ScanTime = 0, ScanMax = 0}
local windows = {}

local function Running()
    return _G.MatchaVDRunId == runId
end

local function Valid(pointer)
    return pointer ~= nil and pointer > 0x10000 and pointer < 0x7FFFFFFFFFFF
end

local function NextSlot(now, phase)
    return (math.floor((now - phase) / .5) + 1) * .5 + phase
end

local scheduler = {Jobs = {}, Budget = .002, Tick = 1 / 60, Rotation = 0}

local function Sleep(seconds)
    local job = scheduler.Current
    if job and coroutine.running() == job.Thread then
        job.WakeAt = tick() + (seconds or 0)
        coroutine.yield()
    else
        task.wait(seconds)
    end
end

local function Yield()
    Sleep(0)
end

local function AddJob(name, critical, fn)
    local job = {Name = name, Critical = critical, Fn = fn, WakeAt = 0}
    job.Thread = coroutine.create(fn)
    table.insert(scheduler.Jobs, if critical then 1 else #scheduler.Jobs + 1, job)
end

local function ResumeJob(job, now)
    scheduler.Current = job
    job.WakeAt = math.huge
    local ok, err = coroutine.resume(job.Thread)
    scheduler.Current = nil
    if not ok then
        print("[MatchaVD] " .. job.Name .. " failed, restarting in 1 s: " .. tostring(err))
        job.Thread, job.WakeAt = coroutine.create(job.Fn), now + 1
    elseif coroutine.status(job.Thread) == "dead" then
        job.Done = true
    end
end

task.spawn(function()
    while Running() do
        local started = os.clock()
        local now = tick() + scheduler.Tick / 2
        local jobs = scheduler.Jobs
        local count = #jobs
        scheduler.Rotation += 1
        for _, job in jobs do
            if job.Critical and not job.Done and now >= job.WakeAt then ResumeJob(job, now) end
        end
        for i = 1, count do
            local job = jobs[(i + scheduler.Rotation) % count + 1]
            if not job.Critical and not job.Done and now >= job.WakeAt then
                if os.clock() - started > scheduler.Budget then break end
                ResumeJob(job, now)
            end
        end
        task.wait(scheduler.Tick)
    end
end)

local blockReads = false
do
    local ok, result = pcall(memory_read, "buffer", workspace.Address, 16)
    if ok and type(result) == "string" then result = buffer.fromstring(result) end
    if ok and type(result) == "buffer" and buffer.len(result) >= 16 then
        local low, high = buffer.readu32(result, 0), buffer.readu32(result, 4)
        blockReads = low + high * 4294967296 == memory_read("uintptr_t", workspace.Address)
    end
end

local function ReadBlock(address, size)
    if not blockReads then return nil end
    local result = memory_read("buffer", address, size)
    if type(result) == "string" then result = buffer.fromstring(result) end
    return if type(result) == "buffer" and buffer.len(result) >= size then result else nil
end

local function BlockU64(block, offset)
    return buffer.readu32(block, offset) + buffer.readu32(block, offset + 4) * 4294967296
end

local parry = {History = {}, LastParry = 0, NextRefresh = 0, AnimationIds = {}}
local world = {NextRefresh = 0, NextKillerType = 0, KillerType = ""}

local function ReadStdString(address)
    local capacity = memory_read("uintptr_t", address + 0x18)
    local text = if capacity and capacity >= 16 then memory_read("uintptr_t", address) else address
    local raw = if Valid(text) then memory_read("string", text) else nil
    return if type(raw) == "string" then raw else ""
end

local function MemoryChildren(address)
    local list = memory_read("uintptr_t", address + childrenStartOffset)
    if not Valid(list) then return nil end
    local first = memory_read("uintptr_t", list)
    local last = memory_read("uintptr_t", list + childrenEndOffset)
    if not Valid(first) or not last or last < first or last - first > 0x10 * 10000 then return nil end
    local result = {}
    local block = last > first and ReadBlock(first, last - first)
    if block then
        for offset = 0, last - first - 0x10, 0x10 do
            local child = BlockU64(block, offset)
            if Valid(child) then result[#result + 1] = child end
        end
        return result
    end
    for entry = first, last - 0x10, 0x10 do
        local child = memory_read("uintptr_t", entry)
        if Valid(child) then result[#result + 1] = child end
    end
    return result
end

local function MemoryName(address)
    local pointer = memory_read("uintptr_t", address + nameOffset)
    return if Valid(pointer) then ReadStdString(pointer) else ""
end

if memoryReady then
    local samples = workspace:GetChildren()
    local function NameOffsetWorks(offset)
        if #samples == 0 then return false end
        for i = 1, math.min(#samples, 5) do
            local pointer = memory_read("uintptr_t", samples[i].Address + offset)
            if not Valid(pointer) or ReadStdString(pointer) ~= samples[i].Name then return false end
        end
        return true
    end
    if not NameOffsetWorks(nameOffset) then
        local found
        for offset = 0, 0x200, 8 do
            if NameOffsetWorks(offset) then
                found = offset
                break
            end
        end
        if not found then print(string.format("[MatchaVD] Instance.Name offset 0x%X is wrong and no other offset matched, memory scans off", nameOffset)) end
        nameOffset = found
        memoryReady = found ~= nil
    end
end

local function MemoryChildNames(address)
    local names = {}
    for _, child in MemoryChildren(address) or {} do
        names[MemoryName(child)] = child
    end
    return names
end

local function MemoryPosition(partAddress)
    local primitive = memory_read("uintptr_t", partAddress + primitiveOffset)
    if not Valid(primitive) then return nil end
    local base = primitive + primitivePositionOffset
    local x, y, z
    local block = ReadBlock(base, 12)
    if block then
        x, y, z = buffer.readf32(block, 0), buffer.readf32(block, 4), buffer.readf32(block, 8)
    else
        x, y, z = memory_read("float", base), memory_read("float", base + 4), memory_read("float", base + 8)
    end
    if not x or not y or not z or x ~= x or y ~= y or z ~= z or math.abs(x) > 1e6 or math.abs(y) > 1e6 or math.abs(z) > 1e6 then return nil end
    return Vector3.new(x, y, z)
end

local function NewAttributeReader(anchor)
    return {Anchor = anchor, NextTry = 0, Backoff = 2}
end

local ReadAttribute

do
    local valueOffset, stride, rootOffset = 0x18, 0x58, 0x38

    local function AttributeName(pointer)
        if not Valid(pointer) then return "" end
        local name = ReadStdString(pointer)
        if name == "" then name = ReadStdString(pointer + 8) end
        return name
    end

    local function EntryMap(first, packed)
        if not Valid(first) or not packed then return nil end
        local count, capacity = packed % 4294967296, math.floor(packed / 4294967296)
        if count <= 0 or count > capacity or capacity > 256 then return nil end
        local map, valid = {}, false
        for i = 0, count - 1 do
            local entry = first + i * stride
            local name = AttributeName(memory_read("uintptr_t", entry))
            if name ~= "" then
                valid = true
                map[name] = entry
            end
        end
        return if valid then map else nil
    end

    local function NodeEntries(node)
        local a, b, c = memory_read("uintptr_t", node + 8), memory_read("uintptr_t", node + 0x10), memory_read("uintptr_t", node + 0x18)
        return EntryMap(a, b) or EntryMap(c, a), string.format("%s %s %s", tostring(a), tostring(b), tostring(c))
    end

    local function FindNode(address, anchor)
        local root = memory_read("uintptr_t", address + rootOffset)
        if not Valid(root) then return nil end
        local queue, visited, index = {root}, {}, 1
        while index <= #queue and index <= 64 do
            local node = queue[index]
            index += 1
            if not visited[node] then
                visited[node] = true
                local entries = NodeEntries(node)
                if entries and entries[anchor] then return node end
                for _, offset in {0, 0x10} do
                    local pointer = memory_read("uintptr_t", node + offset)
                    if Valid(pointer) and not visited[pointer] then queue[#queue + 1] = pointer end
                end
            end
        end
        return nil
    end

    local function Value(entry, kind)
        if kind == "Bool" then return memory_read("byte", entry + valueOffset) == 1 end
        if kind == "Text" then return ReadStdString(entry + valueOffset) end
        local number = memory_read("double", entry + valueOffset)
        return if number == number then number else nil
    end

    ReadAttribute = function(reader, instance, name, kind, now)
        local address = instance and instance.Address
        if not address then return nil end
        if reader.Address ~= address then
            reader.Address, reader.Node, reader.Entries, reader.Layout, reader.NextTry, reader.Backoff = address, nil, nil, nil, 0, 2
        end
        if not reader.Node and now >= reader.NextTry then
            reader.Node = FindNode(address, reader.Anchor)
            if not reader.Node then
                reader.NextTry = now + reader.Backoff
                reader.Backoff = math.min(reader.Backoff * 2, 30)
            end
        end
        local node = reader.Node
        if node then
            local layout = string.format("%s %s %s", tostring(memory_read("uintptr_t", node + 8)), tostring(memory_read("uintptr_t", node + 0x10)), tostring(memory_read("uintptr_t", node + 0x18)))
            if layout ~= reader.Layout then
                local entries = NodeEntries(node)
                if entries and entries[reader.Anchor] then
                    reader.Entries, reader.Layout = entries, layout
                else
                    reader.Node, reader.Entries, reader.Layout, reader.NextTry = nil, nil, nil, now + reader.Backoff
                end
            end
            if reader.Entries then
                local entry = reader.Entries[name]
                return if entry then Value(entry, kind) else nil
            end
        end
        return instance:GetAttribute(name)
    end
end

local function Finish(pose)
    local half = pose.Size / 2
    local right, up, look = pose.Right * half.X, pose.Up * half.Y, pose.Look * half.Z
    local corners = table.create(24)
    for corner = 0, 7 do
        local point = pose.Position
            + right * (if corner % 2 == 0 then 1 else -1)
            + up * (if math.floor(corner / 2) % 2 == 0 then 1 else -1)
            + look * (if corner >= 4 then 1 else -1)
        corners[corner * 3 + 1], corners[corner * 3 + 2], corners[corner * 3 + 3] = point.X, point.Y, point.Z
    end
    pose.Corners = corners
    pose.CX, pose.CY, pose.CZ = pose.Position.X, pose.Position.Y, pose.Position.Z
    return pose
end

local function PartPose(part, fixedSize)
    if not part then return nil end
    local cframe = part.CFrame
    local size = fixedSize or part.Size
    if not cframe or not size or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then return nil end
    return Finish({Position = cframe.Position, Size = size, Right = cframe.RightVector, Up = cframe.UpVector, Look = cframe.LookVector})
end

local function ReadGenerator(generator)
    local pose = PartPose(generator:FindFirstChild("GeneratorBody"), generatorSize)
    return pose and {Pose = pose, Model = generator, Text = "", NextPoll = tick() + math.random() * progressPollInterval, RisingUntil = 0, FallingUntil = 0}
end

local function ReadPallet(pallet)
    local intact = pallet:FindFirstChild("Intact")
    local broken = pallet:FindFirstChild("Broken")
    local part = intact and intact:FindFirstChild("Pallet")
    local brokenPart = broken and broken:FindFirstChild("Pallet_Broken")
    local pose = part and brokenPart and PartPose(part, palletSize)
    if not pose then return nil end
    return {Part = part, BrokenPart = brokenPart, IntactPose = pose, Pose = pose, Hitbox = PartPose(pallet:FindFirstChild("hitbox")), Dropped = false, Pending = 0, NextPoll = 0}
end

local trackers = {
    Generators = {Names = generatorFolders, Child = "Generator", Read = ReadGenerator, Entries = {}},
    Pallets = {Names = palletFolders, Child = "Newpallet", Read = ReadPallet, Entries = {}},
}

local function ResetTracker(tracker)
    tracker.Folder, tracker.Parent, tracker.Name, tracker.Address = nil, nil, nil, nil
    tracker.Entries, tracker.Complete, tracker.NextSearch = {}, false, 0
end

local function FindFolder(map, tracker)
    local resources = map:FindFirstChild("resources")
    for _, parent in {map, resources} do
        for _, name in tracker.Names do
            Yield()
            if not Running() then return end
            local found = parent:FindFirstChild(name)
            if found and found:FindFirstChild(tracker.Child) then
                tracker.Folder, tracker.Parent, tracker.Name, tracker.Address = found, parent, name, found.Address
                return
            end
        end
    end
end

local function ReadEntries(tracker)
    local complete = true
    local found = {}
    for index, child in tracker.Folder:GetChildren() do
        if index % 16 == 0 then Yield() end
        local address = child.Address
        local entry = tracker.Entries[address] or tracker.Read(child)
        if entry then
            found[address] = entry
        else
            complete = false
        end
    end
    tracker.Entries, tracker.Complete = found, complete
end

local function UpdateTracker(tracker, map, now)
    if not tracker.Folder then
        if map and now >= tracker.NextSearch then
            FindFolder(map, tracker)
            if tracker.Folder then
                tracker.Entries = {}
                ReadEntries(tracker)
                tracker.NextCheck = tick() + 5
            else
                tracker.NextSearch = tick() + 2
            end
        end
    elseif now >= tracker.NextCheck then
        tracker.NextCheck = now + (if tracker.Complete then 10 else 5)
        local current = tracker.Parent:FindFirstChild(tracker.Name)
        if not current or current.Address ~= tracker.Address then
            ResetTracker(tracker)
        elseif not tracker.Complete then
            ReadEntries(tracker)
        end
    end
end

local function IsNear(pose)
    local dx, dy, dz = pose.CX - frame.PX, pose.CY - frame.PY, pose.CZ - frame.PZ
    return dx * dx + dy * dy + dz * dz < palletNearDistance * palletNearDistance
end

local function UpdateGenerators(now)
    for _, entry in trackers.Generators.Entries do
        if not entry.Completed and now >= entry.NextPoll then
            entry.NextPoll = now + progressPollInterval
            entry.Reader = entry.Reader or NewAttributeReader("RepairProgress")
            local progress = tonumber(ReadAttribute(entry.Reader, entry.Model, "RepairProgress", "Number", now))
            if progress then
                local regressing = ReadAttribute(entry.Reader, entry.Model, "Regressing", "Bool", now)
                if progress < 100 and (regressing == true or regressing == "true") then
                    entry.FallingUntil = now + progressStateTime
                end
                local last = entry.Progress
                if last and progress > last + .01 then
                    entry.RisingUntil = now + progressStateTime
                elseif last and progress < last - .01 then
                    entry.FallingUntil = now + progressStateTime
                end
                entry.Progress = progress
                entry.Text = string.format("%d%%", math.floor(progress))
                if progress >= 100 then
                    entry.Completed, entry.Text, entry.State = true, "100%", "Done"
                elseif now < entry.FallingUntil then
                    entry.State = "Falling"
                elseif now < entry.RisingUntil then
                    entry.State = "Rising"
                else
                    entry.State = nil
                end
            end
        end
    end
end

local function GeneratorColor(entry)
    local state = entry.State
    if state == "Done" then return completedColor end
    if state == "Falling" and bKickedColor then return regressingColor end
    if state == "Rising" then return repairingColor end
    return generatorColor
end

local function UpdatePallets(now)
    if not frame.Ready then return end
    for _, entry in trackers.Pallets.Entries do
        if not entry.Hidden and now >= entry.NextPoll then
            entry.NextPoll = now + (if IsNear(entry.IntactPose) then palletPollInterval else 1)
            local transparency = entry.Part.Transparency
            local canCollide = entry.Part.CanCollide
            if transparency == nil or transparency > .99 then
                entry.Hidden = true
            elseif canCollide ~= nil then
                local dropped = not canCollide
                if dropped == entry.Dropped then
                    entry.Pending = 0
                else
                    entry.Pending += 1
                    if entry.Pending >= 2 then
                        entry.Dropped, entry.Pending = dropped, 0
                        if dropped then
                            entry.BrokenPose = entry.BrokenPose or PartPose(entry.BrokenPart, palletSize)
                            entry.Pose = entry.BrokenPose or entry.IntactPose
                        else
                            entry.Pose = entry.IntactPose
                        end
                    end
                end
            end
        end
    end
end

local function ScanWindows(map)
    local started = os.clock()
    local descendants = map:GetDescendants()
    local blocked = os.clock() - started
    stats.Scans += 1
    if blocked > stats.ScanMax then stats.ScanMax = blocked end
    local found = table.clone(windows)
    for index, object in descendants do
        if index % 500 == 0 then
            Yield()
            if not Running() then return end
        end
        if object.Name == "Window" then
            local address = object.Address
            local pose = windows[address]
            if not pose then
                local bottom = object:FindFirstChild("Bottom")
                pose = bottom and PartPose(bottom)
            end
            if pose then found[address] = pose end
        end
    end
    windows = found
    local count = 0
    for _ in found do count += 1 end
    return count
end

local function UpdateCamera(now)
    local camera = workspace.CurrentCamera
    if not camera then
        frame.Ready = false
        return
    end
    local cframe = camera.CFrame
    local position, look, right, up = cframe.Position, cframe.LookVector, cframe.RightVector, cframe.UpVector
    frame.PX, frame.PY, frame.PZ = position.X, position.Y, position.Z
    frame.LX, frame.LY, frame.LZ = look.X, look.Y, look.Z
    frame.RX, frame.RY, frame.RZ = right.X, right.Y, right.Z
    frame.UX, frame.UY, frame.UZ = up.X, up.Y, up.Z
    if not frame.NextLens or now >= frame.NextLens then
        frame.NextLens = now + .25
        local viewport = camera.ViewportSize
        frame.HalfWidth, frame.HalfHeight = viewport.X / 2, viewport.Y / 2
    end
    if not frame.NextFov or now >= frame.NextFov then
        frame.NextFov = now + .05
        frame.Focal = frame.HalfHeight / math.tan(math.rad(camera.FieldOfView) / 2)
    end
    frame.Ready = true
end

local lines = {}
local usedLines, wantedLines = 0, 0

local function GrowLines()
    for _ = 1, 20 do
        if #lines >= wantedLines then return end
        local object = Drawing.new("Line")
        object.Thickness = outlineThickness
        object.Transparency = 1
        object.Visible = false
        allDrawings[#allDrawings + 1] = object
        lines[#lines + 1] = {Object = object, Visible = false}
    end
end

local function DrawLine(x1, y1, x2, y2, color)
    usedLines += 1
    local entry = lines[usedLines]
    if not entry then return end
    if entry.X1 ~= x1 or entry.Y1 ~= y1 then
        entry.X1, entry.Y1 = x1, y1
        entry.Object.From = Vector2.new(x1, y1)
        stats.Writes += 1
    end
    if entry.X2 ~= x2 or entry.Y2 ~= y2 then
        entry.X2, entry.Y2 = x2, y2
        entry.Object.To = Vector2.new(x2, y2)
        stats.Writes += 1
    end
    if entry.Color ~= color then
        entry.Color = color
        entry.Object.Color = color
    end
    if not entry.Visible then
        entry.Visible = true
        entry.Object.Visible = true
    end
end

local texts = {}
local usedTexts, wantedTexts = 0, 0

local function GrowTexts()
    for _ = 1, 2 do
        if #texts >= wantedTexts then return end
        local object = Drawing.new("Text")
        if textFont then object.Font = textFont end
        object.Size = textSize
        object.Center = true
        object.Outline = true
        object.Visible = false
        allDrawings[#allDrawings + 1] = object
        texts[#texts + 1] = {Object = object, Visible = false}
    end
end

local function DrawText(x, y, text, color)
    usedTexts += 1
    local entry = texts[usedTexts]
    if not entry then return end
    if entry.X ~= x or entry.Y ~= y then
        entry.X, entry.Y = x, y
        entry.Object.Position = Vector2.new(x, y)
        stats.Writes += 1
    end
    if entry.Text ~= text then
        entry.Text = text
        entry.Object.Text = text
    end
    if entry.Color ~= color then
        entry.Color = color
        entry.Object.Color = color
    end
    if not entry.Visible then
        entry.Visible = true
        entry.Object.Visible = true
    end
end

local triangles = {}
local usedTriangles, wantedTriangles = 0, 0

local function GrowTriangles()
    for _ = 1, 8 do
        if #triangles >= wantedTriangles then return end
        local object = Drawing.new("Triangle")
        object.Filled = true
        object.Transparency = fillOpacity
        object.Visible = false
        allDrawings[#allDrawings + 1] = object
        triangles[#triangles + 1] = {Object = object, Visible = false}
    end
end

local function DrawTriangle(x1, y1, x2, y2, x3, y3, color)
    usedTriangles += 1
    local entry = triangles[usedTriangles]
    if not entry then return end
    if entry.X1 ~= x1 or entry.Y1 ~= y1 then
        entry.X1, entry.Y1 = x1, y1
        entry.Object.PointA = Vector2.new(x1, y1)
    end
    if entry.X2 ~= x2 or entry.Y2 ~= y2 then
        entry.X2, entry.Y2 = x2, y2
        entry.Object.PointB = Vector2.new(x2, y2)
    end
    if entry.X3 ~= x3 or entry.Y3 ~= y3 then
        entry.X3, entry.Y3 = x3, y3
        entry.Object.PointC = Vector2.new(x3, y3)
    end
    if entry.Color ~= color then
        entry.Color = color
        entry.Object.Color = color
    end
    if not entry.Visible then
        entry.Visible = true
        entry.Object.Visible = true
    end
end

local function DrawLabel(pose, text, color)
    local screen, visible = WorldToScreen(Vector3.new(pose.CX, pose.CY, pose.CZ))
    if visible then DrawText(screen.X, screen.Y, text, color) end
end

local screenX, screenY = table.create(8), table.create(8)
local order, hull = table.create(8), table.create(16)

local function Cross(o, a, b)
    return (screenX[a] - screenX[o]) * (screenY[b] - screenY[o]) - (screenY[a] - screenY[o]) * (screenX[b] - screenX[o])
end

local function Before(a, b)
    return screenX[a] < screenX[b] or (screenX[a] == screenX[b] and screenY[a] < screenY[b])
end

local function Highlight(pose, color, anyDistance)
    if not bHighlightFill and not bHighlightOutline then return end
    local px, py, pz = frame.PX, frame.PY, frame.PZ
    if not anyDistance then
        local dx, dy, dz = pose.CX - px, pose.CY - py, pose.CZ - pz
        if dx * dx + dy * dy + dz * dz > highlightDistance * highlightDistance then return end
    end
    local corners = pose.Corners
    local lx, ly, lz = frame.LX, frame.LY, frame.LZ
    local rx, ry, rz = frame.RX, frame.RY, frame.RZ
    local ux, uy, uz = frame.UX, frame.UY, frame.UZ
    local halfWidth, halfHeight, focal = frame.HalfWidth, frame.HalfHeight, frame.Focal
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for i = 1, 8 do
        local base = i * 3 - 2
        local wx, wy, wz = corners[base], corners[base + 1], corners[base + 2]
        local x, y, z = wx - px, wy - py, wz - pz
        local depth = x * lx + y * ly + z * lz
        if depth < .1 then return end
        local sx, sy
        local screen, visible = WorldToScreen(Vector3.new(wx, wy, wz))
        if visible then
            sx, sy = screen.X, screen.Y
        else
            local scale = focal / depth
            sx = halfWidth + (x * rx + y * ry + z * rz) * scale
            sy = halfHeight - (x * ux + y * uy + z * uz) * scale
        end
        screenX[i], screenY[i] = sx, sy
        if sx < minX then minX = sx end
        if sx > maxX then maxX = sx end
        if sy < minY then minY = sy end
        if sy > maxY then maxY = sy end
        order[i] = i
    end
    if maxX < 0 or maxY < 0 or minX > halfWidth * 2 or minY > halfHeight * 2 then return end

    for i = 2, 8 do
        local value = order[i]
        local j = i - 1
        while j >= 1 and Before(value, order[j]) do
            order[j + 1] = order[j]
            j -= 1
        end
        order[j + 1] = value
    end
    local count = 0
    for i = 1, 8 do
        local point = order[i]
        while count >= 2 and Cross(hull[count - 1], hull[count], point) <= 0 do count -= 1 end
        count += 1
        hull[count] = point
    end
    local lower = count + 1
    for i = 7, 1, -1 do
        local point = order[i]
        while count >= lower and Cross(hull[count - 1], hull[count], point) <= 0 do count -= 1 end
        count += 1
        hull[count] = point
    end
    count -= 1
    if count < 3 then return end
    if bHighlightFill then
        local first = hull[1]
        for i = 2, count - 1 do
            local b, c = hull[i], hull[i + 1]
            DrawTriangle(screenX[first], screenY[first], screenX[b], screenY[b], screenX[c], screenY[c], color)
        end
    end
    if bHighlightOutline then
        for i = 1, count do
            local a, b = hull[i], hull[i % count + 1]
            DrawLine(screenX[a], screenY[a], screenX[b], screenY[b], color)
        end
    end
end

local function Project(wx, wy, wz, minDepth)
    local x, y, z = wx - frame.PX, wy - frame.PY, wz - frame.PZ
    local depth = x * frame.LX + y * frame.LY + z * frame.LZ
    if depth < (minDepth or .1) then return nil end
    local screen, visible = WorldToScreen(Vector3.new(wx, wy, wz))
    if visible then return screen.X, screen.Y end
    local scale = frame.Focal / depth
    return frame.HalfWidth + (x * frame.RX + y * frame.RY + z * frame.RZ) * scale, frame.HalfHeight - (x * frame.UX + y * frame.UY + z * frame.UZ) * scale
end

local function TeamName(player)
    local team = player.Team
    return team and team.Name
end

local function RefreshParry()
    local player = Players.LocalPlayer
    parry.Team = TeamName(player)
    local character = player.Character
    parry.LocalRoot = character and character:FindFirstChild("HumanoidRootPart")
    parry.ItemReader = parry.ItemReader or NewAttributeReader("EquippedItem")
    parry.HasDagger = parry.LocalRoot ~= nil and (character:FindFirstChild("Parrying Dagger") ~= nil or ReadAttribute(parry.ItemReader, player, "EquippedItem", "Text", tick()) == "Parrying Dagger")
    local killer
    for _, other in Players:GetPlayers() do
        Yield()
        if other ~= player and TeamName(other) == "Killer" then
            local killerCharacter = other.Character
            local humanoid = killerCharacter and killerCharacter:FindFirstChild("Humanoid")
            local animator = humanoid and humanoid:FindFirstChild("Animator")
            local root = killerCharacter and killerCharacter:FindFirstChild("HumanoidRootPart")
            if animator and root then killer = {Animator = animator.Address, Root = root} end
            break
        end
    end
    local old = parry.Killer
    if killer and old and killer.Animator == old.Animator then
        killer.Tracks = old.Tracks
    else
        parry.Attack = nil
    end
    parry.Killer = killer
end

local function ReadAnimationId(animation)
    local id = parry.AnimationIds[animation]
    if id then return id end
    id = string.match(ReadStdString(animation + animationIdOffset), "%d+") or ""
    parry.AnimationIds[animation] = id
    return id
end

local function StartAttack(config, now)
    local attack = parry.Attack
    if attack and now - attack.Started < .2 and attack.Config == config then return end
    local ping = (tonumber(GetPingValue()) or 0) / 1000
    local windup = config.Windup or attackDefaults.Windup
    local linger = config.Linger or attackDefaults.Linger
    parry.Attack = {
        Config = config,
        Started = now,
        Starts = now + windup - ping - parrySafety,
        Ends = now + windup + linger - ping - parrySafety - .05,
    }
end

local function ScanKillerTracks(now)
    local killer = parry.Killer
    local head = memory_read("uintptr_t", killer.Animator + activeAnimationsOffset)
    local count = memory_read("uintptr_t", killer.Animator + activeAnimationsOffset + 8)
    if not Valid(head) or not count or count > 256 then return end
    local previous, current = killer.Tracks, {}
    local node = memory_read("uintptr_t", head)
    for _ = 1, count do
        if not Valid(node) or node == head then break end
        local track = memory_read("uintptr_t", node + 0x10)
        if Valid(track) then
            current[track] = true
            if previous and not previous[track] then
                local animation = memory_read("uintptr_t", track + trackAnimationOffset)
                local config = Valid(animation) and attackAnimations[ReadAnimationId(animation)]
                if config then StartAttack(config, now) end
            end
        end
        node = memory_read("uintptr_t", node)
    end
    killer.Tracks = current
end

local function PastLocalPosition(now)
    local history = parry.History
    local chosen = history[1]
    for i = #history, 1, -1 do
        if now - history[i].Time >= parryHistoryTime then
            chosen = history[i]
            break
        end
    end
    return chosen and chosen.Position
end

local function PressParry()
    local delay = math.max(0, math.random(-60, 60) / 1000)
    if delay > 0 then wait(delay) end
    mouse2press()
    wait(.07)
    mouse2release()
end

local function CheckAttack(now)
    local attack = parry.Attack
    if not attack or now < attack.Starts or now - parry.LastParry < parryCooldown then return end
    local killerPosition = parry.KillerPosition
    local localPosition = PastLocalPosition(now) or parry.LocalPosition
    if not killerPosition or not localPosition then return end
    local offset = localPosition - killerPosition
    local config = attack.Config
    local radius = (config.Length or attackDefaults.Length) + localRadius
    local height = config.Height or attackDefaults.Height
    if math.abs(offset.Y) > height / 2 + localHalfHeight then return end
    if Vector3.new(offset.X, 0, offset.Z).Magnitude > radius then return end
    parry.Attack, parry.LastParry = nil, now
    task.spawn(PressParry)
end

local function UpdateParry(now)
    if now >= parry.NextRefresh then
        parry.NextRefresh = NextSlot(now, .12)
        RefreshParry()
    end
    if not parry.Killer or parry.Team ~= "Survivors" then
        parry.Attack, parry.KillerPosition = nil, nil
        return false
    end
    parry.KillerPosition = parry.Killer.Root.Position
    if not parry.KillerPosition then
        parry.Killer, parry.Attack, parry.NextRefresh = nil, nil, 0
        return false
    end
    parry.LocalPosition = parry.LocalRoot and parry.LocalRoot.Position
    local history = parry.History
    if parry.LocalPosition then
        local last = history[#history]
        if last and now - last.Time > .5 then table.clear(history) end
        history[#history + 1] = {Time = now, Position = parry.LocalPosition}
        while #history > 2 and now - history[2].Time >= parryHistoryTime do
            table.remove(history, 1)
        end
    end
    ScanKillerTracks(now)
    if parry.Attack and now > parry.Attack.Ends then parry.Attack = nil end
    if bAutoParry and parry.HasDagger then CheckAttack(now) end
    return true
end

local circleCos, circleSin = table.create(parryCircleSegments), table.create(parryCircleSegments)
for i = 0, parryCircleSegments - 1 do
    local angle = i / parryCircleSegments * math.pi * 2
    circleCos[i], circleSin[i] = math.cos(angle), math.sin(angle)
end

local function RenderParry()
    local killer = parry.Killer
    if not killer or parry.Team ~= "Survivors" or not parry.KillerPosition then return end
    local position = killer.Root.Position or parry.KillerPosition
    local attack = parry.Attack
    local config = attack and attack.Config or attackDefaults
    local radius = (config.Length or attackDefaults.Length) + localRadius
    local color = if attack then parryAttackColor else parryRangeColor
    local cx, cy, cz = position.X, position.Y, position.Z
    local firstX, firstY = Project(cx + radius, cy, cz)
    local previousX, previousY = firstX, firstY
    for i = 1, parryCircleSegments do
        local x, y
        if i == parryCircleSegments then
            x, y = firstX, firstY
        else
            x, y = Project(cx + circleCos[i] * radius, cy, cz + circleSin[i] * radius)
        end
        if x and previousX then DrawLine(previousX, previousY, x, y, color) end
        previousX, previousY = x, y
    end
    if attack then
        local x, y = Project(cx, cy + 4, cz)
        if x then DrawText(x, y, config.Name, parryAttackColor) end
    end
end

local UpdateDaggerAim, RenderDaggerTrajectory, RebuildDaggerGradient

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
    local daggerStep = .04
    local daggerMaxTime = 6
    local daggerMaxDrop = 80
    local groundOffset = 3
    local localRightOffset = 1.5
    local localForwardOffset = .1
    local gradientSteps = 32
    local hitRadius = 1.8
    local legHalfHeight = 1
    local headTop = .5
    local hitSamples = 4
    local throwers, targets, motions = {}, {}, {}
    local ownRoot, ownIsSurvivor
    local nextRefresh = 0
    local arcPoints = {}

    local function LerpColor(a, b, t)
        return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
    end

    local gradient, hitGradient, missGradient = {}, {}, {}
    RebuildDaggerGradient = function()
        for i = 0, gradientSteps do
            local fraction = i / gradientSteps
            gradient[i] = LerpColor(daggerColor, daggerEndColor, fraction)
            hitGradient[i] = LerpColor(Color3.fromRGB(255, 120, 50), Color3.fromRGB(255, 30, 30), fraction)
            missGradient[i] = LerpColor(Color3.fromRGB(255, 250, 170), Color3.fromRGB(255, 215, 30), fraction)
        end
    end
    RebuildDaggerGradient()

    local function AnimatorOf(character)
        local humanoid = character and character:FindFirstChild("Humanoid")
        local animator = humanoid and humanoid:FindFirstChild("Animator")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if animator and root then return animator.Address, root end
        return nil
    end

    local function Refresh()
        local states = {}
        for _, thrower in throwers do states[thrower.Animator] = thrower.State end
        local list, roots, newMotions = {}, {}, {}
        local localPlayer = Players.LocalPlayer
        local localTeam = TeamName(localPlayer)
        local animator, root = AnimatorOf(localPlayer.Character)
        ownRoot, ownIsSurvivor = root, localTeam == "Survivors"
        if animator and localTeam == "Killer" then
            list[#list + 1] = {Animator = animator, Root = root, IsLocal = true, State = states[animator] or {}}
        end
        for _, player in Players:GetPlayers() do
            Yield()
            if player ~= localPlayer then
                local team = TeamName(player)
                if team and team ~= "Spectator" then
                    local character = player.Character
                    local otherAnimator, otherRoot = AnimatorOf(character)
                    if otherAnimator then
                        local id = otherRoot.Address
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
                        if team == "Killer" then
                            list[#list + 1] = {Animator = otherAnimator, Root = otherRoot, State = states[otherAnimator] or {}}
                        end
                    end
                end
            end
        end
        throwers, targets, motions = list, roots, newMotions
    end

    local function UpdateAimState(state, animator, now)
        local head = memory_read("uintptr_t", animator + activeAnimationsOffset)
        local count = memory_read("uintptr_t", animator + activeAnimationsOffset + 8)
        if not Valid(head) or not count or count > 256 then return end
        local previous, current = state.Tracks, {}
        local holding = false
        local node = memory_read("uintptr_t", head)
        for _ = 1, count do
            if not Valid(node) or node == head then break end
            local track = memory_read("uintptr_t", node + 0x10)
            if Valid(track) then
                current[track] = true
                local animation = memory_read("uintptr_t", track + trackAnimationOffset)
                local kind = Valid(animation) and aimAnimations[ReadAnimationId(animation)]
                local isNew = not previous or not previous[track]
                if kind == "Hold" then
                    holding = true
                    if isNew then state.Aiming = true end
                elseif kind == "Throw" and isNew then
                    state.Aiming = false
                    state.ThrownAt = now
                end
            end
            node = memory_read("uintptr_t", node)
        end
        if state.ThrownAt == now then state.Aiming = false end
        if holding then
            state.LastHold = now
        elseif state.Aiming and (not state.LastHold or now - state.LastHold > aimTimeout) then
            state.Aiming = false
        end
        state.Tracks = current
    end

    local function UpdateMotion(motion, position, now)
        local dt = motion.LastTime and now - motion.LastTime
        if not dt or dt > .5 then
            motion.LastPosition, motion.LastTime, motion.Velocity = position, now, Vector3.new(0, 0, 0)
            return
        end
        if dt < .05 then return end
        local delta = position - motion.LastPosition
        if delta.Magnitude > .03 then
            motion.Velocity = motion.Velocity * .5 + (delta / dt) * .5
        else
            motion.Velocity = motion.Velocity * .7
        end
        motion.LastPosition, motion.LastTime = position, now
    end

    local function LaunchAngle(distance, rise)
        if distance < .5 then return 0 end
        local speedSquared = daggerSpeed * daggerSpeed
        local angle, adjustedRise = 0, rise
        for _ = 1, 3 do
            local discriminant = speedSquared * speedSquared - daggerGravity * (daggerGravity * distance * distance + 2 * adjustedRise * speedSquared)
            if discriminant < 0 then return math.pi / 4 end
            angle = math.atan((speedSquared - math.sqrt(discriminant)) / (daggerGravity * distance))
            local flightTime = distance / (daggerSpeed * math.cos(angle))
            adjustedRise = rise - daggerGravity * daggerLag * flightTime / 2
        end
        return angle
    end

    local function BodyShape(target, t)
        local head = target.HeadPosition
        if not head then return nil end
        local feet = target.FeetPosition
        local velocity = target.Motion.Velocity
        if t and velocity then
            local shift = Vector3.new(velocity.X, 0, velocity.Z) * t
            head += shift
            feet += shift
        end
        return head, feet, target.Bottom, head.Y + headTop
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
        if not head then return false end
        for i = 0, hitSamples do
            if PointInBody(a + (b - a) * (i / hitSamples), head, feet, bottom, top) then return true end
        end
        return false
    end

    local function BuildArc(origin, velocity, endY)
        local rise = velocity.Y + daggerGravity * daggerLag / 2
        local drop = if endY then origin.Y - endY else daggerMaxDrop
        local discriminant = rise * rise + 2 * daggerGravity * drop
        if discriminant < 0 then return nil end
        local endTime = math.min(daggerMaxTime, (rise + math.sqrt(discriminant)) / daggerGravity)
        local steps = math.max(1, math.ceil(endTime / daggerStep))
        for i = 0, steps do
            local t = endTime * i / steps
            arcPoints[i] = origin + velocity * t - Vector3.new(0, daggerGravity * t * (t - daggerLag) / 2, 0)
        end
        return steps, endTime
    end

    local function ArcHits(origin, velocity, endY)
        local steps, endTime = BuildArc(origin, velocity, endY)
        if not steps then return false end
        for i = 1, steps do
            local t = endTime * i / steps
            for _, target in targets do
                if SegmentHits(arcPoints[i - 1], arcPoints[i], target, t) then return true end
            end
        end
        return false
    end

    local function DrawArc(origin, velocity, startOffset, endY, colors)
        local steps = BuildArc(origin, velocity, endY)
        if not steps then return end
        local previousX, previousY
        for i = 0, steps do
            local fraction = i / steps
            local point = arcPoints[i]
            if startOffset then point += startOffset * (1 - fraction) end
            local x, y = Project(point.X, point.Y, point.Z, if startOffset then .05 else nil)
            if x and previousX then DrawLine(previousX, previousY, x, y, colors[math.floor(fraction * gradientSteps)]) end
            previousX, previousY = x, y
        end
    end

    local function TargetBody()
        if not frame.Ready then return nil end
        local best, bestDistance
        for _, target in targets do
            local position = target.Position
            local x = position and Project(position.X, position.Y, position.Z)
            if x and x >= 0 and x <= frame.HalfWidth * 2 then
                local distance = math.abs(x - frame.HalfWidth)
                if not bestDistance or distance < bestDistance then
                    best, bestDistance = target, distance
                end
            end
        end
        return best
    end

    local function EnemyArc(thrower)
        local rootPosition, rootFrame = thrower.Root.Position, thrower.Root.CFrame
        if not rootPosition or not rootFrame then
            thrower.Origin = nil
            return
        end
        local origin = rootPosition + Vector3.new(0, daggerHeight, 0)
        local look = rootFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude < .01 then
            thrower.Origin = nil
            return
        end
        flat = flat.Unit
        local bestPosition, bestEndY, bestDot
        local function Consider(position, endY)
            local offset = Vector3.new(position.X - origin.X, 0, position.Z - origin.Z)
            if offset.Magnitude < .5 then return end
            local dot = offset.Unit:Dot(flat)
            if not bestDot or dot > bestDot then
                bestPosition, bestEndY, bestDot = position, endY, dot
            end
        end
        for _, target in targets do
            if target.Team == "Survivors" and target.Position then Consider(target.Position, target.Bottom) end
        end
        local ownPosition = ownIsSurvivor and ownRoot and ownRoot.Position
        if ownPosition then Consider(ownPosition, ownPosition.Y - groundOffset) end
        local angle = 0
        if bestPosition then
            angle = LaunchAngle(Vector3.new(bestPosition.X - origin.X, 0, bestPosition.Z - origin.Z).Magnitude, bestPosition.Y - origin.Y)
        end
        thrower.Origin = origin
        thrower.Velocity = (flat * math.cos(angle) + Vector3.new(0, math.sin(angle), 0)) * daggerSpeed
        thrower.EndY = bestEndY
    end

    UpdateDaggerAim = function(now, reset)
        if reset then throwers, targets, motions, nextRefresh = {}, {}, {}, 0 end
        if now >= nextRefresh then
            nextRefresh = NextSlot(now, .25)
            Refresh()
            now = tick()
        end
        if #throwers == 0 then return false end
        for _, target in targets do
            local position = target.Root.Position
            local head, left, right = target.Head.Position, target.LeftLeg.Position, target.RightLeg.Position
            if position and head and left and right then
                target.Position, target.HeadPosition = position, head
                target.FeetPosition = (left + right) / 2
                target.Bottom = math.min(left.Y, right.Y) - legHalfHeight
                UpdateMotion(target.Motion, position, now)
            else
                target.Position, target.HeadPosition = nil, nil
            end
        end
        local leftHeld = ismouse1pressed()
        for _, thrower in throwers do
            UpdateAimState(thrower.State, thrower.Animator, now)
            thrower.Aiming = thrower.State.Aiming == true and (not thrower.IsLocal or leftHeld == true)
            if thrower.Aiming then
                if thrower.IsLocal then
                    local camera = workspace.CurrentCamera
                    local target = TargetBody()
                    local ownPosition = ownRoot and ownRoot.Position
                    local endY = if target then target.Bottom elseif ownPosition then ownPosition.Y - groundOffset else nil
                    thrower.EndY = endY
                    if camera then
                        local cframe = camera.CFrame
                        thrower.Hit = ArcHits(cframe.Position, cframe.LookVector * daggerSpeed, endY)
                    end
                else
                    EnemyArc(thrower)
                end
            end
        end
        return true
    end

    RenderDaggerTrajectory = function()
        for _, thrower in throwers do
            if thrower.Aiming then
                if thrower.IsLocal then
                    local origin = Vector3.new(frame.PX, frame.PY, frame.PZ)
                    local look = Vector3.new(frame.LX, frame.LY, frame.LZ)
                    local right = Vector3.new(frame.RX, frame.RY, frame.RZ)
                    DrawArc(origin, look * daggerSpeed, right * localRightOffset + look * localForwardOffset, thrower.EndY, if thrower.Hit then hitGradient else missGradient)
                elseif thrower.Origin then
                    DrawArc(thrower.Origin, thrower.Velocity, nil, thrower.EndY, gradient)
                end
            end
        end
    end
end

local function RefreshWorld(now)
    local player = Players.LocalPlayer
    world.LocalTeam = TeamName(player)
    local character = player.Character
    world.LocalRoot = character and character:FindFirstChild("HumanoidRootPart")
    local killerCharacter
    for _, other in Players:GetPlayers() do
        if TeamName(other) == "Killer" then
            killerCharacter = other.Character
            break
        end
    end
    if killerCharacter ~= world.KillerCharacter then world.NextKillerType = 0 end
    world.KillerCharacter = killerCharacter
    world.KillerRoot = killerCharacter and killerCharacter:FindFirstChild("HumanoidRootPart")
    if not killerCharacter then
        world.KillerType = ""
    elseif now >= world.NextKillerType then
        world.NextKillerType = now + 2
        world.KillerReader = world.KillerReader or NewAttributeReader("HookCount")
        world.KillerType = tostring(ReadAttribute(world.KillerReader, killerCharacter, "MorphedKiller", "Text", now) or "")
    end
end

local RenderMapEntities, UpdateZombiePositions

do
    local traps, zombies = {}, {}
    local readsPerTick = 300
    local classifyWindow = 3

    local rotationOffset = tonumber(O.Primitive and O.Primitive.Rotation)
    local limbs = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

    local function PartAxes(partAddress)
        if not partAddress or not rotationOffset then return nil end
        local primitive = memory_read("uintptr_t", partAddress + primitiveOffset)
        if not Valid(primitive) then return nil end
        local start = math.min(rotationOffset, primitivePositionOffset)
        local block = ReadBlock(primitive + start, math.max(rotationOffset + 36, primitivePositionOffset + 12) - start)
        local function Float(offset)
            if block then return buffer.readf32(block, offset - start) end
            return memory_read("float", primitive + offset)
        end
        local base, rotation = primitivePositionOffset, rotationOffset
        local x, y, z = Float(base), Float(base + 4), Float(base + 8)
        if not x or x ~= x or math.abs(x) > 1e6 or math.abs(y) > 1e6 or math.abs(z) > 1e6 then return nil end
        local up = Vector3.new(Float(rotation + 4), Float(rotation + 16), Float(rotation + 28))
        local right = Vector3.new(Float(rotation), Float(rotation + 12), Float(rotation + 24))
        if math.abs(up.Magnitude - 1) > .05 or math.abs(right.Magnitude - 1) > .05 then return nil end
        return Vector3.new(x, y, z), up, right
    end

    UpdateZombiePositions = function()
        for _, zombie in zombies do
            local parts = zombie.Parts
            local head = PartAxes(parts.Head)
            local torso, torsoUp, torsoRight = PartAxes(parts.Torso)
            local bones
            if head and torso then
                local neck, pelvis = torso + torsoUp, torso - torsoUp
                bones = {{head, neck}, {neck, pelvis}}
                for _, side in {"Left", "Right"} do
                    local arm, armUp = PartAxes(parts[side .. " Arm"])
                    if arm then
                        local shoulder = arm + armUp
                        bones[#bones + 1] = {neck, shoulder}
                        bones[#bones + 1] = {shoulder, arm - armUp}
                    end
                    local leg, legUp = PartAxes(parts[side .. " Leg"])
                    if leg then
                        local hip = leg + legUp
                        bones[#bones + 1] = {pelvis, hip}
                        bones[#bones + 1] = {hip, leg - legUp}
                    end
                end
            end
            zombie.Bones, zombie.Head = bones, head
        end
    end

    AddJob("Map entities", false, function()
        local known, firstSeen = {}, {}
        local mapAddress
        local reads = 0
        local function Budget(count)
            reads += count
            if reads >= readsPerTick then
                reads = 0
                Yield()
            end
        end
        while Running() do
            local wantTraps = bTrapESP and world.KillerType == "Butcher"
            local wantZombies = bZombieESP and world.KillerType == "Cure"
            if not wantTraps then traps = {} end
            if not wantZombies then zombies = {} end
            if not memoryReady or not (wantTraps or wantZombies) or not isrbxactive() or not world.MapAddress then
                mapAddress = nil
                Sleep(.5)
            else
                if world.MapAddress ~= mapAddress then
                    mapAddress, known, firstSeen, traps, zombies = world.MapAddress, {}, {}, {}, {}
                end
                local now = tick()
                local children = MemoryChildren(mapAddress) or {}
                Budget(#children)
                local seen = {}
                for _, child in children do
                    if not Running() or world.MapAddress ~= mapAddress then break end
                    seen[child] = true
                    if known[child] == nil then
                        local name = MemoryName(child)
                        Budget(4)
                        if name == "BearTrap" then
                            local cube = MemoryChildNames(child).Cube
                            local position = cube and MemoryPosition(cube)
                            Budget(20)
                            if position then
                                traps[child] = {Position = position}
                                known[child] = "Trap"
                            end
                        elseif wantZombies then
                            firstSeen[child] = firstSeen[child] or now
                            local names = MemoryChildNames(child)
                            Budget(10)
                            if names.Humanoid and names.HumanoidRootPart and names.RagdollConstraints then
                                local parts = {}
                                for _, limb in limbs do parts[limb] = names[limb] end
                                zombies[child] = {Parts = parts}
                                known[child] = "Zombie"
                            elseif now - firstSeen[child] > classifyWindow then
                                known[child] = false
                            end
                        else
                            known[child] = false
                        end
                    end
                end
                for child in known do
                    if not seen[child] then
                        known[child], firstSeen[child], traps[child], zombies[child] = nil, nil, nil, nil
                    end
                end
                Sleep(1)
            end
        end
    end)

    RenderMapEntities = function()
        for _, trap in traps do
            local position = trap.Position
            local x, y = Project(position.X, position.Y, position.Z)
            if x then DrawText(x, y, "Bear Trap", trapColor) end
        end
        for _, zombie in zombies do
            for _, bone in zombie.Bones or {} do
                local a, b = bone[1], bone[2]
                local ax, ay = Project(a.X, a.Y, a.Z)
                local bx, by = Project(b.X, b.Y, b.Z)
                if ax and bx then DrawLine(ax, ay, bx, by, zombieColor) end
            end
            local head = zombie.Head
            if head then
                local x, y = Project(head.X, head.Y + 1.5, head.Z)
                if x then DrawText(x, y, "Zombie", zombieColor) end
            end
        end
    end
end

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
    local waves, names = {}, {}
    local crouching = false
    local lastThreat = -math.huge
    local nextScan = 0

    ReleaseCrouch = function()
        if crouching then keyrelease(crouchKey) end
        crouching = false
    end

    UpdateAutoCrouch = function(now)
        local root = world.LocalRoot
        if not memoryReady or world.KillerType ~= "Abysswalker" or world.LocalTeam ~= "Survivors" or not root then
            ReleaseCrouch()
            return
        end
        local children = now >= nextScan and MemoryChildren(workspace.Address)
        if children then
            nextScan = now + .1
            local seen = {}
            for _, address in children do
                seen[address] = true
                if names[address] == nil then
                    names[address] = MemoryName(address)
                    if names[address] == "Wave" then
                        local part = MemoryChildNames(address).Part
                        if part then waves[address] = {Part = part} end
                    end
                end
            end
            for address in names do
                if not seen[address] then names[address], waves[address] = nil, nil end
            end
        end

        local me = root.Position
        if not me then
            ReleaseCrouch()
            return
        end
        for _, wave in waves do
            local position = MemoryPosition(wave.Part)
            if position then
                wave.First = wave.First or position
                if not wave.Direction then
                    local moved = Vector3.new(position.X - wave.First.X, 0, position.Z - wave.First.Z)
                    if moved.Magnitude > 1 then wave.Direction = moved.Unit end
                end
                local direction = wave.Direction
                if direction and math.abs(me.Y - position.Y) <= waveHeight then
                    local offset = Vector3.new(me.X - position.X, 0, me.Z - position.Z)
                    local along = offset:Dot(direction)
                    local lateral = math.abs(offset:Dot(Vector3.new(-direction.Z, 0, direction.X)))
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

local UpdateAutoPallet

do
    local palletReach = 10
    local hitboxMargin = .5
    local pressInterval = .05
    local nextPress = 0

    local function InsideHitbox(box, point)
        local offset = point - box.Position
        local size = box.Size
        return math.abs(offset:Dot(box.Right)) <= size.X / 2 + hitboxMargin
            and math.abs(offset:Dot(box.Up)) <= size.Y / 2 + hitboxMargin
            and math.abs(offset:Dot(box.Look)) <= size.Z / 2 + hitboxMargin
    end

    local function PressSpaceOnce()
        keypress(0x20)
        wait(.02)
        keyrelease(0x20)
    end

    UpdateAutoPallet = function(now)
        if world.LocalTeam ~= "Survivors" or not world.KillerRoot or not world.LocalRoot or now < nextPress then return end
        local killerPosition, localPosition = world.KillerRoot.Position, world.LocalRoot.Position
        if not killerPosition or not localPosition then return end
        for _, entry in trackers.Pallets.Entries do
            local box = entry.Hitbox
            if box and not entry.Hidden and not entry.Dropped
                and (box.Position - localPosition).Magnitude <= palletReach and InsideHitbox(box, killerPosition) then
                nextPress = now + pressInterval
                task.spawn(PressSpaceOnce)
                return
            end
        end
    end
end

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
        MaxLines = 24,
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

    local hud = {X = 40, Y = 200, Width = 230, Lines = {}, NextGenerators = 0, NextKiller = 0, NextRead = 0, Values = {}, Shown = {}, ReadIndex = 0, WasDown = false}
    if isfile(style.File) then
        local x, y, w = string.match(readfile(style.File), "(%-?%d+) (%-?%d+) (%d+)")
        if x then hud.X, hud.Y, hud.Width = tonumber(x), tonumber(y), math.max(tonumber(w), style.MinWidth) end
    end

    local function Create(kind, properties)
        local object = Drawing.new(kind)
        if kind == "Text" and textFont then object.Font = textFont end
        for key, value in properties do object[key] = value end
        object.Visible = false
        allDrawings[#allDrawings + 1] = object
        return {Object = object, Visible = false}
    end

    local background = Create("Square", {Filled = true, Color = style.Background, Transparency = .85, ZIndex = 10})
    local bar = Create("Square", {Filled = true, Color = style.Bar, Transparency = 1, ZIndex = 11})
    local grip = Create("Square", {Filled = true, Color = style.Bar, Transparency = 1, ZIndex = 11})
    local title = Create("Text", {Size = style.TextSize, Outline = true, Center = false, Color = style.TextColor, Text = "Info", ZIndex = 12})
    local rows = {}
    for i = 1, style.MaxLines do
        rows[i] = Create("Text", {Size = style.TextSize, Outline = true, Center = false, ZIndex = 12})
    end
    local parts = {background, bar, grip, title}

    local function Show(entry, visible)
        if entry.Visible ~= visible then
            entry.Visible = visible
            entry.Object.Visible = visible
        end
    end

    local function Place(entry, key, x, y)
        x, y = math.floor(x + .5), math.floor(y + .5)
        if entry[key .. "X"] ~= x or entry[key .. "Y"] ~= y then
            entry[key .. "X"], entry[key .. "Y"] = x, y
            entry.Object[key] = Vector2.new(x, y)
        end
    end

    local function Set(entry, key, value)
        if entry[key] ~= value then
            entry[key] = value
            entry.Object[key] = value
        end
    end

    local function FormatValue(shown, value)
        if shown.Kind == "Bool" then
            local state = value == true or value == "true"
            return if state then "true" else "false", if state and shown.TrueColor then shown.TrueColor else style.TextColor
        end
        if value == nil then return "?", style.TextColor end
        if shown.Kind == "Text" then
            local text = tostring(value)
            local mapped = shown.Values and shown.Values[text]
            if mapped then return mapped.Text, mapped.Color or style.TextColor end
            return text, shown.OtherColor or style.TextColor
        end
        local number = tonumber(value)
        if not number then return tostring(value), style.TextColor end
        local color = if shown.NormalValue and number > shown.NormalValue + 1e-6 then shown.ChangedColor else style.TextColor
        local text
        if shown.Decimals then
            local scale = 10 ^ shown.Decimals
            text = string.format("%." .. shown.Decimals .. "f", math.floor(number * scale + 1e-9) / scale)
        elseif number == math.floor(number) then
            text = string.format("%d", number)
        else
            text = string.format("%.4g", number)
        end
        return (shown.Prefix or "") .. text, color
    end

    local function RefreshLines()
        local lines = {{Text = "Generators", Color = style.Heading}}
        local addresses = {}
        for address in trackers.Generators.Entries do addresses[#addresses + 1] = address end
        table.sort(addresses)
        for _, address in addresses do
            local entry = trackers.Generators.Entries[address]
            local state = entry.State
            local color = if state == "Done" then style.Done elseif state == "Falling" then style.Failing elseif state == "Rising" then style.Working else style.Idle
            lines[#lines + 1] = {Text = "Generator: " .. (if entry.Text ~= "" then entry.Text else "?"), Color = color}
        end
        if #addresses == 0 then lines[#lines + 1] = {Text = "none found", Color = style.TextColor} end
        lines[#lines + 1] = {Gap = true}
        lines[#lines + 1] = {Text = if world.KillerType ~= "" then "Killer: " .. world.KillerType else "Killer", Color = style.Heading}
        if not world.KillerCharacter then
            lines[#lines + 1] = {Text = "no killer found", Color = style.TextColor}
        else
            for _, shown in hud.Shown do
                local text, color = FormatValue(shown, hud.Values[shown.Attribute])
                lines[#lines + 1] = {Text = shown.Name .. ": " .. text, Color = color}
            end
        end
        hud.Lines = lines
    end

    local function ReadNextAttribute()
        local killer = world.KillerCharacter
        if killer ~= hud.Killer or world.KillerType ~= hud.KillerType then
            hud.Killer, hud.KillerType, hud.Values, hud.ReadIndex = killer, world.KillerType, {}, 0
            local shownList = {}
            for _, shown in style.KillerAttributes[world.KillerType] or {} do shownList[#shownList + 1] = shown end
            for _, shown in style.CommonAttributes do shownList[#shownList + 1] = shown end
            hud.Shown = shownList
        end
        if not killer or #hud.Shown == 0 then return end
        hud.ReadIndex = hud.ReadIndex % #hud.Shown + 1
        local shown = hud.Shown[hud.ReadIndex]
        world.KillerReader = world.KillerReader or NewAttributeReader("HookCount")
        hud.Values[shown.Attribute] = ReadAttribute(world.KillerReader, killer, shown.Attribute, shown.Kind or "Number", tick())
    end

    local function HandleMouse()
        local mouse = hud.Mouse
        if not mouse then
            mouse = Players.LocalPlayer:GetMouse()
            hud.Mouse = mouse
        end
        local down = ismouse1pressed() == true
        local x, y = mouse.X, mouse.Y
        if down and not hud.WasDown then
            local height = hud.Height or 0
            if x >= hud.X + hud.Width - style.GripSize and x <= hud.X + hud.Width and y >= hud.Y + height - style.GripSize and y <= hud.Y + height then
                hud.Drag, hud.OffsetX = "Resize", hud.X + hud.Width - x
            elseif x >= hud.X and x <= hud.X + hud.Width and y >= hud.Y and y <= hud.Y + style.TitleHeight then
                hud.Drag, hud.OffsetX, hud.OffsetY = "Move", hud.X - x, hud.Y - y
            end
        elseif not down and hud.Drag then
            hud.Drag = nil
            writefile(style.File, string.format("%d %d %d", math.floor(hud.X), math.floor(hud.Y), math.floor(hud.Width)))
        end
        hud.WasDown = down
        if hud.Drag == "Move" then
            hud.X, hud.Y = x + hud.OffsetX, y + hud.OffsetY
        elseif hud.Drag == "Resize" then
            hud.Width = math.max(x + hud.OffsetX - hud.X, style.MinWidth)
        end
    end

    UpdateInfoHud = function(now)
        HandleMouse()
        if now >= hud.NextRead then
            hud.NextRead = now + .06
            ReadNextAttribute()
        end
        if now >= hud.NextKiller then
            hud.NextKiller = NextSlot(now, .37)
            RefreshLines()
        end
    end

    RenderInfoHud = function(visible)
        if not visible then
            for _, entry in parts do Show(entry, false) end
            for _, row in rows do Show(row, false) end
            return
        end
        local lineCount, gaps = 0, 0
        for _, line in hud.Lines do
            if line.Gap then gaps += 1 else lineCount += 1 end
        end
        lineCount = math.min(lineCount, style.MaxLines)
        local height = style.TitleHeight + 4 + lineCount * style.LineHeight + gaps * 4 + style.Padding
        hud.Height = height
        Place(background, "Position", hud.X, hud.Y)
        Place(background, "Size", hud.Width, height)
        Place(bar, "Position", hud.X, hud.Y)
        Place(bar, "Size", hud.Width, style.TitleHeight)
        Place(grip, "Position", hud.X + hud.Width - style.GripSize, hud.Y + height - style.GripSize)
        Place(grip, "Size", style.GripSize, style.GripSize)
        Place(title, "Position", hud.X + style.Padding, hud.Y + 2)
        for _, entry in parts do Show(entry, true) end

        local maxChars = math.max(math.floor((hud.Width - style.Padding * 2) / style.CharWidth), 4)
        local y = hud.Y + style.TitleHeight + 4
        local used = 0
        for _, line in hud.Lines do
            if line.Gap then
                y += 4
            elseif used < style.MaxLines then
                used += 1
                local row = rows[used]
                local text = line.Text
                if #text > maxChars then text = string.sub(text, 1, maxChars - 2) .. ".." end
                Place(row, "Position", hud.X + style.Padding, y)
                Set(row, "Text", text)
                Set(row, "Color", line.Color)
                Show(row, true)
                y += style.LineHeight
            end
        end
        for i = used + 1, style.MaxLines do Show(rows[i], false) end
    end
end

local function PrintStats(now)
    if now < stats.Next then return end
    local elapsed = now - stats.Next + 5
    if stats.Next > 0 then
        print(string.format("[MatchaVD] loop %d/s (%.1f ms/s) | render %d/s (%.2f ms avg, %d lines, %d writes/s) | skill %d/s | %d window scans (%.0f ms max, first call blocks)",
            stats.Loops / elapsed, stats.LoopTime * 1000 / elapsed, stats.Renders / elapsed,
            if stats.Renders > 0 then stats.RenderTime * 1000 / stats.Renders else 0, stats.Lines, stats.Writes / elapsed,
            stats.Skill / elapsed, stats.Scans, stats.ScanMax * 1000))
    end
    stats.Loops, stats.LoopTime, stats.Renders, stats.RenderTime, stats.Writes = 0, 0, 0, 0, 0
    stats.Skill, stats.Scans, stats.ScanMax = 0, 0, 0
    stats.Next = now + 5
end

local function Render()
    local started = os.clock()
    usedLines, usedTexts, usedTriangles = 0, 0, 0
    UpdateCamera(tick())
    if frame.Ready and not vault.Scanning then
        if bPalletESP then
            for _, entry in trackers.Pallets.Entries do
                if not entry.Hidden then Highlight(entry.Pose, palletColor) end
            end
        end
        if bWindowESP then
            for _, pose in windows do Highlight(pose, windowColor) end
        end
        if bGeneratorESP then
            for _, entry in trackers.Generators.Entries do
                local color = GeneratorColor(entry)
                Highlight(entry.Pose, color, true)
                if entry.Text ~= "" then DrawLabel(entry.Pose, entry.Text, color) end
            end
        end
        RenderMapEntities()
        if bShowParryRange then RenderParry() end
        if bDaggerTrajectory then RenderDaggerTrajectory() end
    end
    RenderInfoHud(bInfoHud and not vault.Scanning)
    if usedLines > wantedLines then wantedLines = usedLines end
    if usedTexts > wantedTexts then wantedTexts = usedTexts end
    if usedTriangles > wantedTriangles then wantedTriangles = usedTriangles end
    for index = usedTriangles + 1, #triangles do
        local entry = triangles[index]
        if entry.Visible then
            entry.Visible = false
            entry.Object.Visible = false
        end
    end
    for index = usedLines + 1, #lines do
        local entry = lines[index]
        if entry.Visible then
            entry.Visible = false
            entry.Object.Visible = false
        end
    end
    for index = usedTexts + 1, #texts do
        local entry = texts[index]
        if entry.Visible then
            entry.Visible = false
            entry.Object.Visible = false
        end
    end
    if bDebugStats then
        stats.Renders += 1
        stats.Lines = usedLines
        stats.RenderTime += os.clock() - started
    end
end

AddJob("Main", false, function()
    local map, mapAddress, generatorFolder
    local nextMapCheck, nextWindowScan = 0, 0
    local windowCount, stableScans = -1, 0
    local function RestartWindows(now)
        windows, nextWindowScan, windowCount, stableScans = {}, now + 2, -1, 0
    end
    for _, tracker in trackers do ResetTracker(tracker) end
    local paused = false
    while Running() do
        if not isrbxactive() then
            paused = true
            Sleep(.5)
        else
            local now = tick()
            local started = os.clock()
            if paused then
                paused = false
                for _, tracker in trackers do ResetTracker(tracker) end
                RestartWindows(now)
                map, mapAddress, generatorFolder, nextMapCheck = nil, nil, nil, 0
                world.NextRefresh, world.LocalRoot, world.KillerRoot, world.KillerCharacter = 0, nil, nil, nil
            end
            GrowLines()
            GrowTexts()
            GrowTriangles()
            if now >= world.NextRefresh then
                world.NextRefresh = NextSlot(now, 0)
                RefreshWorld(now)
                now = tick()
            end
            if now >= nextMapCheck then
                nextMapCheck = now + 2
                map = workspace:FindFirstChild("Map")
                local address = map and map.Address
                world.MapAddress = address
                if address ~= mapAddress then
                    mapAddress = address
                    RestartWindows(now)
                    for _, tracker in trackers do ResetTracker(tracker) end
                end
            end
            UpdateTracker(trackers.Generators, map, now)
            if bGeneratorESP or bInfoHud then UpdateGenerators(tick()) end
            if trackers.Generators.Address ~= generatorFolder then
                generatorFolder = trackers.Generators.Address
                RestartWindows(tick())
            end
            if bPalletESP or bAutoPallet then
                UpdateTracker(trackers.Pallets, map, now)
                UpdatePallets(tick())
            end
            if bAutoPallet then UpdateAutoPallet(tick()) end
            if bAutoCrouch then UpdateAutoCrouch(tick()) else ReleaseCrouch() end
            if bZombieESP then UpdateZombiePositions() end
            if bInfoHud then UpdateInfoHud(tick()) end
            if bWindowESP and map and stableScans < windowStableScans and tick() >= nextWindowScan then
                local count = ScanWindows(map)
                if count and count >= minimumWindows and count == windowCount then
                    stableScans += 1
                else
                    stableScans = 0
                end
                windowCount = count or windowCount
                nextWindowScan = tick() + windowScanInterval
            end
            if bDebugStats then
                stats.Loops += 1
                stats.LoopTime += os.clock() - started
                PrintStats(tick())
            end
            Sleep(loopInterval)
        end
    end
end)

AddJob("Skill check", true, function()
    local player = game:GetService("Players").LocalPlayer
    local guiRotationOffset = visibleOffset - 0x19
    local check, line, goal, trapPerfect
    local nextFind = 0
    local pressed, lastNeedle, lastGoal, step = false, 0, 0, 0

    local function Find()
        local gui = player:FindFirstChild("PlayerGui")
        gui = gui and gui:FindFirstChild("SkillCheckPromptGui")
        check = gui and gui:FindFirstChild("Check")
        line = check and check:FindFirstChild("Line")
        goal = check and check:FindFirstChild("Goal")
        trapPerfect = check and check:FindFirstChild("TrapPerfect")
    end

    local function ZoneStart()
        local goalRotation = memory_read("float", goal.Address + guiRotationOffset)
        if memory_read("byte", goal.Address + visibleOffset) == 1 or math.abs(goalRotation) >= 1 then return goalRotation end
        if trapPerfect and memory_read("byte", trapPerfect.Address + visibleOffset) == 1 then
            return memory_read("float", trapPerfect.Address + guiRotationOffset)
        end
        return nil
    end

    while Running() do
        if not bAutoSkillCheck or not isrbxactive() then
            check, line, goal, trapPerfect, nextFind = nil, nil, nil, nil, 0
            Sleep(.5)
        else
            local now = tick()
            if not (check and line and goal) and now >= nextFind then
                nextFind = now + 2
                Find()
            end
            if check and line and goal then
                if memory_read("byte", check.Address + visibleOffset) == 1 then
                    local needle = memory_read("float", line.Address + guiRotationOffset)
                    local zone = ZoneStart()
                    if needle < lastNeedle - 30 or (zone and math.abs(zone - lastGoal) > 1) then
                        pressed, step = false, 0
                    elseif needle > lastNeedle then
                        step = needle - lastNeedle
                    end
                    lastNeedle, lastGoal = needle, zone or lastGoal
                    if zone and not pressed and step > 0 and needle + step / 2 >= zone + skillCheckAngle and needle <= zone + 114 then
                        pressed = true
                        keypress(0x20)
                        task.spawn(function()
                            wait(.03)
                            keyrelease(0x20)
                        end)
                    end
                else
                    pressed, lastNeedle, step = false, 0, 0
                end
            end
            stats.Skill += 1
            Sleep(if pressed or lastNeedle == 0 then .05 else 1 / 60)
        end
    end
end)

AddJob("Parry", true, function()
    if not activeAnimationsOffset or not trackAnimationOffset or not animationIdOffset then
        print("[MatchaVD] missing animation offsets, auto parry off")
        return
    end
    while Running() do
        if not (bAutoParry or bShowParryRange) or not isrbxactive() then
            parry.Attack, parry.KillerPosition, parry.Killer, parry.LocalRoot, parry.NextRefresh = nil, nil, nil, nil, 0
            table.clear(parry.History)
            Sleep(.5)
        elseif UpdateParry(tick()) then
            Sleep(1 / 60)
        else
            Sleep(.25)
        end
    end
end)

AddJob("Dagger aim", false, function()
    if not activeAnimationsOffset or not trackAnimationOffset or not animationIdOffset then return end
    local paused = false
    while Running() do
        if not bDaggerTrajectory or not isrbxactive() then
            paused = true
            Sleep(.5)
        else
            local active = UpdateDaggerAim(tick(), paused)
            paused = false
            if active then Sleep(1 / 60) else Sleep(.25) end
        end
    end
end)

do
    local keys = {"DISTANCE", "REPEAT_DISTANCE", "DOT", "MIN_SPEED", "ARRIVE_GRACE", "SIDESTEP_TIME"}
    local gameDefaults = {DISTANCE = 3.5, REPEAT_DISTANCE = 4, DOT = .7071067811865476, MIN_SPEED = 12.5, ARRIVE_GRACE = .12, SIDESTEP_TIME = .25}
    local maxPreset = {DISTANCE = .1, REPEAT_DISTANCE = .1, DOT = -1, MIN_SPEED = 0, ARRIVE_GRACE = 1, SIDESTEP_TIME = 5}
    local checkInterval = .5
    local tolerance = .006
    local clusterSpan = 0x400


    local function Matches(value, target)
        value = tonumber(value)
        return value ~= nil and target ~= nil and math.abs(value - target) < tolerance
    end

    local function Desired()
        return maxPreset
    end

    local function Cluster(numeric)
        table.sort(numeric, function(a, b) return a.Addr < b.Addr end)
        for first = 1, #numeric do
            local picked, count = {}, 0
            for index = first, #numeric do
                local entry = numeric[index]
                if entry.Addr - numeric[first].Addr > clusterSpan then break end
                if not picked[entry.Entry.key] then
                    picked[entry.Entry.key] = entry.Entry
                    count += 1
                end
            end
            if count == #keys then
                local entries = {}
                for _, key in keys do entries[#entries + 1] = picked[key] end
                return entries, "grouped"
            end
        end
        return nil
    end

    local function Scan(desired)
        local ok, result = pcall(getgc, keys)
        if not ok or type(result) ~= "table" then
            print("[MatchaVD] fast vault: getgc failed: " .. tostring(result))
            return nil
        end
        local numeric = {}
        for _, entry in result do
            local addr = tonumber(entry.addr)
            if entry.type == "number" and addr then numeric[#numeric + 1] = {Entry = entry, Addr = addr} end
        end
        local entries, how = Cluster(numeric)
        if not entries then
            local applied = _G.MatchaVDVaultApplied or {}
            entries, how = {}, "by value"
            for _, item in numeric do
                local entry = item.Entry
                local key = entry.key
                if Matches(entry.value, gameDefaults[key]) or Matches(entry.value, desired[key]) or Matches(entry.value, applied[key]) then
                    entries[#entries + 1] = entry
                end
            end
        end
        local found = {}
        for _, entry in entries do found[entry.key] = (found[entry.key] or 0) + 1 end
        local summary = {}
        for _, key in keys do summary[#summary + 1] = key .. " x" .. (found[key] or 0) end
        local distinct = 0
        for _, key in keys do
            if found[key] then distinct += 1 end
        end
        local success = distinct == #keys and #entries >= #keys
        if not success then print(string.format("[MatchaVD] fast vault scan failed (%s, %d of %d entries): %s", how, #entries, #result, table.concat(summary, ", "))) end
        return if success then entries else nil
    end

    local function Apply(entries, values)
        local ok, err = pcall(applygc, entries, values)
        if not ok then
            print("[MatchaVD] fast vault: applygc failed: " .. tostring(err))
            return false
        end
        _G.MatchaVDVaultApplied = values
        return true
    end

    local function SameValues(a, b)
        if not a or not b then return false end
        for _, key in keys do
            if not Matches(a[key], b[key]) then return false end
        end
        return true
    end

    local session = _G.MatchaVDVaultScan
    if not session or session.JobId ~= game.JobId then
        session = {JobId = game.JobId}
        _G.MatchaVDVaultScan = session
    end
    local entries = session.Entries
    vault.Ready = entries ~= nil
    local requested = false

    local popup = Drawing.new("Text")
    if textFont then popup.Font = textFont end
    popup.Size = 20
    popup.Center = true
    popup.Outline = true
    popup.Color = Color3.fromRGB(255, 255, 255)
    popup.Text = "Scanning memory for always fast vault\nESP is turned off for a few seconds."
    popup.Visible = false
    allDrawings[#allDrawings + 1] = popup

    local function ScanWithPopup()
        vault.Scanning = true
        local camera = workspace.CurrentCamera
        local size = camera and camera.ViewportSize
        if size then popup.Position = Vector2.new(math.floor(size.X / 2), math.floor(size.Y / 2 - 40)) end
        popup.Visible = true
        Sleep(.2)
        entries = Scan(Desired())
        session.Entries = entries
        popup.Visible = false
        vault.Scanning = false
        vault.Ready = entries ~= nil
        if vault.Ready and vault.RebuildMenu then vault.RebuildMenu() end
    end

    vault.ScanNow = function()
        if not entries and not vault.Scanning then requested = true end
    end

    AddJob("Fast vault", false, function()
        while Running() do
            if requested then
                requested = false
                if not entries then ScanWithPopup() end
            end
            if entries then
                local wanted = if vault.Enabled then Desired() else gameDefaults
                if not SameValues(session.Written, wanted) and Apply(entries, wanted) then session.Written = table.clone(wanted) end
            end
            Sleep(if entries then checkInterval else .1)
        end
    end)
end

do
    local keyS = 0x53
    local autoRotateOffset = tonumber(O.Humanoid and O.Humanoid.AutoRotate)
    local rotationOffset = tonumber(O.Primitive and O.Primitive.Rotation)
    local turnThreshold = math.cos(math.rad(1))

    local function FaceCamera(rootAddress)
        local camera = workspace.CurrentCamera
        if not camera or not rotationOffset or not rootAddress then return end
        local look = camera.CFrame.LookVector
        local length = math.sqrt(look.X * look.X + look.Z * look.Z)
        if length < .01 then return end
        local dx, dz = look.X / length, look.Z / length
        local primitive = memory_read("uintptr_t", rootAddress + primitiveOffset)
        if not Valid(primitive) then return end
        local rotation = primitive + rotationOffset
        local currentX, currentZ = -memory_read("float", rotation + 8), -memory_read("float", rotation + 32)
        if currentX * dx + currentZ * dz > turnThreshold then return end
        local matrix = {-dz, 0, -dx, 0, 1, 0, dx, 0, -dz}
        for i = 1, 9 do memory_write("float", rotation + (i - 1) * 4, matrix[i]) end
    end

    AddJob("Moonwalk", true, function()
        if not autoRotateOffset then
            print("[MatchaVD] moonwalk: no Humanoid.AutoRotate offset, moonwalk off")
            return
        end
        local humanoid, root, character, nextLookup = nil, nil, nil, 0
        local disabled = false

        local function Restore()
            if disabled and humanoid then memory_write("byte", humanoid + autoRotateOffset, 1) end
            disabled = false
        end

        while Running() do
            local now = tick()
            if now >= nextLookup then
                nextLookup = now + .5
                local current = Players.LocalPlayer.Character
                local address = current and current.Address
                if address ~= character then
                    disabled, character = false, address
                    local found = current and current:FindFirstChild("Humanoid")
                    local rootPart = current and current:FindFirstChild("HumanoidRootPart")
                    humanoid, root = found and found.Address, rootPart and rootPart.Address
                end
            end
            if bMoonwalk and humanoid and isrbxactive() and iskeypressed(keyS) then
                if memory_read("byte", humanoid + autoRotateOffset) == 1 then
                    memory_write("byte", humanoid + autoRotateOffset, 0)
                end
                disabled = true
                FaceCamera(root)
                Sleep(1 / 60)
            else
                Restore()
                Sleep(if bMoonwalk then 1 / 60 else .25)
            end
        end
        Restore()
    end)
end

if type(UI) == "table" and type(UI.AddTab) == "function" then
    local tabName = "Violence District"
    local defaults = {
        vd_gen = bGeneratorESP,
        vd_kicked = bKickedColor,
        vd_pal = bPalletESP,
        vd_win = bWindowESP,
        vd_trap = bTrapESP,
        vd_zombie = bZombieESP,
        vd_dagger = bDaggerTrajectory,
        vd_hud = bInfoHud,
        vd_hl_dist = highlightDistance,
        vd_hl_fill = bHighlightFill,
        vd_hl_outline = bHighlightOutline,
        vd_skill = bAutoSkillCheck,
        vd_parry = bAutoParry,
        vd_parry_range = bShowParryRange,
        vd_auto_pallet = bAutoPallet,
        vd_crouch = bAutoCrouch,
        vd_vault = vault.Enabled,
        vd_moonwalk = bMoonwalk,
    }
    local apply = {
        vd_gen = function(v) bGeneratorESP = v == true end,
        vd_kicked = function(v) bKickedColor = v == true end,
        vd_pal = function(v) bPalletESP = v == true end,
        vd_win = function(v) bWindowESP = v == true end,
        vd_trap = function(v) bTrapESP = v == true end,
        vd_zombie = function(v) bZombieESP = v == true end,
        vd_dagger = function(v) bDaggerTrajectory = v == true end,
        vd_hud = function(v) bInfoHud = v == true end,
        vd_hl_dist = function(v) highlightDistance = math.clamp(tonumber(v) or 1000, 25, 1000) end,
        vd_hl_fill = function(v) bHighlightFill = v == true end,
        vd_hl_outline = function(v) bHighlightOutline = v == true end,
        vd_skill = function(v) bAutoSkillCheck = v == true end,
        vd_parry = function(v) bAutoParry = v == true end,
        vd_parry_range = function(v) bShowParryRange = v == true end,
        vd_auto_pallet = function(v) bAutoPallet = v == true end,
        vd_crouch = function(v) bAutoCrouch = v == true end,
        vd_vault = function(v) vault.Enabled = v == true end,
        vd_moonwalk = function(v) bMoonwalk = v == true end,
    }
    local colours = {
        vd_gen_col = function(c) generatorColor = c end,
        vd_gen_done = function(c) completedColor = c end,
        vd_kicked_col = function(c) regressingColor = c end,
        vd_pal_col = function(c) palletColor = c end,
        vd_win_col = function(c) windowColor = c end,
        vd_trap_col = function(c) trapColor = c end,
        vd_zombie_col = function(c) zombieColor = c end,
        vd_dagger_start = function(c)
            daggerColor = c
            RebuildDaggerGradient()
        end,
        vd_dagger_end = function(c)
            daggerEndColor = c
            RebuildDaggerGradient()
        end,
        vd_parry_col = function(c) parryRangeColor = c end,
    }

    local function AsColour(value)
        if typeof(value) == "Color3" then return value end
        if type(value) == "table" then
            if type(value.R) == "number" then return Color3.new(value.R, value.G, value.B) end
            if type(value[1]) == "number" then return Color3.fromRGB(value[1], value[2], value[3]) end
        end
        return nil
    end

    local widgetErrors, reported = {}, {}

    local function Widget(section, method, key, ...)
        local fn = section and section[method]
        if type(fn) ~= "function" then
            widgetErrors[key] = widgetErrors[key] or (method .. " is not a function on the section")
            return nil
        end
        local ok, result = pcall(fn, section, ...)
        if not ok then widgetErrors[key] = widgetErrors[key] or tostring(result) end
        return result
    end

    local function Picker(section, id, colour)
        Widget(section, "ColorPicker", id, id, colour.R, colour.G, colour.B, 1, function(value)
            local picked = AsColour(value)
            if picked then colours[id](picked) end
        end)
    end

    local function Picker2(section, id1, colour1, id2, colour2)
        Widget(section, "ColorPicker2", id1, id1, {colour1.R, colour1.G, colour1.B, 1}, id2, {colour2.R, colour2.G, colour2.B, 1}, function(first, _, second)
            local picked1, picked2 = AsColour(first), AsColour(second)
            if picked1 then colours[id1](picked1) end
            if picked2 then colours[id2](picked2) end
        end)
    end

    local function Section(tab, name, side)
        local ok, section = pcall(tab.Section, tab, name, side)
        if not ok then
            widgetErrors[name] = widgetErrors[name] or tostring(section)
            return nil
        end
        return section
    end

    local function Toggle(section, id, label)
        Widget(section, "Toggle", id, id, label, defaults[id])
    end

    local function BuildTab(tab)
        local esp = Section(tab, "ESP", "Left")
        Toggle(esp, "vd_gen", "Generator ESP")
        Picker2(esp, "vd_gen_col", generatorColor, "vd_gen_done", completedColor)
        Toggle(esp, "vd_kicked", "Kicked generator color")
        Picker(esp, "vd_kicked_col", regressingColor)
        Toggle(esp, "vd_pal", "Pallet ESP")
        Picker(esp, "vd_pal_col", palletColor)
        Toggle(esp, "vd_win", "Window ESP")
        Picker(esp, "vd_win_col", windowColor)
        Toggle(esp, "vd_trap", "Bear trap ESP")
        Picker(esp, "vd_trap_col", trapColor)
        Toggle(esp, "vd_zombie", "Cure zombie skeleton ESP")
        Picker(esp, "vd_zombie_col", zombieColor)
        Toggle(esp, "vd_dagger", "Veil dagger trajectory")
        Picker2(esp, "vd_dagger_start", daggerColor, "vd_dagger_end", daggerEndColor)
        Toggle(esp, "vd_hud", "Info HUD")

        local highlighting = Section(tab, "Highlighting", "Left")
        Widget(highlighting, "SliderInt", "vd_hl_dist", "vd_hl_dist", "Highlight render distance", 25, 1000, defaults.vd_hl_dist)
        Toggle(highlighting, "vd_hl_fill", "Highlight fill")
        Toggle(highlighting, "vd_hl_outline", "Highlight outline")

        local main = Section(tab, "Main", "Right")
        Toggle(main, "vd_skill", "Auto skill check")
        Toggle(main, "vd_parry", "React parry")
        Toggle(main, "vd_parry_range", "Show parry range")
        Picker(main, "vd_parry_col", parryRangeColor)
        Toggle(main, "vd_auto_pallet", "Auto drop pallet on killer")
        Toggle(main, "vd_crouch", "Auto crouch (against Abysswalker)")
        Toggle(main, "vd_moonwalk", "Moonwalk (hold S)")

        local vaulting = Section(tab, "Fast vault", "Right")
        if vault.Ready then
            Toggle(vaulting, "vd_vault", "Always fast vault")
        else
            Widget(vaulting, "Button", "vd_vault_scan", "Scan for always fast vault", function()
                if vault.ScanNow then vault.ScanNow() end
            end)
        end
    end

    vault.RebuildMenu = function()
        pcall(UI.RemoveTab, tabName)
        UI.AddTab(tabName, BuildTab)
    end
    vault.RebuildMenu()

    AddJob("Menu sync", false, function()
        local last = {}
        while Running() do
            for key, err in widgetErrors do
                if not reported[key] then
                    reported[key] = true
                    print("[MatchaVD] menu widget " .. key .. " failed: " .. err)
                end
            end
            for id, set in apply do
                local ok, value = pcall(UI.GetValue, id)
                if not ok or value == nil then value = defaults[id] end
                if last[id] ~= value then
                    last[id] = value
                    set(value)
                end
            end
            for id, set in colours do
                local ok, value = pcall(UI.GetValue, id)
                local colour = ok and AsColour(value)
                if colour then
                    local key = string.format("%.3f %.3f %.3f", colour.R, colour.G, colour.B)
                    if last[id] ~= key then
                        last[id] = key
                        set(colour)
                    end
                end
            end
            Sleep(.1)
        end
    end)
end

_G.MatchaVDConnection = RunService.RenderStepped:Connect(function()
    if Running() then Render() end
end)

print("[MatchaVD] loaded")

else
    print("Not in Violence District")
end
