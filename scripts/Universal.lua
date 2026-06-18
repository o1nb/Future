repeat wait() until game:IsLoaded()
local Future = shared.Future
local GuiLibrary = Future.GuiLibrary
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local WORKSPACE = game:GetService("Workspace")
local PLAYERS = game:GetService("Players")
local COREGUI = game:GetService("CoreGui")
local HTTPSERVICE = game:GetService("HttpService")
local lplr = PLAYERS.LocalPlayer
local mouse = lplr:GetMouse()
local cam = WORKSPACE.CurrentCamera
local getcustomasset = --[[getsynasset or getcustomasset or]] GuiLibrary["getRobloxAsset"]
local requestfunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or getgenv().request or request
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local getgenv = getgenv or function() 
    return _G
end
local spawn = function(func) 
    return coroutine.wrap(func)()
end
local betterisfile = function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil
end

spawn(function() 
    pcall(function() 
        if getconnections then 

            repeat -- turn off connections every 5s

                for i,v in pairs(getconnections(game:GetService("ScriptContext").Error)) do
                    v:Disable()
                end

                task.wait(5)

            until not shared.Future

            for i,v in pairs(getconnections(game:GetService("ScriptContext").Error)) do
                v:Enable() -- enable connections since future is not injected, thus we dont care.
            end

        end
    end)
end)

local function requesturl(url, bypass) 
    if betterisfile(url) and shared.FutureDeveloper then 
        return readfile(url)
    end
    local repourl = bypass and "https://raw.githubusercontent.com/joeengo/" or "https://raw.githubusercontent.com/joeengo/Future/main/"
    local url = url:gsub("Future/", "")
    local req = requestfunc({
        Url = repourl..url,
        Method = "GET"
    })
    if req.StatusCode == 404 then error("404 Not Found") end
    return req.Body
end 

local function getasset(path)
	if not betterisfile(path) then
		local req = requestfunc({
			Url = "https://raw.githubusercontent.com/joeengo/Future/main/"..path:gsub("Future/assets", "assets"),
			Method = "GET"
		})
        print("[Future] downloading "..path.." asset.")
		writefile(path, req.Body)
        repeat task.wait() until betterisfile(path)
        print("[Future] downloaded "..path.." asset successfully!")
	end
	return getcustomasset(path) 
end

local SwearDetection = loadstring(requesturl("Future/lib/swear-detection.lua"))()
local HeartbeatTable = {}
local RenderStepTable = {}
local SteppedTable = {}
local function isAlive(plr, headCheck)
    local plr = plr or lplr
    if plr and plr.Character and ((plr.Character:FindFirstChildOfClass("Humanoid")) and (plr.Character:FindFirstChild("HumanoidRootPart")) and (headCheck and plr.Character:FindFirstChild("Head") or not headCheck)) then
        return true
    end
end

local function skipFrame() 
    return game:GetService("RunService").Heartbeat:Wait()
end

local function BindToHeartbeat(name, func)
    if HeartbeatTable[name] == nil then
        HeartbeatTable[name] = game:GetService("RunService").Heartbeat:connect(func)
    end
end
local function UnbindFromHeartbeat(name)
    if HeartbeatTable[name] then
        HeartbeatTable[name]:Disconnect()
        HeartbeatTable[name] = nil
    end
end
local function BindToRenderStepped(name, func)
	if RenderStepTable[name] == nil then
		RenderStepTable[name] = game:GetService("RunService").RenderStepped:connect(func)
	end
end
local function UnbindFromRenderStepped(name)
	if RenderStepTable[name] then
		RenderStepTable[name]:Disconnect()
		RenderStepTable[name] = nil
	end
end
local function BindToStepped(name, func)
	if SteppedTable[name] == nil then
		SteppedTable[name] = game:GetService("RunService").Stepped:connect(func)
	end
end
local function UnbindFromStepped(name)
	if SteppedTable[name] then
		SteppedTable[name]:Disconnect()
		SteppedTable[name] = nil
	end
end

local function ferror(...)
    local args ={...}
    local str=""
    for i,v in next,args do 
        str=str.." "..tostring(v)
    end
    GuiLibrary["CreateNotification"]("<font color='rgb(255, 10, 10)'>[ERROR]"..str.."</font>")
    error("[Future]"..str)
end

local function fwarn(...)
    local args ={...}
    local str=""
    for i,v in next,args do 
        str=str.." "..tostring(v)
    end
    warn("[Future]"..str)
    GuiLibrary["CreateNotification"]("<font color='rgb(255, 255, 10)'>[WARNING] "..str.."</font>")
end

local function fprint(...)
    local args ={...}
    local str=""
    for i,v in next,args do 
        str=str.." "..tostring(v)
    end
    print("[Future]"..str)
    GuiLibrary["CreateNotification"]("<font color='rgb(200, 200, 200)'>"..str.."</font>")
end

setreadonly(getgenv().table, false)
local table_combine = function(...) 
    local args = {...}
    local MasterTable = {}
    for i,v in next, args do 
        if type(v) == "table" then 
            for i2,v2 in next, v do 
                table.insert(MasterTable, v2)
            end
        else
            table.insert(MasterTable, v)
        end
    end

    return MasterTable
end

local function getCharacters() 
    local t = {}
    for i,v in next, PLAYERS:GetPlayers() do 
        if isAlive(v) then
            t[v.Name] = v.Character
        end
    end
    return t
end

local function getColorFromPlayer(v) 
    if v.Team ~= nil then return v.TeamColor.Color end
end

local function getPlrNearMouse(max)
    local max = max or 99999999999999
    local nearestval, nearestnum = nil,max
    for i,v in next, PLAYERS:GetPlayers() do 
        if isAlive(v) and v~=lplr then 
            local pos, vis = WORKSPACE.CurrentCamera:WorldToScreenPoint(v.Character.HumanoidRootPart.Position)
            if vis and pos then 
                local diff = (UIS:GetMouseLocation() - Vector2.new(pos.X, pos.Y)).Magnitude
                if diff < nearestnum then 
                    nearestnum = diff 
                    nearestval = v
                end
            end
        end
    end
    return nearestval
end

local function getAimAt(pos)
    return WORKSPACE.CurrentCamera:WorldToScreenPoint(pos)
end

local function aimAt(pos,smooth)
    local smooth = smooth +1
    local targetPos = WORKSPACE.CurrentCamera:WorldToScreenPoint(pos)
    local mousePos = WORKSPACE.CurrentCamera:WorldToScreenPoint(mouse.Hit.p)
    mousemoverel((targetPos.X-mousePos.X)/smooth,(targetPos.Y-mousePos.Y)/smooth)
end

local function canBeTargeted(plr, doTeamCheck) 
    return Future.canBeTargeted(plr)
end

local function colorToRichText(color) 
    return " rgb("..tostring(color.R*255)..", "..tostring(color.G*255)..", "..tostring(color.B*255)..")"
end

local convertHealthToColor = function(health, maxHealth) 
    local percent = (health/maxHealth) * 100
    if percent < 70 then 
        return Color3.fromRGB(255, 196, 0)
    elseif percent < 45 then
        return Color3.fromRGB(255, 71, 71)
    end
    return Color3.fromRGB(96, 253, 48)
end

local function table_invert(t) 
    local new = {}
    for i,v in next, t do 
        new[tostring(v)] = i
    end
    return new
end

do 
    Future.AddCommand("vclip", {
        Function = function(args) 
            if not args[1] or not tonumber(args[1]) then 
                return
            end

            if not isAlive() then
                return
            end

            local distance = tonumber(args[1])
            lplr.Character.HumanoidRootPart.CFrame = lplr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -distance)
        end,
        Help = ".vclip <distance>"
    })
    Future.AddCommand("hclip", {
        Function = function(args) 
            if not args[1] or not tonumber(args[1]) then 
                return
            end

            if not isAlive() then
                return
            end

            local distance = tonumber(args[1])
            lplr.Character.HumanoidRootPart.CFrame = lplr.Character.HumanoidRootPart.CFrame * CFrame.new(0, distance, 0)
        end,
        Help = ".hclip <distance>"
    })
end


-- // CombatWindow

do 
    local smoothaim = {["Enabled"] = false}
    local smoothaimfov = {["Value"] = 40 }
    local smoothaimsmoothness = {["Value"] = 0}
    local smoothaimpart = {["Value"] ="Root"}
    local smoothaimheld = {["Value"] = "LMB"}

    smoothaim = GuiLibrary["Objects"]["CombatWindow"]["API"].CreateOptionsButton({
        ["Name"] = "SmoothAim",
        ["Function"] = function(callback) 
            if callback then 
                BindToStepped("SmoothAim", function() 
                    local aimpart = smoothaimpart["Value"] == "Root" and "HumanoidRootPart" or "Head"
                    local plr = getPlrNearMouse(smoothaimfov["Value"] * 10)
                    if plr and canBeTargeted(plr, true) and UIS:IsMouseButtonPressed(smoothaimheld["Value"] == "LMB" and 0 or 1) then 
                        aimAt(plr.Character[aimpart].Position, smoothaimsmoothness["Value"])
                    end
                end)
            else
                UnbindFromStepped("SmoothAim")
            end
        end
    })
    smoothaimpart = smoothaim.CreateSelector({
        ["Name"] = "Part",
        ["Function"] = function() end, 
        ["List"] = {"Root", "Head"}
    })
    smoothaimheld = smoothaim.CreateSelector({
        ["Name"] = "Held",
        ["Function"] = function() end, 
        ["List"] = {"LMB", "RMB"}
    })
    smoothaimsmoothness = smoothaim.CreateSlider({
        ["Name"] = "Smoothness",
        ["Function"] = function(value) end,
        ["Min"] = 1,
        ["Max"] = 50,
        ["Round"] = 0,
    })
    smoothaimfov = smoothaim.CreateSlider({
        ["Name"] = "FOV",
        ["Function"] = function() end,
        ["Min"] = 1,
        ["Max"] = 100,
        ["Round"] = 0,
    })
