-- // Dependencies
local LovenseAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/KillStimulate/LovenseAPI.lua")).new({
    QRData = {
        token = "Your Lovense Developer Token Here",
        uid = "Your UID on the Lovense website",
        uname = "Your Lovense User Nickname"
    }
})
local SignalManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Signal/main/Manager.lua"))().new()

-- // Create signals
SignalManager:Add("OnKill")

-- //
local KillStimulate = {
    LANHost = "https://localhost:443",
    Signals = SignalManager,

    KillCounter = 0,
    KillTimeout = 5, -- // seconds
    LastKill = os.time(),

    Strength = 1, -- // Multiplies the strength

    Modes = {
        Vibrate = true,
        Rotate = true,
        Pump = true
    },

    Time = 5 -- // Could be a function. e.g. function(CurrentKills) return CurrentKills end
}

-- // See whenever we get a kill
SignalManager:Connect("OnKill", function()
    -- // Check if it has been a while since last kill
    if (os.time() - KillStimulate.LastKill >= KillStimulate.KillTimeout) then
        -- // Reset to 0
        KillStimulate.KillCounter = 0
    else
        -- // Increment by one
        KillStimulate.KillCounter += 1
    end

    -- // Vars
    local KillCounter = KillStimulate.KillCounter
    local Time = KillStimulate.Time

    -- // Workout the strength
    local Strength = KillCounter * KillStimulate.Strength

    -- // Workout what action to do
    local action = ""
    for Name, Value in pairs(KillStimulate.Modes) do
        -- // Make sure is enabled
        if (not Value) then
            continue
        end

        -- // Add
        action ..= ("%s:%d,"):format(Name, Strength)
    end

    -- // Remove trailing comma
    action = action:sub(1, #action - 1)

    -- // Stimulate ;)
    LovenseAPI:SendAction("Function", {
        action = action,
        timeSec = typeof(Time) == "function" and Time(KillCounter) or Time
    }, KillStimulate.LANHost)
end)