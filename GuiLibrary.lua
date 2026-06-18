-- // New gui library for future roblox.
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local WORKSPACE = game:GetService("Workspace")
local HTTPSERVICE = game:GetService("HttpService")
local STARTERGUI = game:GetService("StarterGui")
local COREGUI = game:GetService("CoreGui")
local PLAYERS = game:GetService("Players")
local lplr = PLAYERS.LocalPlayer
local mouse = lplr:GetMouse()
local cam = WORKSPACE.CurrentCamera
local requestfunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or getgenv().request or request
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local spawn = function(func) 
    return coroutine.wrap(func)()
end
local betterisfile = function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil
end
local chatchildaddedconnection
local GuiLibrary = {
    getRobloxAsset = function(path) 
        local name = path:split("/")[#path:split("/")]
        if name == "arrow.png" then
            return "rbxassetid://8904422926" 
        elseif name == "gear.png" then
            return "rbxassetid://8905804106"
        elseif name == "click.mp3" then 
            return "rbxassetid://535716488"
        end
    end,
    ColorTheme = {["H"] = 1, ["S"] = 1, ["V"] = 0.7}, 
    Objects = {}, 
    Signals = {}, 
    Rainbow = false,
    RainbowSpeed = 10,
    WindowX = 40,
    Connections = {},
    ClickSounds = true,
    GuiKeybind = "RightShift",
    CurrentConfig = "default",
    AllowNotifications = true,
    HUDEnabled = true,
    CurrentToast = nil,
    ArrayList = false,
    ListBackground = false,
    ListLines = false,
    DrawWatermark = false,
    WatermarkBackground = false,
    WatermarkLine = false,
    Rendering = "Up",
    DrawCoords = false,
    DrawSpeed = false,
    DrawFPS = false,
    DrawPing = false,
    TargetHUDEnabled = false,
    Font = Enum.Font.GothamSemibold,
    TextSize = 19.000,
    TargetHUD = {
        Position = {
            X = {
                Scale = 0,
                Offset = 0,
            },
            Y = {
                Scale = 0,
                Offset = 0,
            },
        },
    },
    ArrayListInfo = {
        Position = {
            X = {
                Scale = 0,
                Offset = 0,
            },
            Y = {
                Scale = 0,
                Offset = 0,
            },
        },
    },
    HUDElements = {
        Position = {
            X = {
                Scale = 0,
                Offset = 0,
            },
            Y = {
                Scale = 0,
                Offset = 0,
            },
        },
    },
}
local getcustomasset = --[[getsynasset or getcustomasset or]] GuiLibrary.getRobloxAsset
local exclusionList = {
    "ConfigOptionsButton", "DestructOptionsButton", "HUDOptionsButton", 
    "ClickGuiOptionsButton", "ColorsOptionsButton", "DiscordOptionsButton",
    "HUDOptionsButtonNotificationsToggle", "ColorsOptionsButtonRainbowToggle", "ClickGuiOptionsButtonClickSoundsToggle",
    "HUDOptionsButtonArrayListToggle", "HUDOptionsButtonListBackgroundToggle", "HUDOptionsButtonListLinesToggle", "HUDOptionsButtonWatermarkToggle",
    "HUDOptionsButtonWMLineToggle", "HUDOptionsButtonWMBackgroundToggle", "HUDOptionsButtonRenderingSelector",
    "HUDOptionsButtonFPSToggle", "HUDOptionsButtonSpeedToggle", "HUDOptionsButtonCoordsToggle", "HUDOptionsButtonPingToggle", "HUDOptionsButtonTargetHUDToggle",
    "RestartOptionsButton", "FontOptionsButton", "FontOptionsButtonTextSizeSlider", "ConfigOptionsButtonConfigNameTextbox"
}

local ScreenGui = Instance.new("ScreenGui", gethui and gethui() or COREGUI:FindFirstChild("RobloxGui") or COREGUI)
ScreenGui.Name = tostring("RobloxVRGui")
local ClickGUI = Instance.new("Frame", ScreenGui)
ClickGUI.Size = UDim2.new(1,0,1,0)
ClickGUI.BackgroundTransparency = 1
ClickGUI.Name = "ClickGUI"
ClickGUI.Visible = false
local NotificationWindow = Instance.new("Frame")
NotificationWindow.BackgroundTransparency = 1
NotificationWindow.Active = false
NotificationWindow.Size = UDim2.new(1, 0, 1, 0)
NotificationWindow.Name = "NotificationWindow"
NotificationWindow.Parent = ScreenGui
GuiLibrary["ScreenGui"] = ScreenGui
GuiLibrary["ClickGUI"] = ClickGUI
makefolder("Future")
makefolder("Future/logs")
makefolder("Future/assets")
makefolder("Future/configs")
makefolder("Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId))
makefolder("Future/configs/!SelectedConfigs/")

local function requesturl(url, bypass) 
    if betterisfile(url) then 
        return readfile(url)
    end
    local repourl = bypass and "https://raw.githubusercontent.com/joeengo/" or "https://raw.githubusercontent.com/joeengo/Future/main/"

    local req = requestfunc({
        Url = repourl..url,
        Method = "GET"
    })
    if req.StatusCode == 404 then error("404 Not Found") end
    return req.Body
end 

local function getasset(path)
	--[[if not betterisfile(path) then
		local req = requestfunc({
			Url = "https://raw.githubusercontent.com/joeengo/Future/main/"..path:gsub("Future/assets", "assets"),
			Method = "GET"
		})
        print("[Future] downloading "..path.." asset.")
		writefile(path, req.Body)
        repeat task.wait() until betterisfile(path)
        print("[Future] downloaded "..path.." asset successfully!")
	end]]
	return GuiLibrary.getRobloxAsset(path) 
end

--[[
if betterisfile("Future/logs/latestmove.log") then 
    local data = readfile("Future/logs/latestmove.log")
    delfile("Future/logs/latestmove.log")
    local date = data:split("\n")[1]
    writefile(("Future/logs/"..date:gsub(" ", "_"):gsub("[^%w%s_:-]+", ""):gsub(":", "-")..".log"), data)
end
if betterisfile("Future/latest.log") then 
    local data = readfile("Future/latest.log")
    delfile("Future/latest.log")
    writefile(("Future/logs/latestmove.log"), data)
end
local function log(sys, mes) 
    local timePrefix = ("[%s] | "):format(os.date("%c").." "..os.date("%Z"))
    local prefix = timePrefix.." ["..tostring(sys).."] "
    local toPush = prefix..tostring(mes).."\n"

    if not betterisfile("Future/latest.log") then 
        writefile("Future/latest.log", os.date("%c").."\n"..toPush)
    else
        appendfile("Future/latest.log", toPush)
    end
end
log("Startup", "---- BEGIN LOG ----")
log("Startup", "Starting GUILibrary")
]]
local function log() end

local function colortotable(color)
    if color:ToHSV() then
        local h,s,v = color:ToHSV()
        return {h=h,s=s,v=v}
    else
        local r,g,b = color.R, color.G, color.B
        return {r=r,g=g,b=b}
    end
end

local function tabletocolor(tab)
    if tab.v then 
        return Color3.fromHSV(tab.h, tab.s, tab.v)
    else
        return Color3.fromRGB(tab.r, tab.g, tab.b)
    end
end

local function HSVtoRGB(color) 
    local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
    return Color3.fromRGB(r,g,b)
end

local function colorToRichText(color) 
    return " rgb("..tostring(color.R*255)..", "..tostring(color.G*255)..", "..tostring(color.B*255)..")"
end

local function RelativeXY(GuiObject, location)
    local x, y = location.X - GuiObject.AbsolutePosition.X, location.Y - GuiObject.AbsolutePosition.Y
    local x2 = 0
    local xm, ym = GuiObject.AbsoluteSize.X, GuiObject.AbsoluteSize.Y
    x2 = math.clamp(x, 4, xm - 6)
    x = math.clamp(x, 0, xm)
    y = math.clamp(y, 0, ym)
    return x, y, x/xm, y/ym, x2/xm
end

local function getRichTextElements(text) 
    local renderedText = text:match("<.*>(.*)<.*>")
    return renderedText, text:gsub(renderedText, "") -- return text that will be rendered and the tags
end

local function dragGUI(gui, dragpart)
    spawn(function()
        local dragging
        local dragInput
        local dragStart = Vector3.new(0,0,0)
        local startPos
        local function update(input)
            local delta = input.Position - dragStart
            local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (delta.X), startPos.Y.Scale, startPos.Y.Offset + (delta.Y))
            game:GetService("TweenService"):Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
        end
        dragpart.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and dragging == false then
                    dragStart = input.Position
                    local delta = (input.Position - dragStart)
                    if delta.Y <= 30 then
                        dragging = ClickGUI.Visible
                        startPos = gui.Position
                        
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                dragging = false
                            end
                        end)
                    end
                end
        end)
        dragpart.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
    end)
end
GuiLibrary["DragGUI"] = dragGUI
local SignalLib = loadstring(requesturl("roblox/main/SignalLib.lua", true))()
local function createsignal(name) 
    local signal = SignalLib.new()
    GuiLibrary["Signals"][name] = signal
    return signal
end
local onDestroySignal = createsignal("onDestroy")
local hudUpdate = createsignal("HUDUpdate")
local statsUpdate = createsignal("statsUpdate")
local clickGuiToggle = createsignal("clickGuiToggle")
-- // Color Management
local updatecolor = createsignal("UpdateColor")
spawn(function() 
    local i = 0
    repeat
        if GuiLibrary["Rainbow"] then
            local h,s,v= GuiLibrary.ColorTheme.H,GuiLibrary.ColorTheme.S,GuiLibrary.ColorTheme.V
            GuiLibrary["ColorTheme"] = {H=i, S=s, V=v}
            GuiLibrary["Signals"]["UpdateColor"]:Fire(GuiLibrary["ColorTheme"])
            i = i + 0.000025 * (GuiLibrary["RainbowSpeed"]*2.5)
            if i > 1 then 
                i = 0
            end
        end
        task.wait()
    until not shared.Future
end)
log("Startup", "Starting Signals")


local function playsound(id, volume) 
    local sound = Instance.new("Sound")
    sound.Parent = workspace
    sound.SoundId = id
    sound.PlayOnRemove = true 
    if volume then 
        sound.Volume = volume
    end
    sound:Destroy()
end

local function playclicksound() 
    if GuiLibrary["ClickSounds"] then
        playsound(getasset("Future/assets/click.mp3"))
    end
end