end

-- // ExploitsWindow

do 
    local phase = {["Enabled"] = false}
    local phasemode = {["Value"] = ""}
    local phaseconnection 
    local cachedparts = {}

    phase = GuiLibrary["Objects"]["ExploitsWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Phase",
        ["Function"] = function(callback) 
            if callback then 
                BindToStepped("Phase", function()
                    if phasemode["Value"] == "Normal" then
                        if isAlive() then
                            for i,v in next, lplr.Character:GetDescendants() do 
                                if v:IsA("BasePart") and v.CanCollide then 
                                    cachedparts[v] = v
                                    v.CanCollide = false
                                end
                            end
                        end
                    end
                end)
            else
                for i,v in next, cachedparts do 
                    v.CanCollide = true
                end
                cachedparts = {}
                UnbindFromStepped("Phase")
            end
        end,
    })
    phasemode = phase.CreateSelector({
        ["Name"] = "Mode",
        ["Function"] = function()
            if phase.Enabled then
                phase.Toggle()
                phase.Toggle()
            end
        end,
        ["List"] = {"Normal"}
    })
end

do
    local fakelagsend = {["Enabled"] = false}
    local fakelagreceive = {["Enabled"] = false}
    local fakelag = GuiLibrary["Objects"]["MovementWindow"]["API"].CreateOptionsButton({
        ["Name"] = "FakeLag",
        ["Function"] = function(callback) 
            if callback then
                if fakelagsend["Enabled"] then 
                    BindToHeartbeat("SendFakeLag", function() 
                        if isAlive() then
                            sethiddenproperty(lplr.Character.HumanoidRootPart, "NetworkIsSleeping", true)
                            --game:GetService("NetworkClient"):SetOutgoingKBPSLimit(1)
                        end
                    end)
                end
                if fakelagreceive["Enabled"] then 
                    settings().Network.IncomingReplicationLag = 99999999999999999
                end
            else
                game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
                settings().Network.IncomingReplicationLag = 0
                UnbindFromHeartbeat("SendFakeLag")
            end
        end,
    })
    fakelagsend = fakelag.CreateToggle({
        ["Name"] = "Sending",
        ["Function"] = function() end,
    })
    fakelagreceive = fakelag.CreateToggle({
        ["Name"] = "Recieving",
        ["Function"] = function() end,
    })
end

local mouseconnection
local ClickTP = GuiLibrary["Objects"]["ExploitsWindow"]["API"].CreateOptionsButton({
    ["Name"] = "ClickTP",
    ["Function"] = function(callback) 
        if callback then 
            mouseconnection = mouse.Button1Down:Connect(function()
                if isAlive() and mouse.Target then 
                    lplr.Character.HumanoidRootPart.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
                end
            end)
        else
            if mouseconnection then 
                mouseconnection:Disconnect()
                mouseconnection = nil
            end
        end
    end
})

-- // MiscWindow
do 
    local AntiAFK = GuiLibrary["Objects"]["MiscellaneousWindow"]["API"].CreateOptionsButton({
        ["Name"] = "AntiAFK",
        ["Function"] = function(callback) 
            if callback then 
                pcall(function()
                    for i,v in next, getconnections(lplr.Idled) do
                        v:Disable()
                    end
                end)
            else
                pcall(function()
                    for i,v in next, getconnections(lplr.Idled) do
                        v:Enable()
                    end
                end)
            end
        end,
    })
end 

do
    local bav
    local antiaimspeed = {["Value"] = 0}
    local function createbav() 
        spawn(function() 
            repeat wait() until isAlive()
            bav = bav or Instance.new("BodyAngularVelocity", lplr.Character.HumanoidRootPart)
            bav.AngularVelocity = Vector3.new(0, antiaimspeed["Value"], 0)
            bav.MaxTorque = Vector3.new(0, 9999999999999999999999, 0)
        end)
    end
    local antiaimcharadded
    local AntiAim = GuiLibrary["Objects"]["MiscellaneousWindow"]["API"].CreateOptionsButton({
        ["Name"] = "AntiAim",
        ["Function"] = function(callback) 
            if callback then 
                createbav()
                antiaimcharadded = lplr.CharacterAdded:connect(createbav)
            else
                if antiaimcharadded then 
                    antiaimcharadded:Disconnect()
                    antiaimcharadded = nil
                end
                if bav then 
                    bav:Destroy()
                    bav = nil
                end
            end
        end,
    })
    antiaimspeed = AntiAim.CreateSlider({
        ["Name"] = "Speed",
        ["Function"] = function(value)
            if bav then bav.AngularVelocity = Vector3.new(0, value, 0) end
        end,
        ["Min"] = 1,
        ["Max"] = 100,
        ["Round"] = 0,
    })
end

do 
    local autoreconnectdelay = {["Value"] = 0}
    local AutoReconnect={["Enabled"] = false}; AutoReconnect = GuiLibrary["Objects"]["MiscellaneousWindow"]["API"].CreateOptionsButton({
        ["Name"] = "AutoReconnect",
        ["Function"] = function(callback) 
            if callback then 
                spawn(function() 
                    repeat wait() until AutoReconnect["Enabled"]==false or #COREGUI.RobloxPromptGui.promptOverlay:GetChildren() ~= 0
                    if AutoReconnect["Enabled"] then 
                        wait(autoreconnectdelay["Value"])
                        game:GetService("TeleportService"):Teleport(game.PlaceId)
                    end
                end)
            end
        end,
    })
    autoreconnectdelay = AutoReconnect.CreateSlider({
        ["Name"] = "Delay (s)",
        ["Function"] = function(value) end,
        ["Min"] = 0,
        ["Max"] = 30,
        ["Round"] = 0,
    })
end

do 
    local DISALLOWED_WHITESPACE = {"\r", "\t", "\v", "\f"} -- from roblox core scripts, removed \n due to spliting at new lines
    local spammer = {["Enabled"] = false}
    local spammerdelay = {["Value"] = 0}
    local spammerfile = {["Value"] = ""}
    local messagetable = {}
    local looping
    spammer = GuiLibrary["Objects"]["MiscellaneousWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Spammer",
        ["Function"] = function(callback)
            if callback then
                if spammerfile["Value"] ~= "" and isfile("Future/"..spammerfile["Value"]) then
                    messagetable = readfile(("Future/"..spammerfile["Value"]))

                    for i,v in next, DISALLOWED_WHITESPACE do
                        messagetable = messagetable:gsub(v, "")
                    end

                    messagetable = messagetable:split("\n")

                    if not looping then
                        spawn(function() 
                            repeat 
                                if spammer["Enabled"] then
                                    local v = messagetable[
                                        math.random(1, #messagetable)
                                    ]   
                                    if v~= nil and v~="" then
                                        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(v,"All")
                                        task.wait(spammerdelay["Value"])
                                    end
                                else
                                    task.wait()
                                end
                            until shared.Future == nil
                        end)
                        looping = true
                    end

                elseif spammer["Enabled"] then
                    local value = spammerfile.Value==nil and "" or spammerfile.Value
                    fprint("Future/"..value.." is not a valid file, please make sure it is in your workspace folder and you include the file extension")
                end
            end
        end
    })
    spammerfile = spammer.CreateTextbox({
        ["Name"] = "file.txt",
        ["Function"] = function(value)
            if value ~= "" and isfile("Future/"..value) then 
                messagetable = readfile(("Future/"..value)):split("\n")
                if spammer["Enabled"] then 
                    spammer.Toggle()
                    spammer.Toggle()
                end
            elseif value ~= "" and spammer.Enabled then
                fprint("Future/"..value.." is not a valid file, please make sure it is in your workspace folder and you include the file extension")
            end
        end
    })
    spammerdelay = spammer.CreateSlider({
        ["Name"] = "Delay (s)",
        ["Function"] = function(value) end,
        ["Min"] = 0,
        ["Max"] = 30,
        ["Round"] = 0,
    })
end

-- // MovementWindow

do 
    local autowalk = GuiLibrary["Objects"]["MovementWindow"]["API"].CreateOptionsButton({
        ["Name"] = "AutoWalk",
        ["Function"] = function(callback) 
            if callback then 
                BindToRenderStepped("AutoWalk", function()
                    if isAlive() then
                        lplr.Character.Humanoid:Move(Vector3.new(0, 0, -1), true)
                    end
                end)
            else
                UnbindFromRenderStepped("AutoWalk")
            end
        end
    })
end

do 
    local oldmovefunc
    local safewalk = {["Enabled"] = false}
    safewalk = GuiLibrary["Objects"]["MovementWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Sneak",
        ["Function"] = function(callback) 
            if callback then 
                local controls = require(lplr.PlayerScripts.PlayerModule).controls
                oldmovefunc = controls.moveFunction
                controls.moveFunction = function(self, movedir, ...)
                    if isAlive() and lplr.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                        local param = RaycastParams.new()
                        param.FilterDescendantsInstances = getCharacters()
                        param.FilterType = Enum.RaycastFilterType.Blacklist
                        local ray = WORKSPACE:Raycast(lplr.Character.HumanoidRootPart.Position + (movedir*1.25), Vector3.new(0, -9999999999, 0), param)
                        if ray == nil then 
                            movedir = Vector3.new(0,0,0)
                        end
                    end
                    return oldmovefunc(self, movedir, ...)
                end
            else
                if oldmovefunc then
                    local controls = require(lplr.PlayerScripts.PlayerModule).controls
                    controls.moveFunction = oldmovefunc
                end
            end
        end
    })
