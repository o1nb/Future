local betterisfile = function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil
end

-- Local/dev copy first. This avoids dead GitHub loads and the old NVLN self-kick.
if betterisfile("Future/Initiate.lua") and loadfile then
	shared.FutureDeveloper = true
	return loadfile("Future/Initiate.lua")()
end

local code = game:HttpGet("https://raw.githubusercontent.com/o1nb/Future/main/Initiate.lua", true)
return loadstring(code)()
