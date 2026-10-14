local Archives = {}

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local GameData = ReplicatedStorage:WaitForChild("GameData", 5)

local droneConnection = nil
local droneWalkedIntoParents = {}

local function processDrones(drones)
    local walkedInto = drones:FindFirstChild("WalkedInto")
    if walkedInto then
        if not droneWalkedIntoParents[walkedInto] then
            droneWalkedIntoParents[walkedInto] = drones
            walkedInto.Parent = ReplicatedStorage
        end
    else
        task.spawn(function()
            local found = drones:WaitForChild("WalkedInto", 2)
            if found and droneConnection and not droneWalkedIntoParents[found] then
                droneWalkedIntoParents[found] = drones
                found.Parent = ReplicatedStorage
            end
        end)
    end
end

function Archives.drones(enabled)
    if droneConnection then
        droneConnection:Disconnect()
        droneConnection = nil
    end

    if enabled then
        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name == "Drones" then
                processDrones(child)
            end
        end
        droneConnection = Workspace.ChildAdded:Connect(function(child)
            if child.Name == "Drones" then
                processDrones(child)
            end
        end)
    else
        for walkedInto, originalParent in pairs(droneWalkedIntoParents) do
            if walkedInto and walkedInto.Parent and originalParent and originalParent.Parent then
                walkedInto.Parent = originalParent
            end
        end
        table.clear(droneWalkedIntoParents)
    end
end

local almaConnection = nil

function Archives.alma(enabled)
    if almaConnection then
        almaConnection:Disconnect()
        almaConnection = nil
    end

    if enabled then
        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name == "Alma" then
                child:Destroy()
            end
        end
        almaConnection = Workspace.ChildAdded:Connect(function(child)
            if child.Name == "Alma" then
                task.defer(function()
                    if child.Parent then
                        child:Destroy()
                    end
                end)
            end
        end)
    end
end

local waterBypassConnection = nil
local waterParts = {}
local waterActive = false

function Archives.water(enabled)
    waterActive = enabled

    if waterBypassConnection then
        waterBypassConnection:Disconnect()
        waterBypassConnection = nil
    end

    if not enabled then
        for _, part in pairs(waterParts) do
            if part and part.Parent then
                part:Destroy()
            end
        end
        table.clear(waterParts)
        return
    end

    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return end

    local function processWaterRoom(room)
        if not tonumber(room.Name) then return end
        task.wait(2.5)
        if not waterActive or not room.Parent then return end

        local water = room:FindFirstChild("Water")
        if not water or waterParts[water] then return end

        local bypassPart = Instance.new("Part")
        bypassPart.Name = "WaterBypass"
        bypassPart.Anchored = true
        bypassPart.CanCollide = true
        bypassPart.CanTouch = false
        bypassPart.CanQuery = false
        bypassPart.Transparency = 0.3
        bypassPart.Color = Color3.fromRGB(0, 150, 255)
        bypassPart.Material = Enum.Material.ForceField

        local size, cf
        if water:IsA("BasePart") then
            size = water.Size
            cf = water.CFrame
        elseif water:IsA("Model") then
            cf, size = water:GetBoundingBox()
        else
            size = Vector3.new(10, 1.5, 10)
            cf = water:GetPivot()
        end

        bypassPart.Size = size + Vector3.new(0, 0.5, 0)
        bypassPart.CFrame = cf * CFrame.new(0, 0.25, 0)

        if bypassPart.Size.Y > 3 then
            bypassPart:Destroy()
            return
        end

        bypassPart.Parent = room
        waterParts[water] = bypassPart
    end

    local latestRoom = GameData and GameData:FindFirstChild("LatestRoom")
    local latestRoomNum = (latestRoom and tonumber(latestRoom.Value)) or 0

    for roomNum = math.max(0, latestRoomNum - 4), latestRoomNum do
        local room = currentRooms:FindFirstChild(tostring(roomNum))
        if room then
            task.spawn(processWaterRoom, room)
        end
    end

    waterBypassConnection = currentRooms.ChildAdded:Connect(function(room)
        task.spawn(processWaterRoom, room)
    end)
end

local stampedeConnection = nil
local cachedClockRemote = nil

local function getClockRemote(room)
    if not room then return nil end
    local assets = room:FindFirstChild("Assets") or room:FindFirstChild("Assets", true)
    local clock = assets and assets:FindFirstChild("ArchivesClock", true)
    if not clock then
        clock = room:FindFirstChild("ArchivesClock", true)
    end
    if clock then
        local remote = clock:FindFirstChild("LookedAtRemote", true)
        if remote and remote:IsA("RemoteEvent") then
            return remote
        end
    end
    return nil
end

local function resolveClockRemote()
    if cachedClockRemote and cachedClockRemote.Parent and cachedClockRemote:IsDescendantOf(game) then
        return cachedClockRemote
    end
    cachedClockRemote = nil

    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return nil end

    local latestRoom = GameData and GameData:FindFirstChild("LatestRoom")
    local latestRoomNum = (latestRoom and tonumber(latestRoom.Value)) or 0

    for roomNum = latestRoomNum, math.max(0, latestRoomNum - 5), -1 do
        local room = currentRooms:FindFirstChild(tostring(roomNum))
        local remote = getClockRemote(room)
        if remote then
            cachedClockRemote = remote
            return remote
        end
    end

    return nil
end

function Archives.anti_stampede(enabled)
    if stampedeConnection then
        task.cancel(stampedeConnection)
        stampedeConnection = nil
    end
    cachedClockRemote = nil

    if not enabled then return end

    stampedeConnection = task.spawn(function()
        while task.wait(0.5) do
            local remote = resolveClockRemote()
            if remote then
                remote:FireServer()
            end
        end
    end)
end

local a90Connection = nil
local active_a90 = false

local function get_a90_frame()
    local pgui = lp:FindFirstChild("PlayerGui")
    local mui = pgui and pgui:FindFirstChild("MainUI")
    local jmp = mui and mui:FindFirstChild("Jumpscare")
    return jmp and jmp:FindFirstChild("Jumpscare_A90")
end

function Archives.a90(enabled)
    active_a90 = enabled
    if a90Connection then
        a90Connection:Disconnect()
        a90Connection = nil
    end

    if active_a90 then
        lp:SetAttribute("Invincibility", true)
        local frame = get_a90_frame()
        if frame then
            frame.Visible = false
            a90Connection = frame:GetPropertyChangedSignal("Visible"):Connect(function()
                if active_a90 and frame.Visible then
                    frame.Visible = false
                end
            end)
        end
    else
        lp:SetAttribute("Invincibility", nil)
        local frame = get_a90_frame()
        if frame then
            frame.Visible = false
        end
    end
end

function Archives.cleanup()
    Archives.drones(false)
    Archives.alma(false)
    Archives.water(false)
    Archives.anti_stampede(false)
    Archives.a90(false)
end

return Archives