end

do 
    local Stepval = {["Value"] = 40}
    local Step = {["Enabled"] = false}
    Step = GuiLibrary["Objects"]["MovementWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Step",
        ["ArrayText"] = function() return Stepval["Value"] end,
        ["Function"] = function(callback)
            if callback then
                BindToStepped("Step", function(time, dt)
                    if isAlive(lplr, true) then
                        local param = RaycastParams.new()
                        param.FilterDescendantsInstances = table_combine(getCharacters(), cam:GetDescendants())
                        param.FilterType = Enum.RaycastFilterType.Blacklist
                        local ray = WORKSPACE:Raycast(lplr.Character.Head.Position-Vector3.new(0, 4, 0), lplr.Character.Humanoid.MoveDirection*3, param)
                        local ray2 = WORKSPACE:Raycast(lplr.Character.Head.Position, lplr.Character.Humanoid.MoveDirection*3, param)
                        if (ray and ray.Instance~=nil) or (ray2 and ray2.Instance~=nil) then
                            local velo = Vector3.new(0, Stepval["Value"] / 100, 0)
                            lplr.Character:TranslateBy(velo)
                            local old = lplr.Character.HumanoidRootPart.Velocity
                            lplr.Character.HumanoidRootPart.Velocity = Vector3.new(old.X, 0, old.Z)
                        end
                    end
                end)
            else
                UnbindFromStepped("Step")
            end
        end
    })
    Stepval = Step.CreateSlider({
        ["Name"] = "Speed",
        ["Min"] = 1,
        ["Max"] = 40,
        ["Default"] = 30,
        ["Round"] = 0,
        ["Function"] = function() end
    })
end





do
    local speedval = {["Value"] = 40}
    local speedmode = {["Enabled"] = false}
    local speed = {["Enabled"] = false}
    local oldWS = 16
    speed = GuiLibrary["Objects"]["MovementWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Speed",
        ["ArrayText"] = function() return speedval["Value"] end,
        ["Function"] = function(callback)
            if callback then
                BindToHeartbeat("Speed", function(dt)
                    if isAlive() then
                        local velo = lplr.Character.Humanoid.MoveDirection * (speedval["Value"]*(5)) * dt
                        velo = Vector3.new(velo.x / 10, 0, velo.z / 10)
                        lplr.Character:TranslateBy(velo)
                    end
                end)
            else
                UnbindFromHeartbeat("Speed")
            end
        end
    })
    speedval = speed.CreateSlider({
        ["Name"] = "Speed",
        ["Min"] = 1,
        ["Max"] = 150,
        ["Round"] = 0,
        ["Function"] = function() end
    })
end

do
    local flyup
    local flydown
    local flydownconnection
    local flyupconnection
    local vertspeed = {["Value"] = 40}
    local verttoggle = {["Enabled"] = false}
    local vertbind = {["Value"] = "LShift"}
    local flyspeed = {["Value"] = 40}
    local flyglide = {["Value"] = 0}
    local fly = {["Enabled"] = false}
    local flymode = {["Value"] = "Velo"}
    fly = GuiLibrary["Objects"]["MovementWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Flight",
        ["Function"] = function(callback)
            if callback then
                BindToStepped("Fly", function(time,dt)
                    if isAlive() then
                        local dt = flymode.Value == "Velo" and 1 or dt
                        local updirection = 0 - flyglide["Value"]
                        if UIS:GetFocusedTextBox()==nil then
                            updirection = (flyup and vertspeed["Value"] or flydown and -vertspeed["Value"] or 0 - flyglide["Value"])*dt
                        end
                        local MoveDirection = lplr.Character.Humanoid.MoveDirection * (flyspeed["Value"]*dt)
                        if flymode.Value == "Velo" then
                            lplr.Character.HumanoidRootPart.Velocity = Vector3.new(MoveDirection.X, verttoggle["Enabled"] and (updirection) or 0 - flyglide["Value"], MoveDirection.Z)
                        elseif flymode.Value == "CFrame" then
                            lplr.Character.HumanoidRootPart.CFrame = lplr.Character.HumanoidRootPart.CFrame + Vector3.new(MoveDirection.X, verttoggle["Enabled"] and (updirection) or 0 - flyglide["Value"], MoveDirection.Z)
                            lplr.Character.HumanoidRootPart.Velocity = Vector3.new()
                        end
                    end
                end)
                flyupconnection = UIS.InputBegan:connect(function(input)
                    if input.KeyCode == Enum.KeyCode.Space then
                        flyup = true
                    end
                    if input.KeyCode == (vertbind.Value == "LShift" and Enum.KeyCode.LeftShift or Enum.KeyCode.LeftControl) then
                        flydown = true
                    end
                end)
                flydownconnection = UIS.InputEnded:connect(function(input)
                    if input.KeyCode == Enum.KeyCode.Space then
                        flyup = false
                    end
                    if input.KeyCode == (vertbind.Value == "LShift" and Enum.KeyCode.LeftShift or Enum.KeyCode.LeftControl) then
                        flydown = false
                    end
                end)
            else
                flyup = false
                flydown = false
                UnbindFromStepped("Fly")
                if flyupconnection then
                    flyupconnection:Disconnect()
                end
                if flydownconnection then
                    flydownconnection:Disconnect()
                end
                WORKSPACE.Gravity = 196.2
            end
        end
    })
    flymode = fly.CreateSelector({
        Name = "Mode", 
        Function = function() end,
        List = {"Velo", "CFrame"}
    })
    flyspeed = fly.CreateSlider({
        ["Name"] = "Speed",
        ["Min"] = 1,
        ["Max"] = 300,
        ["Function"] = function() end
    })
    verttoggle = fly.CreateToggle({
        ["Name"] = "Vertical",
        ["Function"] = function() end
    })
    vertbind = fly.CreateSelector({
        ["Name"] = "VBind",
        ["Function"] = function() end,
        ["List"] = {"LShift", "LCtrl"},
    })
    vertspeed = fly.CreateSlider({
        ["Name"] = "VSpeed",
        ["Min"] = 1,
        ["Max"] = 300,
        ["Function"] = function() end
    })
    flyglide = fly.CreateSlider({
        ["Name"] = "Glide",
        ["Min"] = -100,
        ["Default"] = 0,
        ["Max"] = 100,
        ["Function"] = function() end
    })
end

do
    local HighJumpHeight = {["Value"] = 0}
    local HighJumpMode = {["Value"] = "Normal"}
    local highjumpconnection, highjumpconnection2
    local HighJump = {["Enabled"] = false}
    local function hj() 
        if not HighJump.Enabled then return end
        if HighJumpMode["Value"] == "Velocity" then 
            lplr.Character.HumanoidRootPart.Velocity = Vector3.new(lplr.Character.HumanoidRootPart.Velocity.X, lplr.Character.HumanoidRootPart.Velocity.Y + HighJumpHeight["Value"], lplr.Character.HumanoidRootPart.Velocity.Z)
        elseif HighJumpMode["Value"] == "TP" then
            lplr.Character.HumanoidRootPart.CFrame = lplr.Character.HumanoidRootPart.CFrame + Vector3.new(0,HighJumpHeight["Value"]/1.5,0)
        end
    end
    HighJump = GuiLibrary["Objects"]["MovementWindow"]["API"].CreateOptionsButton({
        ["Name"] = "HighJump",
        ["Function"] = function(callback) 
            if callback then 
                spawn(function()
                    repeat wait() until isAlive() or not HighJump["Enabled"]
                    if HighJump["Enabled"] then
                        highjumpconnection = lplr.Character.Humanoid.Jumping:Connect(hj)
                        highjumpconnection2 = lplr.CharacterAdded:Connect(function(char) 
                            if highjumpconnection then highjumpconnection:Disconnect() end
                            repeat wait() until isAlive() or not HighJump["Enabled"]
                            highjumpconnection = lplr.Character.Humanoid.Jumping:Connect(hj)
                        end)
                    end
                end)
            else
                if highjumpconnection then 
                    highjumpconnection:Disconnect()
                    highjumpconnection = nil
                end
                if highjumpconnection2 then 
                    highjumpconnection2:Disconnect()
                    highjumpconnection2 = nil
                end
            end
        end
    })
    HighJumpMode = HighJump.CreateSelector({
        ["Name"] = "Mode",
        ["Function"] = function() 
        end,
        ["List"] = {"TP", "Velocity"}
    })
    HighJumpHeight = HighJump.CreateSlider({
        ["Name"] = "Height",
        ["Min"] = 1, 
        ["Max"] = 100, 
        ["Default"] = 25,
        ["Round"] = 0,
        ["Function"] = function() end
    })
end
 