local function prepareTableForArrayList(t) 
    local t = t or {}
    local newT = {}
    for i,v in pairs(t) do 
        if v.Type == "OptionsButton" and not table.find(exclusionList, v.Name.."OptionsButton") and v.API.Enabled then 
            newT[#newT+1] = v
        end
    end
    table.sort(newT, function(a,b)
        local atext = a.Name.." "
        if type(a.ArrayText)=="function" then
            atext = atext.."["..tostring(a.ArrayText()).."] "
        end
        local btext = b.Name.." "
        if type(b.ArrayText)=="function" then
            btext = btext.."["..tostring(b.ArrayText()).."] "
        end
        local vec = game:GetService("TextService"):GetTextSize(atext, GuiLibrary.TextSize, GuiLibrary.Font, Vector2.new(99999, 99999))
        local vec2 = game:GetService("TextService"):GetTextSize(btext, GuiLibrary.TextSize, GuiLibrary.Font, Vector2.new(99999, 99999))
        --if GuiLibrary["ArrayList"]["Bottom"] then 
            --return vec.X < vec2.X
        --else
            return vec.X > vec2.X 
        --end
    end)
    return newT
end

local function textbound(instance, xadd, yadd) 

    instance.AutomaticSize = Enum.AutomaticSize.X

    --[[local xadd,yadd = xadd or 0,yadd or 0
    if not instance.ClassName:find("Text") then return end
    local function doIt()
        local X,Y = instance.TextBounds.X, instance.TextBounds.Y
        instance.Size = UDim2.new(instance.Size.X.Scale, X+xadd, instance.Size.Y.Scale, Y+yadd)
    end
    doIt()
    local connection = instance:GetPropertyChangedSignal("Text"):Connect(doIt)
    return connection]]
end
GuiLibrary["GetColor"] = function() 
    return Color3.fromHSV(GuiLibrary.ColorTheme.H, GuiLibrary.ColorTheme.S, GuiLibrary.ColorTheme.V)
end

local function bettertween(obj, newpos, dir, style, tim, override)
    spawn(function()
        local frame = Instance.new("Frame")
        frame.Visible = false
        frame.Position = obj.Position
        frame.Parent = ScreenGui
        frame:GetPropertyChangedSignal("Position"):Connect(function()
            obj.Position = UDim2.new(obj.Position.X.Scale, obj.Position.X.Offset, frame.Position.Y.Scale, frame.Position.Y.Offset)
        end)
        pcall(function()
            frame:TweenPosition(newpos, dir, style, tim, override)
        end)
        frame.Parent = nil
        task.wait(tim)
        frame:Remove()
    end)
end

local function bettertween2(obj, newpos, dir, style, tim, override)
    spawn(function()
        local frame = Instance.new("Frame")
        frame.Visible = false
        frame.Position = obj.Position
        frame.Parent = ScreenGui
        frame:GetPropertyChangedSignal("Position"):Connect(function()
            obj.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, obj.Position.Y.Scale, obj.Position.Y.Offset)
        end)
        pcall(function()
            frame:TweenPosition(newpos, dir, style, tim, override)
        end)
        frame.Parent = nil
        task.wait(tim)
        frame:Remove()
    end)
end

local NotificationSize = UDim2.new(0, 300, 0, 100)
GuiLibrary["CreateToast"] = function(title, text, showtime) 
    spawn(function()
        local showtime = showtime or 2
        local title = title or "Notification"
        local text = text or "No text has been put here..."

        local offset = #NotificationWindow:GetChildren()
        local ToastNotification = Instance.new("Frame")
        local Topbar = Instance.new("Frame")
        local Bottombar = Instance.new("Frame")
        local Title = Instance.new("TextLabel")
        local Text = Instance.new("TextLabel")
        ToastNotification.Name = "ToastNotification"
        ToastNotification.Parent = NotificationWindow
        ToastNotification.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        ToastNotification.BackgroundTransparency = 0.250
        ToastNotification.BorderSizePixel = 0
        ToastNotification.Position = UDim2.new(1, 0, 1, -((5 + NotificationSize.Y.Offset) * (offset + 1)))
        ToastNotification.Size = NotificationSize
        Topbar.Name = "Topbar"
        Topbar.Parent = ToastNotification
        Topbar.BackgroundColor3 = GuiLibrary["GetColor"]()
        Topbar.BackgroundTransparency = 0.6
        Topbar.BorderSizePixel = 0
        Topbar.Size = UDim2.new(0, NotificationSize.X.Offset, 0, NotificationSize.Y.Offset/3.16)
        Bottombar.Name = "Bottombar"
        Bottombar.Parent = ToastNotification
        Bottombar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Bottombar.BackgroundTransparency = 0.6
        Bottombar.BorderSizePixel = 0
        Bottombar.Size = UDim2.new(0, NotificationSize.X.Offset, 0, 5)
        Bottombar.Position = UDim2.new(0.5,0, 1, -5)
        Bottombar.AnchorPoint = Vector2.new(0.5, 0)
        Title.Name = "Title"
        Title.Parent = Topbar
        Title.BackgroundTransparency = 1.000
        Title.Position = UDim2.new(0.0260000005, 0, 0, 0)
        Title.Size = UDim2.new(0, NotificationSize.X.Offset/1.16326531, 0, NotificationSize.Y.Offset/3.16)
        Title.Font = GuiLibrary.Font
        Title.Text = title
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = GuiLibrary.TextSize
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Text.Name = "Text"
        Text.Parent = ToastNotification
        Text.BackgroundTransparency = 1.000
        Text.Position = UDim2.new(0.0260000005, 0, 0, Topbar.Size.Y.Offset + 5)
        Text.Size = UDim2.new(0, NotificationSize.X.Offset/1.14, 0, NotificationSize.Y.Offset/1.05333333)
        Text.Font = GuiLibrary.Font
        Text.Text = text
        Text.TextColor3 = Color3.fromRGB(255, 255, 255)
        Text.TextSize = GuiLibrary.TextSize
        Text.TextWrapped = true
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.TextYAlignment = Enum.TextYAlignment.Top
        local toDis = GuiLibrary["Signals"]["UpdateColor"]:connect(function() 
            Topbar.BackgroundColor3 = GuiLibrary["GetColor"]()
        end)

        bettertween2(ToastNotification, UDim2.new(1, -(NotificationSize.X.Offset + 10), 1, -((5 + NotificationSize.Y.Offset) * (offset + 1))), Enum.EasingDirection.In, Enum.EasingStyle.Sine, 0.15, true)
        task.wait(0.15)
        pcall(function()
            Bottombar:TweenSize(UDim2.new(0, 0, 0, 5), Enum.EasingDirection.In, Enum.EasingStyle.Linear, showtime, true)
        end)
        task.wait(showtime)
        bettertween2(ToastNotification, UDim2.new(1, 0, 1, ToastNotification.Position.Y.Offset), Enum.EasingDirection.In, Enum.EasingStyle.Sine, 0.15, true)
        task.wait(0.15)
        ToastNotification:Destroy()
        toDis:Disconnect()
    end)
end

NotificationWindow.ChildRemoved:Connect(function()
    for i,v in pairs(NotificationWindow:GetChildren()) do
        bettertween(v, UDim2.new(1, v.Position.X.Offset, 1, -((5 + NotificationSize.Y.Offset) * (i - 1))), Enum.EasingDirection.In, Enum.EasingStyle.Sine, 0.15, true)
    end
end)

GuiLibrary["PrepareTargetHUD"] = function() 
    local api = {}

    local TargetHUD = Instance.new("Frame")
    local Topbar = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local MainContainer = Instance.new("Frame")
    local Headshot = Instance.new("ImageLabel")
    local Name = Instance.new("TextLabel")
    local Health = Instance.new("TextLabel")
    local Distance = Instance.new("TextLabel")

    TargetHUD.Name = "TargetHUD"
    TargetHUD.Parent = GuiLibrary["ScreenGui"]
    TargetHUD.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TargetHUD.BackgroundTransparency = 0.250
    TargetHUD.BorderSizePixel = 0
    TargetHUD.Position = UDim2.new(0.5, 0, 0.5, 0)
    TargetHUD.Size = UDim2.new(0, 204, 0, 100)
    TargetHUD.Visible = false

    Topbar.Name = "Topbar"
    Topbar.Parent = TargetHUD
    Topbar.BackgroundColor3 = GuiLibrary["GetColor"]()
    Topbar.BackgroundTransparency = 0.600
    Topbar.BorderSizePixel = 0
    Topbar.Size = UDim2.new(0, 204, 0, 23)

    Title.Name = "Title"
    Title.Parent = Topbar
    Title.AnchorPoint = Vector2.new(0.5, 0.5)
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1.000
    Title.BorderSizePixel = 0
    Title.Position = UDim2.new(0.05, 0, 0.5, 0)
    Title.Size = UDim2.new(0, 10, 0, 23)
    Title.Font = GuiLibrary.Font
    Title.Text = "Target"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = GuiLibrary.TextSize
    Title.TextXAlignment = Enum.TextXAlignment.Left

    MainContainer.Name = "MainContainer"
    MainContainer.Parent = TargetHUD
    MainContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MainContainer.BackgroundTransparency = 1.000
    MainContainer.BorderSizePixel = 0
    MainContainer.Position = UDim2.new(0, 0, 0.230000004, 0)
    MainContainer.Size = UDim2.new(0, 204, 0, 77)

    Headshot.Name = "Headshot"
    Headshot.Parent = MainContainer
    Headshot.AnchorPoint = Vector2.new(0, 0.5)
    Headshot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Headshot.BackgroundTransparency = 1.000
    Headshot.Position = UDim2.new(0.0500000007, 0, 0.5, 0)
    Headshot.Size = UDim2.new(0, 50, 0, 50)
    --Headshot.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=420&h=420"

    Name.Name = "Name"
    Name.Parent = MainContainer
    Name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Name.BackgroundTransparency = 1.000
    Name.Position = UDim2.new(0.328431368, 0, 0.175324678, 0)
    Name.Size = UDim2.new(0, 130, 0, 16)
    Name.Font = GuiLibrary.Font
    Name.Text = ""
    Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    Name.TextSize = GuiLibrary.TextSize
    Name.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    Name.TextXAlignment = Enum.TextXAlignment.Left

    Health.Name = "Health"
    Health.Parent = MainContainer
    Health.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Health.BackgroundTransparency = 1.000
    Health.Position = UDim2.new(0.328431368, 0, 0.396103919, 0)
    Health.Size = UDim2.new(0, 130, 0, 16)
    Health.Font = GuiLibrary.Font
    Health.Text = ""
    Health.TextColor3 = Color3.fromRGB(255, 255, 255)
    Health.TextSize = GuiLibrary.TextSize
    Health.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    Health.TextXAlignment = Enum.TextXAlignment.Left

    Distance.Name = "Distance"
    Distance.Parent = MainContainer
    Distance.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Distance.BackgroundTransparency = 1.000
    Distance.Position = UDim2.new(0.328431368, 0, 0.603896141, 0)
    Distance.Size = UDim2.new(0, 130, 0, 16)
    Distance.Font = GuiLibrary.Font
    Distance.Text = ""
    Distance.TextColor3 = Color3.fromRGB(255, 255, 255)
    Distance.TextSize = GuiLibrary.TextSize
    Distance.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    Distance.TextXAlignment = Enum.TextXAlignment.Left

    local toDis = GuiLibrary["Signals"]["UpdateColor"]:connect(function() 
        Topbar.BackgroundColor3 = GuiLibrary["GetColor"]()
    end)

    dragGUI(TargetHUD, Topbar)

    function api.draw() 
        TargetHUD.Visible = true
    end

    function api.undraw() 
        TargetHUD.Visible = false
    end

    function api.update(plr, health, distance) 
        api.target = plr
        TargetHUD.Visible = true
        Headshot.Image = "rbxthumb://type=AvatarHeadShot&id="..tostring(plr.UserId).."&w=420&h=420"
        Name.Text = plr.Name
        Health.Text = tostring(health or plr.Character:FindFirstChildOfClass("Humanoid").Health).." HP"
        Distance.Text = tostring((math.round((tonumber(distance) or (plr.Character.PrimaryPart.Position - lplr.Character.PrimaryPart.Position).Magnitude)*100)/100)).." studs away"
    end

    function api.clear() 
        api.target = nil
        Headshot.Image = ""
        Name.Text = ""
        Health.Text = ""
        Distance.Text = ""
        TargetHUD.Visible = GuiLibrary.ClickGUI.Visible
    end

    function api.setPosition(pos) 
        TargetHUD.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset)
    end

    function api.getPosition() 
        return TargetHUD.Position
    end

    return api
