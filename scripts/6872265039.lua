repeat wait() until game:IsLoaded()
local Future = shared.Future
local GuiLibrary = Future.GuiLibrary
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local WORKSPACE = game:GetService("Workspace")
local PLAYERS = game:GetService("Players")
local lplr = PLAYERS.LocalPlayer
local mouse = lplr:GetMouse()
local cam = WORKSPACE.CurrentCamera
local getcustomasset = --[[getsynasset or getcustomasset or]] GuiLibrary["getRobloxAsset"]
local requestfunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or getgenv().request or request
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local bedwars = {} 
local spawn = function(func) 
    return coroutine.wrap(func)()
end
local betterisfile = function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil
end
-- skid("vape")

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
        print("[Future] downloaded "..path.." asset successfully!")
	end
	return getcustomasset(path) 
end

local HeartbeatTable = {}
local RenderStepTable = {}
local SteppedTable = {}
local function isAlive(plr)
    local plr = plr or lplr
    if plr and plr.Character and ((plr.Character:FindFirstChild("Humanoid")) and (plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("Humanoid").Health > 0) and (plr.Character:FindFirstChild("HumanoidRootPart"))) then
        return true
    end
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
local function BindToRenderStep(name, func)
	if RenderStepTable[name] == nil then
		RenderStepTable[name] = game:GetService("RunService").RenderStepped:connect(func)
	end
end
local function UnbindFromRenderStep(name)
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

local function getColorFromPlayer(v) 
    if v.Team ~= nil then return v.TeamColor.Color end
end

local function getremote(t)
    for i,v in next, t do 
        if v == "Client" then 
            return t[i+1]
        end
    end
end

local function getPlrNear(max)
    local nearestval, nearestnum = nil,max
    for i,v in next, PLAYERS:GetPlayers() do 
        if isAlive(v) and v~=lplr then 
            local diff = (lplr.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
            if diff < nearestnum then 
                nearestnum = diff 
                nearestval = v
            end
        end
    end
    return nearestval
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

local function getAllPlrsNear()
    if not isAlive() then return {} end
    local t = {}
    for i,v in next, PLAYERS:GetPlayers() do 
        if isAlive(v) and v~=lplr then 
            if v.Character.HumanoidRootPart then table.insert(t, (lplr.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude, v) end
        end
    end
    return t
end

local function canBeTargeted(plr, doTeamCheck) 
    if isAlive(plr) and plr~=lplr and (doTeamCheck and plr.Team ~=lplr.Team or not doTeamCheck) then 
        return true
    end
    return false
end

bedwars = {
    ["Remotes"] = {},
    ["QueueMeta"] = require(game:GetService("ReplicatedStorage").TS.game["queue-meta"]).QueueMeta,
    ["LobbyClientEvents"] = (require(game:GetService("ReplicatedStorage")["rbxts_include"]["node_modules"]["@easy-games"].lobby.out.client.events).LobbyClientEvents),
}

if shared.FutureSavedSessionInfo~= nil then 
    local api = shared.FutureSavedSessionInfo
    local st = api.startTime
    local stringtp = "shared.FutureSavedSessionInfo = {startTime ="..tostring(st)..", kills = "..api.kills..", wins = "..api.wins..", lagbacks = "..api.lagbacks.."}"
    queueteleport(stringtp)
end

do

    local function getQueueFromName(name)
        for i,v in pairs(bedwars.QueueMeta) do 
            if v.title == name and i:find("voice") == nil then
                return i
            end
        end
        return "bedwars_to1"
    end

    local QueueTypes = {}
    for i,v in pairs(bedwars["QueueMeta"]) do 
        if v.title:find("Test") == nil then
            table.insert(QueueTypes, v.title..(i:find("voice") and " (VOICE)" or ""))
        end
    end
    local selectedQueue = {["Value"] = "Solo"}
    local AutoQueue = {["Enabled"] = false}; AutoQueue = GuiLibrary["Objects"]["MiscellaneousWindow"]["API"].CreateOptionsButton({
        ["Name"] = "AutoQueue",
        ["Function"] = function(callback) 
            if callback then
                spawn(function()
                    repeat
                        game:GetService("ReplicatedStorage")["events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events"].joinQueue:FireServer({["queueType"] = getQueueFromName(selectedQueue["Value"])})
                        task.wait(30)
                    until AutoQueue["Enabled"] == false
                end)
            end
        end,
    })
    selectedQueue = AutoQueue.CreateSelector({
        ["Name"] = "",
        ["Function"] = function()
            if AutoQueue["Enabled"] then
                AutoQueue.Toggle()
                AutoQueue.Toggle()
            end
        end,
        ["List"] = QueueTypes
    })
end