do 
    local LongJumpThrust
    local LongJumpPower = {["Value"] = 0}
    local LongJumpMode = {["Value"] = "Normal"}
    local LongJumpconnection
    local LongJump = {["Enabled"] = false}
    LongJump = GuiLibrary["Objects"]["MovementWindow"]["API"].CreateOptionsButton({
        ["Name"] = "LongJump",
        ["Function"] = function(callback) 
            if callback then 
                spawn(function()
                    repeat wait() until isAlive() or not LongJump["Enabled"]
                    if LongJump["Enabled"] then
                        if LongJumpMode["Value"]:find("Velo") then 
                            LongJumpconnection = lplr.Character.Humanoid.Jumping:Connect(function(  ) 
                                local old = lplr.Character.HumanoidRootPart.Velocity
                                local new = (old * LongJumpPower["Value"]) / 2.5
                                local y = LongJumpMode["Value"] == "VeloFlat" and old.Y / 2 or old.Y
                                lplr.Character.HumanoidRootPart.Velocity = Vector3.new(new.X, y, new.X)
                            end)
                        elseif LongJumpMode["Value"] == "Normal" then
                            LongJumpThrust = Instance.new("BodyThrust")
                            LongJumpThrust.Force = Vector3.new(0, -1500, -(LongJumpPower["Value"] * 750))
                            LongJumpThrust.Parent = lplr.Character.HumanoidRootPart
                        end
                    end
                end)
            else
                if LongJumpconnection then 
                    LongJumpconnection:Disconnect()
                    LongJumpconnection = nil
                end
                if LongJumpThrust then 
                    LongJumpThrust:Destroy()
                    LongJumpThrust = nil
                end
            end
        end
    })
    LongJumpMode = LongJump.CreateSelector({
        ["Name"] = "Mode",
        ["Function"] = function() 
            if LongJump["Enabled"] then 
                for i = 1, 2 do 
                    LongJump.Toggle()
                end
            end
        end,
        ["List"] = {"Normal", "Velo", "VeloFlat"}
    })
    LongJumpPower = LongJump.CreateSlider({
        ["Name"] = "Power",
        ["Min"] = 1, 
        ["Max"] = 10, 
        ["Default"] = 2,
        ["Round"] = 0,
        ["Function"] = function() end
    })
end

do 
    local FastFallTicks = {Value = 5}
    local FallHeight = {Value = 10}
    local FastFall = {Enabled = false}
    FastFall = GuiLibrary.Objects.MovementWindow.API.CreateOptionsButton({
        Name = "FastFall",
        Function = function(callback) 
            if callback then 
                spawn(function() 
                    repeat task.wait()
                        if isAlive() then
                            local params = RaycastParams.new()
                            params.FilterDescendantsInstances = {lplr.Character}
                            params.FilterType = Enum.RaycastFilterType.Blacklist
                            local ray = WORKSPACE:Raycast(lplr.Character.HumanoidRootPart.Position, Vector3.new(0, -FallHeight.Value*3, 0), params)
                            if ray and ray.Instance then 
                                local velo = lplr.Character.HumanoidRootPart.Velocity
                                if lplr.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall and velo.Y < 0 then 
                                    lplr.Character.HumanoidRootPart.Velocity = Vector3.new(velo.X, -(FastFallTicks.Value*30), velo.Z)
                                end
                            end
                        end
                    until not FastFall.Enabled
                end)
            end
        end,
    })
    FallHeight = FastFall.CreateSlider({
        Name = "FallHeight",
        Min = 1, 
        Max = 10, 
        Default = 7,
        Round = 1,
        Function = function() end
    })
    FastFallTicks = FastFall.CreateSlider({
        Name = "Ticks",
        Min = 1, 
        Max = 5, 
        Default = 1,
        Round = 0,
        Function = function() end
    })
end

-- // renderwindow

do 
    local MouseIconTable = {
        CSGO = "rbxassetid://9942607125",
        Dot = "rbxassetid://9943092654",
        Three = "rbxassetid://9943167055",
        Tri = "rbxassetid://9948357128",
        Cross = "rbxassetid://9943168532",
        Chevron = "rbxassetid://9948124812",
    }
    local Connection
    local MouseIcon = {Value = "CSGO"}
    local Crosshair = {Enabled = false}
    Crosshair = GuiLibrary.Objects.RenderWindow.API.CreateOptionsButton({
        Name = "Crosshair",
        Function = function(callback) 
            if callback then 
                mouse.Icon = MouseIconTable[MouseIcon.Value]
                Connection = mouse:GetPropertyChangedSignal("Icon"):Connect(function()
                    local mouseicon = MouseIconTable[MouseIcon.Value]
                    if mouse.Icon ~= mouseicon then 
                        mouse.Icon = mouseicon
                    end
                end)
            else
                Connection:Disconnect()
                mouse.Icon = ""
            end
        end
    })
    MouseIcon = Crosshair.CreateSelector({
        Name = "Ico",
        List = table_invert(MouseIconTable),
        Function = function(value) 
            if Crosshair.Enabled then
                mouse.Icon = MouseIconTable[value]
            end
        end
    })
end

