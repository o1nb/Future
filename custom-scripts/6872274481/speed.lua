do return end

local Future = shared.Future
local GuiLibrary = Future.GuiLibrary

local SpeedHack = GuiLibrary.Objects.MovementWindow.API.CreateOptionsButton({
    Name = "SpeedHack",
    Function = function(callback) 
        if callback then 
            game:GetService("RunService"):BindToRenderStep("SpeedHack", 1, function(dt) 
                local Character = game:GetService("Players").LocalPlayer.Character
                if not Character or not Character:FindFirstChild("HumanoidRootPart") or not Character:FindFirstChild("Humanoid") then
                    return 
                end
                local Speed = 25
                local HumanoidRootPart = Character.HumanoidRootPart
                local Humanoid = Character.Humanoid
                local Velocity = HumanoidRootPart.Velocity
                local MoveDirection = Humanoid.MoveDirection
                local MoveDirection2 = MoveDirection * Speed
                HumanoidRootPart.Velocity = (Vector3.new(MoveDirection2.X, Velocity.Y, MoveDirection2.Z))
            end)
        else
            game:GetService("RunService"):UnbindFromRenderStep("SpeedHack")
        end
    end,
})