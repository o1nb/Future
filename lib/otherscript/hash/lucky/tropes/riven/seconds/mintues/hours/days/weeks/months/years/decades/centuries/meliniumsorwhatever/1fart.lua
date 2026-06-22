do
    local loadingUrl =
        "https://raw.githubusercontent.com/amrho94/load/refs/heads/main/load.luau"
    local separator = loadingUrl:find("?", 1, true) and "&" or "?"
    local loadingSource = game:HttpGet(
        loadingUrl .. separator .. "_=" .. tostring(os.time()),
        true
    )

    assert(
        type(loadingSource) == "string" and loadingSource ~= "",
        "Hash Hub loading screen could not be downloaded"
    )

    -- Keep the visible title state on-screen for at least six seconds even
    -- when the whitelist request completes immediately.
    local shownMarker =
        "tween(welcome, 0.42, {TextTransparency = 0}, Enum.EasingStyle.Sine)"
    local shownReplacement = shownMarker
        .. "\nlocal hashMinimumTextEnd = os.clock() + 6"

    local function replaceOncePlain(source, marker, replacement)
        local first, last = source:find(marker, 1, true)
        if not first then
            return source, false
        end

        return source:sub(1, first - 1)
            .. replacement
            .. source:sub(last + 1), true
    end

    local shownReplaced
    loadingSource, shownReplaced = replaceOncePlain(
        loadingSource,
        shownMarker,
        shownReplacement
    )

    local exitMarker = "if not whitelistAllowed then"
    local exitReplacement = table.concat({
        "local hashRemainingTextTime = hashMinimumTextEnd - os.clock()",
        "if hashRemainingTextTime > 0 then",
        "\ttask.wait(hashRemainingTextTime)",
        "end",
        "",
        exitMarker,
    }, "\n")
    local exitReplaced
    loadingSource, exitReplaced = replaceOncePlain(
        loadingSource,
        exitMarker,
        exitReplacement
    )

    assert(
        shownReplaced and exitReplaced,
        "Hash Hub loading screen format is incompatible"
    )

    local loadingChunk, loadingError = loadstring(
        loadingSource,
        "@HashHubLoadingScreen"
    )
    assert(loadingChunk, loadingError)

    -- Do not wrap this call in pcall: whitelist denial intentionally freezes
    -- here, and loader errors must prevent the hub from loading.
    loadingChunk()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local global = (getgenv and getgenv()) or _G

if global.HashHub and global.HashHub.Destroy then
    pcall(global.HashHub.Destroy)
end

local Hash = {
    Running = true,
    Connections = {},
    Interface = nil,
    Visualizer = nil,
}
global.HashHub = Hash
global.HashGrip = global.HashGrip or "regular"

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Hash.Connections, connection)
    return connection
end

local function notify(text, title)
    print(("[%s] %s"):format(title or "Hash Hub", tostring(text)))
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Hash Hub",
            Text = tostring(text),
            Duration = 3,
        })
    end)
end

local function safe(callback)
    return function(...)
        local ok, result = pcall(callback, ...)
        if not ok then notify(result, "Hash error") end
        return result
    end
end

local function compileRemote(url, chunkName)
    local separator = url:find("?", 1, true) and "&" or "?"
    local source = game:HttpGet(
        url .. separator .. "_=" .. tostring(os.time()),
        true
    )
    assert(
        type(source) == "string" and source ~= "",
        tostring(chunkName or "remote script") .. " could not be downloaded"
    )

    local chunk, err = loadstring(source, "@" .. (chunkName or url))
    assert(chunk, err)
    return chunk()
end

local GuiLibrary =
    compileRemote(
        "https://raw.githubusercontent.com/amrho94/load/refs/heads/main/uilol.luau",
        "HashHubUI"
    )

assert(type(GuiLibrary) == "table", "Hash GUI library failed")

-- Hash visualizer control state.
-- Built-in/OpenViz-style backend only: no Pineapple downloads, no OpenViz preset folder.
local Visualizer = {}

local activePreset = "circle"
local visualizerRunning = false
local visualizerSpeed = 3
local visualizerSize = 5
local visualizerHeight = 0
local visualizerSensitivity = 0.65
local visualizerMaxRadiusBoost = 5
local visualizerLoudnessThreshold = 65
local visualizerSmoothingFactor = 0.08
local useNetlessVelocity = true
local visualizerMoverResponsiveness = 200
local visualizerTilt = 0
local reverseRotation = false
local autoTilt = false
local audioReactive = true
local targetPlayer = player

function Visualizer.SetSpeed(value)
    visualizerSpeed = math.clamp(tonumber(value) or visualizerSpeed, 0.05, 20)
end

function Visualizer.SetSize(value)
    visualizerSize = math.clamp(tonumber(value) or visualizerSize, 0.5, 100)
end

function Visualizer.SetHeight(value)
    visualizerHeight = math.clamp(tonumber(value) or visualizerHeight, -50, 100)
end

function Visualizer.SetTilt(value)
    visualizerTilt = math.clamp(tonumber(value) or visualizerTilt, -75, 75)
end

function Visualizer.SetAutoTilt(value)
    autoTilt = value == true
end

function Visualizer.SetReverseRotation(value)
    reverseRotation = value == true
end

function Visualizer.SetAudioReactive(value)
    audioReactive = value == true
end

function Visualizer.SetNetlessVelocity(value)
    -- OpenViz-style: flip netless live. Do not restart/revisualize.
    useNetlessVelocity = value == true
end

function Visualizer.SetMoverResponsiveness(value)
    visualizerMoverResponsiveness = math.clamp(tonumber(value) or visualizerMoverResponsiveness, 80, 300)
    if Visualizer.ApplyMoverTuning then
        pcall(Visualizer.ApplyMoverTuning)
    end
end

function Visualizer.SetVisualizerSensitivity(value)
    local amount = tonumber(value) or 65
    visualizerSensitivity = math.clamp(amount > 2 and amount / 100 or amount, 0, 2)
end

function Visualizer.SetSmoothing(value)
    local amount = tonumber(value) or visualizerSmoothingFactor
    visualizerSmoothingFactor = math.clamp(amount > 1 and amount / 100 or amount, 0.01, 0.4)
end

function Visualizer.SetLoudnessThreshold(value)
    visualizerLoudnessThreshold = math.clamp(tonumber(value) or visualizerLoudnessThreshold, 0, 400)
end

function Visualizer.SetMaxRadiusBoost(value)
    visualizerMaxRadiusBoost = math.clamp(tonumber(value) or visualizerMaxRadiusBoost, 0, 30)
end