do 
    local searchfor, connections, objects = {}, {}, {}
    local searchfolder = Instance.new("Folder", GuiLibrary.ScreenGui)
    local search = {Enabled = false}

    local function addHighlight(v) 
        if not search.Enabled then return end
        --print("Adding Highlight", v:GetFullName())
        local highlight = Instance.new("Highlight", searchfolder)
        highlight.Enabled = true
        highlight.Adornee = v
        highlight.Name = v:GetFullName()
        highlight.FillColor =  GuiLibrary["GetColor"]()
        GuiLibrary["Signals"]["UpdateColor"]:connect(function()
            highlight.FillColor = GuiLibrary["GetColor"]()
        end)
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.OutlineTransparency = 1
        highlight.FillTransparency = 0.01
        highlight.DepthMode = 0
        objects[#objects+1] = {Highlight = highlight, Instance = v}
    end

    local function removeHighlight(x) 
        for i,v in next, objects do 
            if v.Instance == x then 
                --print("Removing ins:", x:GetFullName(), "highlight: ", v.Highlight:GetFullName())
                v.Highlight:Destroy()
            end
        end
    end

    local function refresh()
        searchfolder:ClearAllChildren()
        objects = {}
        for i, v in next, connections do 
            v:Disconnect()
            connections[i] = nil
        end
        spawn(function()
            for i,v in next, WORKSPACE:GetDescendants() do 
                if table.find(searchfor, v.Name) and (v:IsA("BasePart") or v:IsA("Model")) then 
                    addHighlight(v)
                end
            end
        end)
        connections[#connections+1] = WORKSPACE.DescendantAdded:connect(function(v) 
            if table.find(searchfor, v.Name) and (v:IsA("BasePart") or v:IsA("Model"))  then 
                addHighlight(v)
            end
        end)
        connections[#connections+1] = WORKSPACE.DescendantRemoving:connect(function(v) 
            if table.find(searchfor, v.Name) and (v:IsA("BasePart") or v:IsA("Model"))  then 
                removeHighlight(v)
            end
        end)
    end

    Future.AddCommand("search", {Function = function(args) 
        local mode,name = args[1], args[2]
        if mode == nil then  GuiLibrary.CreateNotification("Expected 1 or 2 arguments in command 'search', got 0.") return end
        if mode == "add" then 
            searchfor[#searchfor+1] = name
            refresh()
        elseif mode == "remove" or mode == "del" or mode == "delete" then
            table.remove(searchfor, table.find(searchfor, name))
            refresh()
        elseif mode == "clear" then
            searchfor = {}
            refresh()
        end
    end, Help = ".search add/del/clear &lt;part-name&gt;"})

    search = GuiLibrary.Objects.RenderWindow.API.CreateOptionsButton({
        Name = "Search",
        Function = function(callback) 
            if callback then 
                refresh()
            else
                for i, v in next, connections do 
                    v:Disconnect()
                    connections[i] = nil
                end
                searchfolder:ClearAllChildren()
            end
        end
    })

    local oldsave = GuiLibrary.SaveConfig
    GuiLibrary.SaveConfig = function(name, isAutosave) 
        local path = ("Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId).."/"..name..".search.json")
        writefile(path, HTTPSERVICE:JSONEncode(searchfor))
        return oldsave(name, isAutosave)
    end

    local oldload = GuiLibrary.LoadConfig
    GuiLibrary.LoadConfig = function(name) 
        local path = ("Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId).."/"..name..".search.json")
        if betterisfile(path) then
            searchfor = HTTPSERVICE:JSONDecode(readfile(path))
        else
            searchfor = {}
        end
        refresh()
        return oldload(name)
    end
end

do 
    local connection
    local old
    local FOVSlider = {["Value"] = 120}
    local FOV = {["Enabled"] = false}; FOV = GuiLibrary["Objects"]["RenderWindow"]["API"].CreateOptionsButton({
        ["Name"] = "FOV", 
        ["Function"] = function(callback) 
            if callback then
                old = old or cam.FieldOfView
                cam.FieldOfView = FOVSlider["Value"]
                connection = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function() 
                    cam.FieldOfView = FOVSlider["Value"]
                end)
            else
                if connection then 
                    connection:Disconnect() 
                end
                cam.FieldOfView = old
            end
        end
    })
    FOVSlider = FOV.CreateSlider({
        ["Name"] = "FOV",
        ["Function"] = function(value) 
            if FOV["Enabled"] then
                cam.FieldOfView = value
            end
        end,
        ["Min"] = 40,
        ["Max"] = 120,
        ["Default"] = 120
    })
end

do 
    local CameraFix = {Enabled = false} 
    CameraFix = GuiLibrary.Objects.RenderWindow.API.CreateOptionsButton({
        Name = "CameraFix",
        Function = function(callback) 
            spawn(function()
                repeat
                    task.wait()
                    if (not CameraFix.Enabled) then break end
                    UserSettings():GetService("UserGameSettings").RotationType = ((cam.CFrame.Position - cam.Focus.Position).Magnitude <= 0.5 and Enum.RotationType.CameraRelative or Enum.RotationType.MovementRelative)
                until (not CameraFix.Enabled)
            end)
        end,
    })
end

do 
    local breadcrumbs = {["Enabled"] = false}
    local breadcrumbsmode = {["Value"] = "Ball"}
    local breadcrumbsfolder = Instance.new("Folder", WORKSPACE)
    local breadcrumbstransparency = {["Value"] = 0}
    local breadcrumbstimeout = {["Value"] = 0}
    local cachedpos

    local breadcrumbstrail
    local breadcrumbsconnection
    local attachment1, attachment2

    breadcrumbs = GuiLibrary["Objects"]["RenderWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Breadcrumbs",
        ["Function"] = function(callback) 
            --// line mode:
            if callback and breadcrumbsmode["Value"] == "Line" then 
                spawn(function()
                    repeat wait() until isAlive()
                    breadcrumbstrail = Instance.new("Trail", lplr.Character.HumanoidRootPart)
                    breadcrumbstrail.Color = ColorSequence.new(GuiLibrary.GetColor(), GuiLibrary.GetColor())
                    GuiLibrary["Signals"]["UpdateColor"]:connect(function() 
                        if breadcrumbstrail then
                            breadcrumbstrail.Color = ColorSequence.new(GuiLibrary.GetColor(), GuiLibrary.GetColor())
                        end
                    end)
                    attachment1, attachment2 = Instance.new("Attachment", lplr.Character.HumanoidRootPart), Instance.new("Attachment", lplr.Character.HumanoidRootPart)
                    attachment1.Position = Vector3.new(0,-1.4,0)
                    attachment2.Position = Vector3.new(0,-1.6,0)
                    breadcrumbstrail.Attachment0 = attachment1
                    breadcrumbstrail.Attachment1 = attachment2
                    breadcrumbstrail.Lifetime = breadcrumbstimeout["Value"]
                    breadcrumbstrail.Transparency = NumberSequence.new(math.clamp(breadcrumbstransparency["Value"]/100 - 0.1, 0, 1), math.clamp(breadcrumbstransparency["Value"]/100 + 0.1, 0, 1))
                    breadcrumbstrail.WidthScale = NumberSequence.new(1,1)
                    breadcrumbsconnection = lplr.CharacterAdded:connect(function()
                        repeat wait() until isAlive()
                        breadcrumbstrail.Parent = lplr.Character.HumanoidRootPart
                    end)
                end)
            else
                if breadcrumbsconnection then 
                    breadcrumbsconnection:Disconnect()
                    breadcrumbsconnection = nil
                end
                if breadcrumbstrail then 
                    breadcrumbstrail:Destroy()
                    breadcrumbstrail = nil
                end
                if attachment1 then 
                    attachment1:Destroy()
                    attachment1 = nil
                end
                if attachment2 then 
                    attachment2:Destroy()
                    attachment2 = nil
                end
            end
            -- // ball mode:
            if breadcrumbsmode["Value"] == "Ball" then
                spawn(function()
                    repeat wait()
                        if isAlive() and (cachedpos ~= nil and (lplr.Character.HumanoidRootPart.Position - cachedpos).Magnitude > 1.5 or cachedpos==nil) and breadcrumbsmode["Value"] == "Ball" then
                            cachedpos = lplr.Character.HumanoidRootPart.Position
                            local newBreadcrumb = Instance.new("Part", breadcrumbsfolder)
                            local newBreadcrumbSS = Instance.new("SelectionSphere", newBreadcrumb)
                            newBreadcrumb.Anchored = true
                            newBreadcrumb.CFrame = lplr.Character.HumanoidRootPart.CFrame - Vector3.new(0, 1.5, 0)
                            newBreadcrumb.CanCollide = false
                            newBreadcrumb.Size = Vector3.new(0,0,0)
                            newBreadcrumb.Transparency = 1 
                            newBreadcrumbSS.Transparency = breadcrumbstransparency["Value"]/100
                            newBreadcrumbSS.Adornee = newBreadcrumb
                            newBreadcrumbSS.Color3 = GuiLibrary["GetColor"]()
                            GuiLibrary["Signals"]["UpdateColor"]:connect(function(color) 
                                newBreadcrumbSS.Color3 = GuiLibrary["GetColor"]()
                            end)
                            game:GetService("Debris"):AddItem(newBreadcrumb, breadcrumbstimeout["Value"])
                        end
                    until breadcrumbs["Enabled"] == false
                    breadcrumbsfolder:ClearAllChildren()
                end)
            end
        end,
    })

    breadcrumbsmode = breadcrumbs.CreateSelector({
            ["Name"] = "Mode",
            ["Function"] = function()
                if breadcrumbs["Enabled"] then 
                    breadcrumbs.Toggle()
                    breadcrumbs.Toggle()
                end
            end,
            ["List"] = {"Ball", "Line"}
        })

    breadcrumbstransparency = breadcrumbs.CreateSlider({
        ["Name"] = "Transparency",
        ["Function"] = function(value) 
            for i,v in next, breadcrumbsfolder:GetChildren() do
                v:FindFirstChildOfClass("SelectionSphere").Transparency = value/100
            end
            if breadcrumbstrail then 
                breadcrumbstrail.Transparency = NumberSequence.new(math.clamp(breadcrumbstransparency["Value"]/100 - 0.1, 0, 1), math.clamp(breadcrumbstransparency["Value"]/100 + 0.1, 0, 1))
            end
        end,
        ["Min"] = 0, ["Max"] = 100, ["Round"] = 0, ["Default"] = 0
    })

    breadcrumbstimeout = breadcrumbs.CreateSlider({
        ["Name"] = "Timeout",
        ["Function"] = function(value) 
        
        end,
        ["Min"] = 0, ["Max"] = 120, ["Round"] = 1, ["Default"] = 5
    })
end



do
    local chams = {["Enabled"] = false}
    local chamsoutline = {["Enabled"] = false}
    local chamswalls = {["Enabled"] = false}
    local chamsfolder = Instance.new("Folder", GuiLibrary["ScreenGui"]); chamsfolder.Name = "Chams"
    local chamstransparency = {["Value"] = 0}
    local chamsteamcheck = {["Enabled"] = true}
    local chamslplr = {["Enabled"] = false}

    local chamsplayeraddedconnection
    local chamsplayerremovingconnection
    local chamscharacteraddedconnections = {}

    local function addHighlight(plr)
        spawn(function()
            if not isAlive(plr) then repeat task.wait() until isAlive(plr) end
            if (chamsteamcheck["Enabled"] and plr.Team ~= lplr.Team or not chamsteamcheck["Enabled"]) and (not chamslplr["Enabled"] and plr ~= lplr or chamslplr["Enabled"]) then
                local highlight
                if not chamsfolder:FindFirstChild(plr.Name) then
                    highlight = Instance.new("Highlight", chamsfolder)
                else
                    highlight = chamsfolder:FindFirstChild(plr.Name)
                end
                highlight.Adornee = plr.Character
                highlight.Name = plr.Name
                highlight.FillColor = chamsteamcheck["Enabled"] and getColorFromPlayer(plr) or GuiLibrary["GetColor"]()
                GuiLibrary["Signals"]["UpdateColor"]:connect(function()
                    highlight.FillColor = chamsteamcheck["Enabled"] and getColorFromPlayer(plr) or GuiLibrary["GetColor"]()
                end)
                highlight.OutlineColor = Color3.new(1,1,1)
                highlight.OutlineTransparency = chamsoutline["Enabled"] and 0 or 1
                highlight.FillTransparency = chamstransparency["Value"]/100
                highlight.DepthMode = chamswalls["Enabled"] and 1 or 0
            end
        end)
    end

    local function removeHighlight(plr) 
        if chamsfolder:FindFirstChild(plr.Name) then 
            chamsfolder:FindFirstChild(plr.Name):Destroy()
        end
    end

    chams = GuiLibrary["Objects"]["RenderWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Chams",
        ["Function"] = function(callback) 
            if callback then
                for i,v in next, PLAYERS:GetPlayers() do 
                    addHighlight(v)
                    chamscharacteraddedconnections[v.Name] = v.CharacterAdded:connect(function(char) 
                        addHighlight(v)
                    end)
                end 
                chamsplayeraddedconnection = PLAYERS.PlayerAdded:connect(function(plr)
                    addHighlight(plr)
                    chamscharacteraddedconnections[plr.Name] = plr.CharacterAdded:connect(function(char) 
                        addHighlight(plr)
                    end)
                end)
                chamsplayerremovingconnection = PLAYERS.PlayerRemoving:connect(function(plr) 
                    removeHighlight(plr)
                end)
            else
                if chamsplayeraddedconnection then
                    chamsplayeraddedconnection:Disconnect()
                    chamsplayeraddedconnection = nil
                end
                if chamsplayerremovingconnection then
                    chamsplayerremovingconnection:Disconnect()
                    chamsplayerremovingconnection = nil
                end
                if #chamscharacteraddedconnections > 0 then 
                    for i,v in next, chamscharacteraddedconnections do 
                        v:Disconnect()
                        chamscharacteraddedconnections[i] = nil
                    end
                end
                chamscharacteraddedconnections = {}
                chamsfolder:ClearAllChildren()
            end
        end,
    })
    chamstransparency = chams.CreateSlider({
        ["Name"] = "Transparency",
        ["Function"] = function()
            for i,v in next, chamsfolder:GetChildren() do
                if v:IsA("Highlight") then
                    v.FillTransparency = chamstransparency["Value"]/100
                end
            end
        end,
        ["Min"] = 0,
        ["Max"] = 100,
        ["Default"] = 0,
        ["OnInputEnded"] = false
    })
    chamsoutline = chams.CreateToggle({
        ["Name"] = "Outline",
        ["Function"] = function(callback)
            for i,v in next, chamsfolder:GetChildren() do
                if v:IsA("Highlight") then
                    v.OutlineTransparency = callback and 0 or 1
                end
            end
        end
    }) 
    chamsteamcheck = chams.CreateToggle({
        ["Name"] = "TeamCheck",
        ["Function"] = function()
            if chams.Enabled then
                chams.Toggle()
                chams.Toggle()
            end
        end,
        ["Default"] = true
    })
    chamswalls = chams.CreateToggle({
        ["Name"] = "WallCheck",
        ["Function"] = function(callback) 
            for i,v in next, chamsfolder:GetChildren() do
                if v:IsA("Highlight") then
                    v.DepthMode = callback and 1 or 0
                end
            end
        end
    })
    chamslplr = chams.CreateToggle({
        ["Name"] = "Self",
        ["Function"] = function(callback)
            local func = callback and addHighlight or removeHighlight
            if chams.Enabled then
                func(lplr)
            end
        end,
    })
end



--[[ 
     - TODO -
    
// add team check and team color toggles

]]
do 
    local lastUpdate = os.clock()
    local renderRate = {Value = 60}
    local doRenderRate = {Enabled = false}
    local esp = {["Enabled"] = false}
    local esphealth = {Enabled = false}
    local espfolder = Instance.new("Folder", GuiLibrary["ScreenGui"])
    espfolder.Name = "ESP"
    local espnames= {["Enabled"] = false}
    local espdisplaynames= {["Enabled"] = false}
    esp = GuiLibrary["Objects"]["RenderWindow"]["API"].CreateOptionsButton({
        ["Name"] = "ESP",
        ["Function"] = function(callback) 
            if callback then 
                BindToRenderStepped("ESP", function() 

                    if doRenderRate.Enabled then
                        if (os.clock() - lastUpdate < 1 / renderRate.Value) then
                            return
                        end
                        lastUpdate = os.clock()
                    end

                    for i,v in next, PLAYERS:GetPlayers() do 
                        if v~=lplr and isAlive(v) then
                            local plrespframe
                            if espfolder:FindFirstChild(v.Name) then 
                                plrespframe = espfolder:FindFirstChild(v.Name)
                                plrespframe.line2.BackgroundColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                plrespframe.line1.BackgroundColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                plrespframe.line3.BackgroundColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                plrespframe.line4.BackgroundColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                plrespframe:FindFirstChild("name").TextColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                plrespframe:FindFirstChild("name").Visible = espnames["Enabled"]
                                local text = espdisplaynames["Enabled"] and v.DisplayName or v.Name
                                plrespframe:FindFirstChild("name").Text = "<stroke color='#000000' thickness='1'>"..text..(esphealth["Enabled"] and (" [<font color='#"..(convertHealthToColor(v.Character.Humanoid.Health, v.Character.Humanoid.MaxHealth):ToHex()).."'>"..tostring(math.round(v.Character.Humanoid.Health)).."</font>]") or "").."</stroke>"
                            else
                                plrespframe = Instance.new("Frame", espfolder)
                                plrespframe.BackgroundTransparency = 1
                                plrespframe.Visible = false
                                plrespframe.Name = v.Name
                                plrespframe.BorderSizePixel = 0
                                local line1 = Instance.new("Frame", plrespframe)
                                line1.BorderSizePixel = 0
                                line1.Name = "line1"
                                line1.ZIndex = 99
                                line1.Size = UDim2.new(1, -2, 0, 1)
                                line1.Position = UDim2.new(0, 1, 0, 1)
                                line1.BackgroundColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                line1.Parent = plrespframe
                                local line2 = Instance.new("Frame", plrespframe)
                                line2.BorderSizePixel = 0
                                line2.Name = "line2"
                                line2.ZIndex = 99
                                line2.Size = UDim2.new(1, -2, 0, 1)
                                line2.Position = UDim2.new(0, 1, 1, -2)
                                line2.BackgroundColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                line2.Parent = plrespframe
                                local line3 = Instance.new("Frame", plrespframe)
                                line3.BorderSizePixel = 0
                                line3.Name = "line3"
                                line3.ZIndex = 99
                                line3.Size = UDim2.new(0, 1, 1, -2)
                                line3.Position = UDim2.new(0, 1, 0, 1)
                                line3.BackgroundColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                line3.Parent = plrespframe
                                local line4 = Instance.new("Frame", plrespframe)
                                line4.BorderSizePixel = 0
                                line4.Name = "line4"
                                line4.ZIndex = 99
                                line4.Size = UDim2.new(0, 1, 1, -2)
                                line4.Position = UDim2.new(1, -2, 0, 1)
                                line4.BackgroundColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                line4.Parent = plrespframe
                                local name = Instance.new("TextLabel", plrespframe)
                                local text = espdisplaynames["Enabled"] and v.DisplayName or v.Name
                                name.TextColor3 = getColorFromPlayer(v) or GuiLibrary["GetColor"]()
                                name.BackgroundTransparency = 1
                                name.Size = UDim2.new(0, 1, 1, 2)
                                name.Position = UDim2.new(0.5, 0, -0.95, 0)
                                name.AnchorPoint = Vector2.new(0.5, 0)
                                name.RichText = true
                                name.Text = "<stroke color='#000000' thickness='1'>"..text..(esphealth["Enabled"] and (" [<font color='#"..(convertHealthToColor(v.Character.Humanoid.Health, v.Character.Humanoid.MaxHealth):ToHex()).."'>"..tostring(v.Character.Humanoid.Health).."</font>]") or "").."</stroke>"
                                name.Visible = espnames["Enabled"]
                                name.Name = "name"
                                name.TextSize = 15
                                name.Font = GuiLibrary.Font
                            end

                            local rootPos, rootVis = WORKSPACE.CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
							local rootSize = (v.Character.HumanoidRootPart.Size.X * 1200) * (WORKSPACE.CurrentCamera.ViewportSize.X / 1920)
							local headPos, headVis = WORKSPACE.CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position + Vector3.new(0, 1 + v.Character.Humanoid.HipHeight, 0))
							local legPos, legVis = WORKSPACE.CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position - Vector3.new(0, 1 + v.Character.Humanoid.HipHeight, 0))
                            plrespframe.Visible = rootVis
                            plrespframe.name.Visible = espnames["Enabled"]
                            if rootVis then
                                local rootSize = rootSize * 0.75
                                plrespframe.Size = UDim2.new(0, rootSize / rootPos.Z, 0, (headPos.Y - legPos.Y))
                                plrespframe.Position = UDim2.new(0, rootPos.X - plrespframe.Size.X.Offset / 2, 0, (rootPos.Y - plrespframe.Size.Y.Offset / 2) - 36)
                            end
                        end
                    end
                    for i,v in next, espfolder:GetChildren() do 
                        if not PLAYERS:FindFirstChild(v.Name) or not isAlive(PLAYERS:FindFirstChild(v.Name)) then
                            v:Destroy()
                        end
                    end
                end)
            else
                UnbindFromRenderStepped("ESP")
                espfolder:ClearAllChildren()
            end
        end
    })

    espnames = esp.CreateToggle({
        ["Name"] = "Names",
        ["Function"] = function() end,
    })

    espdisplaynames = esp.CreateToggle({
        ["Name"] = "UseDisplayNames",
        ["Function"] = function() end,
    })
    esphealth = esp.CreateToggle({
        ["Name"] = "Health",
        ["Function"] = function() end,
    })
    doRenderRate = esp.CreateToggle({
        Name = "RenderRate",
        Function = function() end
    })
    renderRate = esp.CreateSlider({
        Name = "RenderRate",
        Function = function() end,
        Min = 10,
        Max = 240,
        Default = 60,
    })

