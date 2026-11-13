if game.GameId == 6331902150 then

local textFont = Drawing.Fonts and (Drawing.Fonts.SystemBold or Drawing.Fonts.System)
local labelSize = 13
local timerSize = 30
local outlineThickness = 1.5
local outlineOpacity = .7
local fillOpacity = .18
local loopInterval = 1 / 60
local watchInterval = .1
local flags = {ESP = true, Highlight = true, Text = true, Timer = false, Show = {}}

local c = {
    danger = Color3.fromRGB(224, 17, 95),
    slightdanger = Color3.fromRGB(198, 115, 115),
    neutral = Color3.fromRGB(109, 129, 150),
    generator = Color3.fromRGB(234, 162, 33),
    cola = Color3.fromRGB(45, 104, 196),
    rare = Color3.fromRGB(155, 17, 30),
    gear = Color3.fromRGB(112, 128, 144),
    medkit = Color3.fromRGB(255, 29, 141),
    trap = Color3.fromRGB(179, 27, 27),
    azure = Color3.fromRGB(127, 0, 255),
    yellow = Color3.fromRGB(241, 195, 56),
    timer = Color3.fromRGB(214, 181, 136),
    autoblock = Color3.fromRGB(255, 255, 255),
    autoblockattack = Color3.fromRGB(255, 50, 50),
    lineprim = Color3.fromRGB(179, 27, 27),
    linesec = Color3.fromRGB(241, 195, 56),
}

local categories = {
    {"generator", "Generators"},
    {"medkit", "Medkits"},
    {"cola", "Bloxy colas / spray bottles"},
    {"rare", "Rare items"},
    {"gear", "Gears"},
    {"danger", "Projectiles"},
    {"trap", "Traps"},
    {"slightdanger", "Passive traps"},
    {"neutral", "Clones / fake generators"},
    {"azure", "Azure abilities"},
    {"yellow", "Minions / other"},
}
for _, category in categories do flags.Show[category[1]] = true end

