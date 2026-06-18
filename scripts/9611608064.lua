repeat wait() until game:IsLoaded()
local Future = shared.Future
local GuiLibrary = Future.GuiLibrary
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local WORKSPACE = game:GetService("Workspace")
local PLAYERS = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local lplr = PLAYERS.LocalPlayer
local mouse = lplr:GetMouse()
local cam = WORKSPACE.CurrentCamera
local getcustomasset = getsynasset or getcustomasset
local requestfunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or getgenv().request or request
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local spawn = function(func) 
    return coroutine.wrap(func)()
end
local br = {}

local function requesturl(url, bypass) 
    if isfile(url) and shared.FutureDeveloper then 
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
	if not isfile(path) then
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
    if plr and plr.Character and ((plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("Humanoid").Health > 0) or (plr.Character:FindFirstChild("HumanoidRootPart"))) then
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

local function canBeTargeted(plr, doTeamCheck) 
    return isAlive(plr) and lplr~=plr
end

local function getCharNearMouse(max)
    local max = max or 99999999999999
    local nearestval, nearestnum = nil,max
    for i,v in next, br.ChickynoidClient.characters do 
        local pos, vis = WORKSPACE.CurrentCamera:WorldToScreenPoint(v.HumanoidRootPart.Position)
        if vis and pos then 
            local diff = (UIS:GetMouseLocation() - Vector2.new(pos.X, pos.Y)).Magnitude
            if diff < nearestnum then 
                nearestnum = diff 
                nearestval = v
            end
        end
    end
    return nearestval
end

local Flamework = require(RS.rbxts_include.node_modules["@flamework"].core.out.flamework).Flamework
repeat task.wait() until Flamework.isInitialized
br = {
    ["ClientStoreController"] = Flamework.resolveDependency("client/controllers/global/rodux/rodux-controller@RoduxController"),
    ["CrosshairController"] = Flamework.resolveDependency("client/controllers/global/crosshair/crosshair-controller@CrosshairController"),
    ["ChickynoidClient"] = require(RS.rbxts_include.node_modules.chickynoid.src).ChickynoidClient,
    ["EntityController"] = Flamework.resolveDependency("@easy-games/damage:client/controllers/entity/entity-controller@EntityController"),
    ["EntityService"] = Flamework.resolveDependency("@easy-games/damage:server/services/entity/entity-service@EntityService"),
    ["GunController"] = Flamework.resolveDependency("client/controllers/global/gun/gun-controller@GunController"),
    ["GunUtil"] = require(RS.TS.gun["gun-util"]).GunUtil,
    ["ItemPickupController"] = Flamework.resolveDependency("client/controllers/global/ground-item/item-pickup-controller@ItemPickupController"),
    ["ItemTable"] = require(RS.TS.item["item-meta"]).RoyaleItemMeta,
    ["InventoryController"] = Flamework.resolveDependency("client/controllers/global/inventory/inventory-controller@InventoryController")
}

local function getCharacter(id) 
    local id = typeof(id) == 'number' and id or id.UserId
    local entitys = br.ChickynoidClient.characters
    if not entitys then 
        return
    end

    for i,v in next, entitys do 
        if v.characterModel.userId == id then
            return v.characterModel.model
        end
    end
end

local function getEntity(from) 
    local from = typeof(from) == 'Instance' and (from:IsA("Player") and getCharacter(from) or from:IsA("Model") and from)
    if not from then 
        return warn("Attempt to get entity from invalid type.")
    end

end

local function getPlayer(char) 
    local entitys = br.ChickynoidClient.characters
    if not entitys then 
        return
    end

    for i,v in next, entitys do 
        if v.characterModel.model == char then
            return PLAYERS:GetPlayerByUserId(v.characterModel.userId)
        end
    end
end
--setclipboard(tabletostring(br.ChickynoidClient.characters))


if not shared._FUTURECACHED then do 
    local old
    old = hookmetamethod(game, "__index", newcclosure(function(self, key, ...) 
        if checkcaller() and shared.Future then
            if self:IsA("Player") and key == "Character" then  
                return getCharacter(self)
            end

            if self:IsA("Humanoid") and key == "Health" then 
                local plr = getPlayer(self.Parent)
                if plr then 
                    --return get heatlh somehow idk cba rn
                end
            end
        end 

        return old(self, key, ...)
    end))
end end