end

do 
    local lastUpdate = os.clock()
    local renderRate = {Value = 60}
    local doRenderRate = {Enabled = false}
    local nametags = {["Enabled"] = false}
    local NametagsFolder = Instance.new("Folder", GuiLibrary["ScreenGui"])
    NametagsFolder.Name = "Nametags"
    local tagsarmor = {["Enabled"] = false}
    local tagsitemname = {["Enabled"] = false}
    local tagshealth = {["Enabled"] = false}
    local tagsscale = {Value = 1}
    nametags = GuiLibrary["Objects"]["RenderWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Nametags",
        ["Function"] = function(callback) 
            if callback then 
                BindToStepped("Nametags", function() 
                    debug.profilebegin("Future Nametags Loop")

                    if doRenderRate.Enabled then
                        if (os.clock() - lastUpdate < 1 / renderRate.Value) then
                            return
                        end
                        lastUpdate = os.clock()
                    end

                    for i,v in next, PLAYERS:GetPlayers() do 
                        if v~=lplr and isAlive(v) then
                            local frame
                            local MainText
                            local UIScale
                            local raw = v.DisplayName..(tagshealth.Enabled and ' '..tostring(math.round(v.Character.Humanoid.Health)) or '') 
                            -- blue color: rgb(89, 175, 255)
                            local blue = "2a96fa"
                            local default = "ffffff"
                            local teamcolor = (v.Team and v.TeamColor.Color:ToHex())
                            local text = '<font color="#'..(Future.isFriend(v) and blue or (teamcolor or default))..'">'..v.DisplayName..'</font>'..(tagshealth.Enabled and ' <font color="#'..(convertHealthToColor(v.Character.Humanoid.Health, v.Character.Humanoid.MaxHealth):ToHex())..'">'..tostring(math.round(v.Character.Humanoid.Health))..'</font>' or '')
                            if NametagsFolder:FindFirstChild(v.Name) then 
                                frame = NametagsFolder:FindFirstChild(v.Name)
                                local name = v.DisplayName
                                MainText = frame:FindFirstChild("MainText")
                                MainText.Text = text
                                UIScale = frame:FindFirstChild("UIScale")
                                UIScale.Scale = tagsscale.Value
                            else
                                frame = Instance.new("Frame")
                                local Nametag = frame
                                MainText = Instance.new("TextLabel")
                                UIScale = Instance.new("UIScale", Nametag)
                                UIScale.Scale = tagsscale.Value
                                Nametag.Name = v.Name
                                Nametag.Parent = NametagsFolder
                                Nametag.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                Nametag.BackgroundTransparency = 0.500
                                Nametag.BorderSizePixel = 0
                                Nametag.Position = UDim2.new(0, 0, 0, 0)
                                Nametag.AnchorPoint = Vector2.new(0,0)
                                Nametag.Size = UDim2.new(0, 300, 0, 30)
                                Nametag.ZIndex = -1
                                MainText.Name = "MainText"
                                MainText.RichText = true
                                MainText.Parent = Nametag
                                MainText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                MainText.BackgroundTransparency = 1.000
                                MainText.Position = UDim2.new(0.5, 0, 0.5, 0)
                                MainText.AnchorPoint = Vector2.new(0.5,0.5)
                                MainText.Size = UDim2.new(0, 300, 0, 30)
                                MainText.Font = GuiLibrary.Font
                                MainText.Text = text
                                MainText.TextSize = (18)
                                MainText.TextColor3 = Color3.fromRGB(255, 255, 255)
                                MainText.ZIndex = -1
                            end
                            local tsize = game:GetService("TextService"):GetTextSize(raw, MainText.TextSize, MainText.Font, MainText.AbsoluteSize)
                            frame.Size = UDim2.new(0, tsize.X + 10, 0, tsize.Y)
                            local rootPos, rootVis = WORKSPACE.CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
							local headPos, headVis = WORKSPACE.CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position + Vector3.new(0, 1 + v.Character.Humanoid.HipHeight, 0))
                            frame.Visible = rootVis
                            if rootVis then 
                                frame.Position = UDim2.new(0, (rootPos.X - frame.Size.X.Offset / 2* UIScale.Scale), 0, (headPos.Y - frame.Size.Y.Offset / 2) - 42)
                            end
                        end
                    end
                    for i,v in next, NametagsFolder:GetChildren() do 
                        if not PLAYERS:FindFirstChild(v.Name) or not isAlive(PLAYERS:FindFirstChild(v.Name)) then
                            v:Destroy()
                        end
                    end
                    debug.profileend()
                end)
            else
                UnbindFromStepped("Nametags")
                NametagsFolder:ClearAllChildren()
            end
        end
    })

    tagsscale = nametags.CreateSlider({
        Name = "Scale",
        Min = 0.8,
        Max = 1.5,
        RealMin = 0.8,
        RealMax = 5,
        Round = 1,
        Default = 1,
        Function = function() end,
    })
    --[[tagsarmor = nametags.CreateToggle({
        ["Name"] = "Armor",
        ["Function"] = function() end,
    })
    tagsitemname = nametags.CreateToggle({
        ["Name"] = "ItemName",
        ["Function"] = function() end,
    })]]
    tagshealth = nametags.CreateToggle({
        ["Name"] = "Health",
        ["Function"] = function() end,
    })
    doRenderRate = nametags.CreateToggle({
        Name = "RenderRate",
        Function = function() end
    })
    renderRate = nametags.CreateSlider({
        Name = "RenderRate",
        Function = function() end,
        Min = 10,
        Max = 240,
        Default = 60,
    })
