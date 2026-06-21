-- Hash Hub whitelist
-- Upload this file to:
-- https://amrho94.github.io/target/part/hash/close/almost/oof/hash/hashhub/fart/whitelist.lua

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- UserIds only. Names are comments for readability and are never checked.
local AUTHORIZED_USER_IDS = {
	[3677798980] = true, -- lilgohs2
	[11241745] = true, -- jp1029
}

if not player then
	return false
end

return AUTHORIZED_USER_IDS[player.UserId] == true