local names = {
    Items = {shockwave = true, Shockwave = true, Swords = true, SpikeCollision = true, HumanoidRootProjectile = true, Voidstar = true, Bats = true, Shadow = true, VineModel = true, GroundBulbModel = true, GroundBulb = true, BuildermanDispenser = true, BuildermanSentry = true, ["007n7"] = true, Pizza = true, GraffitiCL = true, CrystalProjectile = true, Medkit = true, BloxyCola = true, MisterBeast = true, Noli = true},
    SurvivorHidden = {BuildermanDispenser = true, BuildermanSentry = true, Pizza = true, GraffitiCL = true, CrystalProjectile = true, TaphTripwire = true, SubspaceTripmine = true},
    KillerHidden = {FakeGenerator = true, SpikeCollision = true, Shadow = true, VineModel = true, GroundBulbModel = true, GroundBulb = true, Medkit = true, BloxyCola = true, MisterBeast = true, Noli = true, Puddle = true, SprayBottle = true, Ghostburger = true, Epicsauce = true, WitchesBrew = true, Slateskin = true, Fruit = true, Point = true, Gear = true},
    Patterns = {"TaphTripwire", "SubspaceTripmine", "Puddle", "Shockwave"},
    Colors = {
        shockwave = "danger", Shockwave = "danger", Swords = "danger", SpikeCollision = "slightdanger", HumanoidRootProjectile = "danger",
        Voidstar = "danger", Bats = "danger", Shadow = "trap", VineModel = "trap", GroundBulbModel = "trap", GroundBulb = "trap",
        MisterBeast = "azure", Azure = "azure", Noli = "neutral", ["1x1x1x1Zombie"] = "yellow", Trail = "slightdanger", Shadows = "trap",
        Puddle = "slightdanger", FakeGenerator = "neutral", TaphTripwire = "trap", SubspaceTripmine = "danger", BuildermanDispenser = "slightdanger",
        BuildermanSentry = "trap", ["007n7"] = "neutral", Pizza = "slightdanger", GraffitiCL = "slightdanger", CrystalProjectile = "danger",
        Medkit = "medkit", BloxyCola = "cola", SprayBottle = "cola", Ghostburger = "rare", Epicsauce = "rare", WitchesBrew = "rare",
        Slateskin = "rare", Fruit = "rare", Gear = "gear",
    },
    Display = {
        BuildermanDispenser = "Builderman Dispenser", BuildermanSentry = "Builderman Sentry", ["007n7"] = "007n7 Clone", Pizza = "Elliot Pizza",
        GraffitiCL = "Vee Graffiti", TaphTripwire = "Taph Tripwire", SubspaceTripmine = "Taph Mine", Shadow = "Digital Footprint",
        VineModel = "Azure Vine", GroundBulbModel = "Azure Bulb", GroundBulb = "Azure Bulb", MisterBeast = "Golem", ["1x1x1x1Zombie"] = "Zombie",
        FakeGenerator = "Fake Gen", Azure = "Azure", Noli = "Fake Noli", Medkit = "Medkit", BloxyCola = "Cola", SprayBottle = "Spray Bottle",
        Ghostburger = "Ghostburger", Epicsauce = "Epicsauce", WitchesBrew = "Witches Brew", Slateskin = "Slateskin", Point = "Graffiti", Gear = "Gear",
    },
    MapItems = {FakeGenerator = true, BloxyCola = true, Medkit = true, Ghostburger = true, Epicsauce = true, WitchesBrew = true, Slateskin = true},
    MapFolders = {BottleSpawns = "SprayBottle", Graffiti = "Point", GearsTest = "Gear", OrangeFruits = "Fruit"},
    Dropped = {BloxyCola = true, Medkit = true, Ghostburger = true, Epicsauce = true, WitchesBrew = true, Slateskin = true, SprayBottle = true, Gear = true, Fruit = true},
    Puzzles = {LockServerMinigame = "Padlock", GearServerMinigame = "Gears", FlowServerMinigame = "Flow wires", ConnectServerMinigame = "Wire connect"},
    Body = {"Head", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg"},
    PartClasses = {Part = true, MeshPart = true, UnionOperation = true},
    IngameIgnored = {Map = true},
}

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function FetchOffsets()
    local urls = {"https://offsets.imtheo.lol/" .. tostring(getrbxversion()) .. "/offsets.json", "https://offsets.imtheo.lol/offsets.json"}
    for _, url in urls do
        local body = httpget(url)
        if type(body) == "string" and string.sub(body, 1, 1) == "{" then
            local decoded = HttpService:JSONDecode(body)
            if type(decoded) == "table" and type(decoded.Offsets) == "table" then return decoded.Offsets end
        end
    end
    print("[MatchaForsaken] couldn't load offsets, using GetChildren only")
    return {}
end

local O = FetchOffsets()
local childrenStartOffset = tonumber(O.Instance and O.Instance.ChildrenStart)
local childrenEndOffset = tonumber(O.Instance and O.Instance.ChildrenEnd)
local nameOffset = tonumber(O.Instance and O.Instance.Name)
local promptEnabledOffset = tonumber(O.ProximityPrompt and O.ProximityPrompt.Enabled)
local memoryReady = childrenStartOffset and childrenEndOffset and nameOffset and true or false

local runId = tick()
_G.MatchaForsakenRunId = runId
if _G.MatchaForsakenConnection then _G.MatchaForsakenConnection:Disconnect() end
for _, object in _G.MatchaForsakenDrawings or {} do object:Remove() end
local allDrawings = {}
_G.MatchaForsakenDrawings = allDrawings

local frame = {}
local world = {Survivor = false, Killer = false}
local entries = {}

local function Running()
    return _G.MatchaForsakenRunId == runId
end

local function Valid(pointer)
    return pointer ~= nil and pointer > 0x10000 and pointer < 0x7FFFFFFFFFFF
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
        print("[MatchaForsaken] " .. job.Name .. " failed, restarting in 1 s: " .. tostring(err))
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
            local child = buffer.readu32(block, offset) + buffer.readu32(block, offset + 4) * 4294967296
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
        if not found then print(string.format("[MatchaForsaken] Instance.Name offset 0x%X is wrong and no other offset matched, using GetChildren only", nameOffset)) end
        nameOffset = found
        memoryReady = found ~= nil
    end
end

local function MemoryHasChild(address, name, limit)
    local list = MemoryChildren(address)
    if not list or #list > limit then return false end
    for _, child in list do
        if MemoryName(child) == name then return true end
    end
    return false
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

local lines, texts, triangles = {}, {}, {}
local used = {Lines = 0, Texts = 0, Triangles = 0}
local wanted = {Lines = 0, Texts = 0, Triangles = 0}

local function GrowPools()
    for _ = 1, 20 do
        if #lines >= wanted.Lines then break end
        local object = Drawing.new("Line")
        object.Thickness = outlineThickness
        object.Transparency = outlineOpacity
        object.Visible = false
        allDrawings[#allDrawings + 1] = object
        lines[#lines + 1] = {Object = object, Visible = false}
    end
    for _ = 1, 4 do
        if #texts >= wanted.Texts then break end
        local object = Drawing.new("Text")
        if textFont then object.Font = textFont end
        object.Size = labelSize
        object.Center = true
        object.Outline = true
        object.Visible = false
        allDrawings[#allDrawings + 1] = object
        texts[#texts + 1] = {Object = object, Visible = false}
    end
    for _ = 1, 10 do
        if #triangles >= wanted.Triangles then break end
        local object = Drawing.new("Triangle")
        object.Filled = true
        object.Transparency = fillOpacity
        object.Visible = false
        allDrawings[#allDrawings + 1] = object
        triangles[#triangles + 1] = {Object = object, Visible = false}
    end
end

local function DrawLine(x1, y1, x2, y2, color)
    used.Lines += 1
    local entry = lines[used.Lines]
    if not entry then return end
    if entry.X1 ~= x1 or entry.Y1 ~= y1 then
        entry.X1, entry.Y1 = x1, y1
        entry.Object.From = Vector2.new(x1, y1)
    end
    if entry.X2 ~= x2 or entry.Y2 ~= y2 then
        entry.X2, entry.Y2 = x2, y2
        entry.Object.To = Vector2.new(x2, y2)
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

local function DrawText(x, y, text, color)
    used.Texts += 1
    local entry = texts[used.Texts]
    if not entry then return end
    if entry.X ~= x or entry.Y ~= y then
        entry.X, entry.Y = x, y
        entry.Object.Position = Vector2.new(x, y)
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

local function DrawTriangle(x1, y1, x2, y2, x3, y3, color)
    used.Triangles += 1
    local entry = triangles[used.Triangles]
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

local function HidePool(pool, count)
    for index = count + 1, #pool do
        local entry = pool[index]
        if entry.Visible then
            entry.Visible = false
            entry.Object.Visible = false
        end
    end
end

local function Project(wx, wy, wz)
    local x, y, z = wx - frame.PX, wy - frame.PY, wz - frame.PZ
    local depth = x * frame.LX + y * frame.LY + z * frame.LZ
    if depth < .1 then return nil end
    local screen, visible = WorldToScreen(Vector3.new(wx, wy, wz))
    if visible then return screen.X, screen.Y end
    local scale = frame.Focal / depth
    return frame.HalfWidth + (x * frame.RX + y * frame.RY + z * frame.RZ) * scale, frame.HalfHeight - (x * frame.UX + y * frame.UY + z * frame.UZ) * scale
end

local Highlight

do
    local screenX, screenY, order, hull = {}, {}, {}, {}

    local function Cross(o, a, b)
        return (screenX[a] - screenX[o]) * (screenY[b] - screenY[o]) - (screenY[a] - screenY[o]) * (screenX[b] - screenX[o])
    end

    local function Before(a, b)
        return screenX[a] < screenX[b] or (screenX[a] == screenX[b] and screenY[a] < screenY[b])
    end

    Highlight = function(corners, points, color)
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        for i = 1, points do
            local base = i * 3 - 2
            local sx, sy = Project(corners[base], corners[base + 1], corners[base + 2])
            if not sx then return end
            screenX[i], screenY[i] = sx, sy
            if sx < minX then minX = sx end
            if sx > maxX then maxX = sx end
            if sy < minY then minY = sy end
            if sy > maxY then maxY = sy end
            order[i] = i
        end
        if maxX < 0 or maxY < 0 or minX > frame.HalfWidth * 2 or minY > frame.HalfHeight * 2 then return end

        for i = 2, points do
            local value = order[i]
            local j = i - 1
            while j >= 1 and Before(value, order[j]) do
                order[j + 1] = order[j]
                j -= 1
            end
            order[j + 1] = value
        end
        local count = 0
        for i = 1, points do
            local point = order[i]
            while count >= 2 and Cross(hull[count - 1], hull[count], point) <= 0 do count -= 1 end
            count += 1
            hull[count] = point
        end
        local lower = count + 1
        for i = points - 1, 1, -1 do
            local point = order[i]
            while count >= lower and Cross(hull[count - 1], hull[count], point) <= 0 do count -= 1 end
            count += 1
            hull[count] = point
        end
        count -= 1
        if count < 3 then return end
        local first = hull[1]
        for i = 2, count - 1 do
            local b, d = hull[i], hull[i + 1]
            DrawTriangle(screenX[first], screenY[first], screenX[b], screenY[b], screenX[d], screenY[d], color)
        end
        for i = 1, count do
            local a, b = hull[i], hull[i % count + 1]
            DrawLine(screenX[a], screenY[a], screenX[b], screenY[b], color)
        end
    end
end

local function WriteCorners(out, index, cframe, size)
    local p, r, u, l = cframe.Position, cframe.RightVector, cframe.UpVector, cframe.LookVector
    local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
    local rx, ry, rz = r.X * hx, r.Y * hx, r.Z * hx
    local ux, uy, uz = u.X * hy, u.Y * hy, u.Z * hy
    local lx, ly, lz = l.X * hz, l.Y * hz, l.Z * hz
    local px, py, pz = p.X, p.Y, p.Z
    for corner = 0, 7 do
        local sr = if corner % 2 == 0 then 1 else -1
        local su = if corner % 4 < 2 then 1 else -1
        local sl = if corner >= 4 then 1 else -1
        out[index + 1] = px + rx * sr + ux * su + lx * sl
        out[index + 2] = py + ry * sr + uy * su + ly * sl
        out[index + 3] = pz + rz * sr + uz * su + lz * sl
        index += 3
    end
    return index
end

local function AddSpaces(text)
    text = text:gsub("(%l)(%u)", "%1 %2")
    text = text:gsub("(%u)(%u%l)", "%1 %2")
    return text
end

local GetNameInfo

do
    local cache, count = {}, 0

    GetNameInfo = function(name)
        local info = cache[name]
        if info then return info end

        local colorKey = names.Colors[name]
        local display = names.Display[name]
        local pattern = false
        for _, p in names.Patterns do
            if string.find(name, p) then
                colorKey = names.Colors[p]
                display = names.Display[p]
                pattern = true
            end
        end

        info = {
            ColorKey = colorKey or "yellow",
            Display = display,
            IsItem = names.Items[name] == true or pattern,
            IsTrailFolder = string.find(name, "JohnDoeTrail") ~= nil or string.find(name, "Shadows") ~= nil,
            Hidden = name == "JaneGhost" or (string.find(name, "Spray") ~= nil and name ~= "SprayBottle"),
            SurvivorHidden = names.SurvivorHidden[name] == true or string.find(name, "TaphTripwire") ~= nil or string.find(name, "SubspaceTripmine") ~= nil,
            KillerHidden = names.KillerHidden[name] == true or string.find(name, "Puddle") ~= nil or string.find(name, "Shockwave") ~= nil,
        }

        if count >= 400 then
            cache, count = {}, 0
        end
        cache[name] = info
        count += 1
        return info
    end
end

local NewWatch, UpdateWatch

do
    NewWatch = function(filter)
        return {Filter = filter, Known = {}, Items = {}, Count = 0, NextResolve = 0}
    end

    local function Resolve(watch, instances, address)
        local known = watch.Known[address]
        local inst = instances[address]
        if inst then watch.Items[address] = {Name = known.Name, Kind = known.Kind, Instance = inst, Address = address} end
        return inst ~= nil
    end

    UpdateWatch = function(watch, folder, now)
        local address = folder and folder.Address
        if address ~= watch.Folder then
            watch.Folder, watch.Known, watch.Items, watch.Count = address, {}, {}, 0
        end
        if not address then return end

        local list = memoryReady and MemoryChildren(address)
        local instances
        if not list then
            list, instances = {}, {}
            for _, child in folder:GetChildren() do
                local childAddress = child.Address
                list[#list + 1] = childAddress
                instances[childAddress] = child
            end
        end
        watch.Count = #list

        local present, unresolved = {}, false
        for _, child in list do
            present[child] = true
            local known = watch.Known[child]
            if not known then
                known = {First = now}
                watch.Known[child] = known
            end
            if known.Kind == nil then
                if not known.Name or known.Name == "" then
                    known.Name = if instances then instances[child].Name else MemoryName(child)
                end
                if known.Name and known.Name ~= "" then
                    known.Kind = watch.Filter(known.Name, child, now - known.First, instances and instances[child])
                end
            end
            if known.Kind and not watch.Items[child] then
                if not instances or not Resolve(watch, instances, child) then unresolved = true end
            end
        end
        for child in watch.Known do
            if not present[child] then
                watch.Known[child] = nil
                watch.Items[child] = nil
            end
        end

        if unresolved and now >= watch.NextResolve then
            watch.NextResolve = now + .25
            local found = {}
            for _, inst in folder:GetChildren() do found[inst.Address] = inst end
            for child, known in watch.Known do
                if known.Kind and not watch.Items[child] then Resolve(watch, found, child) end
            end
        end
    end
end

local folders = {}

local watches = {
    Ingame = NewWatch(function(name, address, age, inst)
        local info = GetNameInfo(name)
        if info.IsItem then return "item" end
        if info.IsTrailFolder then return "trail" end
        if names.IngameIgnored[name] then return false end
        if inst then
            if inst:FindFirstChild("Humanoid") then return "item" end
        elseif MemoryHasChild(address, "Humanoid", 64) then
            return "item"
        end
        if age > 1 then return false end
        return nil
    end),
    Killers = NewWatch(function(name)
        return name == "Noli" and "noli" or false
    end),
    Workspace = NewWatch(function(name)
        return names.Dropped[name] and "dropped" or false
    end),
    Map = NewWatch(function(name)
        return name == "Azure" and "item" or false
    end),
    MapContent = NewWatch(function(name)
        if name == "Generator" then return "generator" end
        if names.MapItems[name] then return "static" end
        if names.MapFolders[name] then return "folder" end
        return false
    end),
}
local subWatches = {}

local function ResetAll()
    entries = {}
    subWatches = {}
    for _, watch in watches do
        watch.Folder, watch.Known, watch.Items, watch.Count = nil, {}, {}, 0
    end
end

local function FindParts(entry)
    local inst = entry.Instance
    local parts, sizes, labelIndex, partNames = {}, {}, nil, nil
    local className = inst.ClassName
    if names.PartClasses[className] then
        parts[1] = inst
    elseif entry.Humanoid then
        partNames = {}
        for _, partName in names.Body do
            local part = inst:FindFirstChild(partName)
            if part then
                parts[#parts + 1] = part
                partNames[#parts] = partName
                if partName == "Torso" then labelIndex = #parts end
            end
        end
    else
        local part
        if entry.Name == "MisterBeast" then
            part = inst:FindFirstChildOfClass("MeshPart")
        elseif entry.Name == "VineModel" then
            part = inst:FindFirstChild("Tentacle")
        end
        part = part or (className == "Model" and inst.PrimaryPart) or inst:FindFirstChildOfClass("Part") or inst:FindFirstChildOfClass("MeshPart") or inst:FindFirstChildOfClass("UnionOperation")
        parts[1] = part
    end
    for i, part in parts do
        local size = part.Size
        if not size then return nil end
        sizes[i] = size
    end
    entry.Parts, entry.Sizes, entry.LabelIndex, entry.PartNames = parts, sizes, labelIndex or 1, partNames
    entry.Stale = false
    return #parts > 0
end

local function NewEntry(item, source, now)
    local name = item.Name
    local entry = {
        Address = item.Address,
        Instance = item.Instance,
        Name = name,
        Source = source,
        Info = GetNameInfo(name),
        Corners = {},
        Points = 0,
        Visible = false,
        Ready = false,
        NextCheck = now,
        NextPose = now,
        NextParts = 0,
        Static = source == "generator" or source == "static" or source == "trail",
        PoseInterval = if source == "dropped" then .1 else 0,
    }
    if source == "generator" then
        entry.ColorKey = "generator"
        entry.Text = "Generator"
    else
        entry.ColorKey = entry.Info.ColorKey
        entry.Text = entry.Info.Display
        if not names.PartClasses[item.Instance.ClassName] then entry.Humanoid = item.Instance:FindFirstChild("Humanoid") end
        if entry.Humanoid then entry.Text = entry.Text or "Minion" end
        entry.Static = entry.Static and not entry.Humanoid
    end
    return entry
end

local function CheckGenerator(entry, now)
    entry.NextCheck = now + .4 + math.random() * .2
    local main = entry.Main or entry.Instance:FindFirstChild("Main")
    if not main then
        entry.Visible = false
        return
    end
    if main ~= entry.Main then
        local size = main.Size
        if not size then
            entry.Visible = false
            return
        end
        entry.Main, entry.Parts, entry.Sizes, entry.LabelIndex, entry.Ready = main, {main}, {size}, 1, false
    end
    if not entry.Puzzle and now >= (entry.NextPuzzle or 0) then
        entry.NextPuzzle = now + 2
        local puzzle = entry.Instance:GetAttribute("Puzzle")
        if type(puzzle) == "string" and puzzle ~= "" then
            entry.Puzzle = puzzle
            entry.Text = names.Puzzles[puzzle] or "Generator"
        end
    end
    entry.Visible = not world.Killer and main:FindFirstChild("generatorActivate") == nil
end

local function IsFakeNoli(entry, now)
    if watches.Killers.Count <= 1 then return false end
    if not entry.Username then
        local username = entry.Instance:GetAttribute("Username")
        if type(username) == "string" and username ~= "" then
            entry.Username = username
            world.NoliName = username
        end
    end
    local username = entry.Username or world.NoliName
    if not username then return false end
    local player = Players:FindFirstChild(username)
    local character = player and player.Character
    return character ~= nil and character.Address ~= entry.Address
end

local function CheckItem(entry, now)
    entry.NextCheck = now + .25 + math.random() * .05
    local info = entry.Info
    if info.Hidden or (world.Survivor and info.SurvivorHidden) or (world.Killer and info.KillerHidden) or (entry.Source == "trail" and world.Killer) then
        entry.Visible = false
        return
    end
    if entry.Source == "noli" and not IsFakeNoli(entry, now) then
        entry.Visible = false
        return
    end
    if entry.Name == "Point" then
        entry.Prompt = entry.Prompt or entry.Instance:FindFirstChild("ProximityPrompt")
        if not entry.Prompt or (promptEnabledOffset and memory_read("byte", entry.Prompt.Address + promptEnabledOffset) == 0) then
            entry.Visible = false
            return
        end
    end
    if entry.Humanoid then
        local health = entry.Humanoid.Health
        if health == nil or health <= 0 then
            entry.Visible = false
            return
        end
    end
    if not entry.Parts or entry.Stale or (entry.Humanoid and now >= entry.NextParts) then
        entry.NextParts = now + 1
        entry.Ready = false
        if not FindParts(entry) then
            entry.Visible = false
            return
        end
    end
    if entry.Name == "Trail" then
        local size = entry.Sizes[1]
        if size.X > 100 or size.Y > 100 or size.Z > 100 then
            entry.Visible = false
            return
        end
    end
    if entry.Name == "Fruit" and not entry.FruitRead then
        entry.FruitRead = true
        local fruit = entry.Instance:GetAttribute("Fruit")
        entry.Text = if type(fruit) == "string" and fruit ~= "" then AddSpaces(fruit) else "Fruit"
    end
    entry.Visible = true
end

local function ReadPose(entry)
    local corners, index = entry.Corners, 0
    for i, part in entry.Parts do
        local cframe = part.CFrame
        local size = entry.Sizes[i]
        if not cframe or not size then
            entry.Stale = true
            entry.Ready = false
            return
        end
        if i == entry.LabelIndex then
            local p = cframe.Position
            entry.LX, entry.LY, entry.LZ = p.X, p.Y, p.Z
        end
        index = WriteCorners(corners, index, cframe, size)
        if entry.PartNames then
            local joints = entry.Joints or {}
            entry.Joints = joints
            joints[entry.PartNames[i]] = {cframe.Position, cframe.UpVector * (size.Y / 2)}
        end
    end
    entry.Points = math.floor(index / 3)
    entry.Ready = entry.Points > 0
    local joints = entry.PartNames and entry.Joints
    if joints then
        local bones = {}
        local function Bone(a, b)
            bones[#bones + 1] = a.X
            bones[#bones + 1] = a.Y
            bones[#bones + 1] = a.Z
            bones[#bones + 1] = b.X
            bones[#bones + 1] = b.Y
            bones[#bones + 1] = b.Z
        end
        local torso, head = joints.Torso, joints.Head
        if torso then
            local neck, pelvis = torso[1] + torso[2], torso[1] - torso[2]
            Bone(neck, pelvis)
            if head then Bone(head[1], neck) end
            for _, side in {"Left", "Right"} do
                local arm, leg = joints[side .. " Arm"], joints[side .. " Leg"]
                if arm then
                    local shoulder = arm[1] + arm[2]
                    Bone(neck, shoulder)
                    Bone(shoulder, arm[1] - arm[2])
                end
                if leg then
                    local hip = leg[1] + leg[2]
                    Bone(pelvis, hip)
                    Bone(hip, leg[1] - leg[2])
                end
            end
        end
        entry.Bones = if #bones > 0 then bones else nil
        local top = (head and head[1] + head[2]) or (torso and torso[1] + torso[2] * 2)
        if top then entry.LX, entry.LY, entry.LZ = top.X, top.Y + 1.2, top.Z end
        table.clear(joints)
    end
end

local function UpdateEntries(now)
    for _, entry in entries do
        if now >= entry.NextCheck then
            if entry.Source == "generator" then CheckGenerator(entry, now) else CheckItem(entry, now) end
        end
        if entry.Visible and entry.Parts and (not entry.Ready or (not entry.Static and now >= entry.NextPose)) then
            entry.NextPose = now + entry.PoseInterval
            ReadPose(entry)
            if entry.Stale then entry.NextCheck = now end
        end
    end
end

local function SyncEntries(now)
    local present = {}
    local function Take(item, source)
        present[item.Address] = true
        local entry = entries[item.Address]
        if not entry then
            entries[item.Address] = NewEntry(item, source, now)
        end
    end

    for address, item in watches.Ingame.Items do
        if item.Kind == "trail" then
            local sub = subWatches[address] or NewWatch(function() return "trail" end)
            subWatches[address] = sub
            UpdateWatch(sub, item.Instance, now)
            sub.Seen = now
            for _, child in sub.Items do Take(child, "trail") end
        else
            Take(item, "ingame")
        end
    end
    for _, item in watches.Killers.Items do Take(item, "noli") end
    for _, item in watches.Workspace.Items do Take(item, "dropped") end
    for _, item in watches.Map.Items do Take(item, "ingame") end
    for address, item in watches.MapContent.Items do
        if item.Kind == "folder" then
            local wantedName = names.MapFolders[item.Name]
            local sub = subWatches[address] or NewWatch(function(name) return name == wantedName and "static" or false end)
            subWatches[address] = sub
            UpdateWatch(sub, item.Instance, now)
            sub.Seen = now
            for _, child in sub.Items do Take(child, "static") end
        else
            Take(item, item.Kind)
        end
    end

    for address, sub in subWatches do
        if sub.Seen ~= now then subWatches[address] = nil end
    end
    for address in entries do
        if not present[address] then entries[address] = nil end
    end
end

local function RefreshWorld(now)
    local character = LocalPlayer.Character
    local parent = character and character.Parent
    local parentName = parent and parent.Name
    world.Survivor = parentName == "Survivors"
    world.Killer = parentName == "Killers"

    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    world.PlayerGui = gui
    local inPuzzle = gui ~= nil and gui:FindFirstChild("PuzzleUI") ~= nil
    world.InPuzzle = inPuzzle
    world.HiddenGenerator = nil
    local root = inPuzzle and character and character:FindFirstChild("HumanoidRootPart")
    local rootPosition = root and root.Position
    if rootPosition then
        local nearest
        for address, entry in entries do
            if entry.Source == "generator" and entry.LX then
                local dx, dy, dz = entry.LX - rootPosition.X, entry.LY - rootPosition.Y, entry.LZ - rootPosition.Z
                local distance = dx * dx + dy * dy + dz * dz
                if not nearest or distance < nearest then
                    nearest = distance
                    world.HiddenGenerator = address
                end
            end
        end
    end
end

local function RefreshFolders()
    local map = workspace:FindFirstChild("Map")
    local ingame = map and map:FindFirstChild("Ingame")
    local playersFolder = workspace:FindFirstChild("Players")
    folders.Map = map
    folders.Ingame = ingame
    folders.MapContent = ingame and ingame:FindFirstChild("Map")
    folders.Killers = playersFolder and playersFolder:FindFirstChild("Killers")
    folders.Survivors = playersFolder and playersFolder:FindFirstChild("Survivors")
end

local function NewBigText(size)
    local object = Drawing.new("Text")
    if textFont then object.Font = textFont end
    object.Size = size
    object.Center = true
    object.Outline = true
    object.Visible = false
    allDrawings[#allDrawings + 1] = object
    return {Object = object, Shown = false}
end

local function SetBigText(entry, show, x, y, text, color)
    local object = entry.Object
    if show then
        if entry.X ~= x or entry.Y ~= y then
            entry.X, entry.Y = x, y
            object.Position = Vector2.new(x, y)
        end
        if entry.Text ~= text then
            entry.Text = text
            object.Text = text
        end
        if entry.Color ~= color then
            entry.Color = color
            object.Color = color
        end
    end
    if entry.Shown ~= show then
        entry.Shown = show
        object.Visible = show
    end
end

local function Path(inst, ...)
    for _, name in {...} do
        if not inst then return nil end
        inst = inst:FindFirstChild(name)
    end
    return inst
end

local timer = {Visible = false, Text = "", Label = NewBigText(timerSize)}

local function RenderTimer()
    local show = flags.Timer and timer.Visible and frame.HalfWidth ~= nil
    SetBigText(timer.Label, show, frame.HalfWidth, frame.HalfHeight * 2 / 10, timer.Text, c.timer)
end

local NewAttributeReader, ReadAttribute

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

    local function Layout(node)
        return memory_read("uintptr_t", node + 8), memory_read("uintptr_t", node + 0x10), memory_read("uintptr_t", node + 0x18)
    end

    local function NodeEntries(node)
        local a, b, d = Layout(node)
        return EntryMap(a, b) or EntryMap(d, a)
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

    NewAttributeReader = function(anchor)
        return {Anchor = anchor, NextTry = 0, Backoff = 2, Fallback = {}}
    end

    ReadAttribute = function(reader, instance, name, now)
        local address = instance and instance.Address
        if not address then return nil end
        if reader.Address ~= address then
            reader.Address, reader.Node, reader.Entries, reader.Layout, reader.NextTry, reader.Backoff, reader.Fallback = address, nil, nil, nil, 0, 2, {}
        end
        if memoryReady and not reader.Node and now >= reader.NextTry then
            reader.Node = FindNode(address, reader.Anchor)
            if not reader.Node then
                reader.NextTry = now + reader.Backoff
                reader.Backoff = math.min(reader.Backoff * 2, 30)
            end
        end
        local node = reader.Node
        if node then
            local a, b, d = Layout(node)
            local layout = string.format("%s %s %s", tostring(a), tostring(b), tostring(d))
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
                if not entry then return nil end
                local number = memory_read("double", entry + valueOffset)
                return if number == number then number else nil
            end
        end
        local cached = reader.Fallback[name]
        if cached and now < cached.Until then return cached.Value end
        local value = instance:GetAttribute(name)
        reader.Fallback[name] = {Value = value, Until = now + .1}
        return value
    end
end

local block = {
    Enabled = false,
    Show = false,
    SafeSprint = false,
    Mode = "default",
    Modes = {"very-strict", "strict", "default", "permissive", "always"},
    Delay = 0,
    Parry = false,
    ParryDelay = 0,
    ParryAngle = 0,
    ParryImmune = false,
    ParryLookup = .6,
    Chance = false,
    Safety = .1,
    StartWidth = 7.5,
    Killers = {},
    FlashUntil = 0,
    Profiles = {
        ["very-strict"] = {Shape = "Rectangle", RadiusMode = "Inner"},
        strict = {Shape = "Cone", Angle = 100, RadiusMode = "Inner"},
        default = {Shape = "Cone", Angle = 140, RadiusMode = "Inner"},
        permissive = {Shape = "Cone", Angle = 240, InnerRadius = 4.5, RadiusMode = "Inner"},
        always = {Shape = "Circle", RadiusMode = "Outer"},
    },
    KillerData = {
        Default = {Windup = .2, Linger = .25, Length = 7.5, Height = 7},
        c00lkidd = {Windup = .1, Linger = .3, Length = 6, Height = 7, Backward = 2},
        Slasher = {Windup = .2, Linger = .25, Length = 7.5, Height = 7, Backward = 3},
        JohnDoe = {Windup = .4, Linger = .25, Length = 7.5, Height = 7, Backward = 3},
        Noli = {Windup = .35, Linger = .25, Length = 8, Height = 7, Backward = 3},
        ["1x1x1x1"] = {Windup = .4, Linger = .25, Length = 7.5, Height = 7, Backward = 3},
        Sixer = {Windup = .3, Linger = .25, Length = 8.5, Height = 8, Backward = 2},
        Nosferatu = {Windup = .3, Linger = .3, Length = 8.5, Height = 7, Backward = 3},
        Azure = {Windup = .2, Linger = .25, Length = 8.5, Height = 7, Backward = 3.5},
    },
    Guests = {Guest1337 = true, ["007n7"] = true},
    Modifiers = {LeftShift = 0xA0, RightShift = 0xA1, LeftCtrl = 0xA2, RightCtrl = 0xA3, LeftAlt = 0xA4, RightAlt = 0xA5},
    Status = NewBigText(30),
    GuestColor = Color3.fromRGB(248, 131, 121),
    InactiveColor = Color3.fromRGB(109, 129, 150),
    FlashColor = Color3.fromRGB(255, 25, 25),
    Flash = NewBigText(35),
    ShapeX = {},
    ShapeY = {},
}

local RenderBlock

do
    local function Keycode(value)
        if type(value) ~= "string" then return nil end
        if #value == 1 then return string.byte(string.upper(value)) end
        return block.Modifiers[value]
    end

    local function RefreshBinds()
        local keybinds = Path(LocalPlayer, "PlayerData", "Settings", "Keybinds")
        if not keybinds then return end
        local ability = Path(keybinds, "AltAbility1")
        local sprint = Path(keybinds, "Sprinting")
        local parryBind = Path(keybinds, "AltAbility3")
        block.BlockKey = ability and Keycode(ability.Value) or block.BlockKey
        block.ParryKey = parryBind and Keycode(parryBind.Value) or block.ParryKey
        block.SprintKey = sprint and Keycode(sprint.Value) or block.SprintKey
    end

    local function FindHitbox(character, now)
        local address = character.Address
        if block.HitboxOwner == address and block.Hitbox then return end
        if block.HitboxOwner == address and now < (block.NextHitboxSearch or 0) then return end
        block.HitboxOwner, block.Hitbox, block.HitboxSize, block.NextHitboxSearch = address, nil, nil, now + 2
        for _, descendant in character:GetDescendants() do
            if descendant.Name == "QueryHitbox" then
                local size = descendant.Size
                if size then block.Hitbox, block.HitboxSize = descendant, size end
                return
            end
        end
    end

    local function IsFake(killer, count)
        if killer.Name ~= "Noli" or count <= 1 then return false end
        if not killer.Username then
            local username = killer.Model:GetAttribute("Username")
            if type(username) == "string" and username ~= "" then killer.Username = username end
        end
        local player = killer.Username and Players:FindFirstChild(killer.Username)
        local character = player and player.Character
        return character ~= nil and character.Address ~= killer.Address
    end

    local function Refresh(now)
        local character = LocalPlayer.Character
        local name = character and character.Name
        block.Guest = name ~= nil and block.Guests[name] == true
        block.Root = character and character:FindFirstChild("HumanoidRootPart")
        if character and (block.Enabled or block.Show) then FindHitbox(character, now) end
        if now >= (block.NextBinds or 0) then
            block.NextBinds = now + 2
            RefreshBinds()
        end
        if block.SafeSprint then
            block.Stamina = Path(world.PlayerGui, "TemporaryUI", "PlayerInfo", "Bars", "Stamina", "Amount")
        end

        local killers = {}
        local folder = folders.Killers
        local children = folder and folder:GetChildren() or {}
        for _, model in children do
            local address = model.Address
            local killer = block.Killers[address]
            if not killer then
                local root = model:FindFirstChild("HumanoidRootPart")
                if root then
                    killer = {Address = address, Model = model, Root = root, Name = model.Name, Reader = NewAttributeReader("AbilityLastUsed"), VisualUntil = 0}
                end
            end
            if killer and not IsFake(killer, #children) then killers[address] = killer end
        end
        block.Killers = killers
    end

    local function UpdatePrediction(killer, position, now)
        if not killer.PredictTime then
            killer.PredictPosition, killer.PredictTime, killer.Velocity, killer.LastMovement = position, now, Vector3.new(0, 0, 0), now
            return
        end
        local dt = now - killer.PredictTime
        if dt < .05 then return end
        local delta = position - killer.PredictPosition
        if delta.Magnitude > .03 then
            killer.Velocity = killer.Velocity * .5 + (delta / dt) * .5
            killer.LastMovement = now
        elseif now - killer.LastMovement > .25 then
            killer.Velocity = killer.Velocity * .7
            if killer.Velocity.Magnitude < .5 then killer.Velocity = Vector3.new(0, 0, 0) end
        end
        killer.PredictPosition, killer.PredictTime = position, now
    end

    local function BuildTest(killer, hitboxSize, localPos)
        local profile = block.Profiles[block.Mode]
        local kp, look = killer.Position, killer.Look
        if not profile or not kp or not look or not hitboxSize then return nil end
        local config = block.KillerData[killer.Name] or block.KillerData.Default
        local attackLength, attackHeight, backward = config.Length, config.Height, config.Backward or 0

        if localPos and killer.Velocity then
            local alpha = math.clamp((kp - localPos).Magnitude / 92, 0, 1)
            kp = kp + killer.Velocity * (.2 * alpha ^ .3 * 1.5)
        end

        local fx, fz = look.X, look.Z
        local magnitude = math.sqrt(fx * fx + fz * fz)
        if magnitude == 0 then return nil end
        fx, fz = fx / magnitude, fz / magnitude
        local rx, rz = -fz, fx
        local hx, hz = hitboxSize.X / 2, hitboxSize.Z / 2
        local queryRadius = if profile.RadiusMode == "Outer" then math.sqrt(hx * hx + hz * hz) else math.min(hx, hz)
        local halfHeight = hitboxSize.Y / 2
        local halfWidth = block.StartWidth / 2
        local innerCircle = profile.InnerRadius
        if innerCircle and killer.Name == "c00lkidd" then innerCircle = 3.5 end
        local kx, ky, kz = kp.X, kp.Y, kp.Z

        local function RectangleDistance(forward, side, back)
            local df = forward - math.clamp(forward, -back, attackLength)
            local ds = side - math.clamp(side, -halfWidth, halfWidth)
            return math.sqrt(df * df + ds * ds)
        end

        local function Inside(px, py, pz)
            local ox, oy, oz = px - kx, py - ky, pz - kz
            if math.abs(oy) > attackHeight / 2 + halfHeight then return false end
            local distance = math.sqrt(ox * ox + oz * oz)
            local forward = ox * fx + oz * fz
            local side = ox * rx + oz * rz
            if profile.Shape == "Rectangle" then return RectangleDistance(forward, side, 0) <= queryRadius end
            if profile.Shape == "Circle" then return distance <= attackLength + queryRadius end
            if innerCircle and distance <= innerCircle + queryRadius then return true end
            if RectangleDistance(forward, side, backward) <= queryRadius then return true end
            if distance > attackLength + queryRadius then return false end
            if distance <= queryRadius then return true end
            local allowed = math.min(math.pi, math.rad(profile.Angle / 2) + math.asin(math.clamp(queryRadius / distance, 0, 1)))
            return forward / distance >= math.cos(allowed)
        end

        local rectRadius = math.sqrt((math.max(attackLength, backward) + queryRadius) ^ 2 + (halfWidth + queryRadius) ^ 2)
        local maxRadius = math.max(attackLength + queryRadius, innerCircle and (innerCircle + queryRadius) or 0, rectRadius) + 1
        return Inside, kx, ky, kz, fx, fz, rx, rz, maxRadius
    end

    local function BuildShape(killer, hitboxSize, localPos)
        local Inside, kx, ky, kz, fx, fz, rx, rz, maxRadius = BuildTest(killer, hitboxSize, localPos)
        if not Inside then
            killer.Shape = nil
            return
        end
        local shape = killer.Shape or {}
        for i = 0, 35 do
            local angle = -math.pi + (i / 36) * math.pi * 2
            local ca, sa = math.cos(angle), math.sin(angle)
            local low, high = 0, maxRadius
            for _ = 1, 6 do
                local mid = (low + high) / 2
                if Inside(kx + (fx * ca + rx * sa) * mid, ky, kz + (fz * ca + rz * sa) * mid) then low = mid else high = mid end
            end
            shape[i * 3 + 1], shape[i * 3 + 2], shape[i * 3 + 3] = kx + (fx * ca + rx * sa) * low, ky, kz + (fz * ca + rz * sa) * low
        end
        shape.CX, shape.CY, shape.CZ = kx, ky, kz
        killer.Shape = shape
    end

    local function Press()
        local key = block.BlockKey
        if not key then return end
        task.spawn(function()
            keypress(key)
            task.wait(.1)
            keyrelease(key)
        end)
    end

    local function StartAttack(killer, now)
        local config = block.KillerData[killer.Name] or block.KillerData.Default
        local ping = (type(GetPingValue) == "function" and tonumber(GetPingValue()) or 0) / 1000
        killer.Attack = {
            Started = now,
            From = now + math.max(0, config.Windup + block.Delay - ping - block.Safety),
            Until = now + math.max(0, config.Windup + config.Linger - ping - block.Safety - .05),
        }
        killer.VisualUntil = now + config.Windup + config.Linger
    end

    local function Update(now)
        local root = block.Root
        local localPos = root and root.Position
        local hitbox = block.Hitbox
        local hitboxPos = hitbox and hitbox.Position
        for _, killer in block.Killers do
            local cframe = killer.Root.CFrame
            if cframe then
                killer.Position, killer.Look = cframe.Position, cframe.LookVector
                UpdatePrediction(killer, killer.Position, now)
            else
                killer.Position, killer.Look = nil, nil
            end

            if block.Enabled then
                local abTime = tonumber(ReadAttribute(killer.Reader, killer.Model, "AbilityLastUsed", now))
                if abTime then
                    if not killer.AbTime or not killer.Ab then
                        local ab = tonumber(ReadAttribute(killer.Reader, killer.Model, "AbilitiesUsed", now))
                        if ab then killer.AbTime, killer.Ab = abTime, ab end
                    elseif killer.AbTime ~= abTime then
                        local ab = tonumber(ReadAttribute(killer.Reader, killer.Model, "AbilitiesUsed", now))
                        if ab and ab == killer.Ab then
                            killer.AbTime = abTime
                            if localPos and not (killer.Attack and now - killer.Attack.Started < .2) then StartAttack(killer, now) end
                        elseif ab and ab > killer.Ab then
                            killer.Ab, killer.AbTime = ab, abTime
                        end
                    end
                end

                local attack = killer.Attack
                if attack then
                    if now > attack.Until then
                        killer.Attack = nil
                    elseif now >= attack.From and hitboxPos and localPos then
                        local Inside = BuildTest(killer, block.HitboxSize, localPos)
                        if Inside and Inside(hitboxPos.X, hitboxPos.Y, hitboxPos.Z) then
                            killer.Attack = nil
                            if block.Guest then
                                block.FlashUntil = now + 1
                                Press()
                            end
                        end
                    end
                end
            end

            if block.Show and block.HitboxSize then BuildShape(killer, block.HitboxSize, localPos) else killer.Shape = nil end
        end
    end

    local function SafeSprint()
        local label = block.Stamina
        local key = block.SprintKey
        if not label or not key then return end
        local text = label.Text
        if type(text) == "string" and string.match(text, "^%s*(%d+)") == "1" then keyrelease(key) end
    end

    RenderBlock = function()
        local now = tick()
        if block.Show then
            local xs, ys = block.ShapeX, block.ShapeY
            for _, killer in block.Killers do
                local shape = killer.Shape
                if shape then
                    local color = if now < killer.VisualUntil then c.autoblockattack else c.autoblock
                    for i = 0, 35 do
                        local x, y = Project(shape[i * 3 + 1], shape[i * 3 + 2], shape[i * 3 + 3])
                        xs[i + 1], ys[i + 1] = x or false, y or false
                    end
                    local cx, cy = Project(shape.CX, shape.CY, shape.CZ)
                    for i = 1, 36 do
                        local j = i % 36 + 1
                        if xs[i] and xs[j] then
                            if cx then DrawTriangle(cx, cy, xs[i], ys[i], xs[j], ys[j], color) end
                            DrawLine(xs[i], ys[i], xs[j], ys[j], color)
                        end
                    end
                end
            end
        end
        local width, height = frame.HalfWidth, frame.HalfHeight
        local ready = width ~= nil
        SetBigText(block.Status, ready and block.Enabled, width, height * 1.5 - 30, if block.Guest then "AUTO BLOCK" else "AUTO BLOCK (inactive)", if block.Guest then block.GuestColor else block.InactiveColor)
        local flashing = ready and block.Enabled and now < block.FlashUntil
        SetBigText(block.Flash, flashing, flashing and width + math.random(-5, 5) or 0, flashing and height + math.random(-5, 5) or 0, "BLOCK", block.FlashColor)
    end

    local primitiveOffset = tonumber(O.BasePart and O.BasePart.Primitive)
    local rotationOffset = tonumber(O.Primitive and O.Primitive.Rotation)
    local positionOffset = tonumber(O.Primitive and O.Primitive.Position)

    local function WritePose(root, look, up, position)
        if not root or not primitiveOffset or not rotationOffset or not positionOffset then return end
        local primitive = memory_read("uintptr_t", root.Address + primitiveOffset)
        if not Valid(primitive) then return end
        look = look.Unit
        local right = look:Cross(up)
        if right.Magnitude < .01 then return end
        right = right.Unit
        up = right:Cross(look)
        local matrix = {right.X, up.X, -look.X, right.Y, up.Y, -look.Y, right.Z, up.Z, -look.Z}
        for i = 1, 9 do memory_write("float", primitive + rotationOffset + (i - 1) * 4, matrix[i]) end
        if position then
            memory_write("float", primitive + positionOffset, position.X)
            memory_write("float", primitive + positionOffset + 4, position.Y)
            memory_write("float", primitive + positionOffset + 8, position.Z)
        end
    end
    block.WritePose = WritePose

    local function FaceTowards(root, target)
        local position = root and root.Position
        if not position or not target then return nil end
        local flat = Vector3.new(target.X - position.X, 0, target.Z - position.Z)
        if flat.Magnitude < .01 then return nil end
        WritePose(root, flat, Vector3.new(0, 1, 0))
        return flat.Unit
    end

    local function RealKiller()
        for _, killer in block.Killers do
            if killer.Position then return killer end
        end
        return nil
    end

    local function PredictKiller(killer, localPos, multiplier)
        local position = killer.Position
        if not position or not killer.Velocity or not localPos then return position end
        local alpha = math.clamp((position - localPos).Magnitude / 92, 0, 1)
        return position + killer.Velocity * (.2 * alpha ^ .3 * multiplier)
    end

    local function HitIds(character, into)
        local fov = character:FindFirstChild("FOVMultipliers")
        if not fov then return end
        for _, child in fov:GetChildren() do
            if child.Name == "HitRegistered" then into[child.Address] = true end
        end
    end

    local function SetCollision(parts, enabled)
        for _, part in parts do
            local ok = pcall(function() part.CanCollide = enabled end)
            if not ok then return end
        end
    end

    local function RunParry(character)
        local root = character:FindFirstChild("HumanoidRootPart")
        local killer = RealKiller()
        local key = block.ParryKey
        if not root or not killer or not key then return end
        if block.ParryDelay > 0 then Sleep(block.ParryDelay) end
        if not block.ParryImmune then
            local model = killer.Model
            if model:GetAttribute("Invincible") or model:GetAttribute("StunnedDisabled") then return end
        end
        local tiltEnabled = block.ParryAngle > 0
        local up = Vector3.new(0, 1, 0)
        local pitch = math.rad(block.ParryAngle)
        local cosPitch, sinPitch = math.cos(pitch), math.sin(pitch)
        local released, aimed = false, false
        local forward, pitchAt, hitAt
        local killerParts, oldHits = {}, {}
        HitIds(character, oldHits)
        keypress(key)
        local start = os.clock()
        local lastNow = start
        while Running() do
            local now = os.clock()
            local elapsed = now - start
            if pitchAt then
                local hits = {}
                HitIds(character, hits)
                for id in hits do
                    if not oldHits[id] then hitAt = elapsed end
                end
            end
            if hitAt then
                break
            elseif pitchAt then
                if now >= pitchAt + block.ParryLookup then break end
            elseif aimed or elapsed >= 1.1 then
                break
            end
            if not released and elapsed >= .1 then
                keyrelease(key)
                released = true
            end
            local lpos, kpos = root.Position, killer.Position
            if not lpos or not kpos then break end
            local frameDt = math.min(now - lastNow, .05)
            lastNow = now
            local flat = Vector3.new(kpos.X - lpos.X, 0, kpos.Z - lpos.Z)
            local dist = flat.Magnitude
            if not pitchAt and elapsed >= .25 then
                if tiltEnabled and dist <= 11 then
                    pitchAt = now
                    for _, part in killer.Model:GetDescendants() do
                        if (part.ClassName == "Part" or part.ClassName == "MeshPart") and part.CanCollide == true then
                            killerParts[#killerParts + 1] = part
                        end
                    end
                elseif elapsed >= .35 then
                    local predicted = PredictKiller(killer, lpos, 2.25)
                    local offset = predicted - kpos
                    if offset.Magnitude > dist * .5 then predicted = kpos + offset * (dist * .5 / offset.Magnitude) end
                    FaceTowards(root, predicted)
                    aimed = true
                end
            end
            if pitchAt then
                if dist > .01 then forward = flat / dist end
                forward = forward or Vector3.new(0, 0, -1)
                SetCollision(killerParts, false)
                local position = lpos
                local step = math.min(100 * frameDt, dist - 4)
                if step > 0 then position = lpos + forward * step end
                WritePose(root, forward * cosPitch + up * sinPitch, up * cosPitch - forward * sinPitch, position)
            end
            Sleep(0)
        end
        if not released then keyrelease(key) end
        if forward then WritePose(root, forward, up) end
        SetCollision(killerParts, true)
    end

    AddJob("Guest parry", true, function()
        local wasBlocking = false
        while Running() do
            local character = block.Parry and block.Guest and isrbxactive() and LocalPlayer.Character
            local state = character and character:FindFirstChild("SpeedMultipliers")
            local blocking = state and state:FindFirstChild("SpeedStatus") ~= nil and state:FindFirstChild("GuestBlocking") ~= nil or false
            if blocking and not wasBlocking then RunParry(character) end
            wasBlocking = blocking
            Sleep(if block.Parry and block.Guest then loopInterval else .25)
        end
    end)

    AddJob("Chance aim", false, function()
        local wasShooting = false
        while Running() do
            local character = block.Chance and isrbxactive() and LocalPlayer.Character
            local isChance = character and character.Name == "Chance" or false
            local state = isChance and character:FindFirstChild("SpeedMultipliers")
            local shooting = state and state:FindFirstChild("ShootingGun") ~= nil or false
            if shooting and not wasShooting then
                Sleep(.825)
                local root = character:FindFirstChild("HumanoidRootPart")
                local killer = RealKiller()
                local lpos = root and root.Position
                if lpos and killer then FaceTowards(root, PredictKiller(killer, lpos, 1)) end
            end
            wasShooting = shooting
            Sleep(if isChance then loopInterval else .5)
        end
    end)

    block.KeyActive = function()
        local keybind = block.Keybind
        if not keybind then return true end
        local ok, key = pcall(keybind.GetKey, keybind)
        if not ok or not key or key == 0 then return true end
        local active, enabled = pcall(keybind.IsEnabled, keybind)
        return active and enabled == true
    end

    AddJob("Auto block", true, function()
        local nextRefresh = 0
        while Running() do
            block.Enabled = block.Toggled == true and block.KeyActive()
            local tracking = block.Toggled or block.Show or block.Parry or block.Chance
            if not (tracking or block.SafeSprint) or not isrbxactive() then
                block.Killers, block.HitboxOwner, block.Hitbox, block.HitboxSize, nextRefresh = {}, nil, nil, nil, 0
                Sleep(.25)
            else
                local now = tick()
                if now >= nextRefresh then
                    nextRefresh = now + .5
                    Refresh(now)
                end
                if block.SafeSprint then SafeSprint() end
                if tracking and folders.MapContent and not world.Killer then
                    Update(tick())
                else
                    for _, killer in block.Killers do
                        killer.Shape, killer.Attack = nil, nil
                    end
                end
                Sleep(loopInterval)
            end
        end
    end)
end

local reach = {Enabled = false, Forward = 8, Mode = "Forward", SurvivorEnabled = false, SurvivorForward = 8, SurvivorMode = "Forward", Modes = {"Forward", "Auto", "Chaos"}}

do
    local swingDelay = .15
    local extraDelay = .03
    local hold = .05
    local settle = .035
    local maxSpeed = 120
    local speedWindow = .1
    local swingWindow = .25
    local revertJump = 4
    local revertRadius = 3
    local stableTime = .3
    local guardTime = 1.5
    local gap = 2
    local targetLead = .1
    local movingSpeed = 2
    local chaosStep = math.rad(137.5)
    local chaosEarly = .05
    local killerDelays = {
        Slasher = {Slash = .16, Behead = .40, GashingWound = .28},
        c00lkidd = {Tag = .07},
        JohnDoe = {Slash = .30},
        Noli = {Stab = .29},
        ["1x1x1x1"] = {Slash = .36},
        Sixer = {["Carving Slash"] = .25},
        Nosferatu = {Slash = .24},
        Azure = {Slash = .18},
    }
    local survivorDelays = {
        Shedletsky = {Slash = .51},
        TwoTime = {Dagger = {Default = .245, TwoTimeCrouching = .20}},
        JaneDoe = {Axe = .68},
        Guest1337 = {Punch = .56},
    }
    local behindCharacters = {TwoTime = 10}
    local state = {Cooldowns = {}, NextScan = 0, WasPressed = false}

    local function Flat(v)
        return Vector3.new(v.X, 0, v.Z)
    end

    local function Place(root, position, facing)
        local look = Vector3.new(facing.X - position.X, 0, facing.Z - position.Z)
        if look.Magnitude < .01 then look = Vector3.new(0, 0, -1) end
        block.WritePose(root, look, Vector3.new(0, 1, 0), position)
    end

    local function ChildAddresses(root)
        local known = {}
        for _, child in root:GetChildren() do known[child.Address] = child end
        return known
    end

    local function WaitForSwing(root)
        local known = ChildAddresses(root)
        local start = os.clock()
        while os.clock() - start < swingWindow do
            Sleep(0)
            for address, child in ChildAddresses(root) do
                if not known[address] then
                    known[address] = child
                    if child.ClassName == "Sound" then return os.clock() end
                end
            end
        end
        return nil
    end

    local function PickTarget(folder, localPos, range)
        if not folder or not frame.HalfWidth then return nil end
        local best, bestOffset
        for _, character in folder:GetChildren() do
            local root = character:FindFirstChild("HumanoidRootPart")
            local humanoid = root and character:FindFirstChild("Humanoid")
            local health = humanoid and humanoid.Health
            local position = root and root.Position
            if health and health > 0 and position and (Flat(position) - Flat(localPos)).Magnitude <= range then
                local screen, visible = WorldToScreen(position)
                local offset = visible and math.abs(screen.X - frame.HalfWidth)
                if offset and (not bestOffset or offset < bestOffset) then best, bestOffset = root, offset end
            end
        end
        return best
    end

    local function Destination(startPos, target, targetPos, behind, targetVelocity)
        local tpos = targetPos + targetVelocity * targetLead
        if behind then
            local heading = targetVelocity
            if heading.Magnitude < movingSpeed then
                local cframe = target.CFrame
                local look = cframe and cframe.LookVector or Vector3.new(0, 0, -1)
                heading = Vector3.new(look.X, 0, look.Z)
            end
            if heading.Magnitude < .01 then heading = Vector3.new(0, 0, -1) end
            local back = heading.Unit
            local position = Vector3.new(tpos.X, startPos.Y, tpos.Z) - back * behind
            return position, position + back
        end
        local offset = Flat(tpos) - Flat(startPos)
        local distance = offset.Magnitude
        if distance < .01 then return startPos, tpos end
        return startPos + offset / distance * math.max(distance - gap, 0), tpos
    end

    local function Velocity(samples, now, current)
        local from = samples[1]
        for _, sample in samples do
            if now - sample.Time >= speedWindow then from = sample end
        end
        local elapsed = now - from.Time
        local velocity = if elapsed > 0 then (Flat(current) - Flat(from.Position)) / elapsed else Vector3.new(0, 0, 0)
        if velocity.Magnitude > maxSpeed then velocity = velocity.Unit * maxSpeed end
        return velocity
    end

    local function Attack(root, swingAt, moveDelay, settings)
        local localPos = root.Position
        if not localPos then return end
        local target = settings.Auto and PickTarget(settings.Folder, localPos, settings.Forward + gap)
        if settings.Auto and not target then return end
        local samples = {{Time = os.clock(), Position = localPos}}
        local targetPos = target and target.Position
        local targetSamples = target and targetPos and {{Time = os.clock(), Position = targetPos}}
        local early = if settings.Chaos then chaosEarly else 0
        local holdTime = if settings.Chaos then settings.Linger else hold
        while os.clock() - swingAt < moveDelay + extraDelay - early do
            Sleep(0)
            local now = os.clock()
            local position = root.Position
            if not position then return end
            samples[#samples + 1] = {Time = now, Position = position}
            if targetSamples then
                local current = target.Position
                if current then
                    targetPos = current
                    targetSamples[#targetSamples + 1] = {Time = now, Position = current}
                end
            end
        end

        local startPos = root.Position
        local cframe = root.CFrame
        if not startPos or not cframe then return end
        local startTime = os.clock()
        local velocity = Velocity(samples, startTime, startPos)
        local targetVelocity = targetSamples and Velocity(targetSamples, startTime, targetPos)
        local look = cframe.LookVector
        local back = Flat(look)
        back = if back.Magnitude > .01 then back.Unit else Vector3.new(0, 0, -1)
        local movedPos = startPos + back * settings.Forward
        local spots = {}
        local angle = math.random() * math.pi * 2
        repeat
            if target and targetPos then
                local position, facing = Destination(startPos, target, targetPos, settings.Behind, targetVelocity)
                movedPos = position
                Place(root, movedPos, facing)
            elseif settings.Chaos then
                angle += chaosStep
                local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
                movedPos = startPos + direction * settings.Forward
                spots[#spots + 1] = movedPos
                Place(root, movedPos, movedPos + direction)
            else
                Place(root, movedPos, movedPos + back)
            end
            Sleep(0)
        until os.clock() - startTime >= holdTime
        if #spots == 0 then spots[1] = movedPos end

        local returnPos = startPos + velocity * (os.clock() - startTime + settle)
        Place(root, returnPos, returnPos + back)
        local lastGood = returnPos
        local returnedAt = os.clock()
        local stableSince = returnedAt
        while os.clock() - returnedAt < guardTime and os.clock() - stableSince < stableTime do
            Sleep(0)
            local position = root.Position
            if not position then return end
            local nearSpot = false
            for _, spot in spots do
                if (Flat(position) - Flat(spot)).Magnitude < revertRadius then nearSpot = true end
            end
            if (Flat(position) - Flat(lastGood)).Magnitude > revertJump and nearSpot then
                Place(root, lastGood, lastGood + back)
                stableSince = os.clock()
            else
                lastGood = position
            end
        end
    end

    local function ScanCooldowns(delays)
        local container = Path(world.PlayerGui, "MainUI", "AbilityContainer")
        local found = {}
        if container then
            for name in delays do
                local label = Path(container, name, "CooldownTime")
                if label then
                    local old = state.Cooldowns[name]
                    found[name] = {Label = label, Ready = old and old.Label == label and old.Ready}
                end
            end
        end
        state.Cooldowns = found
    end

    local function Update(character, isKiller)
        local now = os.clock()
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local name = character.Name
        local mode = if isKiller then reach.Mode else reach.SurvivorMode
        local settings = {
            Forward = if isKiller then reach.Forward else reach.SurvivorForward,
            Auto = mode == "Auto",
            Chaos = mode == "Chaos",
            Linger = (if isKiller then (block.KillerData[name] or block.KillerData.Default) else block.KillerData.Default).Linger,
            Folder = if isKiller then folders.Survivors else folders.Killers,
            Behind = behindCharacters[name],
        }
        local delays = (if isKiller then killerDelays else survivorDelays)[name]
        if not delays then
            if isKiller then
                local pressed = ismouse1pressed() == true
                if pressed and not state.WasPressed then
                    state.WasPressed = true
                    local swingAt = WaitForSwing(root)
                    if swingAt then Attack(root, swingAt, swingDelay, settings) end
                    return
                end
                state.WasPressed = pressed
            end
            return
        end
        if now >= state.NextScan or name ~= state.Character then
            state.NextScan = now + 1
            if name ~= state.Character then state.Cooldowns = {} end
            state.Character = name
            ScanCooldowns(delays)
        end
        for abilityName, cooldown in state.Cooldowns do
            local text = cooldown.Label.Text
            if type(text) == "string" then
                local ready = text == ""
                cooldown.Ready, cooldown.WasReady = ready, cooldown.Ready
                if cooldown.WasReady and not ready then
                    local moveDelay = delays[abilityName]
                    if type(moveDelay) == "table" then
                        local states = moveDelay
                        moveDelay = states.Default
                        local multipliers = character:FindFirstChild("SpeedMultipliers")
                        if multipliers then
                            for _, child in multipliers:GetChildren() do
                                local stateDelay = states[child.Name]
                                if stateDelay then moveDelay = stateDelay end
                            end
                        end
                    end
                    Attack(root, now, moveDelay, settings)
                    return
                end
            end
        end
    end

    AddJob("Reach", true, function()
        while Running() do
            local character = isrbxactive() and LocalPlayer.Character
            local active = character and ((reach.Enabled and world.Killer) or (reach.SurvivorEnabled and world.Survivor))
            if active then
                Update(character, world.Killer)
                Sleep(0)
            else
                state.WasPressed = false
                Sleep(.25)
            end
        end
    end)
end

local corrupt = {Enabled = false, Mode = "Legit", Modes = {"Legit", "Rage"}, Radius = 125, Color = Color3.fromRGB(255, 60, 60), Corners = {}}

do
    local windup = 2
    local duration = 3.5
    local spikeSpeed = 125 / 1.5
    local flickLate = 2
    local steerFrom = -.6 * spikeSpeed
    local steerTolerance = math.rad(3)
    local lead = .15
    local keyCodes = {W = 0x57, A = 0x41, S = 0x53, D = 0x44}
    local keyCombos = {{1, 0, "W"}, {1, 1, "W", "D"}, {0, 1, "D"}, {-1, 1, "S", "D"}, {-1, 0, "S"}, {-1, -1, "S", "A"}, {0, -1, "A"}, {1, -1, "W", "A"}}
    local sensitivityFile = "MatchaForsakenCorruptSensitivity.txt"
    local state = {Held = {}, Motion = {}, PerDegree = 2, Pixels = 0, Degrees = 0, MoveFrames = 0, MoveSign = 0}
    if isfile(sensitivityFile) then state.PerDegree = tonumber(readfile(sensitivityFile)) or 2 end
    if state.PerDegree < .1 or state.PerDegree > 50 then state.PerDegree = 2 end
    state.Saved = state.PerDegree

    local function TrackVelocity(id, position, now)
        local entry = state.Motion[id]
        if not entry or now - entry.Time > .5 then
            state.Motion[id] = {Position = position, Time = now, VelX = 0, VelZ = 0}
            return 0, 0
        end
        local dt = now - entry.Time
        if dt >= .05 then
            local velX, velZ = (position.X - entry.Position.X) / dt, (position.Z - entry.Position.Z) / dt
            if velX * velX + velZ * velZ > 6400 then velX, velZ = 0, 0 end
            entry.VelX, entry.VelZ = entry.VelX * .5 + velX * .5, entry.VelZ * .5 + velZ * .5
            entry.Position, entry.Time = position, now
        end
        return entry.VelX, entry.VelZ
    end

    local function Targets(localPos)
        local list = {}
        local folder = folders.Survivors
        if not folder then return list end
        local now = os.clock()
        for _, character in folder:GetChildren() do
            local root = character:FindFirstChild("HumanoidRootPart")
            local position = root and root.Position
            if position then
                local id = root.Address
                local velX, velZ = TrackVelocity(id, position, now)
                local distance = Vector3.new(position.X - localPos.X, 0, position.Z - localPos.Z).Magnitude
                if distance > .5 and distance <= corrupt.Radius then
                    list[#list + 1] = {Character = character, Root = root, Id = id, Position = position, Distance = distance, VelX = velX, VelZ = velZ}
                end
            end
        end
        return list
    end

    local function PickLegit(targets)
        if not frame.HalfWidth then return nil end
        local best, bestDistance
        for _, target in targets do
            local screen, visible = WorldToScreen(target.Position)
            if visible then
                local distance = Vector2.new(screen.X - frame.HalfWidth, screen.Y - frame.HalfHeight).Magnitude
                if not bestDistance or distance < bestDistance then best, bestDistance = target, distance end
            end
        end
        return best
    end

    local function HasCorruptEnergy(character)
        local multipliers = character:FindFirstChild("SpeedMultipliers")
        return multipliers ~= nil and multipliers:FindFirstChild("CorruptEnergy") ~= nil
    end

    local function Select(target)
        local id = target and target.Id
        if id == state.Selected then return end
        state.Selected = id
        if not target then
            corrupt.Parts = nil
            return
        end
        local parts = {}
        for _, name in names.Body do
            local part = target.Character:FindFirstChild(name)
            local size = part and part.Size
            if size then parts[#parts + 1] = {Part = part, Size = size} end
        end
        corrupt.Parts = parts
    end

    local function SetKeys(first, second)
        for name, code in keyCodes do
            local want = name == first or name == second
            if want and not state.Held[name] then
                keypress(code)
                state.Held[name] = true
            elseif not want and state.Held[name] then
                keyrelease(code)
                state.Held[name] = nil
            end
        end
    end

    local function AngleBetween(from, to)
        return (to - from + math.pi) % (2 * math.pi) - math.pi
    end

    local function PredictTarget(target)
        local offsetX, offsetZ = target.VelX * lead, target.VelZ * lead
        local length = math.sqrt(offsetX * offsetX + offsetZ * offsetZ)
        if length > target.Distance then
            offsetX *= target.Distance / length
            offsetZ *= target.Distance / length
        end
        return target.Position.X + offsetX, target.Position.Z + offsetZ
    end

    local function Steer(root, target, camera)
        local cframe = root.CFrame
        local localPos = cframe and cframe.Position
        if not localPos then
            SetKeys()
            return
        end
        local look = cframe.LookVector
        local aimX, aimZ = PredictTarget(target)
        local toX, toZ = aimX - localPos.X, aimZ - localPos.Z
        if toX * toX + toZ * toZ < .01 then
            SetKeys()
            return
        end
        local current = math.atan2(look.X, look.Z)
        local delta = AngleBetween(current, math.atan2(toX, toZ))
        if math.abs(delta) <= steerTolerance then
            SetKeys()
            return
        end
        local cameraFrame = camera.CFrame
        local forward = Vector3.new(cameraFrame.LookVector.X, 0, cameraFrame.LookVector.Z).Unit
        local right = Vector3.new(cameraFrame.RightVector.X, 0, cameraFrame.RightVector.Z).Unit
        local best, bestTurn, closest, closestMiss
        for _, combo in keyCombos do
            local direction = forward * combo[1] + right * combo[2]
            local turn = AngleBetween(current, math.atan2(direction.X, direction.Z))
            if turn * delta > 0 and math.abs(turn) >= math.abs(delta) and (not bestTurn or math.abs(turn) < bestTurn) then
                best, bestTurn = combo, math.abs(turn)
            end
            local miss = math.abs(AngleBetween(turn, delta))
            if not closestMiss or miss < closestMiss then closest, closestMiss = combo, miss end
        end
        best = best or closest
        SetKeys(best[3], best[4])
    end

    local function ShiftLocked(root, camera)
        local mouse = state.Mouse
        if not mouse then
            mouse = LocalPlayer:GetMouse()
            state.Mouse = mouse
        end
        local viewport = camera.ViewportSize
        if not mouse or not viewport or math.abs(mouse.X - viewport.X / 2) > 3 or math.abs(mouse.Y - viewport.Y / 2) > 3 then return false end
        local cameraFrame = camera.CFrame
        local position = root.Position
        if not position then return false end
        local offset = cameraFrame.Position - position
        local shoulder = offset:Dot(cameraFrame.RightVector)
        return (shoulder > 1.4 and shoulder < 2.1) or offset.Magnitude < 3
    end

    local function MouseAim(root, target, camera)
        local localPos = root.Position
        if not localPos then return end
        local aimX, aimZ = PredictTarget(target)
        local cameraLook = camera.CFrame.LookVector
        local cameraYaw = math.atan2(cameraLook.X, cameraLook.Z)
        if state.PrevYaw and state.MoveFrames > 0 then
            state.MoveFrames -= 1
            local turned = math.deg(AngleBetween(state.PrevYaw, cameraYaw))
            if turned * state.MoveSign < 0 then
                state.Degrees += turned
                if math.abs(state.Degrees) >= 10 then
                    local ratio = -state.Pixels / state.Degrees
                    if ratio > 0 then state.PerDegree = math.clamp(ratio, state.PerDegree * .5, state.PerDegree * 2) end
                    if math.abs(state.Degrees) > 90 then
                        state.Pixels *= .5
                        state.Degrees *= .5
                    end
                end
            end
        end
        state.PrevYaw = cameraYaw
        local delta = math.deg(AngleBetween(cameraYaw, math.atan2(aimX - localPos.X, aimZ - localPos.Z)))
        if math.abs(delta) < 1 then return end
        local pixels = math.floor(math.clamp(-delta * state.PerDegree * .9, -800, 800) + .5)
        if pixels == 0 then return end
        mousemoverel(pixels, 0)
        local sign = if pixels > 0 then 1 else -1
        if sign ~= state.MoveSign then state.Pixels, state.Degrees = 0, 0 end
        state.MoveSign = sign
        state.Pixels += pixels
        state.MoveFrames = 3
    end

    local function NextTarget(targets, front)
        local best
        for _, target in targets do
            if front <= target.Distance + flickLate and (not best or target.Distance < best.Distance) then best = target end
        end
        return best
    end

    local function AimLoop(root, started)
        local lockedId
        table.clear(state.Motion)
        state.Pixels, state.Degrees, state.MoveSign, state.PrevYaw = 0, 0, 0, nil
        if state.PerDegree < .1 or state.PerDegree > 50 then state.PerDegree = 2 end
        while Running() and corrupt.Enabled do
            local elapsed = os.clock() - started
            if elapsed > duration then break end
            local camera = workspace.CurrentCamera
            local localPos = root.Position
            if not camera or not localPos then break end
            local front = (elapsed - windup) * spikeSpeed
            local targets = Targets(localPos)
            local target
            if corrupt.Mode == "Rage" then
                target = NextTarget(targets, front)
            elseif lockedId then
                for _, candidate in targets do
                    if candidate.Id == lockedId then target = candidate end
                end
            else
                target = PickLegit(targets)
                if target and front >= steerFrom then lockedId = target.Id end
            end
            if target and front > target.Distance + flickLate then target = nil end
            Select(target)
            if target and front >= steerFrom then
                if ShiftLocked(root, camera) then
                    SetKeys()
                    MouseAim(root, target, camera)
                else
                    state.PrevYaw = nil
                    Steer(root, target, camera)
                end
            else
                SetKeys()
                state.PrevYaw = nil
            end
            Sleep(0)
        end
        SetKeys()
        if state.PerDegree ~= state.Saved then
            state.Saved = state.PerDegree
            writefile(sensitivityFile, string.format("%.4f", state.PerDegree))
        end
        Select(nil)
    end

    corrupt.Render = function()
        local parts = corrupt.Parts
        if not parts then return end
        local corners = corrupt.Corners
        for _, entry in parts do
            local cframe = entry.Part.CFrame
            if cframe then
                WriteCorners(corners, 0, cframe, entry.Size)
                Highlight(corners, 8, corrupt.Color)
            end
        end
    end

    AddJob("Corrupt aim", true, function()
        local wasActive = false
        while Running() do
            local character = corrupt.Enabled and world.Killer and isrbxactive() and LocalPlayer.Character
            local active = character and HasCorruptEnergy(character) or false
            if active and not wasActive then
                local root = character:FindFirstChild("HumanoidRootPart")
                if root then AimLoop(root, os.clock()) end
            end
            wasActive = active
            Sleep(if character then 0 else .25)
        end
    end)
end

local autoGen = {Enabled = false, Delay = 1.75, Random = .5}

do
    local directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
    local cellSize = 75
    local dragCellsPerSecond = 20
    local travelSpeed = 4000
    local maxDragStep = cellSize * .45

    local function SolveWires(endpoints, size)
        local grid, wires, solution = {}, {}, {}
        for y = 1, size do
            grid[y] = {}
            for x = 1, size do grid[y][x] = false end
        end

        local function Key(x, y)
            return (y - 1) * size + x
        end

        local function InBounds(x, y)
            return x >= 1 and x <= size and y >= 1 and y <= size
        end

        local function Manhattan(x1, y1, x2, y2)
            return math.abs(x1 - x2) + math.abs(y1 - y2)
        end

        for id, points in endpoints do
            if not points[1] or not points[2] then return nil end
            local ax, ay, bx, by = points[1].x, points[1].y, points[2].x, points[2].y
            if not ax or not ay or not bx or not by or not InBounds(ax, ay) or not InBounds(bx, by) then return nil end
            if grid[ay][ax] or grid[by][bx] then return nil end
            local wire = {Id = id, AX = ax, AY = ay, BX = bx, BY = by}
            wires[#wires + 1] = wire
            grid[ay][ax], grid[by][bx] = wire, wire
        end

        local function IsGoal(wire, x, y)
            return x == wire.BX and y == wire.BY
        end

        local function CanUse(wire, x, y)
            if not InBounds(x, y) then return false end
            if IsGoal(wire, x, y) then return true end
            return grid[y][x] == false
        end

        local function Flood(wire, startX, startY)
            local queue, head, visited, count, reached = {{startX, startY}}, 1, {[Key(startX, startY)] = true}, 0, false
            while head <= #queue do
                local x, y = queue[head][1], queue[head][2]
                head += 1
                count += 1
                if IsGoal(wire, x, y) then reached = true end
                for _, direction in directions do
                    local nx, ny = x + direction[1], y + direction[2]
                    if InBounds(nx, ny) then
                        local key = Key(nx, ny)
                        if not visited[key] and CanUse(wire, nx, ny) then
                            visited[key] = true
                            queue[#queue + 1] = {nx, ny}
                        end
                    end
                end
            end
            return reached, count
        end

        local function AllReachable(remaining)
            for _, wire in remaining do
                if not Flood(wire, wire.AX, wire.AY) then return false end
            end
            return true
        end

        local function CountExits(wire, x, y)
            local count = 0
            for _, direction in directions do
                if CanUse(wire, x + direction[1], y + direction[2]) then count += 1 end
            end
            return count
        end

        local function ChooseWire(remaining)
            local bestIndex, bestExits, bestArea, bestDistance
            for i, wire in remaining do
                local reachable, area = Flood(wire, wire.AX, wire.AY)
                if not reachable then return nil end
                local exits = math.min(CountExits(wire, wire.AX, wire.AY), CountExits(wire, wire.BX, wire.BY))
                local distance = Manhattan(wire.AX, wire.AY, wire.BX, wire.BY)
                if not bestIndex or exits < bestExits or (exits == bestExits and area < bestArea) or (exits == bestExits and area == bestArea and distance < bestDistance) then
                    bestIndex, bestExits, bestArea, bestDistance = i, exits, area, distance
                end
            end
            return bestIndex
        end

        local SolveRemaining

        SolveRemaining = function(remaining)
            if #remaining == 0 then return true end
            local chosen = ChooseWire(remaining)
            if not chosen then return false end
            local wire = remaining[chosen]
            local nextRemaining = {}
            for i, value in remaining do
                if i ~= chosen then nextRemaining[#nextRemaining + 1] = value end
            end
            if Manhattan(wire.AX, wire.AY, wire.BX, wire.BY) == 1 then
                solution[wire.Id] = {{x = wire.AX, y = wire.AY}, {x = wire.BX, y = wire.BY}}
                if SolveRemaining(nextRemaining) then return true end
                solution[wire.Id] = nil
                return false
            end
            local path = {{x = wire.AX, y = wire.AY}}
            local pathVisited = {[Key(wire.AX, wire.AY)] = true}

            local function SearchPath(x, y)
                if IsGoal(wire, x, y) then
                    local copy = {}
                    for i, point in path do copy[i] = {x = point.x, y = point.y} end
                    solution[wire.Id] = copy
                    if SolveRemaining(nextRemaining) then return true end
                    solution[wire.Id] = nil
                    return false
                end
                local neighbors = {}
                for _, direction in directions do
                    local nx, ny = x + direction[1], y + direction[2]
                    if InBounds(nx, ny) and not pathVisited[Key(nx, ny)] and CanUse(wire, nx, ny) then
                        neighbors[#neighbors + 1] = {x = nx, y = ny, distance = Manhattan(nx, ny, wire.BX, wire.BY)}
                    end
                end
                table.sort(neighbors, function(a, b) return a.distance < b.distance end)
                for _, nextPos in neighbors do
                    local nx, ny = nextPos.x, nextPos.y
                    local key = Key(nx, ny)
                    local goal = IsGoal(wire, nx, ny)
                    pathVisited[key] = true
                    path[#path + 1] = {x = nx, y = ny}
                    if not goal then grid[ny][nx] = wire end
                    local possible = goal or Flood(wire, nx, ny)
                    if possible and AllReachable(nextRemaining) and SearchPath(nx, ny) then return true end
                    if not goal then grid[ny][nx] = false end
                    path[#path] = nil
                    pathVisited[key] = nil
                end
                return false
            end

            return SearchPath(wire.AX, wire.AY)
        end

        local remaining = {}
        for _, wire in wires do remaining[#remaining + 1] = wire end
        if SolveRemaining(remaining) then return solution end
        return nil
    end

    local state = {OffsetX = 0, OffsetY = 0}

    local function MouseNow()
        local mouse = state.Mouse
        if not mouse then
            mouse = LocalPlayer:GetMouse()
            state.Mouse = mouse
        end
        return mouse.X, mouse.Y
    end

    local function MoveMouse(x, y)
        mousemoveabs(x + state.OffsetX, y + state.OffsetY)
    end

    local function CalibrateMouse()
        state.OffsetX, state.OffsetY = 0, 0
        local sx, sy = MouseNow()
        mousemoveabs(sx, sy)
        Sleep(.05)
        local ax, ay = MouseNow()
        state.OffsetX, state.OffsetY = math.floor(sx - ax + .5), math.floor(sy - ay + .5)
        MoveMouse(sx, sy)
        Sleep(0)
    end

    local function GetCenter(cell)
        local position = cell.AbsolutePosition
        if not position then return nil end
        return position.X + cellSize / 2, position.Y + cellSize / 2
    end

    local function MoveAlong(points, speed, maxStep)
        local lengths, total = {}, 0
        for i = 2, #points do
            local dx, dy = points[i].x - points[i - 1].x, points[i].y - points[i - 1].y
            lengths[i] = math.sqrt(dx * dx + dy * dy)
            total += lengths[i]
        end
        local last = points[#points]
        if total <= 0 then
            MoveMouse(last.x, last.y)
            return
        end
        local duration = math.max(total / speed, .07)
        local start = os.clock()
        local traveled, segment, segmentStart = 0, 2, 0
        while traveled < total do
            local alpha = math.min((os.clock() - start) / duration, 1)
            traveled = math.min(alpha * alpha * (3 - 2 * alpha) * total, traveled + maxStep)
            while segment < #points and segmentStart + lengths[segment] < traveled do
                segmentStart += lengths[segment]
                segment += 1
            end
            local a, b = points[segment - 1], points[segment]
            local f = if lengths[segment] > 0 then math.clamp((traveled - segmentStart) / lengths[segment], 0, 1) else 1
            MoveMouse(a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f)
            if traveled >= total then break end
            Sleep(0)
        end
        MoveMouse(last.x, last.y)
    end

    local function SpeedJitter()
        return .9 + math.random() * .2
    end

    local function SimplifyPath(path)
        if #path <= 2 then return path end
        local result = {path[1]}
        local lastDX, lastDY = path[2].x - path[1].x, path[2].y - path[1].y
        for i = 2, #path - 1 do
            local dx, dy = path[i + 1].x - path[i].x, path[i + 1].y - path[i].y
            if dx ~= lastDX or dy ~= lastDY then result[#result + 1] = path[i] end
            lastDX, lastDY = dx, dy
        end
        result[#result + 1] = path[#path]
        return result
    end

    local function Solve(grid, solution)
        mouse1release()
        Sleep(math.floor(math.max(autoGen.Delay + (math.random() * 2 - 1) * autoGen.Random, .2) * 100) / 100)
        if not world.InPuzzle then return end
        CalibrateMouse()
        for _, path in solution do
            if #path >= 2 then
                local first = path[1]
                local firstCell = grid:FindFirstChild(first.x .. "-" .. first.y)
                local fx, fy
                if firstCell then fx, fy = GetCenter(firstCell) end
                if fx then
                    local mx, my = MouseNow()
                    MoveAlong({{x = mx, y = my}, {x = fx, y = fy}}, travelSpeed * SpeedJitter(), math.huge)
                    Sleep(.03)
                    mouse1press()
                    local points = {{x = fx, y = fy}}
                    for i, point in SimplifyPath(path) do
                        if i > 1 then
                            local cell = grid:FindFirstChild(point.x .. "-" .. point.y)
                            local px, py
                            if cell then px, py = GetCenter(cell) end
                            if not px then break end
                            points[#points + 1] = {x = px, y = py}
                        end
                    end
                    MoveAlong(points, cellSize * dragCellsPerSecond * SpeedJitter(), maxDragStep)
                    Sleep(0)
                    mouse1release()
                end
            end
        end
    end

    local function ReadBoard(grid)
        local endpoints = {}
        for _, cell in grid:GetChildren() do
            local circle = cell:FindFirstChild("Circle")
            if circle then
                local number = circle:FindFirstChild("Number")
                local id = number and number.Text
                if type(id) ~= "string" then return nil end
                local x, y = string.match(cell.Name, "^(%d+)-(%d+)$")
                if x then
                    endpoints[id] = endpoints[id] or {}
                    table.insert(endpoints[id], {x = tonumber(x), y = tonumber(y)})
                end
            end
        end
        local parts = {}
        for id, points in endpoints do
            for _, point in points do parts[#parts + 1] = id .. ":" .. point.x .. "," .. point.y end
        end
        table.sort(parts)
        return endpoints, table.concat(parts, "|")
    end

    AddJob("Auto generator", false, function()
        local lastSignature
        while Running() do
            if autoGen.Enabled and world.InPuzzle and isrbxactive() then
                local grid = Path(world.PlayerGui, "PuzzleUI", "Container", "GridHolder", "Grid")
                local endpoints, signature = nil, nil
                if grid then endpoints, signature = ReadBoard(grid) end
                if endpoints and signature ~= "" and signature ~= lastSignature then
                    local solution = SolveWires(endpoints, 7)
                    if solution then
                        lastSignature = signature
                        Solve(grid, solution)
                    end
                end
            elseif not world.InPuzzle then
                lastSignature = nil
            end
            Sleep(.2)
        end
    end)
end

local paths = {Enabled = false, ShowLocal = false, Active = {}, Lines = {}, Names = {}, Used = 0, UsedNames = 0}

do
    local sounds = {
        Ent = {"rbxassetid://135854269153231", "rbxassetid://105934041806374", "rbxassetid://130247421279831", "rbxassetid://107039569833867", "rbxassetid://100150551345482", "rbxassetid://91488514366191", "rbxassetid://101739035738613", "rbxassetid://75675413747752", "rbxassetid://78992685630984", "rbxassetid://130994756001980", "rbxassetid://102799653891975", "rbxassetid://106588300253785", "rbxassetid://75814121589418"},
        MassInf = {"rbxassetid://70845653728841", "rbxassetid://73504812754586", "rbxassetid://97061990471922", "rbxassetid://85647688284850", "rbxassetid://83349035240699", "rbxassetid://90556583105741"},
        Rejuv = {"rbxassetid://109351069746096", "rbxassetid://96908026446030", "rbxassetid://120877949577353", "rbxassetid://108829275072240", "rbxassetid://134770542596997", "rbxassetid://99174224422295", "rbxassetid://135436619867662", "rbxassetid://85069492524977", "rbxassetid://127962518201254", "rbxassetid://90613634629510"},
        Corrupt = {"rbxassetid://75210765058860", "rbxassetid://87883890694872", "rbxassetid://109525294317144", "rbxassetid://119285029803606", "rbxassetid://100163947838165", "rbxassetid://74901476984677", "rbxassetid://99582226869588", "rbxassetid://96733419994623", "rbxassetid://137444402376234", "rbxassetid://108685516047210", "rbxassetid://129466330433467"},
        Martyr = {"rbxassetid://124122529017069"},
    }
    local lineThickness = 3
    local maxLines = 160
    local maxNames = 8
    local segmentLength = 5
    local ascensionFeetOffset = 3
    local rejuvSuppressUntil = {}

    local function PathLine(x1, y1, x2, y2)
        paths.Used += 1
        local entry = paths.Lines[paths.Used]
        if not entry then return end
        if entry.X1 ~= x1 or entry.Y1 ~= y1 then
            entry.X1, entry.Y1 = x1, y1
            entry.Object.From = Vector2.new(x1, y1)
        end
        if entry.X2 ~= x2 or entry.Y2 ~= y2 then
            entry.X2, entry.Y2 = x2, y2
            entry.Object.To = Vector2.new(x2, y2)
        end
        if not entry.Visible then
            entry.Visible = true
            entry.Object.Visible = true
        end
    end

    local function DrawSegment(a, b)
        local ax, ay = Project(a.X, a.Y, a.Z)
        local bx, by = Project(b.X, b.Y, b.Z)
        if ax and bx then PathLine(ax, ay, bx, by) end
    end

    local function DrawWorldLine(startPos, endPos)
        local offset = endPos - startPos
        local distance = offset.Magnitude
        if distance <= 0 then return end
        local direction = offset / distance
        local segments = math.max(1, math.ceil(distance / segmentLength))
        local step = distance / segments
        for i = 0, segments - 1 do
            DrawSegment(startPos + direction * (i * step), startPos + direction * math.min((i + 1) * step, distance))
        end
    end

    local function DrawLookLine(position, look, right, up, distance, rightAmount, downAmount)
        local direction = look + right * (rightAmount or 0) - up * (downAmount or 0)
        if direction.Magnitude == 0 then return end
        DrawWorldLine(position, position + direction.Unit * distance)
    end

    local function CurrentLookLine(data, rightAmount, downAmount)
        DrawLookLine(data.CurrentPosition, data.CurrentLookVector, data.CurrentRightVector, data.CurrentUpVector, data.Length, rightAmount, downAmount)
    end

    local function TrackedPosition(object)
        if not object then return nil end
        local position = object.Position
        if typeof(position) == "Vector3" then return position end
        for _, part in {object:FindFirstChild("Core"), object.PrimaryPart, object:FindFirstChildOfClass("Part"), object:FindFirstChildOfClass("MeshPart")} do
            local partPosition = part and part.Position
            if typeof(partPosition) == "Vector3" then return partPosition end
        end
        return nil
    end

    local childNames = {}

    local function HasSound(root, list)
        local address = root.Address
        local cached = childNames[address]
        if not cached or cached.Tick ~= paths.Tick then
            local set = {}
            for _, child in root:GetChildren() do set[child.Name] = true end
            cached = {Tick = paths.Tick, Names = set}
            childNames[address] = cached
        end
        for _, sound in list do
            if cached.Names[sound] then return true end
        end
        return false
    end

    local function SnapshotObjects()
        local result = {}
        local ingame = folders.Ingame
        if ingame then
            for _, object in ingame:GetChildren() do result[object.Address] = true end
        end
        return result
    end

    local function FindNewObject(data, root, wanted)
        local ingame = folders.Ingame
        local rootPos = root.Position
        if not ingame or not rootPos then return nil end
        for _, object in ingame:GetChildren() do
            if wanted[object.Name] and not data.KnownObjects[object.Address] then
                local position = TrackedPosition(object)
                if position and (rootPos - position).Magnitude < 30 then return object end
            end
        end
        return nil
    end

    local function MovementFromOrigin(data)
        local current = data.CurrentPosition
        local movement = Vector3.new(current.X - data.Origin.X, 0, current.Z - data.Origin.Z)
        local traveled = movement.Magnitude
        if traveled <= 2 then
            CurrentLookLine(data)
            return
        end
        local direction = movement / traveled
        if traveled < data.Length then
            DrawWorldLine(current, Vector3.new(data.Origin.X + direction.X * data.Length, current.Y, data.Origin.Z + direction.Z * data.Length))
        end
    end

    local function UpdateTrackedObject(data)
        local current = TrackedPosition(data.TrackedObject)
        if not current then
            data.Finished, data.HasTrackedLine = true, false
            return
        end
        if not data.ObjectSamplePos then
            data.ObjectSamplePos, data.HasTrackedLine = current, false
            return
        end
        if not data.ObjectDirection then
            local movement = Vector3.new(current.X - data.ObjectSamplePos.X, 0, current.Z - data.ObjectSamplePos.Z)
            if movement.Magnitude >= .5 then
                data.ObjectDirection = movement.Unit
                data.ObjectDestination = data.ObjectSamplePos + data.ObjectDirection * data.Length
            end
        end
        data.TrackedFrom = current
        data.HasTrackedLine = data.ObjectDestination ~= nil
    end

    local function DrawTrackedObject(data)
        if not data.HasTrackedLine then return end
        local position = data.TrackedFrom
        DrawWorldLine(position, Vector3.new(data.ObjectDestination.X, position.Y, data.ObjectDestination.Z))
    end

    local function HasLeftOrigin(data, root)
        if data.LeftOrigin then return true end
        local position = root.Position
        if not position then return false end
        local dx, dz = position.X - data.Origin.X, position.Z - data.Origin.Z
        if dx * dx + dz * dz > 4 then data.LeftOrigin, data.StillPosition, data.StillSince = true, nil, nil end
        return data.LeftOrigin == true
    end

    local function IsStandingStill(data, root)
        local position = root.Position
        local now = os.clock()
        if not position then return false end
        if not data.StillPosition then
            data.StillPosition, data.StillSince = position, now
            return false
        end
        if Vector3.new(position.X - data.StillPosition.X, 0, position.Z - data.StillPosition.Z).Magnitude > .12 then
            data.StillPosition, data.StillSince = position, now
            return false
        end
        return now - data.StillSince >= .2
    end

    local function Multiplier(character, name)
        local state = character:FindFirstChild("SpeedMultipliers")
        return state ~= nil and state:FindFirstChild(name) ~= nil
    end

    local function ProjectileAbility(name, length, soundCheck, objectNames)
        return {
            Name = name,
            Length = length,
            Check = function(character, root, data)
                local active = soundCheck(character, root)
                if data then
                    if data.Finished then return active end
                    if data.TrackedObject then return true end
                    if os.clock() - data.Started <= 2 then return true end
                end
                return active
            end,
            Start = function(data) data.KnownObjects = SnapshotObjects() end,
            Update = function(character, root, data)
                if data.Finished then return end
                if not data.TrackedObject then data.TrackedObject = FindNewObject(data, root, objectNames) end
                if data.TrackedObject then UpdateTrackedObject(data) end
            end,
            Draw = function(data)
                if data.Finished then return end
                if data.TrackedObject then DrawTrackedObject(data) else CurrentLookLine(data) end
            end,
        }
    end

    local killerAbilities = {
        c00lkidd = {
            {
                Name = "Walkspeed Override",
                Length = 90,
                TriggerOnce = true,
                Check = function(character, root, data)
                    if not data then return character:FindFirstChild("c00lgui") ~= nil end
                    if data.Finished then return false end
                    return os.clock() - data.Started < 1.9
                end,
                Update = function(character, root, data)
                    if os.clock() - data.Started < .6 then return end
                    if HasLeftOrigin(data, root) and IsStandingStill(data, root) then data.Finished = true end
                end,
                Draw = function(data)
                    if os.clock() - data.Started < .6 then CurrentLookLine(data) else MovementFromOrigin(data) end
                end,
            },
        },
        ["1x1x1x1"] = {
            ProjectileAbility("Entanglement", 125, function(character, root) return HasSound(root, sounds.Ent) end, {Swords = true}),
            ProjectileAbility("Mass Infection", 630, function(character, root)
                local address = character.Address
                if HasSound(root, sounds.Martyr) then
                    rejuvSuppressUntil[address] = os.clock() + 1.4
                    return false
                end
                if os.clock() < (rejuvSuppressUntil[address] or 0) then return false end
                return HasSound(root, sounds.MassInf) and not HasSound(root, sounds.Rejuv)
            end, {shockwave = true, Shockwave = true}),
        },
        JohnDoe = {
            {
                Name = "Corrupt Energy",
                Length = 125,
                Duration = 3.5,
                TriggerOnce = true,
                Check = function(character, root) return HasSound(root, sounds.Corrupt) end,
                Draw = function(data)
                    local windup = 2
                    local elapsed = os.clock() - data.Started
                    if elapsed < windup then
                        CurrentLookLine(data)
                        return
                    end
                    local direction = data.CurrentLookVector
                    if direction.Magnitude == 0 then return end
                    direction = direction.Unit
                    local alpha = math.clamp((elapsed - windup) / (data.Duration - windup), 0, 2)
                    DrawWorldLine(data.CurrentPosition + direction * data.Length * alpha, data.CurrentPosition + direction * data.Length)
                end,
            },
        },
        Noli = {
            {
                Name = "Voidrush",
                Length = 20,
                TriggerOnce = true,
                Check = function(character, root, data)
                    if data and data.Finished then return false end
                    return Multiplier(character, "VoidRushCharging") or Multiplier(character, "VoidRushDash")
                end,
                Draw = function(data) CurrentLookLine(data) end,
            },
        },
        Sixer = {
            {
                Name = "Demonic Pursuit",
                Length = 155,
                TriggerOnce = true,
                Check = function(character, root, data)
                    local start, pursuit = Multiplier(character, "666PursuitStart"), Multiplier(character, "666Pursuit")
                    if not start and not pursuit then return false end
                    if data and not start and pursuit and data.LeftOrigin and IsStandingStill(data, root) then return false end
                    return true
                end,
                Update = function(character, root, data)
                    data.Pursuing = Multiplier(character, "666Pursuit")
                    if data.Pursuing then HasLeftOrigin(data, root) end
                end,
                Draw = function(data)
                    if data.Pursuing then MovementFromOrigin(data) else CurrentLookLine(data) end
                end,
            },
        },
        Nosferatu = {
            {
                Name = "Ascension",
                Length = 120,
                Check = function(character, root, data)
                    if Multiplier(character, "NosFlying") then
                        if data then data.LastPresent = os.clock() end
                        return true
                    end
                    if data and data.LastPresent then return os.clock() - data.LastPresent <= 1.1 end
                    return false
                end,
                Draw = function(data)
                    local distance = data.Length
                    local localPos = paths.LocalPosition
                    if localPos then
                        local direction = data.CurrentLookVector - data.CurrentUpVector
                        if direction.Magnitude == 0 then return end
                        local dropY = direction.Y / direction.Magnitude
                        if dropY < 0 then distance = math.min(distance, (localPos.Y - ascensionFeetOffset - data.CurrentPosition.Y) / dropY) end
                    end
                    if distance <= 0 then return end
                    DrawLookLine(data.CurrentPosition, data.CurrentLookVector, data.CurrentRightVector, data.CurrentUpVector, distance, 0, 1)
                end,
            },
            {
                Name = "Bloodhook",
                Length = 115,
                Check = function(character) return Multiplier(character, "NosBloodhookThrow") end,
                Draw = function(data) CurrentLookLine(data) end,
            },
        },
        Azure = {
            {
                Name = "Enstrangle",
                Length = 55,
                Check = function(character, root) return root:FindFirstChild("HomingSpotlightOthers") ~= nil end,
                Draw = function(data) CurrentLookLine(data, .03, 0) end,
            },
        },
    }

    local survivorAbilities = {
        Shedletsky = {
            {
                Name = "Slash",
                Length = 6,
                Check = function(character)
                    local state = character:FindFirstChild("ResistanceMultipliers")
                    local resist = state and state:FindFirstChild("ResistanceStatus")
                    return resist ~= nil and resist.Value == 40
                end,
                Draw = function(data) CurrentLookLine(data) end,
            },
        },
        Chance = {
            {
                Name = "One Shot",
                Length = 92,
                Duration = .925,
                TriggerOnce = true,
                Check = function(character)
                    local flintlock = character:FindFirstChild("Flintlock")
                    return flintlock ~= nil and flintlock.Transparency == 0
                end,
                Draw = function(data) CurrentLookLine(data) end,
            },
        },
        Guest1337 = {
            {
                Name = "Block",
                Duration = .9,
                TriggerOnce = true,
                Check = function(character)
                    local own = LocalPlayer.Character
                    if own and own.Address == character.Address then return false end
                    return Multiplier(character, "GuestBlocking")
                end,
            },
        },
        JaneDoe = {
            {
                Name = "Hachet",
                Length = 13,
                Duration = 1.1,
                TriggerOnce = true,
                Check = function(character) return Multiplier(character, "jdaw") end,
                Draw = function(data) CurrentLookLine(data) end,
            },
        },
    }

    local function ReadPose(root)
        local cframe = root.CFrame
        if not cframe then return nil end
        return cframe.Position, cframe.LookVector, cframe.RightVector, cframe.UpVector
    end

    local function UpdateAbility(ability, character, root, lines, pose)
        local data
        for _, existing in lines do
            if existing.Ability == ability then
                data = existing
                break
            end
        end
        local triggered = ability.Check(character, root)
        local address = character.Address

        local function Create()
            if not pose.Position then pose.Position, pose.Look, pose.Right, pose.Up = ReadPose(root) end
            if not pose.Position then return end
            local own = LocalPlayer.Character
            data = {
                Ability = ability, Character = character, Root = root, IsLocal = own ~= nil and own.Address == address,
                Name = ability.Name, Length = ability.Length, Duration = ability.Duration, Origin = pose.Position,
                CurrentPosition = pose.Position, CurrentLookVector = pose.Look, CurrentRightVector = pose.Right, CurrentUpVector = pose.Up,
                Started = os.clock(),
            }
            if ability.Start then ability.Start(data, character) end
            lines[#lines + 1] = data
        end

        if ability.TriggerOnce then
            ability.ActiveStates = ability.ActiveStates or {}
            ability.InactiveSince = ability.InactiveSince or {}
            if triggered and not ability.ActiveStates[address] and not data then Create() end
            if triggered then
                ability.ActiveStates[address], ability.InactiveSince[address] = true, nil
            else
                ability.InactiveSince[address] = ability.InactiveSince[address] or os.clock()
                if os.clock() - ability.InactiveSince[address] >= .2 then
                    ability.ActiveStates[address], ability.InactiveSince[address] = false, nil
                end
            end
        elseif triggered and not data then
            Create()
        end

        if data and not data.LineDone then
            if ability.Update then ability.Update(character, root, data) end
            if not data.Duration and not ability.Check(character, root, data) then data.LineDone = true end
        end
    end

    local function UpdateFolder(folder, abilitiesTable, seenRoots)
        if not folder then return end
        for _, character in folder:GetChildren() do
            local abilities = abilitiesTable[character.Name]
            local root = abilities and character:FindFirstChild("HumanoidRootPart")
            if root then
                local address = root.Address
                seenRoots[address] = true
                local lines = paths.Active[address]
                if not lines then
                    lines = {}
                    paths.Active[address] = lines
                end
                local pose = {}
                for _, ability in abilities do UpdateAbility(ability, character, root, lines, pose) end
            end
        end
    end

    paths.Render = function()
        paths.Used, paths.UsedNames = 0, 0
        if paths.Enabled then
            for address, lines in paths.Active do
                for i, data in lines do
                    local elapsed = os.clock() - data.Started
                    if (data.Duration and elapsed >= data.Duration) or (not data.Duration and data.LineDone) then
                        lines[i] = nil
                    elseif paths.ShowLocal or not data.IsLocal then
                        local position, look, right, up = ReadPose(data.Root)
                        if position then
                            data.CurrentPosition, data.CurrentLookVector, data.CurrentRightVector, data.CurrentUpVector = position, look, right, up
                        end
                        if data.Ability.Draw then data.Ability.Draw(data) end
                        local label = data.CurrentPosition or data.Origin
                        local x, y
                        if label then x, y = Project(label.X, label.Y, label.Z) end
                        if x then
                            paths.UsedNames += 1
                            local entry = paths.Names[paths.UsedNames]
                            if entry then SetBigText(entry, true, x, y, data.Name, c.linesec) end
                        end
                    end
                end
                if next(lines) == nil then paths.Active[address] = nil end
            end
        end
        for index = paths.Used + 1, #paths.Lines do
            local entry = paths.Lines[index]
            if entry.Visible then
                entry.Visible = false
                entry.Object.Visible = false
            end
        end
        for index = paths.UsedNames + 1, #paths.Names do SetBigText(paths.Names[index], false) end
    end

    AddJob("Attack paths", false, function()
        while Running() do
            if paths.Enabled and isrbxactive() then
                while #paths.Lines < maxLines do
                    local object = Drawing.new("Line")
                    object.Thickness = lineThickness
                    object.Color = c.lineprim
                    object.Transparency = 1
                    object.Visible = false
                    allDrawings[#allDrawings + 1] = object
                    paths.Lines[#paths.Lines + 1] = {Object = object, Visible = false}
                end
                while #paths.Names < maxNames do paths.Names[#paths.Names + 1] = NewBigText(25) end
                local own = LocalPlayer.Character
                local ownRoot = own and own:FindFirstChild("HumanoidRootPart")
                paths.LocalPosition = ownRoot and ownRoot.Position
                local seenRoots = {}
                paths.Tick = (paths.Tick or 0) + 1
                table.clear(childNames)
                UpdateFolder(folders.Killers, killerAbilities, seenRoots)
                UpdateFolder(folders.Survivors, survivorAbilities, seenRoots)
                for address in paths.Active do
                    if not seenRoots[address] then paths.Active[address] = nil end
                end
                Sleep(loopInterval)
            else
                table.clear(paths.Active)
                Sleep(.25)
            end
        end
    end)
end

local function Render()
    used.Lines, used.Texts, used.Triangles = 0, 0, 0
    UpdateCamera(tick())
    if frame.Ready and flags.ESP and (flags.Highlight or flags.Text) then
        local show = flags.Show
        for address, entry in entries do
            if entry.Visible and entry.Ready and show[entry.ColorKey] and address ~= world.HiddenGenerator then
                local color = c[entry.ColorKey]
                local bones = flags.Highlight and entry.Bones
                if bones then
                    for i = 1, #bones, 6 do
                        local ax, ay = Project(bones[i], bones[i + 1], bones[i + 2])
                        local bx, by = Project(bones[i + 3], bones[i + 4], bones[i + 5])
                        if ax and bx then DrawLine(ax, ay, bx, by, color) end
                    end
                elseif flags.Highlight then
                    Highlight(entry.Corners, entry.Points, color)
                end
                if flags.Text and entry.Text and entry.LX then
                    local x, y = Project(entry.LX, entry.LY, entry.LZ)
                    if x then DrawText(x, y, entry.Text, color) end
                end
            end
        end
    end
    if frame.Ready then
        RenderBlock()
        corrupt.Render()
    end
    if frame.Ready then paths.Render() end
    RenderTimer()
    if used.Lines > wanted.Lines then wanted.Lines = used.Lines end
    if used.Texts > wanted.Texts then wanted.Texts = used.Texts end
    if used.Triangles > wanted.Triangles then wanted.Triangles = used.Triangles end
    HidePool(triangles, used.Triangles)
    HidePool(lines, used.Lines)
    HidePool(texts, used.Texts)
end

AddJob("Main", false, function()
    local nextWorld, nextFolders, nextWatch = 0, 0, 0
    local paused, espWasOn = false, flags.ESP
    while Running() do
        if not isrbxactive() then
            paused = true
            Sleep(.5)
        else
            local now = tick()
            if paused or espWasOn ~= flags.ESP then
                paused, espWasOn = false, flags.ESP
                ResetAll()
                nextFolders, nextWatch = 0, 0
            end
            GrowPools()
            if now >= nextFolders then
                nextFolders = now + 1
                RefreshFolders()
            end
            if now >= nextWorld then
                nextWorld = now + .25
                RefreshWorld(now)
            end
            if flags.ESP then
                if now >= nextWatch then
                    nextWatch = now + watchInterval
                    UpdateWatch(watches.Ingame, folders.Ingame, now)
                    UpdateWatch(watches.Killers, folders.Killers, now)
                    UpdateWatch(watches.Workspace, workspace, now)
                    UpdateWatch(watches.Map, folders.Map, now)
                    UpdateWatch(watches.MapContent, folders.MapContent, now)
                    SyncEntries(now)
                end
                UpdateEntries(tick())
            end
            Sleep(loopInterval)
        end
    end
end)

AddJob("Round timer", false, function()
    local mismatchSince
    while Running() do
        if not flags.Timer or not isrbxactive() then
            timer.Visible, mismatchSince = false, nil
            Sleep(.5)
        else
            local now = tick()
            local storage = game:FindFirstChild("ReplicatedStorage")
            local roundTimer = storage and storage:FindFirstChild("RoundTimer")
            local timeLeft = roundTimer and roundTimer:GetAttribute("TimeLeft")
            local text
            if type(timeLeft) == "number" then
                text = string.format("%d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60))
                timer.Text = "Real timer: " .. text
            end
            local gui = world.PlayerGui
            local label = gui and gui:FindFirstChild("RoundTimer")
            label = label and label:FindFirstChild("Main")
            label = label and label:FindFirstChild("Time")
            local shown = label and label.Text
            if text and type(shown) == "string" and shown ~= text then
                mismatchSince = mismatchSince or now
                timer.Visible = now - mismatchSince >= .4
            else
                mismatchSince = nil
                timer.Visible = false
            end
            Sleep(.25)
        end
    end
end)

if type(UI) == "table" and type(UI.AddTab) == "function" then
    local tabName = "Forsaken"
    local defaults = {
        fs_esp = flags.ESP,
        fs_highlight = flags.Highlight,
        fs_text = flags.Text,
        fs_paths = true,
        fs_paths_local = true,
        fs_timer = true,
        fs_block = false,
        fs_block_mode = 2,
        fs_block_delay = block.Delay,
        fs_block_show = block.Show,
        fs_safe_sprint = true,
        fs_parry = true,
        fs_parry_delay = .05,
        fs_parry_angle = 0,
        fs_parry_immune = false,
        fs_chance = true,
        fs_corrupt = corrupt.Enabled,
        fs_corrupt_mode = 0,
        fs_reach = reach.Enabled,
        fs_reach_mode = 0,
        fs_reach_forward = reach.Forward,
        fs_sreach = reach.SurvivorEnabled,
        fs_sreach_mode = 0,
        fs_sreach_forward = reach.SurvivorForward,
    }
    local apply = {
        fs_esp = function(v) flags.ESP = v == true end,
        fs_highlight = function(v) flags.Highlight = v == true end,
        fs_text = function(v) flags.Text = v == true end,
        fs_paths = function(v) paths.Enabled = v == true end,
        fs_paths_local = function(v) paths.ShowLocal = v == true end,
        fs_timer = function(v) flags.Timer = v == true end,
        fs_block = function(v) block.Toggled = v == true end,
        fs_block_mode = function(v)
            local mode = if type(v) == "string" then v else block.Modes[(tonumber(v) or 2) + 1]
            if block.Profiles[mode] then block.Mode = mode end
        end,
        fs_block_delay = function(v) block.Delay = math.clamp(tonumber(v) or 0, 0, .5) end,
        fs_block_show = function(v) block.Show = v == true end,
        fs_safe_sprint = function(v) block.SafeSprint = v == true end,
        fs_parry = function(v) block.Parry = v == true end,
        fs_parry_delay = function(v) block.ParryDelay = math.clamp(tonumber(v) or 0, 0, .6) end,
        fs_parry_angle = function(v) block.ParryAngle = math.clamp(tonumber(v) or 0, 0, 90) end,
        fs_parry_immune = function(v) block.ParryImmune = v == true end,
        fs_chance = function(v) block.Chance = v == true end,
        fs_corrupt = function(v) corrupt.Enabled = v == true end,
        fs_corrupt_mode = function(v)
            local mode = if type(v) == "string" then v else corrupt.Modes[(tonumber(v) or 0) + 1]
            if table.find(corrupt.Modes, mode) then corrupt.Mode = mode end
        end,
        fs_reach = function(v) reach.Enabled = v == true end,
        fs_reach_mode = function(v)
            local mode = if type(v) == "string" then v else reach.Modes[(tonumber(v) or 0) + 1]
            if table.find(reach.Modes, mode) then reach.Mode = mode end
        end,
        fs_reach_forward = function(v) reach.Forward = math.clamp(tonumber(v) or 8, 2, 14) end,
        fs_sreach = function(v) reach.SurvivorEnabled = v == true end,
        fs_sreach_mode = function(v)
            local mode = if type(v) == "string" then v else reach.Modes[(tonumber(v) or 0) + 1]
            if table.find(reach.Modes, mode) then reach.SurvivorMode = mode end
        end,
        fs_sreach_forward = function(v) reach.SurvivorForward = math.clamp(tonumber(v) or 8, 2, 14) end,
    }
    local colours = {
        fs_col_autoblock = function(colour) c.autoblock = colour end,
        fs_col_autoblockattack = function(colour) c.autoblockattack = colour end,
    }
    for _, category in categories do
        local key = category[1]
        defaults["fs_show_" .. key] = true
        apply["fs_show_" .. key] = function(v) flags.Show[key] = v == true end
        colours["fs_col_" .. key] = function(colour) c[key] = colour end
    end

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

    local function SetPrivacy(fields)
        for _, player in Players:GetChildren() do
            local privacy = Path(player, "PlayerData", "Settings", "Privacy")
            for _, field in fields do
                local value = Path(privacy, field)
                if value then value.Value = false end
            end
        end
    end

    local function BuildTab(tab)
        local survivor = Section(tab, "Survivor", "Left")
        Toggle(survivor, "fs_block", "Auto block (Guest 1337)")
        local keybind = Widget(survivor, "Keybind", "fs_block_kb", "fs_block_kb", 0, "toggle")
        if type(keybind) == "table" or type(keybind) == "userdata" then
            block.Keybind = keybind
            pcall(keybind.AddToHotkey, keybind, "Auto block", "fs_block")
        end
        Widget(survivor, "Combo", "fs_block_mode", "fs_block_mode", "Auto block mode", block.Modes, defaults.fs_block_mode)
        Widget(survivor, "SliderFloat", "fs_block_delay", "fs_block_delay", "Auto block delay (s)", 0, .5, defaults.fs_block_delay, "%.2f")
        Toggle(survivor, "fs_block_show", "Show auto block range")
        Picker2(survivor, "fs_col_autoblock", c.autoblock, "fs_col_autoblockattack", c.autoblockattack)
        Toggle(survivor, "fs_safe_sprint", "Safe sprint (stop before 0 stamina)")
        Toggle(survivor, "fs_parry", "Guest 1337 auto parry")
        Widget(survivor, "SliderFloat", "fs_parry_delay", "fs_parry_delay", "Auto parry delay (s)", 0, .6, defaults.fs_parry_delay, "%.2f")
        Widget(survivor, "SliderInt", "fs_parry_angle", "fs_parry_angle", "Auto parry upwards angle (fling killer, blatant)", 0, 90, defaults.fs_parry_angle)
        Toggle(survivor, "fs_parry_immune", "Parry when the killer is stun immune")
        Toggle(survivor, "fs_chance", "Chance aimbot")

        local attackReach = Section(tab, "Attack reach (BLATANT)", "Left")
        Toggle(attackReach, "fs_sreach", "Survivor attack reach")
        Widget(attackReach, "Combo", "fs_sreach_mode", "fs_sreach_mode", "Survivor attack reach mode", reach.Modes, defaults.fs_sreach_mode)
        Widget(attackReach, "SliderInt", "fs_sreach_forward", "fs_sreach_forward", "Survivor forward distance", 2, 14, defaults.fs_sreach_forward)
        Toggle(attackReach, "fs_reach", "Killer attack reach")
        Widget(attackReach, "Combo", "fs_reach_mode", "fs_reach_mode", "Killer attack reach mode", reach.Modes, defaults.fs_reach_mode)
        Widget(attackReach, "SliderInt", "fs_reach_forward", "fs_reach_forward", "Killer forward distance", 2, 14, defaults.fs_reach_forward)

        local killerSection = Section(tab, "Killer", "Right")
        Toggle(killerSection, "fs_corrupt", "John Doe corrupt energy aimbot")
        Widget(killerSection, "Combo", "fs_corrupt_mode", "fs_corrupt_mode", "Corrupt energy aimbot mode", corrupt.Modes, defaults.fs_corrupt_mode)

        local other = Section(tab, "Other", "Left")
        Toggle(other, "fs_timer", "Show round timer on bloodhunt")
        Widget(other, "Button", "fs_unhide_playtime", "Unhide playtime of all players", function()
            SetPrivacy({"HidePlaytime"})
        end)
        Widget(other, "Button", "fs_unhide_wins", "Unhide killer and survivor wins", function()
            SetPrivacy({"HideKillerWins", "HideSurvivorWins"})
        end)

        local esp = Section(tab, "ESP", "Right")
        Toggle(esp, "fs_esp", "Enable ESP")
        Toggle(esp, "fs_highlight", "Highlight part")
        Toggle(esp, "fs_text", "Show object name")
        Toggle(esp, "fs_paths", "Show attack path")
        Toggle(esp, "fs_paths_local", "Show path when you're killer")
        for _, category in categories do
            local key = category[1]
            Toggle(esp, "fs_show_" .. key, category[2])
            Picker(esp, "fs_col_" .. key, c[key])
        end
    end

    pcall(UI.RemoveTab, tabName)
    UI.AddTab(tabName, BuildTab)

    AddJob("Menu sync", false, function()
        local last = {}
        while Running() do
            for key, err in widgetErrors do
                if not reported[key] then
                    reported[key] = true
                    print("[MatchaForsaken] menu widget " .. key .. " failed: " .. err)
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

_G.MatchaForsakenConnection = RunService.RenderStepped:Connect(function()
    if Running() then Render() end
end)

print("[MatchaForsaken] loaded")

else
    print("Not in Forsaken")
end