end

do 
    local connections = {}
    local renamedInstances = {}
    local textservice = game:GetService("TextService")
    local namebox = {Value="Player"}
    local others = {Enabled=false}
    local othersnamebox = {Value="Other"}
    local function x(v) 
        local removed = v:gsub(lplr.Name, namebox.Value or "Player")
        :gsub(tostring(lplr.UserId), "1")
        :gsub(lplr.DisplayName, namebox.Value or "Player")
        if others.Enabled then
            for _,plr in next, PLAYERS:GetPlayers() do 
                removed = removed:gsub(plr.Name, othersnamebox.Value or "Other")
                :gsub(tostring(plr.UserId), "1")
                :gsub(plr.DisplayName, othersnamebox.Value or "Other")
            end
        end
        return removed
    end
    local function replace(v) 
        if pcall(function() return v.Text end) and typeof(v.Text)=="string" then
            renamedInstances[v] = {Original = v.Text, Property = "Text"}
            local y = x(v.Text)
            v.Text = y
            connections[#connections+1] = v:GetPropertyChangedSignal("Text"):connect(function() 
                renamedInstances[v].Original = v.Text
                v.Text = x(v.Text)
            end)
            return y
        end    
        if pcall(function() return v.Image end) and typeof(v.Image)=="string" then 
            renamedInstances[v] = {Original = v.Image, Property = "Image"}
            local y = x(v.Image)
            v.Image = y
            connections[#connections+1] = v:GetPropertyChangedSignal("Image"):connect(function() 
                renamedInstances[v].Original = v.Image
                v.Image = x(v.Image)
            end)
            return y
        end   
        return v
    end

    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldnamecall = mt.__namecall

    local StopFPSIssue = {Enabled = false}
    local NameProtect = {Enabled = false}
    NameProtect = GuiLibrary.Objects.RenderWindow.API.CreateOptionsButton({
        Name = "NameProtect",
        Function = function(callback) 
            if callback then 
                spawn(function()
                    for i,v in next, game:GetDescendants() do
                        replace(v)
                        if StopFPSIssue.Enabled and i % 500 == 0 then 
                            skipFrame()
                        end
                    end
                end)
                connections[#connections+1] = game.DescendantAdded:connect(function(v)
                    replace(v)
                end)
                mt.__namecall = newcclosure(function(self, ...) 
                    local args = {...}
                    local ncm = getnamecallmethod()
                    if ncm == "GetTextSize" and self == textservice then 
                        args[1] = replace(args[1])    
                    end
                    return oldnamecall(self, table.unpack(args))
                end)
            else
                for i,v in next, connections do 
                    v:Disconnect()
                    connections[i] = nil
                end
                mt.__namecall = oldnamecall
                for i,v in next, renamedInstances do 
                    if typeof(i)=="Instance" and i.Parent ~= nil then 
                        i[v.Property] = v.Original   
                    end
                end
            end
        end
    })
    namebox = NameProtect.CreateTextbox({
        Name = "Name",
        Function = function(callback) 
            if NameProtect.Enabled then
                NameProtect.Toggle()
                NameProtect.Toggle()
            end
        end,
        Default = "Player",
    })
    others = NameProtect.CreateToggle({
        Name = "Others",
        Function = function(callback) 
            if NameProtect.Enabled then
                NameProtect.Toggle()
                NameProtect.Toggle()
            end
            othersnamebox.Instance.Visible = callback
        end,
    })
    othersnamebox = NameProtect.CreateTextbox({
        Name = "Name",
        Function = function(callback) 
            if NameProtect.Enabled then
                NameProtect.Toggle()
                NameProtect.Toggle()
            end
        end,
        Default = "Other",
    })
    othersnamebox.Instance.Visible = false
    StopFPSIssue = NameProtect.CreateToggle({
        Name = "StopFreeze",
        Function = function(callback) end,
    })
end

