-- // Vars
local Repository = "https://raw.githubusercontent.com/Stefanuk12/KillStimulate/main/"
local PatchFormat = Repository .. "GamePatches/%s.lua"

-- // Load the base
loadstring(game:HttpGet(Repository .. "Load.lua"))()

-- // Attempt to load a patch for the game
pcall(function()
    local URL = PatchFormat:format(game.PlaceId)
    loadstring(game:HttpGet(URL))()
end)