function Visualizer.SetTargetPlayer(value)
    local text = tostring(value or ""):lower()
    if text == "" then
        targetPlayer = player
        return player
    end

    for _, serverPlayer in ipairs(Players:GetPlayers()) do
        if serverPlayer.Name:lower():sub(1, #text) == text
            or serverPlayer.DisplayName:lower():sub(1, #text) == text then
            targetPlayer = serverPlayer
            return serverPlayer
        end
    end

    targetPlayer = player
    return player
end

Hash.Visualizer = Visualizer

-- OpenViz-style direct mover backend using Hash presets only.

do
    local names = {
        "wings",
        "circle",
        "orb",
        "backpack",
        "zoom",
        "twisty line",
        "tail",
        "halo",
        "spiral",
        "spiral 2",
        "spin",
        "react circle",
    }

    local function normalizePreset(name)
        local preset = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        preset = preset:gsub("%s+", " ")

        if preset == "spread circle" then return "zoom" end
        if preset == "ball" then return "halo" end
        if preset == "double spiral" then return "spiral" end
        if preset == "spiral2" or preset == "spiral two" or preset == "double spiral 2" then return "spiral 2" end
        if preset == "reactcircle" or preset == "rolling react" or preset == "reactive circle" or preset == "rolling circle" then return "react circle" end
        if preset == "spin wings" or preset == "spinwings" or preset == "spinning wings" or preset == "twist wings" then return "wings" end

        return preset
    end

    activePreset = normalizePreset(activePreset)
    if not table.find(names, activePreset) then
        activePreset = "circle"
    end

    local renderConnection
    local netFixConnection
    local childAddedConnection
    local tracked = {}
    local trackedByTool = {}
    local visualizerObjects = {}
    local disabledScripts = {}
    local currentSound = nil
    local currentTimePosition = 0
    local startClock = 0
    local tailMode = "Reset"
    local tailHistory = {}
    local tailSegments = {}
    local backpackSpin = {}
    local tailLastHead = nil
    local tailLastLook = nil
    local tailActivity = 0
    local tailBasePosition = nil
    local tailBaseYaw = nil
    local tailLastUpdateTime = nil
    local restartLocked = false
    local smoothBoost = 0
    local latestLoudness = 0
    local legacyVolume = 0
    local smoothRootCFrame = nil
    local presetRevision = 0

    local OPENVIZ_NETLESS_VECTOR = Vector3.new(0, 0, -31)

    local function copyList(list)
        local out = {}
        for i, value in ipairs(list) do
            out[i] = value
        end
        return out
    end

    local function isValidPreset(name)
        return table.find(names, normalizePreset(name)) ~= nil
    end

    local function getToolHandle(tool)
        if not tool or not tool:IsA("Tool") then return nil end
        local handle = tool:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            return handle
        end
        return tool:FindFirstChildWhichIsA("BasePart", true)
    end

    local function getToolSound(tool)
        if not tool then return nil end
        return tool:FindFirstChildWhichIsA("Sound", true)
    end

    local function getAudioRemote(tool)
        if not tool then return nil end
        return tool:FindFirstChild("PlayAudio", true)
            or tool:FindFirstChild("Remote", true)
            or tool:FindFirstChildWhichIsA("RemoteEvent", true)
            or tool:FindFirstChildWhichIsA("RemoteFunction", true)
    end

    local function isVisualizableTool(tool)
        if not tool or not tool:IsA("Tool") or not getToolHandle(tool) then
            return false
        end

        local name = tostring(tool.Name or ""):lower()
        return name:find("boombox", 1, true) ~= nil
            or name:find("boom", 1, true) ~= nil
            or name:find("radio", 1, true) ~= nil
            or getToolSound(tool) ~= nil
            or getAudioRemote(tool) ~= nil
    end

    local function fireAudioRemote(tool, id)
        id = extractId(id)
        if not id or id == "" then return false end

        local remote = getAudioRemote(tool)
        if not remote then return false end

        local attempts
        if remote:IsA("RemoteFunction") then
            attempts = {
                function() return remote:InvokeServer("PlaySong", tonumber(id) or id) end,
                function() return remote:InvokeServer("PlaySong", tonumber(id) or id, 1) end,
                function() return remote:InvokeServer("PlayAudio", tostring(id), "1", "0", "0") end,
                function() return remote:InvokeServer("PlayAudio", tostring(id), 1, 0, 0) end,
                function() return remote:InvokeServer(tonumber(id) or id) end,
            }
        elseif remote:IsA("RemoteEvent") then
            attempts = {
                function() return remote:FireServer("PlaySong", tonumber(id) or id) end,
                function() return remote:FireServer("PlaySong", tonumber(id) or id, 1) end,
                function() return remote:FireServer("PlayAudio", tostring(id), "1", "0", "0") end,
                function() return remote:FireServer("PlayAudio", tostring(id), 1, 0, 0) end,
                function() return remote:FireServer(tonumber(id) or id) end,
            }
        else
            return false
        end

        local fired = false
        for _, attempt in ipairs(attempts) do
            fired = pcall(attempt) or fired
        end
        return fired
    end

    local function setToolNoneAnimation(animationId)
        local character = player.Character
        local animate = character and character:FindFirstChild("Animate")
        if not animate then return end

        for _, item in ipairs(animate:GetDescendants()) do
            if item:IsA("Animation") and item.Name:lower():find("tool") then
                pcall(function()
                    item.AnimationId = animationId or "rbxassetid://0"
                end)
            end
        end
    end

    local function restoreToolNoneAnimation()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            setToolNoneAnimation("http://www.roblox.com/asset/?id=507768375")
        else
            setToolNoneAnimation("rbxassetid://182393478")
        end
    end

    local function removeCharacterGrips(character, handle)
        if not character or not handle then return end
        for _, item in ipairs(character:GetDescendants()) do
            local destroy = false

            if item.Name == "RightGrip" and (item:IsA("Motor6D") or item:IsA("Weld")) then
                destroy = true
            elseif item:IsA("Motor6D") or item:IsA("Weld") or item:IsA("WeldConstraint") then
                local ok, part0, part1 = pcall(function()
                    return item.Part0, item.Part1
                end)

                if ok then
                    destroy = (part0 == handle or part1 == handle)
                end
            end

            if destroy then
                pcall(function()
                    item:Destroy()
                end)
            end
        end
    end

    local function disableToolLocalScripts(tool)
        if disabledScripts[tool] then return end
        disabledScripts[tool] = {}

        for _, item in ipairs(tool:GetDescendants()) do
            if item:IsA("LocalScript") then
                disabledScripts[tool][item] = item.Disabled
                pcall(function()
                    item.Disabled = true
                end)
            end
        end
    end

    local function restoreToolLocalScripts(tool)
        local saved = disabledScripts[tool]
        if not saved then return end

        for scriptObj, wasDisabled in pairs(saved) do
            if scriptObj and scriptObj.Parent then
                pcall(function()
                    scriptObj.Disabled = wasDisabled
                end)
            end
        end

        disabledScripts[tool] = nil
    end

    local function removeOldVisualizerObjects(handle)
        if not handle then return end

        local function shouldRemove(object)
            return object.Name == "OrbitAtt"
                or object.Name == "PineappleAlignPos"
                or object.Name == "PineappleAlignRot"
                or object.Name == "HashOpenVizAlignPos"
                or object.Name == "HashOpenVizAlignRot"
                or object.Name == "HashBuiltInAttachment"
                or object.Name == "HashBuiltInPosition"
                or object.Name == "HashBuiltInRotation"
                or object.Name == "HashPresetAttachment"
                or object.Name == "HashPresetPosition"
                or object.Name == "HashPresetRotation"
                or object:IsA("AlignPosition")
                or object:IsA("AlignOrientation")
                or object:IsA("BodyPosition")
                or object:IsA("BodyGyro")
                or object:IsA("BodyVelocity")
                or object:IsA("LinearVelocity")
                or object:IsA("AngularVelocity")
                or object:IsA("VectorForce")
        end

        for _, child in ipairs(handle:GetChildren()) do
            if shouldRemove(child) then
                pcall(function()
                    child:Destroy()
                end)
            end
        end
    end

    local function setHandleOpenVizActive(handle)
        if not handle or not handle.Parent then return end

        pcall(function()
            handle.Anchored = false
            handle.Massless = true
            handle.CanCollide = false
            handle.AssemblyLinearVelocity = useNetlessVelocity and OPENVIZ_NETLESS_VECTOR or Vector3.zero
            handle.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local function cfToRotationVector(cf)
        local x, y, z = cf:ToOrientation()
        return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
    end

    local function makeOpenVizProxy(handle)
        removeOldVisualizerObjects(handle)

        local attachment = Instance.new("Attachment")
        attachment.Name = "OrbitAtt"
        attachment.Position = Vector3.new(0, 0, 0)
        attachment.Parent = handle

        local alignPosition = Instance.new("AlignPosition")
        alignPosition.Name = "HashOpenVizAlignPos"
        alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPosition.Attachment0 = attachment
        alignPosition.RigidityEnabled = true
        alignPosition.ReactionForceEnabled = false
        alignPosition.ApplyAtCenterOfMass = true
        alignPosition.MaxForce = math.huge
        alignPosition.MaxVelocity = math.huge
        alignPosition.Responsiveness = visualizerMoverResponsiveness
        alignPosition.Position = handle.Position
        alignPosition.Parent = handle

        local alignRotation = Instance.new("AlignOrientation")
        alignRotation.Name = "HashOpenVizAlignRot"
        alignRotation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        alignRotation.Attachment0 = attachment
        alignRotation.ReactionTorqueEnabled = false
        alignRotation.PrimaryAxisOnly = false
        alignRotation.MaxTorque = math.huge
        alignRotation.MaxAngularVelocity = math.huge
        alignRotation.Responsiveness = visualizerMoverResponsiveness
        alignRotation.CFrame = handle.CFrame
        alignRotation.Parent = handle

        local state = {
            Position = handle.Position,
            Rotation = Vector3.new(),
        }

        local proxy = {}
        setmetatable(proxy, {
            __index = function(_, key)
                return state[key]
            end,
            __newindex = function(_, key, value)
                state[key] = value

                if key == "Position" and typeof(value) == "Vector3" then
                    alignPosition.Position = value
                elseif key == "Rotation" and typeof(value) == "Vector3" then
                    alignRotation.CFrame = CFrame.new(state.Position)
                        * CFrame.Angles(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
                end
            end,
        })

        table.insert(visualizerObjects, attachment)
        table.insert(visualizerObjects, alignPosition)
        table.insert(visualizerObjects, alignRotation)

        return proxy, alignPosition, alignRotation, attachment
    end

    local function validTrackedData(data)
        return data
            and data.Tool
            and data.Tool.Parent
            and data.Handle
            and data.Handle.Parent
            and data.Proxy
    end

    local function countTracked()
        local amount = 0
        for _, data in ipairs(tracked) do
            if validTrackedData(data) then
                amount += 1
            end
        end
        return amount
    end

    local function getLoudestSound()
        local loudest = 0
        for _, data in ipairs(tracked) do
            if data.Sound and data.Sound.Parent and data.Sound.IsPlaying then
                loudest = math.max(loudest, tonumber(data.Sound.PlaybackLoudness) or 0)
            else
                local sound = getToolSound(data.Tool)
                data.Sound = sound
                if sound and sound.IsPlaying then
                    loudest = math.max(loudest, tonumber(sound.PlaybackLoudness) or 0)
                end
            end
        end
        return loudest
    end

    local function updateAudioBoost(dt)
        dt = math.clamp(tonumber(dt) or (1 / 60), 1 / 240, 0.1)
        if not audioReactive then
            latestLoudness = 0
            legacyVolume = 0
            local release = 1 - math.exp(-dt * 7)
            smoothBoost += (0 - smoothBoost) * release
            return smoothBoost
        end

        local loudest = getLoudestSound()
        latestLoudness = loudest
        legacyVolume = loudest / math.clamp(100 / math.max(visualizerSensitivity, 0.05), 25, 350)
        local targetBoost = 0

        if loudest > visualizerLoudnessThreshold then
            targetBoost = math.min((loudest - visualizerLoudnessThreshold) / 450, 1)
                * visualizerMaxRadiusBoost
                * visualizerSensitivity
        end

        -- Faster attack, slower release; both are frame-rate independent.
        local speed = targetBoost > smoothBoost and 11 or 5.5
        local alpha = 1 - math.exp(-dt * speed)
        smoothBoost += (targetBoost - smoothBoost) * alpha
        return smoothBoost
    end

    local function clearTailState()
        table.clear(tailHistory)
        table.clear(tailSegments)
        tailLastHead = nil
        tailLastLook = nil
        tailActivity = 0
        tailBasePosition = nil
        tailBaseYaw = nil
        tailLastUpdateTime = nil
    end

    local function getYaw(cf)
        local _, yaw = cf:ToOrientation()
        return yaw
    end

    local function lerpAngle(current, target, alpha)
        local diff = math.atan2(math.sin(target - current), math.cos(target - current))
        return current + diff * alpha
    end

    local function frameAlpha(base, dt)
        return 1 - math.pow(1 - base, math.clamp(dt * 60, 0.25, 4))
    end

    local function getTailSpacing()
        -- The v2.4 reference keeps a tight, even chain at distance 5.
        return math.clamp(1.12 + visualizerSize * 0.075, 1.28, 1.85)
    end

    local function sampleYawHistory(delayFrames, fallbackYaw)
        if #tailHistory == 0 then
            return fallbackYaw
        end

        local index = math.clamp(math.floor(delayFrames) + 1, 1, #tailHistory)
        local nextIndex = math.clamp(index + 1, 1, #tailHistory)
        local alpha = delayFrames - math.floor(delayFrames)

        local a = tailHistory[index] or fallbackYaw
        local b = tailHistory[nextIndex] or a
        return lerpAngle(a, b, alpha)
    end

    local function tailLocalOffset(index, count, elapsed, radiusBoost)
        local u = (index - 1) / math.max(count - 1, 1)
        local spacing = getTailSpacing()

        local back = 0.72 + (index - 1) * spacing
        local audioLift = math.min(
            math.max(tonumber(radiusBoost) or 0, 0) * 2.8,
            math.max(2.8, visualizerSize * 1.05)
        )
        local height = visualizerHeight - 0.58
            + u * (0.46 + visualizerSize * 0.095)
            + (u ^ 1.18) * audioLift

        -- Small v2.4 idle "breathing": a slow ripple that is almost still at
        -- the base and becomes visible near the tip. It stays subtle enough
        -- that the preset remains a clean chain when no audio is playing.
        local idlePhase = elapsed * (1.18 + visualizerSpeed * 0.025) - u * 1.35
        local idleWeight = 0.12 + (u ^ 1.35) * 0.88
        height += math.sin(idlePhase) * (0.025 + visualizerSize * 0.009) * idleWeight
        height += math.sin(idlePhase * 0.53 + 0.8) * 0.018 * idleWeight

        local side = math.sin(idlePhase * 0.72)
            * (0.008 + visualizerSize * 0.0025)
            * (u ^ 1.5)

        if tailMode == "Flow" then
            local flow = math.sin(elapsed * (1.9 + visualizerSpeed * 0.04) - u * 1.75)
            side = flow * (u ^ 1.2) * visualizerSize * 0.28
        end

        return Vector3.new(side, height, back)
    end

    local function ensureTailSegments(root, count, elapsed)
        local yaw = getYaw(root.CFrame)
        local base = root.Position

        for index = 1, count do
            local segment = tailSegments[index]
            if not segment then
                segment = {
                    Point = root.CFrame:PointToWorldSpace(tailLocalOffset(index, count, elapsed, 0)),
                    Yaw = yaw,
                    Base = base,
                }
                tailSegments[index] = segment
            end
        end

        for index = count + 1, #tailSegments do
            tailSegments[index] = nil
        end
    end

    local function updateTailHistory(root, count, elapsed)
        ensureTailSegments(root, count, elapsed)

        local yaw = getYaw(root.CFrame)
        local rootPos = root.Position

        if not tailBasePosition then
            tailBasePosition = rootPos
            tailBaseYaw = yaw
            tailLastUpdateTime = elapsed
        end

        local dt = math.clamp(elapsed - (tailLastUpdateTime or elapsed), 0, 0.1)
        tailLastUpdateTime = elapsed

        -- Base follows X/Z quickly, Y slowly. This is the jump fix.
        local xzAlpha = frameAlpha(0.82, dt)
        local yAlpha = frameAlpha(0.055, dt)

        tailBasePosition = Vector3.new(
            tailBasePosition.X + (rootPos.X - tailBasePosition.X) * xzAlpha,
            tailBasePosition.Y + math.clamp((rootPos.Y - tailBasePosition.Y) * yAlpha, -0.09, 0.09),
            tailBasePosition.Z + (rootPos.Z - tailBasePosition.Z) * xzAlpha
        )

        tailBaseYaw = lerpAngle(tailBaseYaw or yaw, yaw, frameAlpha(0.78, dt))

        table.insert(tailHistory, 1, tailBaseYaw)
        local maxYawSamples = math.max(180, count * 18)
        while #tailHistory > maxYawSamples do
            table.remove(tailHistory)
        end
    end

    local function tailWorldCFrame(index, count, root, elapsed, radiusBoost)
        ensureTailSegments(root, count, elapsed)

        local segment = tailSegments[index]
        local u = (index - 1) / math.max(count - 1, 1)
        local currentYaw = tailBaseYaw or getYaw(root.CFrame)

        local delay = (index - 1) * (2.15 + visualizerSize * 0.075)
        if tailMode == "Flow" then
            delay += u * 3.0
        end

        local yaw = sampleYawHistory(delay, currentYaw)

        if tailMode == "Wag" then
            local wagSpeed = elapsed * (2.75 + visualizerSpeed * 0.05)
            local wag = math.sin(wagSpeed - u * 0.58)
            yaw += wag * (u ^ 1.1) * math.rad(28)
        elseif tailMode == "Flow" then
            local flowYaw = math.sin(elapsed * (1.55 + visualizerSpeed * 0.035) - u * 1.2)
            yaw += flowYaw * (u ^ 1.25) * math.rad(13)
        end

        local basePos = tailBasePosition or root.Position
        local baseCF = CFrame.new(basePos) * CFrame.Angles(0, yaw, 0)

        local desiredPoint = baseCF:PointToWorldSpace(
            tailLocalOffset(index, count, elapsed, radiusBoost)
        )

        local pointFollow = frameAlpha(math.clamp(0.80 - u * 0.52, 0.18, 0.84), 1 / 60)
        if tailMode == "Wag" then
            pointFollow = frameAlpha(math.clamp(0.74 - u * 0.46, 0.15, 0.78), 1 / 60)
        elseif tailMode == "Flow" then
            pointFollow = frameAlpha(math.clamp(0.68 - u * 0.44, 0.13, 0.72), 1 / 60)
        end

        if segment and segment.Point then
            segment.Point = segment.Point:Lerp(desiredPoint, pointFollow)
        elseif segment then
            segment.Point = desiredPoint
        end

        return CFrame.new(segment and segment.Point or desiredPoint)
    end

    local function normalPreset(index, count, elapsed, radiusBoost)
        local direction = reverseRotation and -1 or 1
        local a = elapsed * visualizerSpeed * 24 * direction
        local t = elapsed * visualizerSpeed * direction
        local slot = (index - 1) / math.max(count, 1)
        local u = (index - 1) / math.max(count - 1, 1)
        local angle = slot * math.pi * 2
        local radius = math.max(visualizerSize + (radiusBoost or 0), 1)

        -- Higher boombox counts need more spacing so presets do not clump at
        -- the edges. 10-ish boxes keeps the old scale; 20 boxes spreads wider.
        local countDistanceMultiplier = math.clamp(1 + math.max(count - 10, 0) * 0.055, 1, 2.35)

        if activePreset == "wings" then
            -- Final tuned mirror wings - closer to original video
            local pairCount = math.floor(count / 2)

            if count % 2 == 1 and index == count then
                return CFrame.new(0, visualizerHeight + 0.18, 0.85)
            end

            local side = (index % 2 == 1) and -1 or 1
            local pairIndex = math.ceil(index / 2)
            local p = pairCount > 1 and (pairIndex - 1) / (pairCount - 1) or 0

            local distanceScale = math.clamp(visualizerSize / 4.2, 0.75, 1.85)
            local countDistanceMultiplier = math.clamp(1 + math.max(count - 8, 0) * 0.075, 1, 2.8)

            -- Stronger, smoother upward feather curve
            local sourceX = 0.45 + p * (6.85 * distanceScale * countDistanceMultiplier)
            local curveLift = math.sin(p * math.pi * 0.85) * (1.55 * distanceScale)   -- more arch
            local y = visualizerHeight + 0.1 + p * (3.55 * distanceScale * countDistanceMultiplier) + curveLift
            local z = 0.75 + p * (0.45 * countDistanceMultiplier) - math.sin(p * math.pi * 0.7) * 0.22

            return CFrame.new(side * sourceX, y, z)
        elseif false then -- old regular wings removed
            -- Two real feather rows per side. The old version was one wavy arc
            -- with alternating offsets, which still read as a pair of noodles.
            local half = math.ceil(count / 2)
            local side = index <= half and -1 or 1
            local sideIndex = index <= half and index or index - half
            local sideTotal = index <= half and half or math.max(count - half, 1)
            local layer = (sideIndex - 1) % 2
            local feather = math.floor((sideIndex - 1) / 2)
            local layerTotal = math.max(1, math.ceil((sideTotal - layer) / 2))
            local progress = layerTotal > 1 and feather / (layerTotal - 1) or 0

            -- The lower row starts between upper feathers and finishes shorter,
            -- making a broad fan even with only ten boomboxes.
            local stagger = layer == 1 and 0.11 or 0
            local p = math.clamp(progress * (layer == 1 and 0.88 or 1) + stagger, 0, 1)
            local audioAmount = math.min(math.max(radiusBoost or 0, 0), 3.5)
            local wingSpan = math.max(6.6, visualizerSize * 1.72) + audioAmount * 0.28
            local shoulder = 1.0

            -- One slow hinge motion per wing, with a small delayed flex at the tip.
            local flapClock = elapsed * (0.72 + visualizerSpeed * 0.075) * direction
            local hinge = math.sin(flapClock) * math.rad(7.5)
            local tipFlex = math.sin(flapClock - p * 0.95) * (0.05 + p * 0.22)

            local xDistance = shoulder + p * wingSpan
            local arch = math.sin(p * math.pi * 0.88)
            local baseY = 0.58 + arch * math.max(1.65, visualizerSize * 0.38) - p * 0.62
            local layerY = layer == 1 and (-0.72 - p * 0.34) or 0
            local audioLift = audioAmount * (0.08 + p ^ 1.45 * 0.34)

            local x = side * xDistance
            local y = visualizerHeight + baseY + layerY
                + math.sin(hinge) * xDistance * 0.34
                + tipFlex
                + audioLift
            local z = 0.72
                + p * 0.94
                + (layer == 1 and 0.46 or 0)
                - arch * 0.18
                + math.cos(hinge) * p * 0.16

            return CFrame.new(x, y, z)
        elseif activePreset == "backpack" then
            -- OG Backpack preset, but spinning like the screenshot:
            -- front face stays presented, tilted diagonal, then rolls in-place.
            local spinDirection = reverseRotation and -1 or 1
            local backpackSpin = elapsed * (1.25 + visualizerSpeed * 0.18) * spinDirection

            return CFrame.new(0, 0, 0.8)
                * CFrame.Angles(0, math.rad(180), 0)
                * CFrame.Angles(0, 0, math.rad(45) + backpackSpin)

        elseif activePreset == "orb" then
            -- Orb: tight clumped ball like the old version, but the whole clump
            -- rotates as one object and every boombox still has fast weird spin.
            local countSafe = math.max(count, 1)
            local spin = backpackSpin[index]
            if not spin then
                spin = {
                    X = math.rad(math.random(-260, 260)) / 10,
                    Y = math.rad(math.random(220, 520)) / 10,
                    Z = math.rad(math.random(-420, 420)) / 10,
                    Phase = math.rad(math.random(0, 360)),
                    Offset = math.rad(math.random(0, 360)),
                }
                backpackSpin[index] = spin
            end

            -- Tiny sphere spacing. This keeps it clumped instead of huge.
            -- Do NOT use countDistanceMultiplier here.
            local golden = math.pi * (3 - math.sqrt(5))
            local sphereY = 1 - (2 * (index - 0.5) / countSafe)
            local sphereRadius = math.sqrt(math.max(0, 1 - sphereY * sphereY))
            local sphereTheta = index * golden

            local orbRadius = 0.62 + math.min(countSafe, 35) * 0.006
            local localPoint = Vector3.new(
                math.cos(sphereTheta) * sphereRadius * orbRadius,
                sphereY * orbRadius,
                math.sin(sphereTheta) * sphereRadius * orbRadius
            )

            -- Whole ball rotation: fast and strange, but still tight.
            local ballSpeed = 2.8 + visualizerSpeed * 0.55
            local ballRotation = CFrame.Angles(
                elapsed * ballSpeed * 0.95 * direction,
                elapsed * ballSpeed * 1.45 * direction,
                math.sin(elapsed * 1.35 + spin.Offset) * 0.85
                    + elapsed * ballSpeed * 0.42 * direction
            )

            local rotatedPoint = ballRotation:VectorToWorldSpace(localPoint)
            local spinTime = elapsed * (3.8 + visualizerSpeed * 0.62)

            return CFrame.new(rotatedPoint.X, visualizerHeight + 4.35 + rotatedPoint.Y, rotatedPoint.Z)
                * ballRotation
                * CFrame.Angles(0, math.rad(180), math.rad(45))
                * CFrame.Angles(
                    spin.Phase + spinTime * spin.X,
                    spin.Offset + spinTime * spin.Y,
                    spinTime * spin.Z
                )
        elseif activePreset == "zoom" then
            -- New Zoom preset ported from the coroutine version, but driven by
            -- the single RenderStepped backend so every boombox stays synced.
            local countSafe = math.max(count, 1)
            local ro = math.rad(a / 2 + (index * (360 / countSafe)))
            local wave = elapsed * 60
            local vector = math.sin((wave / 25) + (index / countSafe) * (math.pi * 2))
            local waveOffset = math.sin(a / countSafe / 2) * 4
            local vol = legacyVolume

            return CFrame.new(vector * countDistanceMultiplier, 0, vector * countDistanceMultiplier)
                * CFrame.Angles(0, ro, 0)
                * CFrame.new(vol + (visualizerSize * countDistanceMultiplier), waveOffset * countDistanceMultiplier, waveOffset * countDistanceMultiplier)
        elseif activePreset == "twisty line" then
            local centered = u - 0.5
            local phase = u * math.pi * 2.05 - t * 0.54
            local wave = math.sin(phase)
            local wave2 = math.cos(phase)

            return CFrame.new(
                centered * math.max(radius * countDistanceMultiplier, 3.5) * 2.75,
                visualizerHeight + 0.8 + wave * (0.72 * countDistanceMultiplier),
                0.9 + wave2 * (0.78 * countDistanceMultiplier)
            )
        elseif activePreset == "halo" then
            local orbit = angle + t * 0.3
            local haloRadius = math.max(3.2, radius * 0.82 * countDistanceMultiplier)
            local tilt = math.rad(23)
            local localPoint = CFrame.Angles(tilt, 0, math.rad(10))
                * Vector3.new(math.cos(orbit) * haloRadius, 0, math.sin(orbit) * haloRadius)
            local bob = math.sin(t * 0.62) * 0.18

            return CFrame.new(
                localPoint.X,
                visualizerHeight + 2.25 + localPoint.Y + bob,
                localPoint.Z
            ) * CFrame.Angles(0, -orbit + math.pi / 2, math.rad(88))
        elseif activePreset == "spin" then
            -- Spin: tweaked from the supplied coroutine preset.
            -- Instead of one spiral line, this makes TWO intertwined spin lines.
            local countSafe = math.max(count, 1)
            local strand = (index % 2 == 1) and -1 or 1
            local strandIndex = math.ceil(index / 2)
            local strandCount = strand == -1 and math.ceil(countSafe / 2) or math.floor(countSafe / 2)
            strandCount = math.max(strandCount, 1)

            local p = strandCount > 1 and (strandIndex - 1) / (strandCount - 1) or 0
            local countSpread = math.clamp(1 + math.max(countSafe - 10, 0) * 0.035, 1, 1.75)

            -- Coroutine-style clocks, but synced in RenderStepped.
            local a2 = elapsed * visualizerSpeed * 24
            local ro = math.rad((a2 / 2) * strandIndex + (strandIndex * (360 / strandCount)))

            local vol = legacyVolume
            local radius = (visualizerSize + vol) * countSpread
            local height = visualizerHeight + ((strandIndex + (strandIndex / strandCount / 2)) / 1.5) * countSpread
            local depth = ((strandIndex + (strandIndex / strandCount / 2)) * 0.34) * countSpread

            -- Two-line split:
            -- each strand gets opposite phase and a tiny sideways lane so they
            -- read as two separate spirals instead of one fat clump.
            local phase = strand == -1 and 0 or math.pi
            local lane = strand * (0.38 + math.min(countSafe, 30) * 0.01)

            local spinCFrame = CFrame.Angles(0, ro / 4 + phase, 0)
                * CFrame.new(radius, height, depth)

            return spinCFrame * CFrame.new(lane, 0, 0)

        elseif activePreset == "spiral 2" then
            -- Spiral 2: tweaked from the coroutine version.
            -- It keeps the old uh/ro wave math, but uses this visualizer's
            -- single RenderStepped backend so high boombox counts stay stable.
            local countSafe = math.max(count, 1)
            local countSpread = math.clamp(1 + math.max(countSafe - 10, 0) * 0.035, 1, 1.85)

            -- Old preset-style clocks:
            -- a was incremented by speed / 2.5 every heartbeat.
            -- woah was incremented by speed / #tools / 8.
            local a2 = elapsed * visualizerSpeed * 24
            local woah = elapsed * visualizerSpeed * (7.5 / countSafe)

            local ro = math.rad((a2 / 2) * index + (index * (360 / countSafe)))
            local uh = math.sin(woah + index * math.pi)

            local vol = legacyVolume
            local distance = (visualizerSize + vol + uh * 4.25) * countSpread
            local depth = ((index + (index / countSafe / 2)) / 4) * countSpread
            local verticalWave = math.sin((elapsed * visualizerSpeed * 0.85) + index * 0.42) * 0.28

            return CFrame.Angles(0, (uh * 4.2) + (ro / 4), 0)
                * CFrame.new(distance, verticalWave, depth)

        elseif activePreset == "spiral" then
            -- New Spiral preset ported from the supplied BP/BG coroutine math.
            -- It keeps the original audio-roll behavior: when the track gets
            -- louder, the vertical stack opens into a tighter spiral.
            local countSafe = math.max(count, 1)
            local ro = math.rad(a + (index * (360 / countSafe)))
            local vol = latestLoudness / 150

            return CFrame.Angles(0, ro + (index * (1 / countSafe)), vol / 5)
                * CFrame.new(0, (visualizerSize * countDistanceMultiplier) + (index * ((5 * countDistanceMultiplier) / countSafe)), 0)
        elseif activePreset == "react circle" then
            -- React Circle: calm rolling circle.
            -- Audio still reacts, but it no longer snaps/jerks the ring around.
            local countSafe = math.max(count, 1)
            local orbitAngle = angle + (t * 0.18)

            -- Use the already-processed values instead of raw loudness so the
            -- preset does not tweak out on sharp loudness spikes.
            local audioPulse = math.clamp(legacyVolume, 0, 4.5)
            local beat = math.clamp((radiusBoost or 0) / math.max(maxRadiusBoost, 1), 0, 1)

            local calmCountScale = math.clamp(countDistanceMultiplier, 1, 1.45)
            local circleRadius = math.max(1.5, (visualizerSize + audioPulse * 0.18 + (radiusBoost or 0) * 0.18) * calmCountScale)

            -- Higher counts still get a tiny lane split, but not enough to make
            -- the boomboxes look like they are exploding outward.
            local lane = (index % 2 == 0) and 1 or -1
            local laneOffset = countSafe > 14 and lane * 0.16 or 0
            local laneAngle = orbitAngle + lane * 0.025

            local wobble = math.sin(elapsed * 0.85 + index * 0.48)
            local yWave = visualizerHeight
                + wobble * (0.08 + beat * 0.18)
                + lane * (countSafe > 14 and 0.06 or 0)

            return CFrame.new(
                math.cos(laneAngle) * (circleRadius + laneOffset),
                yWave,
                math.sin(laneAngle) * (circleRadius + laneOffset)
            )

        elseif activePreset == "circle" then
            -- Tuned Default.preset: one shared clock keeps every slot perfectly
            -- spaced, while the already-smoothed loudness expands the ring.
            local orbitAngle = angle + (t * 0.2)
            local circleRadius = math.max(1, (visualizerSize + (radiusBoost or 0)) * countDistanceMultiplier)

            return CFrame.new(
                math.cos(orbitAngle) * circleRadius,
                visualizerHeight,
                math.sin(orbitAngle) * circleRadius
            )
        elseif activePreset == "tail" then
            return CFrame.new(tailLocalOffset(index, count, elapsed))
        end

        -- Fallback circle.
        local orbitAngle = angle + (t * 0.31)
        local circleRadius = math.max(radius * countDistanceMultiplier, 4.75)

        return CFrame.new(
            math.cos(orbitAngle) * circleRadius,
            visualizerHeight + 0.58 + math.sin(t * 0.5 + angle * 2) * 0.035,
            math.sin(orbitAngle) * circleRadius
        ) * CFrame.Angles(0, -orbitAngle + math.pi / 2, math.rad(82))
    end

    local function trackTool(tool, handle, character)
        if trackedByTool[tool] then return true end
        if not tool or not handle or not character then return false end

        setHandleOpenVizActive(handle)
        disableToolLocalScripts(tool)
        removeCharacterGrips(character, handle)

        local proxy, alignPosition, alignRotation, attachment = makeOpenVizProxy(handle)
        local sound = getToolSound(tool)

        local data = {
            Tool = tool,
            Handle = handle,
            Proxy = proxy,
            AlignPosition = alignPosition,
            AlignRotation = alignRotation,
            Attachment = attachment,
            Sound = sound,
            Index = #tracked + 1,
            StartedAt = tick(),
            SmoothedCFrame = handle.CFrame,
            NetlessAllowed = true,
        }

        trackedByTool[tool] = data
        table.insert(tracked, data)

        -- Netless is enabled immediately for sturdier ownership behavior.
        data.NetlessAllowed = true

        if not currentSound and sound then
            currentSound = sound
        end

        return true
    end

    local function cleanupTrackedData(data, returnToBackpack)
        if not data then return end

        trackedByTool[data.Tool] = nil

        if data.Tool then
            restoreToolLocalScripts(data.Tool)
        end

        pcall(function()
            if data.AlignPosition then data.AlignPosition:Destroy() end
            if data.AlignRotation then data.AlignRotation:Destroy() end
            if data.Attachment then data.Attachment:Destroy() end
        end)

        if data.Handle then
            removeOldVisualizerObjects(data.Handle)
            pcall(function()
                data.Handle.AssemblyLinearVelocity = Vector3.zero
                data.Handle.AssemblyAngularVelocity = Vector3.zero
            end)
        end

        if returnToBackpack and data.Tool and data.Tool.Parent then
            local backpack = player:FindFirstChildOfClass("Backpack")
            if backpack then
                pcall(function()
                    data.Tool.Parent = backpack
                end)
            end
        end
    end

    local function cleanupOpenVizBackend(returnToBackpack)
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end

        if netFixConnection then
            netFixConnection:Disconnect()
            netFixConnection = nil
        end

        if childAddedConnection then
            childAddedConnection:Disconnect()
            childAddedConnection = nil
        end

        for _, data in ipairs(tracked) do
            cleanupTrackedData(data, returnToBackpack)
        end

        for tool in pairs(disabledScripts) do
            restoreToolLocalScripts(tool)
        end

        for _, object in ipairs(visualizerObjects) do
            pcall(function()
                if object and object.Parent then
                    object:Destroy()
                end
            end)
        end

        table.clear(tracked)
        table.clear(trackedByTool)
        table.clear(visualizerObjects)
        table.clear(disabledScripts)
        clearTailState()

        _G.tov = {}

        restoreToolNoneAnimation()
        currentSound = nil
        smoothBoost = 0
        latestLoudness = 0
        legacyVolume = 0
        smoothRootCFrame = nil
    end

    local function collectVisualizableTools()
        local character = player.Character
        local backpack = player:FindFirstChildOfClass("Backpack")
        local candidates = {}
        local seen = {}

        local function scan(container)
            if not container then return end
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and isVisualizableTool(tool) and not seen[tool] then
                    seen[tool] = true
                    table.insert(candidates, tool)
                end
            end
        end

        scan(character)
        scan(backpack)

        return candidates
    end

    local function primeToolsOpenVizStyle(candidates)
        local character = player.Character or player.CharacterAdded:Wait()
        local backpack = player:WaitForChild("Backpack")
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        -- OpenViz-style startup order: bounce the tool through backpack/character
        -- so Roblox lets go of the equipped tool grip before AlignPosition owns it.
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and isVisualizableTool(tool) then
                pcall(function()
                    tool.Parent = backpack
                end)
            end
        end

        RunService.Heartbeat:Wait()

        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and isVisualizableTool(tool) then
                pcall(function()
                    tool.Parent = character
                end)
            end
        end

        RunService.Heartbeat:Wait()

        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and isVisualizableTool(tool) then
                pcall(function()
                    tool.Parent = backpack
                end)
            end
        end

        RunService.Heartbeat:Wait()

        local toolCount = 0
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and isVisualizableTool(tool) then
                toolCount += 1
            end
        end

        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and isVisualizableTool(tool) then
                task.spawn(function()
                    pcall(function() tool.Parent = character end)
                    pcall(function() tool.Parent = backpack end)
                    pcall(function() tool.Parent = character end)
                    pcall(function() tool.Parent = backpack end)

                    if humanoid then
                        pcall(function()
                            tool.Parent = humanoid
                        end)
                    end

                    pcall(function()
                        tool.Parent = character
                    end)

                    RunService.Heartbeat:Wait()

                    local handle = getToolHandle(tool)
                    if not handle then return end

                    setHandleOpenVizActive(handle)
                    removeCharacterGrips(character, handle)
                    trackTool(tool, handle, character)

                    if audioId and audioId ~= "" then
                        fireAudioRemote(tool, audioId)
                    end

                    local startedAt = tick()
                    repeat
                        RunService.Heartbeat:Wait()
                    until getToolSound(tool) or tick() - startedAt > 1

                    local sound = getToolSound(tool)
                    local data = trackedByTool[tool]
                    if data then
                        data.Sound = sound
                    end
                    if not currentSound and sound then
                        currentSound = sound
                    end

                    removeCharacterGrips(character, handle)

                    task.spawn(function()
                        repeat
                            RunService.Heartbeat:Wait()
                        until not tool.Parent or tool.Parent == backpack or not visualizerRunning

                        if visualizerRunning then
                            local data = trackedByTool[tool]
                            if data then
                                cleanupTrackedData(data, false)
                                for index = #tracked, 1, -1 do
                                    if tracked[index] == data or tracked[index].Tool == tool then
                                        table.remove(tracked, index)
                                    end
                                end
                            end

                            if countTracked() <= 0 then
                                Visualizer.Stop()
                                notify("Visualizer stopped: no tracked tools remain", "Hash visualizer")
                            else
                                notify("One boombox dropped; continuing visualizer", "Hash visualizer")
                            end
                        end
                    end)
                end)
            end
        end

        return toolCount
    end

    local function startNetFix()
        if netFixConnection then
            netFixConnection:Disconnect()
            netFixConnection = nil
        end

        netFixConnection = RunService.Heartbeat:Connect(function()
            if not visualizerRunning then return end

            -- OpenViz netless style: apply the velocity directly to each
            -- tracked handle after its short startup grace period. Do not use
            -- legacy proxy globals and do not spam .Velocity.
            for _, data in ipairs(tracked) do
                local handle = data and data.Handle
                if handle and handle.Parent then
                    pcall(function()
                        handle.Massless = true
                        handle.CanCollide = false
                        if useNetlessVelocity and data.NetlessAllowed then
                            handle.AssemblyLinearVelocity = PINEAPPLE_NETLESS_VECTOR
                            handle.AssemblyAngularVelocity = Vector3.zero
                        end
                    end)
                end
            end
        end)
    end

    local function syncStartedSounds(timePosition)
        for _, data in ipairs(tracked) do
            task.spawn(function()
                local sound = data.Sound or getToolSound(data.Tool)
                if sound then
                    pcall(function()
                        sound.TimePosition = timePosition or currentTimePosition or 0
                        sound.Playing = true
                    end)
                    data.Sound = sound
                    if not currentSound then
                        currentSound = sound
                    end
                end
            end)
        end
    end

    local function startSoundTimer()
        task.spawn(function()
            while visualizerRunning do
                task.wait(0.6)
                if currentSound and currentSound.Parent and currentSound.IsPlaying then
                    currentTimePosition = currentSound.TimePosition
                end
            end
        end)
    end

    local function startChildWatcher()
        if childAddedConnection then
            childAddedConnection:Disconnect()
        end

        local character = player.Character
        local backpack = player:FindFirstChildOfClass("Backpack")
        if not character or not backpack then return end

        childAddedConnection = character.ChildAdded:Connect(function(child)
            if restartLocked then return end
            if child:IsA("Tool") and visualizerRunning and not trackedByTool[child] then
                restartLocked = true
                task.spawn(function()
                    task.wait()
                    pcall(function()
                        child.Parent = backpack
                    end)
                    task.wait(0.3)
                    if visualizerRunning then
                        Visualizer.Start()
                    end
                    restartLocked = false
                end)
            end
        end)
    end

    local function targetRoot()
        local targetCharacter = targetPlayer and targetPlayer.Character or nil
        targetCharacter = targetCharacter or player.Character
        if not targetCharacter then return nil end

        return targetCharacter:FindFirstChild("HumanoidRootPart")
            or targetCharacter:FindFirstChild("UpperTorso")
            or targetCharacter:FindFirstChild("Torso")
    end

    local function computeRotationCFrame(target, root, index, count, elapsed)
        if activePreset == "orb" or activePreset == "backpack" then
            return target
        end

        if activePreset == "react circle" then
            -- Calm true roll:
            -- still rolls one direction, but way slower and with no raw-loudness
            -- speed spikes.
            local beat = math.clamp((radiusBoost or 0) / math.max(maxRadiusBoost, 1), 0, 1)
            local dir = reverseRotation and -1 or 1

            local rollAngle = elapsed * (1.65 + visualizerSpeed * 0.22 + beat * 0.9) * dir
            local indexPhase = index * 0.18
            local bank = math.rad(3) * dir

            return CFrame.new(target.Position, root.Position + Vector3.new(0, visualizerHeight + legacyVolume / 6, 0))
                * CFrame.Angles(math.rad(visualizerTilt), 0, 0)
                * CFrame.Angles(rollAngle + indexPhase, 0, 0)
                * CFrame.Angles(0, 0, bank)
        end

        if activePreset == "circle" then
            -- Default.preset points every boombox toward the torso. Preserve
            -- its reactive vertical aim, but use the smoothed audio value.
            local reactiveDrop = math.sin(-smoothBoost * 2)
            local lookTarget = root.Position
                + Vector3.new(0, visualizerHeight + reactiveDrop, 0)
            return CFrame.lookAt(target.Position, lookTarget)
                * CFrame.Angles(math.rad(visualizerTilt), 0, 0)
        end

        if activePreset == "wings" then
            -- Paint.NET-style horizontal flip:
            -- use the photo-left wing as the source, then mirror its yaw/roll
            -- onto the other side instead of giving both sides their own twist.
            local pairCount = math.floor(count / 2)

            if count % 2 == 1 and index == count then
                return CFrame.new(target.Position)
                    * (root.CFrame - root.Position)
                    * CFrame.Angles(math.rad(-14 + visualizerTilt), 0, math.rad(8))
            end

            local side = (index % 2 == 1) and -1 or 1
            local pairIndex = math.ceil(index / 2)
            local p = pairCount > 1 and (pairIndex - 1) / (pairCount - 1) or 0

            local base = CFrame.new(target.Position) * (root.CFrame - root.Position)

            -- In a front-view screenshot, photo-left is the avatar's right side.
            -- If Roblox shows the wrong side mirrored for your avatar, swap this
            -- from 1 to -1.
            local photoLeftWingSide = 1
            local mirrorSign = side == photoLeftWingSide and 1 or -1

            local upwardTilt = math.rad(-14 + visualizerTilt)
            local outwardYaw = mirrorSign * math.rad(12 + p * 30)
            local featherTwist = mirrorSign * math.rad(8 + p * 42 + p * 38)

            -- Restore the old rotating feather motion, but keep it mirrored.
            -- This is always on now; Auto Tilt only adds a tiny extra wobble.
            local spinDirection = reverseRotation and -1 or 1
            local wingRotate = elapsed * (0.82 + visualizerSpeed * 0.105) * spinDirection
            local featherWave = math.sin(elapsed * (0.9 + visualizerSpeed * 0.045) * spinDirection - p * 0.65)
                * math.rad(4 + p * 3)

            featherTwist += mirrorSign * wingRotate
            featherTwist += mirrorSign * featherWave

            if autoTilt then
                featherTwist += mirrorSign
                    * math.rad(math.sin(elapsed * 1.35 * spinDirection - p * 0.8) * 5)
            end

            return base
                * CFrame.Angles(upwardTilt, 0, 0)
                * CFrame.Angles(0, outwardYaw, 0)
                * CFrame.Angles(0, 0, featherTwist)
        elseif false then -- old regular wings removed
            -- Face the fronts outward like layered feathers, then fan each box
            -- progressively toward its wingtip.
            local lookTarget = root.Position + Vector3.new(0, visualizerHeight + 1.15, 0)
            local rotation = CFrame.new(target.Position, lookTarget)

            local half = math.ceil(count / 2)
            local side = index <= half and -1 or 1
            local sideIndex = index <= half and index or index - half
            local sideTotal = index <= half and half or math.max(count - half, 1)
            local layer = (sideIndex - 1) % 2
            local feather = math.floor((sideIndex - 1) / 2)
            local layerTotal = math.max(1, math.ceil((sideTotal - layer) / 2))
            local progress = layerTotal > 1 and feather / (layerTotal - 1) or 0
            local roll = side * math.rad(8 + progress * 24 + layer * 5)
            local pitch = math.rad(visualizerTilt - progress * 5 + layer * 7)

            if autoTilt then
                local direction = reverseRotation and -1 or 1
                roll += math.rad(math.sin(elapsed * 1.35 * direction - progress * 0.8) * 5)
            end

            return rotation * CFrame.Angles(pitch, 0, roll)
        end

        if activePreset == "zoom" then
            local spinTilt = elapsed * 1.875
            return CFrame.lookAt(
                target.Position,
                root.Position + Vector3.new(0, visualizerHeight, visualizerHeight)
            ) * CFrame.Angles(math.rad(visualizerTilt), 0, 0)
              * CFrame.Angles(spinTilt, 0, spinTilt)
        end

        if activePreset == "spin" then
            -- Same idea as the old BG.CFrame:
            -- look toward torso, with loudness lifting the aim point.
            return CFrame.lookAt(
                target.Position,
                root.Position + Vector3.new(0, visualizerHeight + legacyVolume / 2, 0)
            ) * CFrame.Angles(math.rad(visualizerTilt), 0, 0)
        end

        if activePreset == "spiral 2" then
            -- Same idea as the old BG.CFrame:
            -- look toward the torso, with loudness lifting the aim point.
            return CFrame.lookAt(
                target.Position,
                root.Position + Vector3.new(0, visualizerHeight + legacyVolume / 2, 0)
            ) * CFrame.Angles(math.rad(visualizerTilt), 0, 0)
        end

        if activePreset == "spiral" then
            return CFrame.lookAt(
                target.Position,
                root.Position + Vector3.new(0, visualizerHeight, 0)
            ) * CFrame.Angles(math.rad(visualizerTilt), 0, 0)
        end

        if activePreset == "halo" then
            local roll = 0
            if autoTilt then
                local direction = reverseRotation and -1 or 1
                roll = math.rad(math.sin(elapsed * 1.8 * direction + index * 0.5) * 12)
            end

            return target * CFrame.Angles(math.rad(visualizerTilt), 0, roll)
        end

        if activePreset == "tail" then
            -- The reference boxes all face with the avatar instead of pointing
            -- down the chain. Tilt slider = forward/back lean.
            return CFrame.new(target.Position)
                * (root.CFrame - root.Position)
                * CFrame.Angles(math.rad(visualizerTilt), 0, 0)
        end

        return CFrame.new(target.Position, root.Position)
    end

    local function applyPresetMoverTuning()
        local response = (activePreset == "backpack" or activePreset == "wings")
            and math.min(300, visualizerMoverResponsiveness * 2)
            or visualizerMoverResponsiveness

        for _, data in ipairs(tracked) do
            pcall(function()
                if data.AlignPosition then
                    data.AlignPosition.RigidityEnabled = true
                    data.AlignPosition.MaxVelocity = math.huge
                    data.AlignPosition.Responsiveness = response
                end
                if data.AlignRotation then
                    data.AlignRotation.Responsiveness = response
                    data.AlignRotation.MaxAngularVelocity =
                        activePreset == "backpack" and math.huge
                        or activePreset == "wings" and math.huge
                        or math.huge
                end
            end)
        end
    end

    Visualizer.ApplyMoverTuning = applyPresetMoverTuning

    function Visualizer.GetPresetNames()
        return copyList(names)
    end

    function Visualizer.RefreshCustomPresets()
        return copyList(names)
    end

    function Visualizer.Stop()
        visualizerRunning = false
        cleanupOpenVizBackend(true)
    end

    function Visualizer.Start()
        Visualizer.Stop()

        local character = player.Character or player.CharacterAdded:Wait()
        local root = targetRoot()
        if not root then
            notify("Target character is not ready", "Hash visualizer")
            return false
        end

        setToolNoneAnimation("rbxassetid://0")

        local candidates = collectVisualizableTools()
        if #candidates == 0 then
            notify("No visualizable tools found", "Hash visualizer")
            return false
        end

        visualizerRunning = true
        startClock = tick()
        smoothRootCFrame = root.CFrame
        clearTailState()

        local expectedCount = primeToolsOpenVizStyle(candidates)
        local waitStarted = tick()

        repeat
            RunService.Heartbeat:Wait()
        until #tracked >= expectedCount or tick() - waitStarted > 3 or not visualizerRunning

        if #tracked == 0 then
            notify("Visualizer could not align any tools", "Hash visualizer")
            Visualizer.Stop()
            return false
        end

        if #tracked < expectedCount then
            notify(("Attached %d/%d tools"):format(#tracked, expectedCount), "Hash visualizer")
        end

        -- OpenViz-style start: do not sit for a full second before the movers run.
        task.wait(0.15)

        if not visualizerRunning then
            return false
        end

        syncStartedSounds(currentTimePosition)
        applyPresetMoverTuning()
        startNetFix()
        startSoundTimer()
        startChildWatcher()

        renderConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not visualizerRunning then return end

            local rootNow = targetRoot()
            if not rootNow then return end

            for index = #tracked, 1, -1 do
                local data = tracked[index]
                if not validTrackedData(data) then
                    cleanupTrackedData(data, false)
                    table.remove(tracked, index)
                end
            end

            local count = countTracked()
            if count <= 0 then
                Visualizer.Stop()
                return
            end

            deltaTime = math.clamp(deltaTime or (1 / 60), 1 / 240, 0.1)
            -- No root smoothing: follow the character immediately.
            smoothRootCFrame = rootNow.CFrame
            local motionRoot = {
                Position = rootNow.Position,
                CFrame = rootNow.CFrame,
            }

            local elapsed = tick() - startClock
            local radiusBoost = updateAudioBoost(deltaTime)
            local liveIndex = 0

            if activePreset == "tail" then
                updateTailHistory(motionRoot, count, elapsed)
            end

            for _, data in ipairs(tracked) do
                if validTrackedData(data) then
                    liveIndex += 1

                    local target
                    if activePreset == "tail" then
                        target = tailWorldCFrame(liveIndex, count, motionRoot, elapsed, radiusBoost)
                    else
                        target = smoothRootCFrame * normalPreset(liveIndex, count, elapsed, radiusBoost)
                    end

                    local rotation = computeRotationCFrame(target, motionRoot, liveIndex, count, elapsed)
                    local desired = CFrame.new(target.Position) * rotation.Rotation

                    -- No visualizer smoothing/Lerp: drive directly into the target CFrame.
                    -- AlignPosition/AlignOrientation handle the physical correction.
                    data.SmoothedCFrame = desired

                    data.Proxy.Position = desired.Position
                    data.Proxy.Rotation = cfToRotationVector(desired)
                end
            end
        end)

        return true
    end

    function Visualizer.SetPreset(value)
        local newPreset = normalizePreset(value)

        if not isValidPreset(newPreset) then
            newPreset = "circle"
        end

        if activePreset == newPreset then
            if newPreset == "tail" then
                tailMode = "Reset"
                clearTailState()
            end
            return true
        end

        activePreset = newPreset
        presetRevision += 1
        tailMode = "Reset"
        smoothBoost = 0
        latestLoudness = 0
        legacyVolume = 0
        smoothRootCFrame = nil
        clearTailState()
        table.clear(backpackSpin)
        applyPresetMoverTuning()

        return true
    end

    function Visualizer.SetTailMode(mode)
        tailMode = tostring(mode or "Reset")
        clearTailState()
    end

    function Visualizer.Destroy()
        Visualizer.Stop()
    end

    connect(UserInputService.InputBegan, function(input, processed)
        if processed or activePreset ~= "tail" then return end

        if input.KeyCode == Enum.KeyCode.Z then
            Visualizer.SetTailMode("Wag")
            notify("Tail: wag", "Hash visualizer")
        elseif input.KeyCode == Enum.KeyCode.X then
            Visualizer.SetTailMode("Flow")
            notify("Tail: flow", "Hash visualizer")
        elseif input.KeyCode == Enum.KeyCode.C then
            Visualizer.SetTailMode("Reset")
            notify("Tail reset", "Hash visualizer")
        end
    end)
end


local function extractId(value)
    return tostring(value or ""):match("%d+")
end

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function isBoombox(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = tool.Name:lower()
    return name:find("boombox", 1, true) ~= nil
        or name:find("radio", 1, true) ~= nil
        or tool:FindFirstChild("Remote", true) ~= nil
        or tool:FindFirstChild("PlayAudio", true) ~= nil
end

local function collectBoomboxes()
    local tools, seen = {}, {}
    local function scan(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if isBoombox(tool) and not seen[tool] then
                seen[tool] = true
                table.insert(tools, tool)
            end
        end
    end
    scan(player.Character)
    scan(player:FindFirstChildOfClass("Backpack"))
    return tools
end

local function equipBoomboxes()
    local character = getCharacter()
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if isBoombox(tool) then tool.Parent = character end
        end
    end
    RunService.Heartbeat:Wait()
    return collectBoomboxes()
end

local builtInGripModes = {"regular", "lowhold", "backpack", "shoulder", "moneyspread"}
local gripPresetFolder = "Hash/presets/grip"
local gripPresetCache = {}

local function normalizeGripMode(mode)
    mode = tostring(mode or "regular"):lower():gsub("^%s+", ""):gsub("%s+$", "")
    mode = mode:gsub("%s+", " ")
    if mode == "low hold" then mode = "lowhold" end
    if mode == "money spread" then mode = "moneyspread" end
    return mode
end

local function ensureGripPresetFolder()
    if makefolder then
        pcall(function()
            if isfolder and not isfolder("Hash") then makefolder("Hash") end
            if isfolder and not isfolder("Hash/presets") then makefolder("Hash/presets") end
            if isfolder and not isfolder(gripPresetFolder) then makefolder(gripPresetFolder) end
        end)
    end
end

local function getGripPresetNames()
    ensureGripPresetFolder()

    local out, seen = {}, {}
    if listfiles then
        local scanPaths = {
            gripPresetFolder,
            "Hash/presets",
            "Hash",
        }

        for _, scanPath in ipairs(scanPaths) do
            local ok, files = pcall(listfiles, scanPath)
            if ok and type(files) == "table" then
                for _, path in ipairs(files) do
                    local pathText = tostring(path)
                    local lowerPath = pathText:lower():gsub("\\", "/")
                    if lowerPath:sub(-8) == ".gpreset" and lowerPath:find("hash/presets/grip", 1, true) then
                        local name = pathText:match("([^/\\]+)%.gpreset$")
                        if name then
                            local normalized = normalizeGripMode(name)
                            if not seen[normalized] then
                                seen[normalized] = true
                                table.insert(out, name)
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(out, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
    return out
end

local function getGripDropdownOptions()
    local out = {}
    local seen = {}

    for _, name in ipairs(builtInGripModes) do
        seen[normalizeGripMode(name)] = true
        table.insert(out, name)
    end

    for _, name in ipairs(getGripPresetNames()) do
        local normalized = normalizeGripMode(name)
        if not seen[normalized] then
            seen[normalized] = true
            table.insert(out, name)
        end
    end

    return out
end

local function gripSlotToCFrame(slot)
    if not slot then return nil end

    if typeof(slot.CFrame) == "CFrame" then
        return slot.CFrame
    end

    if type(slot.pos) == "table" then
        local rx, ry, rz = 0, 0, 0
        if type(slot.rot) == "table" then
            rx = tonumber(slot.rot.x) or tonumber(slot.rot[1]) or 0
            ry = tonumber(slot.rot.y) or tonumber(slot.rot[2]) or 0
            rz = tonumber(slot.rot.z) or tonumber(slot.rot[3]) or 0
        end

        return CFrame.new(
            tonumber(slot.pos.x) or tonumber(slot.pos[1]) or 0,
            tonumber(slot.pos.y) or tonumber(slot.pos[2]) or 0,
            tonumber(slot.pos.z) or tonumber(slot.pos[3]) or 0
        ) * CFrame.Angles(rx, ry, rz)
    end

    return nil
end

local function loadGripPreset(mode)
    local presetName = normalizeGripMode(mode)
    if presetName == "" then return nil end

    if gripPresetCache[presetName] ~= nil then
        return gripPresetCache[presetName] or nil
    end

    ensureGripPresetFolder()

    if not (isfile and readfile) then
        gripPresetCache[presetName] = false
        return nil
    end

    local path = gripPresetFolder .. "/" .. presetName .. ".gpreset"

    -- File names can have caps/spaces. Find the real file by normalized name.
    for _, name in ipairs(getGripPresetNames()) do
        if normalizeGripMode(name) == presetName then
            path = gripPresetFolder .. "/" .. name .. ".gpreset"
            break
        end
    end

    if not isfile(path) then
        gripPresetCache[presetName] = false
        return nil
    end

    local ok, source = pcall(readfile, path)
    if not ok or type(source) ~= "string" or source == "" then
        gripPresetCache[presetName] = false
        return nil
    end

    local data
    local chunk, compileErr = nil, nil
    if loadstring then
        chunk, compileErr = loadstring(source, "@HashGripPreset/" .. presetName)
    end

    if chunk then
        local runOk, result = pcall(chunk)
        if runOk and type(result) == "table" then
            data = result
        else
            warn("Hash grip: .gpreset failed to run -> " .. path)
        end
    else
        warn("Hash grip: .gpreset failed to compile -> " .. tostring(compileErr))
    end

    if not (data and type(data.Slots) == "table" and #data.Slots > 0) then
        gripPresetCache[presetName] = false
        warn("Hash grip: invalid .gpreset -> " .. path)
        return nil
    end

    table.sort(data.Slots, function(a, b)
        return (tonumber(a.Index) or 0) < (tonumber(b.Index) or 0)
    end)

    gripPresetCache[presetName] = data
    return data
end

local function refreshGripPresets()
    table.clear(gripPresetCache)
    ensureGripPresetFolder()
    return getGripDropdownOptions()
end

local function getGripLimit(mode, total)
    mode = normalizeGripMode(mode)

    local customGrip = loadGripPreset(mode)
    if customGrip then
        return math.min(#customGrip.Slots, total)
    end

    if mode == "moneyspread" then
        return 15
    elseif mode == "backpack" then
        -- SalmonHub reference uses tools 1-10 for the back build.
        return math.min(10, total)
    elseif mode == "regular" or mode == "lowhold" or mode == "shoulder" then
        return math.min(1, total)
    end

    return math.min(1, total)
end

local function getGripCFrame(mode, index, count)
    mode = normalizeGripMode(mode)

    local customGrip = loadGripPreset(mode)
    if customGrip then
        local slot = customGrip.Slots[index] or customGrip.Slots[((index - 1) % #customGrip.Slots) + 1]
        return gripSlotToCFrame(slot) or CFrame.new()
    end

    local u = (index - 1) / math.max(count - 1, 1)

    if mode == "regular" then
        return CFrame.new()
    elseif mode == "lowhold" then
        -- Lowhold: hangs lower by the side like the reference image instead of
        -- sitting tucked under the torso.
        return CFrame.new(0.62, -1.32, -0.12)
            * CFrame.Angles(math.rad(-12), math.rad(10), math.rad(4))
    elseif mode == "backpack" then
        -- Direct SalmonHub-style backpack grip.
        -- Their build puts the same Grip on tools 1-10, then parents them.
        return CFrame.new(-1, 1, 2.3)
            * CFrame.Angles(0, math.rad(180), 0.65)
    elseif mode == "shoulder" then
        return CFrame.new(0.72, 0.45, -0.18)
            * CFrame.Angles(math.rad(82), math.rad(0), math.rad(90))
    elseif mode == "moneyspread" then
        -- Shoulder-based money spread:
        -- start from the shoulder grip, then stack 15 boomboxes almost on top of
        -- each other, rotating each one from left to right like a cash fan.
        local spread = (u * 2) - 1
        local absSpread = math.abs(spread)

        -- This is the shoulder grip, nudged down/forward so the fan sits around
        -- the hand/shoulder instead of becoming a giant shell.
        local shoulderBase = CFrame.new(0.58, 0.26, -0.32)
            * CFrame.Angles(math.rad(82), math.rad(-6), math.rad(92))

        -- Keep spacing VERY tight. The fan should come from rotation, not from
        -- throwing the boomboxes far apart.
        local tightStack = CFrame.new(
            spread * 0.055,
            absSpread * 0.018,
            (index - 1) * 0.006
        )

        -- Leftmost is turned left, then every next boombox turns right.
        local turn = math.rad(spread * -64)

        return shoulderBase
            * tightStack
            * CFrame.Angles(math.rad(0), math.rad(spread * 2), turn)
    end

    return CFrame.new()
end

local function applyGripMode(mode)
    mode = normalizeGripMode(mode or global.HashGrip or "regular")

    local customGrip = loadGripPreset(mode)

    local character = getCharacter()
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = player:FindFirstChildOfClass("Backpack")

    if humanoid then
        pcall(function()
            humanoid:UnequipTools()
        end)
    end

    RunService.Heartbeat:Wait()

    local tools = collectBoomboxes()
    if #tools == 0 then
        tools = equipBoomboxes()
    end

    table.sort(tools, function(a, b)
        return tostring(a.Name) < tostring(b.Name)
    end)

    local useCount = getGripLimit(mode, #tools)

    if customGrip and #tools < #customGrip.Slots then
        notify(("%s needs %d boomboxes; found %d"):format(mode, #customGrip.Slots, #tools), "Hash grip")
        return false
    end

    if mode == "moneyspread" and #tools < 15 then
        notify(("Moneyspread needs 15 boomboxes; found %d"):format(#tools), "Hash grip")
        return false
    end

    if useCount <= 0 then
        notify("No boomboxes found", "Hash grip")
        return false
    end

    -- Important: do NOT equip every boombox. Only the amount the grip needs.
    -- Anything extra gets left in Backpack.
    for index, tool in ipairs(tools) do
        pcall(function()
            if index <= useCount then
                tool.Grip = getGripCFrame(mode, index, useCount)
                tool.Parent = character
            elseif backpack and tool.Parent == character then
                tool.Parent = backpack
            end
        end)

        if index % 8 == 0 then
            RunService.Heartbeat:Wait()
        end
    end

    global.HashGrip = mode
    notify(("Grip set/equipped: %s (%d/%d)"):format(mode, useCount, #tools), "Hash grip")
    return true
end

-- Audio ----------------------------------------------------------------------

-- Z0R massplay transplant -----------------------------------------------------
-- This block intentionally follows the uploaded Z0R Hub massplay backend:
-- equip a batch, collect audio jobs, fire them synced, then client-sync the
-- created Sound objects back to 0 and :Play() them together.

local currentTimePosition = 0
local timePosition = 0
local massPlaying = false
local lastMassTools = nil
local MassplayTrackedTools = {}
local MassplayStopConnections = {}

local ZorAntiLogBaitChars = {"%0A", "%0B", "%0C", "%0D"}

local function ZorSpawn(callback, ...)
    return coroutine.wrap(callback)(...)
end

local function DecodeAudioIdForSound(id)
    local idText = tostring(id or "")

    if idText:lower():sub(1, 2) == "0x" then
        local decoded = tonumber(idText)
        if decoded then
            return tostring(decoded)
        end
    end

    local digits = idText:match("%d+")
    return digits or idText
end

local function ZorUrlEncode(text)
    local encoded = ""

    for i = 1, #text do
        encoded = encoded .. string.format("%%%02X", string.byte(text:sub(i, i)))
    end

    return encoded
end

local function ZorGenerateAntiLogBait(length)
    local bait = ""

    for _ = 1, length do
        bait = bait .. ZorAntiLogBaitChars[math.random(1, #ZorAntiLogBaitChars)]
    end

    return bait
end

local function ZorScatterAntiLogBait(text)
    local scattered = {}

    for token in tostring(text or ""):gmatch("%%%x%x") do
        if math.random(1, 100) <= 78 then
            table.insert(scattered, token:sub(1, 1))
            table.insert(scattered, string.rep(" ", math.random(1, 8)))
            table.insert(scattered, token:sub(2, 2))
            table.insert(scattered, string.rep(" ", math.random(1, 8)))
            table.insert(scattered, token:sub(3, 3))
        else
            table.insert(scattered, token)
        end

        table.insert(scattered, string.rep(" ", math.random(0, 10)))
    end

    return table.concat(scattered)
end

local function EncodeZorAntiLogAudioId(id)
    local numericId = tonumber(DecodeAudioIdForSound(id))
    if not numericId then
        return id
    end

    local hexId = string.format("0X%X", numericId)
    local urlEncodedHexId = ZorUrlEncode(hexId)
    local baitPrefix = ZorScatterAntiLogBait(ZorGenerateAntiLogBait(math.random(350, 700)))
    local baitSuffix = ZorScatterAntiLogBait(ZorGenerateAntiLogBait(math.random(350, 700)))

    return baitPrefix .. urlEncodedHexId .. baitSuffix
end

local function GetToolHandle(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    return tool:FindFirstChild("Handle")
        or tool:FindFirstChildWhichIsA("BasePart", true)
        or tool:FindFirstChildOfClass("Part")
end

local function GetToolSound(tool)
    if not tool then return nil end
    return tool:FindFirstChildWhichIsA("Sound", true)
end

local function IsBoomboxTool(tool)
    if not tool or not tool:IsA("Tool") then return false end

    local lowerName = tostring(tool.Name or ""):lower()
    return lowerName:find("boombox", 1, true) ~= nil
        or lowerName:find("boom", 1, true) ~= nil
        or lowerName:find("radio", 1, true) ~= nil
        or GetToolSound(tool) ~= nil
        or tool:FindFirstChild("PlayAudio", true) ~= nil
        or tool:FindFirstChild("Remote", true) ~= nil
        or tool:FindFirstChild("Audio", true) ~= nil
        or tool:FindFirstChild("Sound", true) ~= nil
        or tool:FindFirstChildWhichIsA("RemoteEvent", true) ~= nil
        or tool:FindFirstChildWhichIsA("RemoteFunction", true) ~= nil
end

local function collectSounds(tools)
    local sounds, seen = {}, {}

    for _, tool in ipairs(tools or {}) do
        if tool and tool.Parent then
            for _, item in ipairs(tool:GetDescendants()) do
                if item:IsA("Sound") and not seen[item] then
                    seen[item] = true
                    table.insert(sounds, item)
                end
            end
        end
    end

    return sounds
end

local function CollectBoomboxSounds(toolsToPlay)
    return collectSounds(toolsToPlay)
end

local function GetAudioRemoteAttempts(remote, id, preferPlayAudio)
    if not (remote and id) then return nil end

    local pitch = "1"
    local numericPitch = 1

    if remote:IsA("RemoteFunction") then
        if preferPlayAudio then
            return {
                function() return remote:InvokeServer("PlayAudio", tostring(id), pitch, "0", "0") end,
                function() return remote:InvokeServer("PlayAudio", tostring(id), numericPitch, 0, 0) end,
                function() return remote:InvokeServer("PlayAudio", id, numericPitch, 0, 0) end,
                function() return remote:InvokeServer(id, numericPitch) end,
                function() return remote:InvokeServer(id) end,
                function() return remote:InvokeServer("PlaySong", id, numericPitch) end,
                function() return remote:InvokeServer("PlaySong", id) end,
            }
        end

        return {
            function() return remote:InvokeServer("PlaySong", id, numericPitch) end,
            function() return remote:InvokeServer("PlaySong", id) end,
            function() return remote:InvokeServer(id, numericPitch) end,
            function() return remote:InvokeServer(id) end,
            function() return remote:InvokeServer("PlayAudio", tostring(id), pitch, "0", "0") end,
            function() return remote:InvokeServer("PlayAudio", tostring(id), numericPitch, 0, 0) end,
            function() return remote:InvokeServer("PlayAudio", id, numericPitch, 0, 0) end,
        }
    elseif remote:IsA("RemoteEvent") then
        if preferPlayAudio then
            return {
                function() return remote:FireServer("PlayAudio", tostring(id), pitch, "0", "0") end,
                function() return remote:FireServer("PlayAudio", tostring(id), numericPitch, 0, 0) end,
                function() return remote:FireServer("PlayAudio", id, numericPitch, 0, 0) end,
                function() return remote:FireServer("PlaySong", id, numericPitch) end,
                function() return remote:FireServer("PlaySong", id) end,
                function() return remote:FireServer(tostring(id)) end,
                function() return remote:FireServer(id) end,
            }
        end

        return {
            function() return remote:FireServer("PlaySong", id, numericPitch) end,
            function() return remote:FireServer("PlaySong", id) end,
            function() return remote:FireServer(id, numericPitch) end,
            function() return remote:FireServer(id) end,
            function() return remote:FireServer("PlayAudio", tostring(id), pitch, "0", "0") end,
            function() return remote:FireServer("PlayAudio", tostring(id), numericPitch, 0, 0) end,
            function() return remote:FireServer("PlayAudio", id, numericPitch, 0, 0) end,
            function() return remote:FireServer(tostring(id)) end,
            function() return remote:FireServer(id) end,
        }
    end

    return nil
end

local function GetAudioRemoteStopAttempts(remote)
    if not remote then return nil end

    if remote:IsA("RemoteFunction") then
        return {
            function() return remote:InvokeServer("StopAudio") end,
            function() return remote:InvokeServer("StopSong") end,
            function() return remote:InvokeServer("Stop") end,
            function() return remote:InvokeServer("Pause") end,
            function() return remote:InvokeServer(false) end,
        }
    elseif remote:IsA("RemoteEvent") then
        return {
            function() return remote:FireServer("StopAudio") end,
            function() return remote:FireServer("StopSong") end,
            function() return remote:FireServer("Stop") end,
            function() return remote:FireServer("Pause") end,
            function() return remote:FireServer(false) end,
        }
    end

    return nil
end

local function GetPrimaryAudioRemoteAttempt(remote, id, preferPlayAudio)
    if not (remote and id) then return nil end

    if remote:IsA("RemoteFunction") then
        if preferPlayAudio then
            return function()
                return remote:InvokeServer("PlayAudio", tostring(id), "1", "0", "0")
            end
        end

        return function()
            return remote:InvokeServer("PlaySong", id, 1)
        end
    elseif remote:IsA("RemoteEvent") then
        if preferPlayAudio then
            return function()
                return remote:FireServer("PlayAudio", tostring(id), "1", "0", "0")
            end
        end

        return function()
            return remote:FireServer("PlaySong", id, 1)
        end
    end

    return nil
end

local function FireAudioRemote(remote, id, preferPlayAudio, fireAll)
    local attempts = GetAudioRemoteAttempts(remote, id, preferPlayAudio)
    if not attempts then return false end

    local fired = false
    for _, attempt in ipairs(attempts) do
        local ok = pcall(attempt)

        if ok then
            fired = true
            if not fireAll then
                return true
            end
        end
    end

    return fired
end

local function FireStopAudioRemote(remote)
    local attempts = GetAudioRemoteStopAttempts(remote)
    if not attempts then return false end

    local fired = false
    for _, attempt in ipairs(attempts) do
        if pcall(attempt) then
            fired = true
        end
    end

    return fired
end

local function PlaySongOnTool(tool, id)
    if not (tool and id) then return false end

    local playAudio = tool:FindFirstChild("PlayAudio", true)
    if playAudio and FireAudioRemote(playAudio, id, true, false) then
        return true
    end

    local remote = tool:FindFirstChild("Remote", true)
    if remote and FireAudioRemote(remote, id, false, false) then
        return true
    end

    return false
end

local function QueueAudioJob(jobs, tool, remote, id, preferPlayAudio)
    if not remote then return end

    table.insert(jobs, {
        remote = remote,
        id = id,
        preferPlayAudio = preferPlayAudio,
        isEvent = remote:IsA("RemoteEvent"),
        tool = tool,
    })
end

local function QueueStopAudioJob(jobs, tool, remote)
    if not remote then return end

    table.insert(jobs, {
        remote = remote,
        isEvent = remote:IsA("RemoteEvent"),
        tool = tool,
    })
end

local function CollectAudioJobs(toolsToPlay, id)
    local jobs = {}

    for _, tool in ipairs(toolsToPlay or {}) do
        local seen = {}
        local perToolJobs = 0
        local function add(remote, preferPlayAudio)
            if remote and not seen[remote] and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                seen[remote] = true
                perToolJobs += 1
                QueueAudioJob(jobs, tool, remote, id, preferPlayAudio)
            end
        end

        add(tool:FindFirstChild("PlayAudio", true), true)
        add(tool:FindFirstChild("Remote", true), false)

        for _, item in ipairs(tool:GetDescendants()) do
            if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
                local name = tostring(item.Name or ""):lower()
                add(item, name:find("playaudio", 1, true) ~= nil or name:find("audio", 1, true) ~= nil)
                if perToolJobs >= 3 then
                    break
                end
            end
        end
    end

    return jobs
end

local function CollectStopAudioJobs(toolsToStop)
    local jobs = {}

    for _, tool in ipairs(toolsToStop or {}) do
        local seen = {}
        local perToolJobs = 0
        local function add(remote)
            if remote and not seen[remote] and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                seen[remote] = true
                perToolJobs += 1
                QueueStopAudioJob(jobs, tool, remote)
            end
        end

        add(tool:FindFirstChild("StopAudio", true))
        add(tool:FindFirstChild("PlayAudio", true))
        add(tool:FindFirstChild("Remote", true))

        for _, item in ipairs(tool:GetDescendants()) do
            if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
                local name = tostring(item.Name or ""):lower()
                if name:find("stop", 1, true) or name:find("pause", 1, true) or name:find("audio", 1, true) or name:find("remote", 1, true) then
                    add(item)
                end

                if perToolJobs >= 3 then
                    break
                end
            end
        end
    end

    return jobs
end

local function PickTightAudioJobs(jobs)
    -- One tiny burst per tool: PlayAudio first, then Remote as a fallback.
    -- The old massplay used every payload attempt on every remote, which made
    -- later boomboxes start behind earlier ones.
    local pickedByTool = {}
    local ordered = {}

    for _, job in ipairs(jobs or {}) do
        if job.tool and job.remote then
            local picked = pickedByTool[job.tool]
            if not picked then
                picked = {Count = 0}
                pickedByTool[job.tool] = picked
            end

            local key = job.preferPlayAudio and "PlayAudio" or "Remote"
            if not picked[key] and picked.Count < 2 then
                picked[key] = true
                picked.Count += 1
                table.insert(ordered, job)
            end
        end
    end

    return ordered
end

local function FireSyncedAudioJobs(jobs)
    local success = 0
    local firedTools = {}
    local pending = 0

    -- Tight mode: fire only the primary payloads in one burst. This removes
    -- the old per-remote all-attempt spam that caused audible stagger.
    for _, job in ipairs(PickTightAudioJobs(jobs)) do
        local attempt = GetPrimaryAudioRemoteAttempt(job.remote, job.id, job.preferPlayAudio)

        if attempt then
            if job.isEvent then
                if pcall(attempt) then
                    firedTools[job.tool] = true
                end
            else
                pending += 1
                ZorSpawn(function()
                    if pcall(attempt) then
                        firedTools[job.tool] = true
                    end
                    pending -= 1
                end)
            end
        end
    end

    -- RemoteFunctions can yield. Do not let one slow function drag the whole
    -- massplay behind the RemoteEvent boomboxes.
    local started = tick()
    while pending > 0 and tick() - started < 0.18 do
        RunService.Heartbeat:Wait()
    end

    for _ in pairs(firedTools) do
        success += 1
    end

    return success
end

local function FireSyncedAudioJobsOnce(jobs)
    local bestByTool = {}
    local ordered = {}

    for _, job in ipairs(jobs or {}) do
        if job.tool and not bestByTool[job.tool] then
            bestByTool[job.tool] = job
            table.insert(ordered, job)
        elseif job.tool and job.preferPlayAudio and bestByTool[job.tool] and not bestByTool[job.tool].preferPlayAudio then
            bestByTool[job.tool] = job
            for i, existing in ipairs(ordered) do
                if existing.tool == job.tool then
                    ordered[i] = job
                    break
                end
            end
        end
    end

    RunService.Heartbeat:Wait()

    local success = 0
    local pending = 0

    for _, job in ipairs(ordered) do
        local attempt = GetPrimaryAudioRemoteAttempt(job.remote, job.id, job.preferPlayAudio)
        if attempt then
            if job.isEvent then
                if pcall(attempt) then
                    success += 1
                end
            else
                pending += 1
                ZorSpawn(function()
                    if pcall(attempt) then
                        success += 1
                    end
                    pending -= 1
                end)
            end
        end
    end

    local started = tick()
    while pending > 0 and tick() - started < 1 do
        RunService.Heartbeat:Wait()
    end

    return success
end

local function FireStopAudioJobs(jobs)
    for _, job in ipairs(jobs or {}) do
        if job.isEvent then
            FireStopAudioRemote(job.remote)
        end
    end

    for _, job in ipairs(jobs or {}) do
        if not job.isEvent then
            ZorSpawn(function()
                FireStopAudioRemote(job.remote)
            end)
        end
    end
end

local function SyncClientBoomboxSounds(toolsToPlay, id, startAt, tightFrames)
    local decodedId = id and DecodeAudioIdForSound(id) or nil
    local soundId = decodedId and decodedId ~= "" and ("rbxassetid://" .. decodedId) or nil
    local basePosition = tonumber(startAt) or 0
    local startedClock = os.clock()
    local syncedSounds = {}
    local synced = 0

    local function syncSound(sound, targetPosition)
        if not (sound and sound.Parent) then return end

        if not syncedSounds[sound] then
            syncedSounds[sound] = true
            synced += 1
        end

        pcall(function()
            if soundId and sound.SoundId ~= soundId then
                sound.SoundId = soundId
            end

            if not sound.IsPlaying then
                sound.TimePosition = targetPosition
                sound:Play()
            elseif math.abs((tonumber(sound.TimePosition) or 0) - targetPosition) > 0.025 then
                sound.TimePosition = targetPosition
            end

            sound.Playing = true
        end)
    end

    -- Immediate first pass, then a very short lock window. New Sound objects
    -- sometimes replicate a few frames late, so this catches them without the
    -- old 0.7s delay/snap.
    local frames = math.clamp(tonumber(tightFrames) or 14, 1, 24)
    for frame = 1, frames do
        local targetPosition = basePosition + (os.clock() - startedClock)

        for _, sound in ipairs(CollectBoomboxSounds(toolsToPlay)) do
            syncSound(sound, targetPosition)
        end

        if frame < frames then
            RunService.Heartbeat:Wait()
        end
    end

    currentTimePosition = basePosition + (os.clock() - startedClock)
    return synced
end

local function StopClientBoomboxSounds(toolsToStop)
    for _, tool in ipairs(toolsToStop or {}) do
        for _, item in ipairs(tool:GetDescendants()) do
            if item:IsA("Sound") then
                pcall(function()
                    item:Stop()
                    item.TimePosition = 0
                end)
            end
        end
    end
end

local function DisconnectMassplayStopWatcher(tool)
    local connection = MassplayStopConnections[tool]
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
        MassplayStopConnections[tool] = nil
    end
end

local function StopBoomboxTools(toolsToStop)
    if not toolsToStop or #toolsToStop == 0 then return end

    StopClientBoomboxSounds(toolsToStop)
    FireStopAudioJobs(CollectStopAudioJobs(toolsToStop))

    for _, tool in ipairs(toolsToStop) do
        MassplayTrackedTools[tool] = nil
        DisconnectMassplayStopWatcher(tool)
    end
end

local function WatchMassplayToolStop(tool)
    if not tool then return end

    DisconnectMassplayStopWatcher(tool)
    MassplayTrackedTools[tool] = true

    local connections = {}
    local function disconnectAll()
        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    local function checkStopped()
        ZorSpawn(function()
            RunService.Heartbeat:Wait()
            local character = player.Character

            if MassplayTrackedTools[tool] and (not character or tool.Parent ~= character) then
                StopBoomboxTools({tool})
            end
        end)
    end

    pcall(function()
        table.insert(connections, tool.Unequipped:Connect(checkStopped))
    end)
    table.insert(connections, tool.AncestryChanged:Connect(checkStopped))

    MassplayStopConnections[tool] = {
        Disconnect = disconnectAll,
    }
end

local function EquipBoomboxBatch(toolsToEquip)
    local character = getCharacter()
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character then return {} end

    for _, tool in ipairs(toolsToEquip or {}) do
        if tool and tool.Parent then
            pcall(function()
                if humanoid then
                    humanoid:EquipTool(tool)
                end
            end)
            pcall(function()
                tool.Parent = character
            end)
        end
    end

    RunService.Heartbeat:Wait()
    RunService.Heartbeat:Wait()

    local equipped = {}
    local seen = {}
    for _, tool in ipairs(toolsToEquip or {}) do
        if tool and tool.Parent and not seen[tool] then
            seen[tool] = true
            if tool.Parent ~= character then
                pcall(function()
                    tool.Parent = character
                end)
            end

            if tool.Parent == character and IsBoomboxTool(tool) then
                table.insert(equipped, tool)
                WatchMassplayToolStop(tool)
            end
        end
    end

    return equipped
end

local function RefreshVisualizerToolSounds(_toolsToPlay)
    -- Z0R updates its visualizer-tracked sound cache here. Hash's visualizer
    -- keeps its own private cache, so this stays a no-op in the transplant.
end

local function PlayBoomboxToolsSynced(toolsToPlay, id, keepAlreadyEquipped, useAntiLog, startAt)
    local rawId = DecodeAudioIdForSound(id)
    if not rawId or tostring(rawId) == "" then
        return 0
    end

    local remoteId = useAntiLog and EncodeZorAntiLogAudioId(rawId) or rawId

    if keepAlreadyEquipped then
        local character = player.Character
        local equippedOnly = {}
        for _, tool in ipairs(toolsToPlay or {}) do
            if tool and tool.Parent == character and IsBoomboxTool(tool) then
                table.insert(equippedOnly, tool)
                WatchMassplayToolStop(tool)
            end
        end
        toolsToPlay = equippedOnly
    else
        toolsToPlay = EquipBoomboxBatch(toolsToPlay)
    end

    -- Single pre-activate pass only. The old double activate + two heartbeat
    -- waits was the main source of delayed starts.
    for _, tool in ipairs(toolsToPlay) do
        pcall(function()
            tool:Activate()
        end)
    end

    local audioJobs = CollectAudioJobs(toolsToPlay, remoteId)
    local fired = useAntiLog and FireSyncedAudioJobsOnce(audioJobs) or FireSyncedAudioJobs(audioJobs)

    SyncClientBoomboxSounds(toolsToPlay, rawId, tonumber(startAt) or 0, 16)
    RefreshVisualizerToolSounds(toolsToPlay)
    lastMassTools = toolsToPlay
    return fired
end

local function syncAudio()
    local tools = lastMassTools or collectBoomboxes()
    local synced = SyncClientBoomboxSounds(tools, nil, tonumber(timePosition) or 0, 3)

    if synced == 0 then
        local character = player.Character
        if character then
            for _, item in pairs(character:GetDescendants()) do
                if item:IsA("Sound") and item.Playing then
                    pcall(function()
                        item.TimePosition = tonumber(timePosition) or 0
                    end)
                    synced += 1
                end
            end
        end
    end

    currentTimePosition = tonumber(timePosition) or 0
    return synced
end

local function collectBoomboxHubRadios(useAllTools)
    -- Zero-delay version: do NOT unequip first and do NOT wait a heartbeat.
    -- The old BoomboxHub-style unequip/re-equip path is what made massplay
    -- feel about a second late compared to firing Character remotes directly.
    local radios, seen = {}, {}
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")

    local function add(tool)
        if not (tool and tool:IsA("Tool") and not seen[tool]) then return end
        if not GetToolHandle(tool) then return end

        if useAllTools or IsBoomboxTool(tool) or isBoombox(tool) then
            seen[tool] = true
            table.insert(radios, tool)
        end
    end

    -- Character first = already-visualized/equipped boomboxes fire instantly.
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            add(tool)
        end
    end

    -- Backpack second = only used when something is not already equipped.
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            add(tool)
        end
    end

    return radios
end

local function DirectCharacterRemoteMassplay(rawId, selectedTools)
    -- This is the fast path based on the tiny loop:
    -- for every RemoteEvent in Character, FireServer("PlaySong", id)
    -- No equip heartbeat, no delayed sound correction, no fallback spam.
    local character = player.Character
    if not character then return 0 end

    local idValue = tonumber(rawId) or rawId
    local remotes, seen = {}, {}

    local function addRemote(remote)
        if remote and remote:IsA("RemoteEvent") and not seen[remote] then
            seen[remote] = true
            table.insert(remotes, remote)
        end
    end

    -- Exact user-style pass: every RemoteEvent under Character.
    for _, item in ipairs(character:GetDescendants()) do
        addRemote(item)
    end

    -- Extra safety for tools that were just parented to Character but did not
    -- appear in GetDescendants() yet in weird executors/frames.
    for _, tool in ipairs(selectedTools or {}) do
        if tool and tool.Parent == character then
            for _, item in ipairs(tool:GetDescendants()) do
                addRemote(item)
            end
        end
    end

    local fired = 0
    for _, remote in ipairs(remotes) do
        if pcall(function()
            remote:FireServer("PlaySong", idValue)
        end) then
            fired += 1
        end
    end

    return fired
end

local function moveRadiosToBackpackKeepingSound(radios)
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not (character and backpack) then return end

    local connections = {}

    for _, radio in ipairs(radios or {}) do
        for _, item in ipairs(radio:GetDescendants()) do
            if item:IsA("Sound") then
                table.insert(connections, item:GetPropertyChangedSignal("Playing"):Connect(function()
                    if not item.Playing then
                        pcall(function()
                            item.Playing = true
                        end)
                    end
                end))
            end
        end

        pcall(function()
            radio.Parent = backpack
        end)
    end

    task.wait(0.6)

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    local equippedConnection
    equippedConnection = character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            if equippedConnection then
                equippedConnection:Disconnect()
            end

            RunService.Heartbeat:Wait()

            for _, radio in ipairs(radios or {}) do
                for _, item in ipairs(radio:GetDescendants()) do
                    if item:IsA("Sound") then
                        pcall(function()
                            item:Stop()
                        end)
                    end
                end
            end
        end
    end)

    local respawnConnection
    respawnConnection = player.CharacterAdded:Connect(function()
        if equippedConnection then equippedConnection:Disconnect() end
        if respawnConnection then respawnConnection:Disconnect() end
    end)
end

local function playRadiosBoomboxHubV3(id, playType, startAt)
    if massPlaying then
        notify("Mass play is already running", "Hash audio")
        return
    end

    local rawId = DecodeAudioIdForSound(id)
    if not rawId or rawId == "" or rawId == "0" then
        notify("Enter an audio ID", "Hash audio")
        return
    end

    playType = tostring(playType or "Mass")
    startAt = tonumber(startAt)

    massPlaying = true
    local ok, err = pcall(function()
        local character = getCharacter()
        if not character then return end

        local radios = collectBoomboxHubRadios(false)
        if #radios < 1 then
            notify("No compatible radios found", "Hash audio")
            return
        end

        local selected = {}
        for index, radio in ipairs(radios) do
            if index == 1 or playType == "Mass" or playType == "Backpack" then
                table.insert(selected, radio)

                -- Parent instantly. Do not call Humanoid:EquipTool and do not
                -- wait a heartbeat before firing; this keeps the same timing as
                -- the raw Character:GetDescendants() remote loop.
                if radio.Parent ~= character then
                    pcall(function()
                        radio.Parent = character
                    end)
                end
                WatchMassplayToolStop(radio)
            end

            if playType == "Normal" then
                break
            end
        end

        timePosition = startAt or 0
        lastMassTools = selected

        local fired = DirectCharacterRemoteMassplay(rawId, selected)

        if playType == "Backpack" then
            -- Backpack play is the only mode that still needs to move tools
            -- after firing. The move happens AFTER the instant remote burst.
            task.spawn(function()
                moveRadiosToBackpackKeepingSound(selected)
            end)
        end

        notify(("%s instant-fired %d remotes"):format(playType, fired), "Hash audio")
    end)

    if not ok then
        warn("Hash BoomboxHubV3 massplay failed: " .. tostring(err))
        notify("Mass play failed", "Hash audio")
    end

    massPlaying = false
end

local function massPlay(id, playType, startAt)
    return playRadiosBoomboxHubV3(id, playType or "Mass", startAt)
end

-- Tools ----------------------------------------------------------------------

local loopGrab = false
local dupeRunning = false
local cancelDupe = false

local function grabOnce()
    local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0 end
    local count = 0
    for _, tool in ipairs(workspace:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function() humanoid:EquipTool(tool) end)
            count += 1
        end
    end
    return count
end

connect(RunService.Heartbeat, function()
    if loopGrab then grabOnce() end
end)

local function collectOwnedTools()
    local tools, seen = {}, {}
    for _, container in ipairs({player.Character, player:FindFirstChildOfClass("Backpack")}) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and not seen[tool] then
                    seen[tool] = true
                    table.insert(tools, tool)
                end
            end
        end
    end
    return tools
end

local function dupeTools(amount)
    if dupeRunning then
        cancelDupe = true
        return
    end
    amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 75)
    dupeRunning = true
    cancelDupe = false

    task.spawn(function()
        for cycle = 1, amount do
            if cancelDupe then break end
            local character = getCharacter()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local root = character:FindFirstChild("HumanoidRootPart")
            local backpack = player:FindFirstChildOfClass("Backpack")
            local tools = collectOwnedTools()
            if not humanoid or not root or not backpack or #tools == 0 then break end

            Visualizer.Stop()
            local returnCFrame = root.CFrame
            for _, tool in ipairs(tools) do
                pcall(function()
                    tool.Parent = workspace
                    local handle = tool:FindFirstChild("Handle")
                    if handle then handle.CFrame = returnCFrame * CFrame.new(0, 1.5, 0) end
                end)
            end

            task.wait(0.62)
            humanoid.Health = 0
            local oldCharacter = character
            local deadline = os.clock() + math.max((Players.RespawnTime or 5) + 5, 7)
            repeat
                RunService.Heartbeat:Wait()
            until (player.Character and player.Character ~= oldCharacter)
                or os.clock() >= deadline

            local newCharacter = player.Character
            if not newCharacter or newCharacter == oldCharacter then break end
            local newRoot = newCharacter:WaitForChild("HumanoidRootPart", 5)
            local newHumanoid = newCharacter:WaitForChild("Humanoid", 5)
            backpack = player:WaitForChild("Backpack", 5)
            task.wait(0.32)
            if newRoot then newRoot.CFrame = returnCFrame end
            for _, tool in ipairs(tools) do
                if tool.Parent == workspace then
                    pcall(function()
                        tool.Parent = backpack
                        newHumanoid:EquipTool(tool)
                    end)
                end
            end
            notify(("Dupe pass %d/%d"):format(cycle, amount), "Hash tools")
            task.wait(0.42)
        end
        dupeRunning = false
        cancelDupe = false
    end)
end

local function serverDemesh()
    local remote = ReplicatedStorage:FindFirstChild("HashBoomboxDemesh")
    if not remote then
        notify("Server demesh endpoint missing", "Hash tools")
        return
    end
    remote:FireServer(collectBoomboxes())
end

-- UI -------------------------------------------------------------------------

local interface = GuiLibrary.Load("ui")
local footer = player.Name .. " | " .. os.date("%m/%d/%Y")
local window = interface:Start({
    Header = "hash [v2.4]",
    Footer = footer,
    VisibleKeybind = Enum.KeyCode.RightAlt,
})
Hash.Interface = window

function Hash.Destroy()
    if not Hash.Running then return end
    Hash.Running = false
    pcall(Visualizer.Destroy)
    for _, connection in ipairs(Hash.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Hash.Connections)
    pcall(window.Destroy)
    if global.HashHub == Hash then global.HashHub = nil end
end

local audioId = ""
local dupeAmount = 1
local selectedLoggerTarget = player.Name
local presetNames = Visualizer.GetPresetNames()
local selectedPreset = table.find(presetNames, "circle") and "circle"
    or table.find(presetNames, "circle") and "circle"
    or presetNames[1]
Visualizer.SetPreset(selectedPreset)

local mainPage = window:CreatePage({Subject = "main", Footer = footer})
local antiLoggerPage = window:CreatePage({Subject = "anti-logger", Footer = footer})
local visualizerPage = window:CreatePage({Subject = "visualizer", Footer = footer})
local miscellaneousPage = window:CreatePage({Subject = "miscellaneous", Footer = footer})
local settingsPage = window:CreatePage({Subject = "settings", Footer = footer})

local play = mainPage:CreateSection({Header = "play"})
play:CreateTextBox({Text = "id", PlaceHolder = "id", Pattern = "number", Script = safe(function(v)
    audioId = extractId(v) or ""
end)})
play:CreateButton({Text = "play", Script = safe(function() massPlay(audioId, "Normal", timePosition) end)})
play:CreateButton({Text = "mass play", Script = safe(function() massPlay(audioId, "Mass", timePosition) end)})
play:CreateButton({Text = "backpack play", Script = safe(function() massPlay(audioId, "Backpack", timePosition) end)})

local audio = mainPage:CreateSection({Header = "audio"})
audio:CreateButton({Text = "sync", Script = safe(function()
    notify("Zero-synced " .. syncAudio() .. " sounds", "Hash audio")
end)})
audio:CreateButton({Text = "re-sync", Script = safe(function()
    notify("Zero-synced " .. syncAudio() .. " sounds", "Hash audio")
end)})
audio:CreateTextBox({Text = "time position", PlaceHolder = "0", Pattern = "number", Script = safe(function(v)
    timePosition = tonumber(v) or 0
end)})

local grip = mainPage:CreateSection({Header = "grip position"})
grip:CreateButton({Text = "set", Script = safe(function()
    applyGripMode(global.HashGrip or "regular")
end)})

local gripDropdown
local function createGripDropdown()
    local options = getGripDropdownOptions()

    gripDropdown = grip:CreateDropdown({
        Text = "grip",
        Default = global.HashGrip or "regular",
        Options = options,
        Script = safe(function(value)
            global.HashGrip = value
            applyGripMode(value)
        end),
    })

    return gripDropdown
end

createGripDropdown()

grip:CreateButton({Text = "refresh .gpreset", Script = safe(function()
    local options = refreshGripPresets()

    if gripDropdown then
        -- Different UI-library versions use different update names, so try all
        -- the common ones first.
        local updated = false

        for _, methodName in ipairs({"Refresh", "Update", "update"}) do
            if gripDropdown[methodName] then
                local ok = pcall(function()
                    gripDropdown[methodName](gripDropdown, options)
                end)
                updated = updated or ok
            end
        end

        if not updated then
            for _, name in ipairs(options) do
                pcall(function()
                    gripDropdown.AddOption(name)
                end)
            end
        end
    else
        createGripDropdown()
    end

    notify("Loaded " .. tostring(#getGripPresetNames()) .. " .gpreset grip presets", "Hash grip")
end)})

local anti = antiLoggerPage:CreateSection({Header = "anti-logger settings"})
anti:CreateTextBox({Text = "custom text", PlaceHolder = "custom text", Script = safe(function(v)
    global.HashAntilogText = v
end)})
anti:CreateLabel({Text = "file decoder"})
anti:CreateLabel({Text = "put file inside Hash/decoder,"})
anti:CreateLabel({Text = "enter file name and extension;"})
anti:CreateLabel({Text = "example: text.txt"})
anti:CreateTextBox({Text = "textbox", PlaceHolder = "file.txt", Script = safe(function(v)
    global.HashDecoderFile = v
end)})
anti:CreateButton({Text = "decode file", Script = safe(function()
    notify("No decoder installed", "Hash anti-logger")
end)})

local function usernames()
    local names = {}
    for _, serverPlayer in ipairs(Players:GetPlayers()) do
        table.insert(names, serverPlayer.Name)
    end
    table.sort(names)
    return names
end

local logger = antiLoggerPage:CreateSection({Header = "logger"})
logger:CreateButton({Text = "log audio", Script = safe(function()
    local target = Players:FindFirstChild(selectedLoggerTarget)
    local character = target and target.Character
    if not character then return end
    for _, sound in ipairs(character:GetDescendants()) do
        if sound:IsA("Sound") and sound.IsPlaying then
            print(target.Name, sound.SoundId)
        end
    end
end)})
local targetDropdown = logger:CreateDropdown({
    Text = "target",
    Default = selectedLoggerTarget,
    Options = usernames(),
    Script = safe(function(value) selectedLoggerTarget = value end),
})
connect(Players.PlayerAdded, function(joined)
    targetDropdown.AddOption(joined.Name)
end)
connect(Players.PlayerRemoving, function(leaving)
    targetDropdown.RemoveOption(leaving.Name)
end)

local viz = visualizerPage:CreateSection({Header = "visualizer"})
viz:CreateButton({Text = "visualize", Script = safe(function()
    Visualizer.SetPreset(selectedPreset)

    if visualizerRunning then
        syncAudio()
    else
        Visualizer.Start()
    end
end)})
viz:CreateTextBox({Text = "target", PlaceHolder = player.Name, Script = safe(function(v)
    Visualizer.SetTargetPlayer(v)
end)})
viz:CreateButton({Text = "sync", Script = safe(function()
    notify("Zero-synced " .. syncAudio() .. " sounds", "Hash audio")
end)})
viz:CreateButton({Text = "re-sync", Script = safe(function()
    notify("Zero-synced " .. syncAudio() .. " sounds", "Hash audio")
end)})
viz:CreateTextBox({Text = "time position", PlaceHolder = "0", Pattern = "number", Script = safe(function(v)
    timePosition = tonumber(v) or 0
end)})

local vizSettings = visualizerPage:CreateSection({Header = "settings"})
vizSettings:CreateToggle({Text = "reverse rotation", Script = safe(Visualizer.SetReverseRotation)})
vizSettings:CreateToggle({Text = "auto tilt", Script = safe(Visualizer.SetAutoTilt)})
vizSettings:CreateSlider({Text = "tilt", Suffix = "°", Values = {Minimum = -45, Maximum = 45, Default = 18}, Script = safe(Visualizer.SetTilt)})
vizSettings:CreateSlider({Text = "distance", Suffix = " studs", Values = {Minimum = 1, Maximum = 15, Default = 5}, Script = safe(Visualizer.SetSize)})
vizSettings:CreateSlider({Text = "sensitivity", Suffix = "%", Values = {Minimum = 1, Maximum = 200, Default = 65}, Script = safe(Visualizer.SetVisualizerSensitivity)})
vizSettings:CreateSlider({Text = "speed", Suffix = " units", Values = {Minimum = 1, Maximum = 10, Default = 3}, Script = safe(Visualizer.SetSpeed)})
vizSettings:CreateDropdown({Text = "preset", Default = selectedPreset, Options = presetNames, Script = safe(function(v)
    selectedPreset = v
    Visualizer.SetPreset(v)
end)})

local mute = miscellaneousPage:CreateSection({Header = "mute"})
mute:CreateDropdown({Text = "target", Default = "all", Options = {"all", player.Name}, Script = safe(function() end)})
mute:CreateButton({Text = "mute", Script = safe(function()
    for _, sound in ipairs(workspace:GetDescendants()) do
        if sound:IsA("Sound") then sound.Volume = 0 end
    end
end)})

local misc = miscellaneousPage:CreateSection({Header = "misc"})
misc:CreateButton({Text = "demesh tools", Script = safe(serverDemesh)})
misc:CreateButton({Text = "remove boombox gui", Script = safe(Hash.Destroy)})

local dupe = miscellaneousPage:CreateSection({Header = "dupe tools"})
dupe:CreateTextBox({Text = "amount", PlaceHolder = "1", Pattern = "number", Script = safe(function(v)
    dupeAmount = tonumber(v) or 1
end)})
dupe:CreateDropdown({Text = "mode", Default = "normal", Options = {"normal"}, Script = safe(function() end)})
dupe:CreateButton({Text = "dupe", Script = safe(function() dupeTools(dupeAmount) end)})

local grab = miscellaneousPage:CreateSection({Header = "grab tools"})
grab:CreateToggle({Text = "loop grab", Script = safe(function(v) loopGrab = v end)})
grab:CreateButton({Text = "grab once", Script = safe(function()
    notify("Grabbed " .. grabOnce() .. " tools", "Hash")
end)})

local presets = settingsPage:CreateSection({Header = "presets"})
presets:CreateDropdown({Text = "active preset", Default = selectedPreset, Options = presetNames, Script = safe(function(v)
    selectedPreset = v
    Visualizer.SetPreset(v)
end)})
presets:CreateButton({Text = "refresh preset list", Script = safe(function()
    Visualizer.RefreshCustomPresets()
    notify("Hash preset list refreshed", "Hash")
end)})

local settings = settingsPage:CreateSection({Header = "settings"})
settings:CreateToggle({Text = "audio reactive", Script = safe(Visualizer.SetAudioReactive)})
settings:CreateSlider({Text = "height", Suffix = " studs", Values = {Minimum = 0, Maximum = 20, Default = 2}, Script = safe(Visualizer.SetHeight)})
settings:CreateButton({Text = "stop visualizer", Script = safe(Visualizer.Stop)})
settings:CreateButton({Text = "destroy gui", Script = safe(Hash.Destroy)})

notify("made by bbungiee & i_db")
wait(1)
notify("thx for purchasing")
return Hash