do 
    local norenderconnection
    local norender = {["Enabled"] = false}
    local norenderparticles = {["Enabled"] = false}
    local norendertextures
    local norendercache = {}

    norender = GuiLibrary["Objects"]["RenderWindow"]["API"].CreateOptionsButton({
        ["Name"] = "NoRender",
        ["Function"] = function(callback) 
            if callback then 
                spawn(function()
                    repeat wait() until isAlive()
                    local norendertypes = {
                        ["ParticleEmitter"] = {["Property"] = "Enabled", ["SetTo"] = false, ["Variable"] = norenderparticles},
                        ["Explosion"] = {["Property"] = "Visible", ["SetTo"] = false, ["Variable"] = norenderparticles},
                        ["Sparkles"] = {["Property"] = "Enabled", ["SetTo"] = false, ["Variable"] = norenderparticles},
                        ["Fire"] = {["Property"] = "Enabled", ["SetTo"] = false, ["Variable"] = norenderparticles},
                        ["Smoke"] = {["Property"] = "Enabled", ["SetTo"] = false, ["Variable"] = norenderparticles}, 
                    }
                    for i,v in next, WORKSPACE:GetDescendants() do 
                        if norendertypes[v.ClassName] and norendertypes[v.ClassName].Variable.Enabled then
                            local x = norendertypes[v.ClassName]
                            norendercache[#norendercache+1] = {Instance = v, Property = x.Property, Was = v[x.Property]}
                            v[x.Property] = x.SetTo
                        end
                    end
                    norenderconnection = WORKSPACE.DescendantAdded:Connect(function(v) 
                        if norendertypes[v.ClassName] and norendertypes[v.ClassName].Variable.Enabled then 
                            local x = norendertypes[v.ClassName]
                            norendercache[#norendercache+1] = {Instance = v, Property = x.Property, Was = v[x.Property]}
                            v[x.Property] = x.SetTo
                        end
                    end)
                end)
            else
                for i,v in next, norendercache do 
                    if v.Instance and v.Property then
                        v.Instance[v.Property] = v.Was
                    end
                end
                norendercache = {}
                if norenderconnection then 
                    norenderconnection:Disconnect()
                    norenderconnection = nil
                end
            end
        end
    })
    norenderparticles = norender.CreateToggle({
        ["Name"] = "Effects",
        ["Function"] = function()
            if norender.Enabled then
                norender.Toggle()
                norender.Toggle()
            end
        end
    })
end

local ViewClip = GuiLibrary["Objects"]["RenderWindow"]["API"].CreateOptionsButton({
    ["Name"] = "ViewClip",
    ["Function"] = function(callback)
        if callback then
            lplr.DevCameraOcclusionMode = "Invisicam"
        else
            lplr.DevCameraOcclusionMode = "Zoom"
        end
    end,
})




-- // WorldWindow

do 
    local origGrav
    local connection
    local Gravity = {Enabled = false}
    local Intensity = {Value = 192}
    Gravity = GuiLibrary.Objects.WorldWindow.API.CreateOptionsButton({
        Name = "Gravity",
        Function = function(callback) 
            if callback then 
                origGrav = WORKSPACE.Gravity
                connection = WORKSPACE:GetPropertyChangedSignal("Gravity"):connect(function() 
                    if WORKSPACE.Gravity ~= Intensity.Value then
                        WORKSPACE.Gravity = Intensity.Value
                    end
                end)
                WORKSPACE.Gravity = Intensity.Value
            else
                if connection then
                    connection:Disconnect()
                    connection = nil 
                end
                WORKSPACE.Gravity = origGrav
            end
        end
    })
    Intensity = Gravity.CreateSlider({
        Name = "Intensity",
        Function = function(value) 
            if Gravity.Enabled then
                WORKSPACE.Gravity = value
            end
        end,
        Min = 0,
        Round = 0,
        Max = 192,
        Default = 192
    })
end

do
    local cachedparts = {}
    local wallhackopacity = {["Value"] = 0}
    local Wallhack = {["Enabled"] = false}
    local WallhackConnection
    local function refreshwallhack(callback) 
        if Wallhack.Enabled or callback==true then
            for i,v in next, WORKSPACE:GetDescendants() do 
                if v:IsA("BasePart") then
                    table.insert(cachedparts, v)
                    v.LocalTransparencyModifier = wallhackopacity["Value"] / 255
                end
            end
        end
    end
    Wallhack = GuiLibrary["Objects"]["WorldWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Wallhack",
        ["Function"] = function(callback) 
            if callback then 
                refreshwallhack(true)
                WallhackConnection = WORKSPACE.DescendantAdded:Connect(function(v) 
                    if v:IsA("BasePart") and not table.find(cachedparts, v) then 
                        table.insert(cachedparts, v)
                        v.LocalTransparencyModifier = wallhackopacity["Value"] / 255
                    end
                end)
            else
                for i,v in next, cachedparts do 
                    v.LocalTransparencyModifier = 0
                    cachedparts[i] = nil
                end
                if WallhackConnection then 
                    WallhackConnection:Disconnect() 
                    WallhackConnection = nil 
                end
            end
        end,
    })
    wallhackopacity = Wallhack.CreateSlider({
        ["Name"] = "Opacity",
        ["Function"] = function(value)
            refreshwallhack()
        end,
        ["Min"] = 0,
        ["Max"] = 255,
    })
end

do 
    -- most stupid and useless module
    local oldg, oldws
    local timerspeed = {["Value"] = 10}
    local Timer = {["Enabled"] = false}
    Timer = GuiLibrary["Objects"]["MiscellaneousWindow"]["API"].CreateOptionsButton({
        ["Name"] = "Timer",
        ["ArrayText"] = function() return timerspeed["Value"] end,
        ["Function"] = function(callback) 
            if callback then 
                oldg = oldg or WORKSPACE.Gravity
                WORKSPACE.Gravity = WORKSPACE.Gravity * (timerspeed["Value"] / 10)
                if GuiLibrary["Objects"]["SpeedOptionsButton"]["API"]["Enabled"] then 
                    GuiLibrary["Objects"]["SpeedOptionsButton"]["API"]["Toggle"](nil, true)
                end
                spawn(function()
                    if not isAlive() then repeat task.wait() until isAlive() end
                    oldws = oldws or lplr.Character.Humanoid.WalkSpeed
                    lplr.Character.Humanoid.WalkSpeed = lplr.Character.Humanoid.WalkSpeed * (timerspeed["Value"] / 10)

                    repeat skipFrame()
                        local tracks = lplr.Character.Humanoid:GetPlayingAnimationTracks()
                        for i,v in next, tracks do 
                            v:AdjustSpeed((timerspeed["Value"] / 10))
                        end
                    until not Timer["Enabled"]
                end)
            else
                WORKSPACE.Gravity = oldg
                if isAlive() then 
                    lplr.Character.Humanoid.WalkSpeed = oldws
                end
            end
        end
    })
    timerspeed = Timer.CreateSlider({
        ["Name"] = "Speed",
        ["Default"] = 10,
        ["Min"] = 1,
        ["Max"] = 7500,
        ["OnInputEnded"] = true,
        ["Function"] = function(value) 
            if Timer.Enabled then 
                Timer.Toggle() 
                Timer.Toggle()
            end
        end
    })
end

do
    local Heaven = {}
    local connection

    local function onStateFunc(old, new)
        if new == Enum.HumanoidStateType.Dead then 
            repeat task.wait() 
                lplr.Character.HumanoidRootPart.Anchored = true
                lplr.Character.HumanoidRootPart.CFrame = lplr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1,0)
            until ({pcall(function() return not lplr.Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead end)})[2]==true
        end
    end

    local function setupConnection() 
        local hum = lplr.Character:FindFirstChildWhichIsA("Humanoid")
        if not hum then 
            repeat task.wait() until lplr.Character:FindFirstChildWhichIsA("Humanoid")
            hum = lplr.Character:FindFirstChildWhichIsA("Humanoid")
        end
        connection = hum.StateChanged:Connect(function(old, new) 
            if Heaven.Enabled then
                pcall(onStateFunc,old, new)
                connection:Disconnect()
                setupConnection()
            end
        end)
    end

    Heaven = GuiLibrary.Objects.MiscellaneousWindow.API.CreateOptionsButton({
        Name = "Heaven",
        Function = function(callback)
            if callback then 
                spawn(function() 
                    if not isAlive() then repeat task.wait() until isAlive() end
                    pcall(setupConnection)
                end)
            else
                connection:Disconnect()
            end
        end
    })
end

do 
    local function getPlayerFromPart(target) 
        if not target then return end
        for i,v in next, PLAYERS:GetPlayers() do 
            if isAlive(v) then 
                if target:IsDescendantOf(v.Character) then 
                    return v
                end
            end
        end
    end

    local mcf = {Enabled = true}
    local inputconnection
    local MiddleClick = {Enabled = false}
    MiddleClick = GuiLibrary.Objects.MiscellaneousWindow.API.CreateOptionsButton({
        Name = "MiddleClick",
        Function = function(callback) 
            if callback then 
                inputconnection = UIS.InputBegan:connect(function(input) 
                    if input.UserInputType == Enum.UserInputType.MouseButton3 then 
                        local plr = getPlayerFromPart(mouse.Target)
                        if plr then 
                            if mcf.Enabled then 
                                Future.toggleFriend(plr.Name)
                            end
                        end
                    end
                end)
            else
                if inputconnection then inputconnection:Disconnect(); inputconnection = nil; end
            end
        end,
    })
end

do
    local function addtofile(plr, reason, result) 
        if not betterisfile("Future/reported.txt") then 
            writefile("Future/reported.txt", "-- FutureClient.xyz AutoReport logs.\n-- by engo#0320\n\n--LOG BEGIN --\n")
        end

        appendfile("Future/reported.txt", "reported "..plr.Name.." ("..tostring(plr.UserId)..") for "..reason.." for saying '"..result.."'\n")
    end

    local lastReport = -999
    local connections, queue = {}, {}

    local AutoReport = {Enabled = false}

    local function isqueued(tab) 
        for i,v in next, queue do 
            if v.result == tab.result and v.plr == tab.plr and v.reason == tab.reason and v.msg == tab.msg then
                return true
            end
        end
        return false
    end

    local function addtoqueue(msg, plr)
        if plr==lplr then
            return 
        end

        if AutoReport.Enabled == false then 
            return
        end

        local result, reason = SwearDetection(msg)
        local tab = {result = result, reason = reason, plr = plr, msg = msg, tick = tick()}
        if result and reason and (not isqueued(tab)) then 
            table.insert(queue, tab)
            local suc, ret = pcall(addtofile, plr, reason, result)
            if not suc and shared.FutureDeveloper then 
                warn(ret)
            end
        end
    end

    local function getnextqueue() 
        local nextInQueue = queue[1]
        table.remove(queue, 1)
        return {queue = queue, nextInQueue = nextInQueue, amt = #queue}
    end

    AutoReport = GuiLibrary.Objects.MiscellaneousWindow.API.CreateOptionsButton({
        Name = "AutoReport",
        Function = function(callback)
            if callback then 

                for i, v in next, PLAYERS:GetPlayers() do
                    connections[#connections+1] = v.Chatted:connect(function(msg) 
                        if SwearDetection(msg) then
                            addtoqueue(msg, v)
                        end
                    end)
                end
                connections[#connections+1] = PLAYERS.PlayerAdded:connect(function(v) 
                    connections[#connections+1] = v.Chatted:connect(function(msg) 
                        if SwearDetection(msg) then
                            addtoqueue(msg, v)
                        end
                    end)
                end)

                spawn(function()
                    repeat task.wait(0.1)

                        if tick() - lastReport >= 10 then
                            local nextqueue = getnextqueue()
                            local tab = nextqueue.nextInQueue

                            if nextqueue and tab then 
                                local message = "he said '"..tab.result.."' !!! pls ban him!!"

                                PLAYERS:ReportAbuse(tab.plr, tab.reason, message)
                                GuiLibrary.CreateToast("[AR] Reported "..tab.plr.DisplayName, "Reason: "..tab.reason.."\n"..message, 9.5)

                                lastReport = tick()
                            end
                        end

                    until not AutoReport.Enabled
                end)

            else
                for i,v in next, connections do 
                    v:Disconnect()
                    connections[i] = nil
                end
            end
        end
    })
end