end
GuiLibrary["TargetHUDAPI"] = GuiLibrary["PrepareTargetHUD"]()

GuiLibrary["PrepareHUDAPI"] = function() 
    local api = {}

    local Coords = Instance.new("TextLabel")
    local Speed = Instance.new("TextLabel")
    local FPS = Instance.new("TextLabel")
    local Ping = Instance.new("TextLabel")
    local HUDElements = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")

    HUDElements.Name = "HUDElements"
    HUDElements.Parent = GuiLibrary["ScreenGui"]
    HUDElements.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HUDElements.BackgroundTransparency = 1.000
    HUDElements.Position = UDim2.new(0.5, 0, 0.5, 0)
    HUDElements.Size = UDim2.fromOffset(200, 15)

    function api.setPosition(pos) 
        HUDElements.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset)
    end

    function api.getPosition() 
        return HUDElements.Position
    end

    dragGUI(HUDElements, HUDElements)

    UIListLayout.Parent = HUDElements
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    function api.draw(CoordsBool, SpeedBool, FPSBool, PingBool)
        --HUDElements.Size = UDim2.fromOffset(UIListLayout.AbsoluteContentSize.X, UIListLayout.AbsoluteContentSize.Y)

        if CoordsBool then
            Coords.Name = "Coords"
            Coords.Visible = true
            Coords.Parent = HUDElements
            Coords.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Coords.BackgroundTransparency = 1.000
            Coords.Size = UDim2.new(0, 200, 0, 20)
            Coords.Font = GuiLibrary.Font
            Coords.RichText = true
            Coords.Text = ""
            Coords.TextStrokeTransparency = 0
            Coords.TextColor3 = Color3.fromRGB(255,255,255)
            Coords.TextSize = GuiLibrary.TextSize --0.000
            Coords.TextXAlignment = Enum.TextXAlignment.Right
        end
        
        if SpeedBool then
            Speed.Name = "Speed"
            Speed.Visible = true
            Speed.Parent = HUDElements
            Speed.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Speed.BackgroundTransparency = 1.000
            Speed.Position = UDim2.new(0, 0, 0.195512831, 0)
            Speed.Size = UDim2.new(0, 200, 0, 20)
            Speed.Font = GuiLibrary.Font
            Speed.RichText = true
            Speed.Text = ""
            Speed.TextStrokeTransparency = 0.2
            Speed.TextColor3 = Color3.fromRGB(255,255,255)
            Speed.TextSize = GuiLibrary.TextSize --0.000
            Speed.TextXAlignment = Enum.TextXAlignment.Right
        end

        if PingBool then 
            Ping.Name = "Ping"
            Ping.Visible = true
            Ping.Parent = HUDElements
            Ping.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Ping.BackgroundTransparency = 1.000
            Ping.Position = UDim2.new(0, 0, 0.391025662, 0)
            Ping.Size = UDim2.new(0, 200, 0, 20)
            Ping.Font = GuiLibrary.Font
            Ping.RichText = true
            Ping.Text = ""
            Ping.TextStrokeTransparency = 0
            Ping.TextColor3 = Color3.fromRGB(255,255,255)
            Ping.TextSize = GuiLibrary.TextSize --0.000
            Ping.TextXAlignment = Enum.TextXAlignment.Right
        end
        
        if FPSBool then
            FPS.Name = "FPS"
            FPS.Visible = true
            FPS.Parent = HUDElements
            FPS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            FPS.BackgroundTransparency = 1.000
            FPS.Position = UDim2.new(0, 0, 0.391025662, 0)
            FPS.Size = UDim2.new(0, 200, 0, 20)
            FPS.Font = GuiLibrary.Font
            FPS.RichText = true
            FPS.Text = ""
            FPS.TextStrokeTransparency = 0
            FPS.TextColor3 = Color3.fromRGB(255,255,255)
            FPS.TextSize = GuiLibrary.TextSize --0.000
            FPS.TextXAlignment = Enum.TextXAlignment.Right
        end

        if FPSBool or CoordsBool or SpeedBool or PingBool then
            local Connection = GuiLibrary["Signals"]["statsUpdate"]:connect(function(curCoords, curSpeed, curFPS, curPing) 
                if CoordsBool then 
                    local x = math.round(curCoords.X *10)/10
                    x = (math.round(x) == x and tostring(x)..".0") or tostring(x)
                    local y = math.round(curCoords.Y *10)/10
                    y = (math.round(y) == y and tostring(y)..".0") or tostring(y)
                    local z = math.round(curCoords.Z *10)/10
                    z = (math.round(z) == z and tostring(z)..".0") or tostring(z)
                    Coords.Text = ("<font color='rgb(190,190,190)'>XYZ</font> <font color='rgb(255,255,255)'>%s</font>"):format(x..", "..y..", "..z)
                end

                if SpeedBool then
                    Speed.Text = "<font color='rgb(190,190,190)'>Speed</font> <font color='rgb(255,255,255)'>"..tostring(curSpeed).."km/h</font>"
                end

                if FPSBool then 
                    FPS.Text = "<font color='rgb(190,190,190)'>FPS</font> <font color='rgb(255,255,255)'>"..tostring(curFPS).."</font>"
                end

                if PingBool then 
                    Ping.Text = "<font color='rgb(190,190,190)'>Ping</font> <font color='rgb(255,255,255)'>"..tostring(math.round(curPing)).."</font>"
                end
            end)
        end
    end

            
    function api.undraw() 
        if Coords then 
            Coords.Visible = false
        end
        if Speed then 
            Speed.Visible = false
        end
        if FPS then 
            FPS.Visible = false
        end
        if Ping then 
            Ping.Visible = false
        end
    end

    api.Instance = HUDElements
    api.UIListLayout = UIListLayout

    return api
end
GuiLibrary["HUDAPI"] = GuiLibrary["PrepareHUDAPI"]()

GuiLibrary["PrepareWatermark"] = function()
    local api = {}

    local connection, Watermark, Shadow, Line

    function api.draw() 
        Watermark = Instance.new("TextLabel")
        Watermark.Name = "Watermark"
        Watermark.Parent = GuiLibrary["ScreenGui"]
        Watermark.BackgroundColor3 = Color3.fromRGB(0,0,0)
        Watermark.BackgroundTransparency = 1.000
        Watermark.Position = UDim2.new(0, 110, 0, -27)
        Watermark.Size = UDim2.new(0, 0, 0, 20)
        Watermark.Font = GuiLibrary.Font
        Watermark.Text = "Future"..(isfolder("Future/plus") and "+" or "").." v"..tostring(shared._FUTUREVERSION).." | "..tostring(shared._FUTUREMOTD)
        Watermark.BorderSizePixel = 0
        Watermark.TextSize = GuiLibrary.TextSize --0.000
        Watermark.TextStrokeTransparency = 0.4
        Watermark.TextXAlignment = Enum.TextXAlignment.Center
        Watermark.TextColor3 = GuiLibrary["GetColor"]()
        Watermark.AutomaticSize = Enum.AutomaticSize.X

        Shadow = Instance.new("TextLabel")
        Shadow.Name = "Background"
        Shadow.Parent = Watermark
        Shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
        Shadow.BackgroundTransparency = GuiLibrary["WatermarkBackground"] and 0.5 or 1
        Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        Shadow.AnchorPoint = Vector2.new(0.5,0.5)
        local vec = Watermark.AbsoluteSize + Vector2.new(5, 0)
        Shadow.Size = UDim2.new(0, vec.X, 0, vec.Y)
        Shadow.Font = GuiLibrary.Font
        Shadow.Text = ""
        Shadow.BorderSizePixel = 0
        Shadow.ZIndex = -1
        Shadow.TextSize = GuiLibrary.TextSize --0.000
        Shadow.TextXAlignment = Enum.TextXAlignment.Center

        Line = Instance.new("TextLabel")
        Line.Name = "Line"
        Line.Parent = Watermark
        Line.BackgroundColor3 = GuiLibrary["GetColor"]()
        Line.BackgroundTransparency = GuiLibrary["WatermarkLine"] and 0 or 1
        Line.Position = UDim2.new(0, -5, 0.5, 0)
        Line.AnchorPoint = Vector2.new(0, 0.5)
        Line.Size = UDim2.new(0, 3, 0, 20)
        Line.Font = GuiLibrary.Font
        Line.Text = ""
        Line.BorderSizePixel = 0
        Line.TextSize = GuiLibrary.TextSize --0.000
        Line.TextXAlignment = Enum.TextXAlignment.Center

        connection = GuiLibrary["Signals"]["UpdateColor"]:connect(function() 
            if Watermark then
                Watermark.TextColor3 = GuiLibrary["GetColor"]()
            end
            if Line then 
                Line.BackgroundColor3 = GuiLibrary["GetColor"]()
            end
        end)
    end

    function api.undraw() 
        if connection then 
            connection:Disconnect()
            connection = nil
        end
        if Watermark then 
            Watermark:Destroy()
            Watermark = nil
        end
        if Shadow then 
            Shadow:Destroy()
            Shadow = nil
        end
        if Line then 
            Line:Destroy()
            Line = nil
        end
    end

    api.Instance = Watermark

    return api
end
GuiLibrary["WatermarkAPI"] = GuiLibrary["PrepareWatermark"]()

GuiLibrary["CreateArrayList"] = function() 
    local api = {}
    local connections = {}
    local shadows = {}
    local lines = {}
    local arrayobjects = {}

    local ArrayList = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")

    ArrayList.Name = "ArrayList"
    ArrayList.Parent = GuiLibrary["ScreenGui"]
    ArrayList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ArrayList.BackgroundTransparency = 1.000
    ArrayList.Position = UDim2.new(0.5, 0, 0.5, 0)
    ArrayList.Size = UDim2.new(0, 197, 0, 346)
    ArrayList.Visible = false

    --local _con = ArrayList:GetPropertyChangedSignal("Position"):connect(function() 
    --end)
    --table.insert(GuiLibrary["Connections"], _con)


    dragGUI(ArrayList, ArrayList)

    UIListLayout.Parent = ArrayList
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 0)

    function api.setPosition(pos) 
        ArrayList.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset)
    end

    function api.getPosition() 
        return ArrayList.Position
    end

    function api.createArrayObject(name,label)
        local Shadow = Instance.new("TextLabel")
        local ArrayObject = Instance.new("TextLabel")
        local Line = Instance.new("TextLabel")
        ArrayObject.Name = name
        ArrayObject.Parent = ArrayList
        ArrayObject.BackgroundColor3 = Color3.fromRGB(0,0,0)
        ArrayObject.BackgroundTransparency = 1.000
        ArrayObject.Position = UDim2.new(-0.0152284261, 0, 0, 0)
        ArrayObject.Size = UDim2.new(0, 0, 0, 18)
        ArrayObject.Font = GuiLibrary.Font
        ArrayObject.RichText = true
        local text = name.." "
        if type(label)=="function" then
            text = text.."<font color='rgb(130,130,130)'>[</font><font color='rgb(170,170,170)'>"..tostring(label()).."</font><font color='rgb(130,130,130)'>]</font> "
        end
        ArrayObject.Text = text
        ArrayObject.BorderSizePixel = 0
        ArrayObject.TextStrokeTransparency = 0.4
        ArrayObject.TextColor3 = GuiLibrary["GetColor"]()
        local insertme = GuiLibrary["Signals"]["UpdateColor"]:connect(function() 
            ArrayObject.TextColor3 = GuiLibrary["GetColor"]()
            Line.BackgroundColor3 = GuiLibrary["GetColor"]()
        end)
        connections[name] = insertme
        local connectionTextbound = textbound(ArrayObject)
        ArrayObject.TextSize = GuiLibrary.TextSize --0.000
        ArrayObject.TextXAlignment = Enum.TextXAlignment.Center
        arrayobjects[name] = ArrayObject

        Shadow.Name = "Background"
        Shadow.Parent = ArrayObject
        Shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
        Shadow.BackgroundTransparency = 1.000
        Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        Shadow.AnchorPoint = Vector2.new(0.5,0.5)
        local vec = ArrayObject.AbsoluteSize + Vector2.new(5, 0)
        Shadow.Size = UDim2.new(0, vec.X, 0, vec.Y)
        Shadow.Font = GuiLibrary.Font
        Shadow.Text = ""
        Shadow.BorderSizePixel = 0
        Shadow.ZIndex = -1
        local insertme = ArrayObject:GetPropertyChangedSignal("Size"):connect(function()
            local vec = ArrayObject.AbsoluteSize + Vector2.new(7, 0)
            Shadow.Size = UDim2.new(0, vec.X, 0, vec.Y)
        end)
        connections["Shadow"..name] = insertme
        Shadow.TextSize = GuiLibrary.TextSize --0.000
        Shadow.TextXAlignment = Enum.TextXAlignment.Center
        shadows[name] = Shadow

        Line.Name = "Line"
        Line.Parent = ArrayObject
        Line.BackgroundColor3 = GuiLibrary["GetColor"]()
        Line.BackgroundTransparency = 0
        Line.Position = UDim2.new(1, 1, 0.5, 0)
        Line.AnchorPoint = Vector2.new(-1, 0.5)
        Line.Size = UDim2.new(0, 3, 0, 20)
        Line.Font = GuiLibrary.Font
        Line.Text = ""
        Line.BorderSizePixel = 0
        Line.TextSize = GuiLibrary.TextSize --0.000
        Line.TextXAlignment = Enum.TextXAlignment.Center
        lines[name] = Line

        return ArrayObject
    end

    function api.removeArrayObject(name)
        if arrayobjects[name] then 
            arrayobjects[name]:Destroy()
            arrayobjects[name] = nil
        end
        if shadows[name] then 
            shadows[name]:Destroy()
            shadows[name] = nil
        end
        if lines[name] then 
            lines[name]:Destroy()
            lines[name] = nil
        end
        if connections[name] then
            connections[name]:Disconnect()
            connections[name] = nil
        end
        if connections["Shadow"..name] then
            connections["Shadow"..name]:Disconnect()
            connections["Shadow"..name] = nil
        end
    end

    function api.clearArrayObjects()
        for i,v in next, arrayobjects do 
            api.removeArrayObject(i)
        end
    end

    function api.findArrayObject(name)
        if arrayobjects[name] then 
            return true
        end
    end

    function api.getArrayObjects() 
        return arrayobjects
    end

    function api.renderShadows(transparency) 
        local transparency = transparency or 0.5
        for i,v in next, shadows do 
            v.BackgroundTransparency = transparency
        end
    end

    function api.renderLines(transparency) 
        local transparency = transparency or 0
        for i,v in next, lines do 
            v.BackgroundTransparency = transparency
        end
    end

    api.Instance = ArrayList
    api.UIListLayout = UIListLayout

    return api
end
GuiLibrary["ArrayListAPI"] = GuiLibrary.CreateArrayList()


GuiLibrary["CreateNotification"] = function(content)
    if GuiLibrary["AllowNotifications"] then
        chatchildaddedconnection = chatchildaddedconnection or PLAYERS.LocalPlayer.PlayerGui.Chat.Frame.ChatChannelParentFrame["Frame_MessageLogDisplay"].Scroller.ChildAdded:Connect(function(child) 
            if child:FindFirstChildOfClass("TextLabel").Text:find("[Future]") then 
                child:FindFirstChildOfClass("TextLabel").RichText = true
            end
        end)
        STARTERGUI:SetCore("ChatMakeSystemMessage", {["Text"] = "\n<font color='rgb(255, 85, 85)'>[Future]</font> <font color='rgb(200,200,200)'>"..tostring(content).."</font>"})
    end
end
GuiLibrary["Debug"] = function(content) 
    if not shared.FutureDebug then return end
    print("[Future] [DEBUG] "..content)
end
GuiLibrary["SaveConfig"] = function(name, isAutosave) 
    if shared.Future==nil or shared.Future.Destructing then return end
    local name = (name == nil or name == "") and "default" or name
    GuiLibrary["Debug"]("save Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId).."/"..name..".json")
    local config = {}
    for i,v in next, GuiLibrary["Objects"] do 
        if v.Type == "OptionsButton" and not table.find(exclusionList, i) and not v.DisableOnLeave then 
            config[i] = {["Enabled"] = v.API.Enabled, ["Keybind"] = v.API.Keybind, ["Type"] = v.Type, ["Window"] = v.Window}
        elseif v.Type == "Toggle" and --[[not table.find(exclusionList, v.OptionsButton) and]] not table.find(exclusionList, i) then
            config[i] = {["Enabled"] = v.API.Enabled, ["Type"] = v.Type, ["OptionsButton"] = v.OptionsButton, ["Window"] = v.Window}
        elseif v.Type == "Slider" and not table.find(exclusionList, v.OptionsButton) then
            config[i] = {["Value"] = v.API.Value==math.huge and "inf" or v.API.Value, ["Type"] = v.Type, ["OptionsButton"] = v.OptionsButton, ["Window"] = v.Window}
        elseif v.Type == "Selector" and not table.find(exclusionList, v.OptionsButton) then
            config[i] = {["Value"] = v.API.Value, ["Type"] = v.Type, ["OptionsButton"] = v.OptionsButton, ["Window"] = v.Window}
        elseif v.Type == "Textbox" and not table.find(exclusionList, v.OptionsButton) then
            config[i] = {["Value"] = v.API.Value, ["Type"] = v.Type, ["OptionsButton"] = v.OptionsButton, ["Window"] = v.Window}
        end
    end
    local guiconfig = {
        ["AllowNotifications"] = GuiLibrary.AllowNotifications,
        ["HUDEnabled"] = GuiLibrary.HUDEnabled, 
        ["ColorTheme"] = GuiLibrary.ColorTheme, 
        ["Rainbow"] = GuiLibrary.Rainbow, 
        ["RainbowSpeed"] = GuiLibrary.RainbowSpeed, 
        ["ClickSounds"] = GuiLibrary.ClickSounds, 
        ["GuiKeybind"] = GuiLibrary.GuiKeybind,
        ["ArrayList"] = GuiLibrary.ArrayList,
        ["ListBackground"] = GuiLibrary.ListBackground,
        ["ListLines"] = GuiLibrary.ListLines,
        ["DrawWatermark"] = GuiLibrary.DrawWatermark,
        ["WatermarkLine"] = GuiLibrary.WatermarkLine,
        ["WatermarkBackground"] = GuiLibrary.WatermarkBackground,
        ["Rendering"] = GuiLibrary.Rendering,
        ["DrawCoords"] = GuiLibrary.DrawCoords,
        ["DrawSpeed"] = GuiLibrary.DrawSpeed, 
        ["DrawFPS"] = GuiLibrary.DrawFPS,
        ["DrawPing"] = GuiLibrary.DrawPing,
        ["TargetHUD"] = GuiLibrary.TargetHUD,
        ["TargetHUDEnabled"] = GuiLibrary.TargetHUDEnabled,
        ["ArrayListInfo"] = GuiLibrary.ArrayListInfo,
        ["HUDElements"] = GuiLibrary.HUDElements,
        ["Font"] = GuiLibrary.Font.Name,
        ["TextSize"] = GuiLibrary.TextSize,
    }
    local path = "Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId).."/"..name..".json"
    makefolder("Future/configs")
    makefolder("Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId))
    if betterisfile((path)) then 
        delfile(path)
    end

    local pos = GuiLibrary["TargetHUDAPI"].getPosition()
    guiconfig.TargetHUD.Position = {
        ["X"] = {
            ["Scale"] = pos.X.Scale,
            ["Offset"] = pos.X.Offset,
        },
        ["Y"] = {
            ["Scale"] = pos.Y.Scale,
            ["Offset"] = pos.Y.Offset,
        },
    }
    local pos = GuiLibrary["ArrayListAPI"].getPosition()
    guiconfig.ArrayListInfo.Position = {
        ["X"] = {
            ["Scale"] = pos.X.Scale,
            ["Offset"] = pos.X.Offset,
        },
        ["Y"] = {
            ["Scale"] = pos.Y.Scale,
            ["Offset"] = pos.Y.Offset,
        },
    }
    local pos = GuiLibrary["HUDAPI"].getPosition()
    guiconfig.HUDElements.Position = {
        ["X"] = {
            ["Scale"] = pos.X.Scale,
            ["Offset"] = pos.X.Offset,
        },
        ["Y"] = {
            ["Scale"] = pos.Y.Scale,
            ["Offset"] = pos.Y.Offset,
        },
    }

    writefile(path, HTTPSERVICE:JSONEncode(config))
    repeat task.wait() until betterisfile((path))
    if betterisfile("Future/configs/GUIconfig.json") then 
        delfile("Future/configs/GUIconfig.json")
    end
    writefile("Future/configs/GUIconfig.json", HTTPSERVICE:JSONEncode(guiconfig))
    repeat task.wait() until betterisfile("Future/configs/GUIconfig.json")
end
GuiLibrary["LoadOnlyGuiConfig"] = function() 
    if betterisfile("Future/configs/GUIconfig.json") then 
        local success, config = pcall(function() 
            local x = readfile("Future/configs/GUIconfig.json")
            return HTTPSERVICE:JSONDecode(x)
        end)
        if success then 
            for i,v in next, config do 
                GuiLibrary[i] = v
            end
            for i,v in next, GuiLibrary.Objects do 
                if i == "HUDOptionsButton" then 
                    v.API.Toggle(config.HUDEnabled, false, false)
                elseif i == "ClickGuiOptionsButton" then
                    v.API.SetKeybind(config.GuiKeybind)
                elseif i == "HUDOptionsButtonNotificationsToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    v.API.Toggle(config.AllowNotifications, false, true)
                elseif i == "HUDOptionsButtonArrayListToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.ArrayList then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonListBackgroundToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.ListBackground then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonListLinesToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.ListLines then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonWatermarkToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.DrawWatermark then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonWMLineToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.WatermarkLine then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonWMBackgroundToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.WatermarkBackground then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonCoordsToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.DrawCoords then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonSpeedToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.DrawSpeed then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonFPSToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.DrawFPS then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonPingToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if config.DrawPing then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonTargetHUDToggle" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    if (config.TargetHUDEnabled) then
                        v.API.Toggle(true, true)
                    end
                elseif i == "HUDOptionsButtonRenderingSelector" and v.OptionsButton == "HUDOptionsButton" and v.Window == "OtherWindow" then
                    v.API.Select(config.Rendering)
                elseif i == "ClickGuiOptionsButtonClickSoundsToggle" and v.OptionsButton == "ClickGuiOptionsButton" and v.Window == "OtherWindow" then
                    v.API.Toggle(config.ClickSounds, true)
                elseif i == "ColorsOptionsButtonHueSlider" and v.OptionsButton == "ColorsOptionsButton" and v.Window == "OtherWindow" then
                    v.API.Set(config.ColorTheme.H / 0.002777777777777)
                elseif i == "ColorsOptionsButtonSaturationSlider" and v.OptionsButton == "ColorsOptionsButton" and v.Window == "OtherWindow" then
                    v.API.Set(config.ColorTheme.S * 100)
                elseif i == "ColorsOptionsButtonLightnessSlider" and v.OptionsButton == "ColorsOptionsButton" and v.Window == "OtherWindow" then
                    v.API.Set(config.ColorTheme.V * 100)
                elseif i == "ColorsOptionsButtonRainbowToggle" and v.OptionsButton == "ColorsOptionsButton" and v.Window == "OtherWindow" then
                    if config.Rainbow then
                        v.API.Toggle(true, false)
                    else
                        v.API.Toggle(false, false)
                    end
                elseif i == "ColorsOptionsButtonRBSpeedSlider" and v.OptionsButton == "ColorsOptionsButton" and v.Window == "OtherWindow" then
                    v.API.Set(config.RainbowSpeed)
                end
            end
            if type(config.TargetHUD) == "table" then
                GuiLibrary["TargetHUDAPI"].setPosition(config.TargetHUD.Position)
            end
            if type(config.ArrayListInfo) == "table" then
                GuiLibrary["ArrayListAPI"].setPosition(config.ArrayListInfo.Position)
            end
            if type(config.HUDElements) == "table" then
                GuiLibrary["HUDAPI"].setPosition(config.HUDElements.Position)
            end
            if type(config.Font) == "string" then
                GuiLibrary.Font = Enum.Font[config.Font]
                for i,v in next, GuiLibrary.ScreenGui:GetDescendants() do 
                    if pcall(function() return v.Font end) then 
                        v.Font = config.Font
                    end
                end
                GuiLibrary["Signals"]["HUDUpdate"]:Fire()
            end
            if type(config.TextSize) == "number" then 
                for i,v in next, GuiLibrary.ScreenGui:GetDescendants() do 
                    if pcall(function() return v.TextSize end) then 
                        v.TextSize = config.TextSize
                    end
                end
                GuiLibrary["Signals"]["HUDUpdate"]:Fire()
            end
        else
            warn("[Future] Failed to load GUIconfig.json config file")
        end
    else
        for i,v in next, GuiLibrary.Objects do 
            if i == "ClickGuiOptionsButton" then
                v.API.SetKeybind("RightShift")
            elseif i == "ColorsOptionsButtonHueSlider" and v.OptionsButton == "ColorsOptionsButton" and v.Window == "OtherWindow" then
                v.API.Set(360)
            elseif i == "ColorsOptionsButtonSaturationSlider" and v.OptionsButton == "ColorsOptionsButton" and v.Window == "OtherWindow" then
                v.API.Set(100)
            elseif i == "ColorsOptionsButtonLightnessSlider" and v.OptionsButton == "ColorsOptionsButton" and v.Window == "OtherWindow" then
                v.API.Set(70)
            end
        end
    end
end
GuiLibrary["LoadConfig"] = function(name) 
    if shared.Future==nil or shared.Future.Destructing then return end
    local name = name or "default"
    writefile("Future/configs/!SelectedConfigs/"..tostring(shared.FuturePlaceId or game.PlaceId)..".txt", name) 
    GuiLibrary["Debug"]("Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId).."/"..name..".json")
    if betterisfile("Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId).."/"..name..".json") then 
        print("[Future] Loading configuration "..name)
        log("LoadConfig", "Loading "..name)
        local success, config = pcall(function() 
            local x = readfile("Future/configs/"..tostring(shared.FuturePlaceId or game.PlaceId).."/"..name..".json")
            return HTTPSERVICE:JSONDecode(x)
        end)
        if success then 
            print("[Future] Success loading configuration "..name)
            -- // turn off all modules incase they are switching configs (to prevent the old configs settings staying)
            for i,v in next, GuiLibrary.Objects do 
                local check = config[i] and (config[i].Enabled~=nil and true or false) or false
                if v.Type == "Toggle" and not table.find(exclusionList, i) and check then 
                    if v.API.Enabled then 
                        v.API.Toggle(false, true)
                    end
                end
                if v.Type == "OptionsButton" and not table.find(exclusionList, i) and check then 
                    if v.API.Enabled then 
                        v.API.Toggle(false)
                    end
                end
            end
            for i,v in next, config do 
                if GuiLibrary["Objects"][i] then 
                    local API = GuiLibrary["Objects"][i]["API"]
                    local start_time = WORKSPACE:GetServerTimeNow()
                    if v.Type == "OptionsButton" and GuiLibrary["Objects"][i].Window == v.Window and not table.find(exclusionList, i) then 
                        if v.Enabled then
                            --print("LoadConfig", "Loading "..i.." as ".. tostring(v.Enabled))
                            API.Toggle(v.Enabled, false, false)
                        end
                        API.SetKeybind(v.Keybind)
                    elseif v.Type == "Slider" and GuiLibrary["Objects"][i].OptionsButton == v.OptionsButton and not table.find(exclusionList, v.OptionsButton) then
                        API.Set(tonumber(v.Value), true)
                    elseif v.Type == "Selector" and GuiLibrary["Objects"][i].OptionsButton == v.OptionsButton and  not table.find(exclusionList, v.OptionsButton) then
                        API.Select(v.Value)
                    elseif v.Type == "Textbox" and GuiLibrary["Objects"][i].OptionsButton == v.OptionsButton and  not table.find(exclusionList, v.OptionsButton) then
                        API.Set(v.Value)
                    elseif v.Type == "Toggle" and GuiLibrary["Objects"][i].OptionsButton == v.OptionsButton and not table.find(exclusionList, i) then
                        if v.Enabled then 
                            API.Toggle(v.Enabled, true)
                        end
                    end
                    local time_diff = WORKSPACE:GetServerTimeNow() - start_time
                    if time_diff > 0.01 then
                        print("Loaded", i,"as", (v.Enabled~=nil and v.Enabled or v.Value), "in", time_diff)
                    end
                end
            end
        else
            warn("[Future] Failed to load "..tostring(shared.FuturePlaceId or game.PlaceId)..".json config file\nplease report this in the discord!\n("..config..")")
        end
    end
    --GuiLibrary["LoadOnlyGuiConfig"]()
end
GuiLibrary["RemoveObject"] = function(name) 
    pcall(function()
        if GuiLibrary.Objects[name] then 
            GuiLibrary.Objects[name].Instance:Destroy()
            GuiLibrary.Objects[name] = nil
            GuiLibrary.UpdateWindows()
            log("RemoveObject", "Removing "..name)
        end
    end)
end
GuiLibrary["CreateWindow"] = function(argstable)
    local windowapi = {["Expanded"] = true, ["ExpandedOptionsButton"] = nil, ["Expand"] = function() end}
    local windowargs = argstable

    local Window = Instance.new("Frame")
    local Window_2 = Instance.new("TextButton")
    local WindowTitle = Instance.new("TextLabel")
    local Expand = Instance.new("ImageButton")
    local ButtonContainer = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")
    Window.Name = argstable.Name.."Window"
    Window.Parent = ClickGUI
    Window.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Window.BackgroundTransparency = 0.45
    Window.BorderSizePixel = 0
    Window.Position = UDim2.new(0, GuiLibrary["WindowX"], 0, 25)
    GuiLibrary["WindowX"] = GuiLibrary["WindowX"] + (176 + 3)
    Window.Size = UDim2.new(0, 176, 0, 222)
    Window_2.Name = "WindowTopbar"
    Window_2.Modal = true
    Window_2.Parent = Window
    Window_2.BackgroundColor3 = Color3.fromHSV(GuiLibrary["ColorTheme"].H, GuiLibrary["ColorTheme"].S, GuiLibrary["ColorTheme"].V)
    GuiLibrary["Signals"]["UpdateColor"]:connect(function(color) 
        Window_2.BackgroundColor3 = Color3.fromHSV(color.H, color.S, color.V)
    end)
    Window_2.BorderSizePixel = 0
    Window_2.Position = UDim2.new(-0.000213969834, 0, -0.00245500472, 0)
    Window_2.Size = UDim2.new(0, 176, 0, 27)
    Window_2.AutoButtonColor = false
    Window_2.Text = ""
    Window_2.TextColor3 = Color3.fromRGB(0, 0, 0)
    Window_2.TextSize = GuiLibrary.TextSize --4.000
    WindowTitle.Name = "WindowTitle"
    WindowTitle.Parent = Window_2
    WindowTitle.AnchorPoint = Vector2.new(0, 0.5)
    WindowTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    WindowTitle.BackgroundTransparency = 1.000
    WindowTitle.BorderSizePixel = 0
    WindowTitle.Position = UDim2.new(0, 6, 0.5, 0)
    WindowTitle.Size = UDim2.new(0, 130, 0, 20)
    WindowTitle.Font = GuiLibrary.Font
    WindowTitle.Text = argstable.Name
    WindowTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    WindowTitle.TextSize = GuiLibrary.TextSize
    WindowTitle.TextWrapped = true
    WindowTitle.TextXAlignment = Enum.TextXAlignment.Left
    Expand.Name = "Expand"
    Expand.Parent = Window_2
    Expand.AnchorPoint = Vector2.new(0.5, 0.5)
    Expand.BackgroundTransparency = 1.000
    Expand.Position = UDim2.new(1, -14, 0.5, 1)
    Expand.Size = UDim2.new(0, 20, 0, 19)
    Expand.ZIndex = 1
    Expand.Image = getasset("Future/assets/arrow.png") --"rbxassetid://8904422926"
    Expand.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Expand.ScaleType = Enum.ScaleType.Fit
    Expand.Rotation = 0
    ButtonContainer.Name = "ButtonContainer"
    ButtonContainer.Parent = Window
    ButtonContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    ButtonContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ButtonContainer.BackgroundTransparency = 1.000
    ButtonContainer.Position = UDim2.new(0.5, 0, 0, 48)
    ButtonContainer.Size = UDim2.new(0, 175, 0, 30)
    UIListLayout.Parent = ButtonContainer
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.Name
    UIListLayout.Padding = UDim.new(0, 1)

    windowapi["CreateOptionsButton"] = function(argstable) 
        local starttime = WORKSPACE:GetServerTimeNow()
        local buttonapi = {["Enabled"] = false, ["Expanded"] = false, ["Keybind"] = nil, ["IsRecording"] = false}

        local OptionsButton = Instance.new("TextButton")
        local Name = Instance.new("TextLabel")
        local Gear = Instance.new("ImageButton")
        local ChildrenContainer = Instance.new("Frame")
        local UIListLayout_2 = Instance.new("UIListLayout")
        local ModuleContainer = Instance.new("Frame")
        local UIListLayout_3 = Instance.new("UIListLayout")
        OptionsButton.Name = argstable.Name.."OptionsButton"
        OptionsButton.Parent = ButtonContainer
        OptionsButton.BackgroundColor3 = Color3.fromHSV(GuiLibrary["ColorTheme"].H, GuiLibrary["ColorTheme"].S, GuiLibrary["ColorTheme"].V)
        GuiLibrary["Signals"]["UpdateColor"]:connect(function(color) 
            OptionsButton.BackgroundColor3 = Color3.fromHSV(color.H, color.S, color.V)
        end)
        OptionsButton.BackgroundTransparency = 0.85
        OptionsButton.BorderSizePixel = 0
        OptionsButton.AnchorPoint = Vector2.new(0.5, 0)
        OptionsButton.Position = UDim2.new(0.5, 0, 0, 0)
        OptionsButton.Size = UDim2.new(0, 168, 0, 30)
        OptionsButton.AutoButtonColor = false
        OptionsButton.Text = ""
        OptionsButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        OptionsButton.TextSize = GuiLibrary.TextSize --4.000
        OptionsButton.TextXAlignment = Enum.TextXAlignment.Left
        Name.Name = "Name"
        Name.Parent = OptionsButton
        Name.AnchorPoint = Vector2.new(0, 0.5)
        Name.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Name.BackgroundTransparency = 1.000
        Name.BorderSizePixel = 0
        Name.Position = UDim2.new(0.0350000001, 0, 0.5, 0)
        Name.Size = UDim2.new(0, 114, 0, 23)
        Name.Font = GuiLibrary.Font
        Name.Text = argstable.Name
        Name.TextColor3 = Color3.fromRGB(255, 255, 255)
        Name.TextSize = GuiLibrary.TextSize
        Name.TextXAlignment = Enum.TextXAlignment.Left
        Gear.Name ="Gear"
        Gear.Parent = OptionsButton
        Gear.AnchorPoint = Vector2.new(0, 0.5)
        Gear.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Gear.BackgroundTransparency = 1.000
        Gear.Position = UDim2.new(1, -23, 0.5, 0)
        Gear.Size = UDim2.new(0, 19, 0, 19)
        Gear.Image = getasset("Future/assets/gear.png") --"rbxassetid://8905804106"
        Gear.ImageColor3 = Color3.fromRGB(181, 181, 181)
        Gear.SliceScale = 0.000
        ChildrenContainer.Name = argstable.Name.."__ZZZZZ__ChildrenContainer"
        ChildrenContainer.Parent = ButtonContainer
        ChildrenContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        ChildrenContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ChildrenContainer.BackgroundTransparency = 1.000
        ChildrenContainer.Position = UDim2.new(0.5, 0, 0, 48)
        ChildrenContainer.Size = UDim2.new(0, 175, 0, 30)
        ChildrenContainer.Visible = false
        UIListLayout_2.Parent = ChildrenContainer
        UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_2.Padding = UDim.new(0, 1)
        ModuleContainer.Name = "ModuleContainer"
        ModuleContainer.Parent = ChildrenContainer
        ModuleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        ModuleContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ModuleContainer.BackgroundTransparency = 1.000
        ModuleContainer.Position = UDim2.new(0.5, 0, -0.100000001, 48)
        ModuleContainer.Size = UDim2.new(0, 175, 0, 90)
        UIListLayout_3.Parent = ModuleContainer
        UIListLayout_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
        local Keybind
        local KeybindContainer
        local UIListLayout_6
        local Name_5
        if not argstable.NoKeybind then
            Keybind = Instance.new("TextButton")
            KeybindContainer = Instance.new("Frame")
            UIListLayout_6 = Instance.new("UIListLayout")
            Name_5 = Instance.new("TextLabel")
            Keybind.Name = "Keybind"
            Keybind.Parent = ChildrenContainer
            Keybind.BackgroundTransparency = 1.000
            Keybind.BorderSizePixel = 0
            Keybind.Position = UDim2.new(0.0171428565, 0, 0, 0)
            Keybind.Size = UDim2.new(0, 168, 0, 30)
            Keybind.AutoButtonColor = true
            Keybind.Text = ""
            Keybind.TextColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.TextSize = GuiLibrary.TextSize --4.000
            Keybind.TextXAlignment = Enum.TextXAlignment.Left
            Keybind.BackgroundColor3 = Color3.fromHSV(GuiLibrary["ColorTheme"].H, GuiLibrary["ColorTheme"].S, GuiLibrary["ColorTheme"].V)
            GuiLibrary["Signals"]["UpdateColor"]:connect(function(color) 
                Keybind.BackgroundColor3 = Color3.fromHSV(color.H, color.S, color.V)
            end)
            KeybindContainer.Name = "KeybindContainer"
            KeybindContainer.Parent = Keybind
            KeybindContainer.AnchorPoint = Vector2.new(0.5, 0.5)
            KeybindContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            KeybindContainer.BackgroundTransparency = 1.000
            KeybindContainer.BorderSizePixel = 0
            KeybindContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
            KeybindContainer.Size = UDim2.new(0, 158, 0, 30)
            UIListLayout_6.Parent = KeybindContainer
            UIListLayout_6.FillDirection = Enum.FillDirection.Horizontal
            UIListLayout_6.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_6.VerticalAlignment = Enum.VerticalAlignment.Center
            Name_5.Name = "Name"
            Name_5.Parent = KeybindContainer
            Name_5.AnchorPoint = Vector2.new(0, 0.5)
            Name_5.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Name_5.BackgroundTransparency = 1.000
            Name_5.BorderSizePixel = 0
            Name_5.Position = UDim2.new(0, 0, 0.5, 0)
            Name_5.Size = UDim2.new(0, 76, 0, 23)
            Name_5.Font = GuiLibrary.Font
            Name_5.RichText = true
            Name_5.Text = "Keybind <font color='rgb(170,170,170)'>NONE</font>"
            Name_5.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_5.TextSize = GuiLibrary.TextSize
            Name_5.TextXAlignment = Enum.TextXAlignment.Left
        end

        buttonapi["Update"] = function()
            ModuleContainer.Size = not buttonapi.Expanded and UDim2.new(0, 175, 0, 35) or UDim2.new(0, 175, 0, UIListLayout_3.AbsoluteContentSize.Y-1)
            ChildrenContainer.Size = not buttonapi.Expanded and UDim2.new(0, 175, 0, 35) or UDim2.new(0, 175, 0, UIListLayout_2.AbsoluteContentSize.Y + 0)
        end
        windowapi.Update()

        local connection = UIListLayout_3:GetPropertyChangedSignal("AbsoluteContentSize"):connect(windowapi.Update)
        local connection2 = UIListLayout_2:GetPropertyChangedSignal("AbsoluteContentSize"):connect(windowapi.Update)
        table.insert(GuiLibrary.Connections, connection2)
        table.insert(GuiLibrary.Connections, connection)

        buttonapi["Expand"] = function(boolean)
            local doExpand = boolean~=nil and boolean or not buttonapi.Expanded
            buttonapi.Expanded = doExpand
            ChildrenContainer.Visible = doExpand
            windowapi.Update()
            playclicksound()
        end

        buttonapi["Toggle"] = function(boolean, stopclick, isConfigLoad) 
            local doToggle, stopclick, isConfigLoad = boolean, not stopclick, not isConfigLoad
            if boolean==nil then doToggle = not buttonapi.Enabled end
            OptionsButton.BackgroundTransparency = doToggle and 0.35 or 0.85
            buttonapi.Enabled = doToggle
            argstable.Function(doToggle)
            if argstable.Name == "ClickGui" and windowargs.Name == "Other" then 
                clickGuiToggle:Fire(boolean)
            end 
            hudUpdate:Fire()
            if GuiLibrary["AllowNotifications"] then 
                local keyword = doToggle and "Enabled" or "Disabled"
                if not table.find(exclusionList, OptionsButton.Name) and not isConfigLoad then
                    GuiLibrary["CreateToast"](argstable.Name.." "..keyword.."!", "The '"..argstable.Name.."' module was "..keyword..".")
                end
            end
            if not stopclick then
                playclicksound()
            end
        end
        if (argstable.Default~=nil) and buttonapi.Enabled ~= argstable.Default and argstable.Default then 
            buttonapi.Toggle(argstable.Default, false, false)
        end

        buttonapi["SetKeybind"] = function(key) 
            if key == nil then 
                Name_5.Text = "Keybind <font color='rgb(170,170,170)'>NONE</font>"
            else
                Name_5.Text = "Keybind <font color='rgb(170,170,170)'>"..key.."</font>"
            end
            buttonapi.Keybind = key or argstable["DefaultKeybind"]
            if argstable.OnKeybound then 
                argstable.OnKeybound(key)
            end
        end
        if not argstable.NoKeybind then
            local ExclusionsList = {"Unknown"}
            local bindconnection = UIS.InputBegan:Connect(function(input) 
                if buttonapi.IsRecording and not table.find(ExclusionsList, input.KeyCode.Name) and UIS:GetFocusedTextBox() == nil then
                    buttonapi["IsRecording"] = false
                    Keybind.BackgroundTransparency = 1
                    if (input.KeyCode.Name == "Escape") then
                        buttonapi.SetKeybind(argstable["DefaultKeybind"])
                    else
                        buttonapi.SetKeybind(input.KeyCode.Name)
                    end
                    return
                end
                if input.KeyCode.Name == buttonapi.Keybind and UIS:GetFocusedTextBox() == nil then 
                    buttonapi.Toggle(nil, false, true)
                end
            end)
            table.insert(GuiLibrary.Connections, bindconnection)

            Keybind.MouseButton1Click:Connect(function()
                playclicksound()
                if buttonapi["IsRecording"] == false then
                    buttonapi["IsRecording"] = true
                    Name_5.Text = "Press a Key..."
                    Keybind.BackgroundTransparency = 0
                else
                    buttonapi["IsRecording"] = false
                    buttonapi.SetKeybind(buttonapi["Keybind"])
                    Keybind.BackgroundTransparency = 1
                end
            end)
        end
        OptionsButton.MouseButton2Click:Connect(buttonapi.Expand)
        OptionsButton.MouseButton1Click:Connect(buttonapi.Toggle)
        Gear.MouseButton1Click:Connect(buttonapi.Expand)

        buttonapi["CreateToggle"] = function(argstable) 
            local toggleapi = {["Enabled"] = false}
            local Toggle = Instance.new("TextButton")
            local Name_4 = Instance.new("TextLabel")
            Toggle.Name = "Toggle"..argstable.Name
            Toggle.Parent = ModuleContainer
            Toggle.BackgroundColor3 = Color3.fromHSV(GuiLibrary["ColorTheme"].H, GuiLibrary["ColorTheme"].S, GuiLibrary["ColorTheme"].V)
            GuiLibrary["Signals"]["UpdateColor"]:connect(function(color) 
                Toggle.BackgroundColor3 = Color3.fromHSV(color.H, color.S, color.V)
            end)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundTransparency = 1
            Toggle.Position = UDim2.new(0.0171428565, 0, 0, 0)
            Toggle.Size = UDim2.new(0, 168, 0, 30)
            Toggle.AutoButtonColor = false
            Toggle.Text = ""
            Toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.TextSize = GuiLibrary.TextSize --4.000
            Toggle.TextXAlignment = Enum.TextXAlignment.Left
            Name_4.Name = "Name"
            Name_4.Parent = Toggle
            Name_4.AnchorPoint = Vector2.new(0, 0.5)
            Name_4.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Name_4.BackgroundTransparency = 1.000
            Name_4.BorderSizePixel = 0
            Name_4.Position = UDim2.new(0.0350000001, 0, 0.5, 0)
            Name_4.Size = UDim2.new(0, 114, 0, 23)
            Name_4.Font = GuiLibrary.Font
            Name_4.Text = argstable.Name
            Name_4.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_4.TextSize = GuiLibrary.TextSize
            Name_4.TextXAlignment = Enum.TextXAlignment.Left

            toggleapi["Toggle"] = function(boolean, skipclick) 
                local doToggle = boolean
                if boolean==nil then doToggle = not toggleapi.Enabled end
                Toggle.BackgroundTransparency = doToggle and 0.35 or 1
                argstable.Function(doToggle)
                toggleapi.Enabled = doToggle
                if not skipclick then
                    playclicksound()
                end
            end
            toggleapi["Instance"] = Toggle
            if (argstable.Default~=nil) and toggleapi.Enabled ~= argstable.Default then 
                toggleapi.Toggle(argstable.Default, false, true)
            end
            Toggle.MouseButton1Click:Connect(toggleapi.Toggle)
            GuiLibrary["Objects"][OptionsButton.Name..argstable.Name.."Toggle"] = {["API"] = toggleapi, ["Instance"] = Toggle, ["Type"] = "Toggle", ["OptionsButton"] = OptionsButton.Name, ["Window"] = Window.Name}
            return toggleapi
        end

        buttonapi["CreateSelector"] = function(argstable) 
            local selectorapi = {["Value"] = nil, ["List"] = {}}

            for i,v in next, argstable.List do 
                table.insert(selectorapi.List, v)
            end
            selectorapi["Value"] = argstable.Default or selectorapi.List[1]

            local function stringtablefind(table1, key)
                for i,v in next, table1 do 
                    if tostring(v) == tostring(key) then 
                        return i 
                    end
                end
            end

            local function getvalue(index) 
                local realindex
                if index > #selectorapi.List then
                    realindex = 1 
                elseif index < 1 then
                    realindex = #selectorapi.List
                else
                    realindex = index
                end
                return realindex
            end

            local Selector = Instance.new("TextButton")
            local SelectorContainer = Instance.new("Frame")
            local UIListLayout_6 = Instance.new("UIListLayout")
            local Name_5 = Instance.new("TextLabel")
            Selector.Name = argstable.Name.."Selector"
            Selector.Parent = ModuleContainer
            Selector.BackgroundColor3 = Color3.fromHSV(GuiLibrary["ColorTheme"].H, GuiLibrary["ColorTheme"].S, GuiLibrary["ColorTheme"].V)
            GuiLibrary["Signals"]["UpdateColor"]:connect(function(color) 
                Selector.BackgroundColor3 = Color3.fromHSV(color.H, color.S, color.V)
            end)
            Selector.BackgroundTransparency = 0.35
            Selector.BorderSizePixel = 0
            Selector.Position = UDim2.new(0.0171428565, 0, 0, 0)
            Selector.Size = UDim2.new(0, 168, 0, 30)
            Selector.AutoButtonColor = true
            Selector.Text = ""
            Selector.TextColor3 = Color3.fromRGB(0, 0, 0)
            Selector.TextSize = GuiLibrary.TextSize --4.000
            Selector.TextXAlignment = Enum.TextXAlignment.Left
            SelectorContainer.Name = "SelectorContainer"
            SelectorContainer.Parent = Selector
            SelectorContainer.AnchorPoint = Vector2.new(0.5, 0.5)
            SelectorContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SelectorContainer.BackgroundTransparency = 1.000
            SelectorContainer.BorderSizePixel = 0
            SelectorContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
            SelectorContainer.Size = UDim2.new(0, 158, 0, 30)
            UIListLayout_6.Parent = SelectorContainer
            UIListLayout_6.FillDirection = Enum.FillDirection.Horizontal
            UIListLayout_6.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_6.VerticalAlignment = Enum.VerticalAlignment.Center
            Name_5.Name = "Name"
            Name_5.Parent = SelectorContainer
            Name_5.AnchorPoint = Vector2.new(0, 0.5)
            Name_5.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Name_5.BackgroundTransparency = 1.000
            Name_5.BorderSizePixel = 0
            Name_5.Position = UDim2.new(0, 0, 0.5, 0)
            Name_5.Size = UDim2.new(0, 76, 0, 23)
            Name_5.Font = GuiLibrary.Font
            Name_5.RichText = true
            Name_5.Text = argstable.Name.." <font color='rgb(170,170,170)'>"..tostring(selectorapi.Value).."</font>"
            Name_5.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_5.TextSize = GuiLibrary.TextSize
            Name_5.TextXAlignment = Enum.TextXAlignment.Left

            selectorapi["Select"] = function(_select) 
                if selectorapi.List[_select] or stringtablefind(selectorapi.List, _select) then
                    selectorapi["Value"] = selectorapi.List[_select] or selectorapi.List[stringtablefind(selectorapi.List, _select)]
                    Name_5.Text = argstable.Name.." <font color='rgb(170,170,170)'>"..tostring(selectorapi.Value).."</font>"
                    argstable.Function(selectorapi["Value"])
                end
            end
            selectorapi["SelectNext"] = function() 
                local newindex = table.find(selectorapi.List, selectorapi.Value) 
                if newindex then 
                    newindex = getvalue(newindex + 1)
                    selectorapi.Select(newindex)
                else
                    warn("[Future] NewIndex in selector ("..argstable.Name..") in function `SelectNext` was not found!")
                end
                playclicksound()
            end

            selectorapi["SelectPrevious"] = function() 
                local newindex = table.find(selectorapi.List, selectorapi.Value) 
                if newindex then 
                    newindex = getvalue(newindex - 1)
                    selectorapi.Select(newindex)
                else
                    warn("[Future] NewIndex in selector ("..argstable.Name..") in function `SelectPrevious` was not found!")
                end
                playclicksound()
            end

            Selector.MouseButton1Click:Connect(selectorapi.SelectNext)
            Selector.MouseButton2Click:Connect(selectorapi.SelectPrevious)

            GuiLibrary["Objects"][OptionsButton.Name..argstable.Name.."Selector"] = {["API"] = selectorapi, ["Instance"] = Selector, ["Type"] = "Selector", ["OptionsButton"] = OptionsButton.Name, ["Window"] = Window.Name}
            return selectorapi
        end

        buttonapi["CreateSlider"] = function(argstable) 
            local sliderapi = {["Value"] = argstable.Default or argstable.Min}
            local min, max, roundval = argstable.Min, argstable.Max, (argstable.Round or 1)
            local Slider = Instance.new("TextButton")
            local SliderFill = Instance.new("Frame")
            local SliderContainer = Instance.new("Frame")
            local UIListLayout_5 = Instance.new("UIListLayout")
            local Name_3 = Instance.new("TextLabel")
            local Textbox = Instance.new("TextButton")
            local RealTextbox = Instance.new("TextBox")
            Slider.Name = argstable.Name.."Slider"
            Slider.Parent = ModuleContainer
            Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Slider.BackgroundTransparency = 1.000
            Slider.BorderSizePixel = 0
            Slider.Position = UDim2.new(0.0171428565, 0, 0, 0)
            Slider.Size = UDim2.new(0, 168, 0, 30)
            Slider.AutoButtonColor = false
            Slider.Text = ""
            Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
            Slider.TextSize = GuiLibrary.TextSize --4.000
            Slider.TextXAlignment = Enum.TextXAlignment.Left
            SliderFill.Name = "SliderFill"
            SliderFill.Parent = Slider
            SliderFill.AnchorPoint = Vector2.new(0, 0.5)
            SliderFill.BackgroundColor3 = Color3.fromHSV(GuiLibrary["ColorTheme"].H, GuiLibrary["ColorTheme"].S, GuiLibrary["ColorTheme"].V)
            GuiLibrary["Signals"]["UpdateColor"]:connect(function(color) 
                SliderFill.BackgroundColor3 = Color3.fromHSV(color.H, color.S, color.V)
            end)
            SliderFill.BackgroundTransparency = 0.35
            SliderFill.BorderSizePixel = 0
            SliderFill.Position = UDim2.new(0, 0, 0.5, 0)
            SliderFill.Size = UDim2.new(0, 50, 0, 30)
            SliderContainer.Name = "SliderContainer"
            SliderContainer.Parent = Slider
            SliderContainer.AnchorPoint = Vector2.new(0.5, 0.5)
            SliderContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderContainer.BackgroundTransparency = 1.000
            SliderContainer.BorderSizePixel = 0
            SliderContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
            SliderContainer.Size = UDim2.new(0, 158, 0, 30)
            UIListLayout_5.Parent = SliderContainer
            UIListLayout_5.FillDirection = Enum.FillDirection.Horizontal
            UIListLayout_5.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_5.VerticalAlignment = Enum.VerticalAlignment.Center
            Name_3.Name = "Name"
            Name_3.Parent = SliderContainer
            Name_3.AnchorPoint = Vector2.new(0, 0.5)
            Name_3.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Name_3.BackgroundTransparency = 1.000
            Name_3.BorderSizePixel = 0
            Name_3.RichText = true
            Name_3.Position = UDim2.new(0, 0, 0.5, 0)
            Name_3.Size = UDim2.new(0, 61, 0, 23)
            Name_3.Font = GuiLibrary.Font
            Name_3.Text = argstable.Name.."<font color='rgb(170,170,170)'>"..tostring(sliderapi["Value"]).."</font>"
            Name_3.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_3.TextSize = GuiLibrary.TextSize
            Name_3.TextXAlignment = Enum.TextXAlignment.Left
            Textbox.Name = "InputTextbox"
            Textbox.Parent = ModuleContainer
            Textbox.BackgroundTransparency = 1.000
            Textbox.BorderSizePixel = 0
            Textbox.Position = UDim2.new(0.0171428565, 0, 0, 0)
            Textbox.Size = UDim2.new(0, 168, 0, 30)
            Textbox.AutoButtonColor = false
            Textbox.Text = ""
            Textbox.TextColor3 = Color3.fromRGB(0, 0, 0)
            Textbox.TextSize = GuiLibrary.TextSize --4.000
            Textbox.TextXAlignment = Enum.TextXAlignment.Left
            Textbox.Visible = false
            RealTextbox.Name = "RealTextbox"
            RealTextbox.Parent = Textbox
            RealTextbox.AnchorPoint = Vector2.new(0.5, 0.5)
            RealTextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            RealTextbox.BackgroundTransparency = 1.000
            RealTextbox.Position = UDim2.new(0.51767838, 0, 0.5, 0)
            RealTextbox.Size = UDim2.new(0, 162, 0, 30)
            RealTextbox.ClearTextOnFocus = false
            RealTextbox.Font = GuiLibrary.Font
            RealTextbox.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
            RealTextbox.PlaceholderText = "Input Value"
            RealTextbox.Text = ""
            RealTextbox.TextColor3 = Color3.fromRGB(255, 255, 255)
            RealTextbox.TextSize = GuiLibrary.TextSize
            RealTextbox.TextXAlignment = Enum.TextXAlignment.Left
            RealTextbox.FocusLost:connect(function() 
                if tonumber(RealTextbox.Text) then 
                    sliderapi.Set(tonumber(RealTextbox.Text), true)
                end
                RealTextbox.Text = ""
                Textbox.Visible = false
                Slider.Visible = true
            end)
            
            local function slide(input)
                local sizeX = math.clamp((input.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                local value = math.floor( ((((max - min) * sizeX) + min) * (10^roundval))+0.5)/(10^roundval)
                sliderapi["Value"] = value
                Name_3.Text = argstable.Name.." <font color='rgb(170,170,170)'>"..tostring(value).."</font>"
                if not argstable["OnInputEnded"] then
                    argstable.Function(value)
                end
            end
            local sliding
            Slider.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                        Textbox.Visible = true
                        Slider.Visible = false
                        RealTextbox:CaptureFocus()
                        return
                    end
                    sliding = true
                    slide(input)
                    playclicksound()
                end
            end)

            Slider.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if argstable["OnInputEnded"] then
                        argstable.Function(sliderapi.Value)
                    end
                    sliding = false
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if sliding then
                        slide(input)
                    end
                end
            end)

            sliderapi["Set"] = function(value, useOverMax)
                local value = not useOverMax and math.floor((math.clamp(value, min, max) * (10^roundval))+0.5)/(10^roundval) or math.clamp(value, (argstable.RealMin or -math.huge), (argstable.RealMax or math.huge))
                local sizeValue = math.floor((math.clamp(value, min, max) * (10^roundval))+0.5)/(10^roundval)
                sliderapi["Value"] = value
                SliderFill.Size = UDim2.new((sizeValue - min) / (max - min), 0, 1, 0)
                Name_3.Text = argstable.Name.." <font color='rgb(170,170,170)'>"..tostring(value).."</font>"
                argstable.Function(value)
            end
            sliderapi.Set(sliderapi["Value"])

            GuiLibrary["Objects"][OptionsButton.Name..argstable.Name.."Slider"] = {["API"] = sliderapi, ["Instance"] = Slider, ["Type"] = "Slider", ["OptionsButton"] = OptionsButton.Name, ["Window"] = Window.Name}

            return sliderapi
        end

        buttonapi["CreateTextbox"] = function(argstable) 
            local textboxapi = {["Value"] = "", }

            local Textbox = Instance.new("TextButton")
            local RealTextbox = Instance.new("TextBox")
            Textbox.Name = argstable.Name.."Textbox"
            Textbox.Parent = ModuleContainer
            Textbox.BackgroundTransparency = 1.000
            Textbox.BorderSizePixel = 0
            Textbox.Position = UDim2.new(0.0171428565, 0, 0, 0)
            Textbox.Size = UDim2.new(0, 168, 0, 30)
            Textbox.AutoButtonColor = false
            Textbox.Text = ""
            Textbox.TextColor3 = Color3.fromRGB(0, 0, 0)
            Textbox.TextSize = GuiLibrary.TextSize --4.000
            Textbox.TextXAlignment = Enum.TextXAlignment.Left
            RealTextbox.Name = "RealTextbox"
            RealTextbox.Parent = Textbox
            RealTextbox.AnchorPoint = Vector2.new(0.5, 0.5)
            RealTextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            RealTextbox.BackgroundTransparency = 1.000
            RealTextbox.Position = UDim2.new(0.51767838, 0, 0.5, 0)
            RealTextbox.Size = UDim2.new(0, 162, 0, 30)
            RealTextbox.ClearTextOnFocus = false
            RealTextbox.Font = GuiLibrary.Font
            RealTextbox.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
            RealTextbox.PlaceholderText = argstable.Name
            RealTextbox.Text = ""
            RealTextbox.TextColor3 = Color3.fromRGB(255, 255, 255)
            RealTextbox.TextSize = GuiLibrary.TextSize
            RealTextbox.TextXAlignment = Enum.TextXAlignment.Left
            textboxapi.Instance = Textbox
            textboxapi["Set"] = function(value, skipfunction) 
                local value = tostring(value)
                textboxapi["Value"] = value
                RealTextbox.Text = value
                if not skipfunction then
                    argstable.Function(value)
                end
            end
            textboxapi.Set(argstable.Default or "", true)
            RealTextbox.FocusLost:Connect(function()
                textboxapi.Set(RealTextbox.Text)
            end)

            GuiLibrary["Objects"][OptionsButton.Name..argstable.Name.."Textbox"] = {["API"] = textboxapi, ["Instance"] = Textbox, ["Type"] = "Textbox", ["OptionsButton"] = OptionsButton.Name, ["Window"] = Window.Name}
            return textboxapi
        end
        

        GuiLibrary["Objects"][argstable.Name.."OptionsButton"] = {["Name"] = argstable.Name, ["API"] = buttonapi, ["Instance"] = OptionsButton, ["Type"] = "OptionsButton", ["Window"] = Window.Name, ["DisableOnLeave"] = argstable.DisableOnLeave, ["ArrayText"] = argstable.ArrayText}
        return buttonapi
    end


    windowapi["Update"] = function()
        for i,v in next, GuiLibrary.Objects do 
            if v.Type == "OptionsButton" and v.Window == Window.Name then 
                v.API.Update()
            end
        end
        local off = 37
        Window.Size = not windowapi.Expanded and UDim2.new(0, 176, 0, 35) or UDim2.new(0, 176, 0, UIListLayout.AbsoluteContentSize.Y + 37)
    end
    windowapi.Update()
    windowapi["Expand"] = function(boolean) 
        local doexpand = boolean~=nil and boolean or not windowapi["Expanded"]
        windowapi.Expanded = doexpand
        ButtonContainer.Visible = doexpand
        windowapi.Update()
        playclicksound()
    end
    Expand.MouseButton1Click:Connect(windowapi["Expand"])
    Window_2.MouseButton2Click:Connect(windowapi["Expand"])
    dragGUI(Window, Window_2)
    local connection222 = UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):connect(windowapi.Update)
    table.insert(GuiLibrary.Connections, connection222)

    GuiLibrary["Objects"][argstable.Name.."Window"] = {["API"] = windowapi, ["Instance"] = Window, ["Type"] = "Window"}
    return windowapi
end

GuiLibrary["UpdateWindows"] = function() 
    for i,v in next, GuiLibrary.Objects do 
        if v.Type == "Window" then 
            v.API.Update()
        end
    end
end

local oldC, oldS, oldF, oldP, override = GuiLibrary.DrawCoords, GuiLibrary.DrawSpeed, GuiLibrary.DrawFPS, GuiLibrary.DrawPing, false
hudUpdate:Connect(function()
    if GuiLibrary.HUDEnabled then
        GuiLibrary["ArrayListAPI"].clearArrayObjects()

        local arrayListTable = prepareTableForArrayList(GuiLibrary.Objects)
        for i,v in ipairs(arrayListTable) do 
            GuiLibrary["ArrayListAPI"].createArrayObject(v.Name, v.ArrayText)
        end
        if GuiLibrary["ListBackground"] then 
            GuiLibrary["ArrayListAPI"].renderShadows()
        else
            GuiLibrary["ArrayListAPI"].renderShadows(1)
        end
        if GuiLibrary["ListLines"] then 
            GuiLibrary["ArrayListAPI"].renderLines()
        else
            GuiLibrary["ArrayListAPI"].renderLines(1)
        end

        GuiLibrary["WatermarkAPI"].undraw()
        if GuiLibrary["DrawWatermark"] then 
            GuiLibrary["WatermarkAPI"].draw()
        end
        if oldC ~= GuiLibrary.DrawCoords or oldS ~= GuiLibrary.DrawSpeed or oldF ~= GuiLibrary.DrawFPS or oldP ~= GuiLibrary.DrawPing or override then
            GuiLibrary["HUDAPI"].undraw()
            GuiLibrary["HUDAPI"].draw(GuiLibrary.DrawCoords, GuiLibrary.DrawSpeed, GuiLibrary.DrawFPS, GuiLibrary.DrawPing)
            override = false
        end

        oldC, oldS, oldF, oldP = GuiLibrary.DrawCoords, GuiLibrary.DrawSpeed, GuiLibrary.DrawFPS, GuiLibrary.DrawPing
    else
        GuiLibrary["ArrayListAPI"].clearArrayObjects()
        GuiLibrary["HUDAPI"].undraw()
        GuiLibrary["WatermarkAPI"].undraw()
        GuiLibrary["TargetHUDAPI"].undraw()
        override = true
    end
end)

onDestroySignal:Connect(function()
    GuiLibrary["ArrayListAPI"].clearArrayObjects()
    GuiLibrary["ScreenGui"].Enabled = false
    GuiLibrary["ScreenGui"]:Destroy()
    for i,v in next, GuiLibrary.Connections do 
        v:Disconnect()
        GuiLibrary.Connections[i] = nil
    end
    if chatchildaddedconnection then 
        chatchildaddedconnection:Disconnect()
        chatchildaddedconnection = nil
    end
    shared.Future = nil
    log("Destruct", "---- END LOG ----")
end)

return GuiLibrary