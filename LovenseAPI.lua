-- // Services
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- // Merges table b onto table a. Only works with same keys
local function MergeTables(a, b)
    -- // Default
    if (typeof(a) ~= "table" or typeof(b) ~= "table") then
        return a
    end

    -- // Loop through the first table
    for i, v in pairs(a) do
        -- // Make sure this exists in the other table
        local bi = b[i]
        if (not bi) then
            continue
        end

        -- // Recursive if a table
        if (typeof(v) == "table" and typeof(bi) == "table") then
            bi = MergeTables(v, bi)
        end

        -- // Set
        a[i] = bi
    end

    -- // Return
    return a
end

-- //
local function AssertDataType(Data, Name, Types)
    if (typeof(Types) == "string") then
        Types = {Types}
    end

    local DataType = typeof(Data)
    local StringTypes = table.concat(Types, "|")
    assert(table.find(Types, DataType), "invalid type for " .. Name .. " (expected " .. StringTypes .. ", got " .. DataType .. ")")
end

local function AssertIfNotNil(Data, Expression, Error)
    if (Data) then
        assert(Expression, Error)
    end
end

-- //
local LovenseAPI = {}
LovenseAPI.__index = LovenseAPI
do
    -- // Vars
    local this = LovenseAPI
    this.IdealData = {
        QRData = {
            token = "Your Lovense Developer Token Here",
            uid = "Your UID on the Lovense website",
            uname = "Your Lovense User Nickname"
        }
    }

    -- // Constructor. Creates a new lovense client
    function LovenseAPI.new(Data)
        -- // Merge the data
        Data = MergeTables(table.clone(this.IdealData), Data or {})

        -- // Create the object
        local self = setmetatable({}, Data)

        -- // Vars
        self.QRData = Data.QRData

        -- // Return the object
        return self
    end

    -- // Logins in via QR (pretty much useless)
    function LovenseAPI.QRLogin(self)
        -- // Create a unique token
        local Salt = syn.crypt.random(32)
        local UniqueToken = syn.crypt.hash(self.QRData.uid .. Salt)
        self.QRData.utoken = UniqueToken

        -- // Send a request to get the QR code
        local Response = syn.request({
            Url = "https://api.lovense.com/api/lan/getQrCode",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(self.QRData)
        })
        local Body = HttpService:JSONDecode(Response.Body)

        -- // Ensure was success
        if (not Response.Success or not Body.result) then
            return rconsoleerr("[LovenseAPI] Unable to getQrCode")
        end

        -- // Download the QR Code
        local QRCode = syn.request({
            Url = Body.message,
            Method = "GET"
        })

        -- // Prompt the QR Code Scan
        local ImageQR = Drawing.new("Image")
        ImageQR.Data = QRCode
        ImageQR.Size = Vector2.new(500, 500)
        ImageQR.Position = Workspace.CurrentCamera.ViewportSize / 2
        ImageQR.Visible = true

        rconsoleinfo("[LovenseAPI] Please scan the following QR Code, you have one minute.")

        -- // Remove in a minute
        task.delay(60, function()
            pcall(ImageQR.Remove, ImageQR)
        end)

        -- // AFTER SCANNED, THE URL SET ON DEV DASHBOARD WILL RECIEVE DATA
    end

    -- // Verifies the Function data
    function LovenseAPI.VerifyFunctionData(Data)
        -- // Assert Types
        AssertDataType(Data.apiVer, "apiVer", "number")
        AssertDataType(Data.toy, "toy", {"string", "nil"})
        AssertIfNotNil(Data.loopPauseSec, "loopPauseSec", {"number", "nil"})
        AssertIfNotNil(Data.loopRunningSec, "loopRunningSec", {"number", "nil"})
        AssertIfNotNil(Data.timeSec, "timeSec", {"number", "nil"})
        AssertDataType(Data.action, "action", "string")
        AssertDataType(Data.command, "command", "string")
        AssertDataType(Data.uid, "uid", "string")
        AssertDataType(Data.token, "token", "string")

        -- // Special
        assert(Data.apiVer == 1, "invalid apiVer, must be 1 (got " .. Data.apiVer .. ")")
        assert(Data.loopPauseSec > 1, "invalid loopPauseSec, must be above 1 (got " .. Data.loopPauseSec .. ")")
        assert(Data.loopRunningSec > 1, "invalid loopRunningSec, must be above 1 (got " .. Data.loopRunningSec .. ")")
        assert(Data.timeSec > 1 or Data.timeSec == 0, "invalid timeSec, must be above 1 or equal to 0 (got " .. Data.timeSec .. ")")

        local ActionTypes = {"Vibrate", "Rotate", "Pump", "Stop"}
        --assert(table.find(ActionTypes, Data.action), "invalid action (got " .. Data.action .. ", expected " .. table.concat(ActionTypes, "|") .. ")")

        local CommandTypes = {"Function", "Pattern", "Preset"}
        assert(table.find(CommandTypes, Data.command), "invalid command (got " .. Data.command .. ", expected " .. table.concat(CommandTypes, "|") .. ")")
    end

    -- // Verifies the Pattern data
    function LovenseAPI.VerifyPatternData(Data)
        -- // Assert types
        AssertDataType(Data.apiVer, "apiVer", "number")
        AssertDataType(Data.toy, "toy", {"string", "nil"})
        AssertIfNotNil(Data.timeSec, "timeSec", {"number", "nil"})
        AssertDataType(Data.strength, "strength", "string")
        AssertDataType(Data.rule, "rule", "string")
        AssertDataType(Data.command, "command", "string")

        -- // Special
        assert(Data.apiVer == 1, "invalid apiVer, must be 1 (got " .. Data.apiVer .. ")")
        assert(Data.timeSec > 1 or Data.timeSec == 0, "invalid timeSec, must be above 1 or equal to 0 (got " .. Data.timeSec .. ")")

        assert(Data.strength:match("[^%d;]"), "illegal character found in strength")
        do
            local i = 0
            for _ in Data.strength:gmatch("(%d+;)") do
                i += 1
            end
            assert(i > 49, "more than 50 strength parameters")
        end

        -- // not going to bother checking the rule

        local CommandTypes = {"Function", "Pattern", "Preset"}
        assert(table.find(CommandTypes, Data.command), "invalid command (got " .. Data.command .. ", expected " .. table.concat(CommandTypes, "|") .. ")")
    end

    -- // Verifies the Preset data
    function LovenseAPI.VerifyPresetData(Data)
        -- // Assert types
        AssertDataType(Data.apiVer, "apiVer", "number")
        AssertDataType(Data.toy, "toy", {"string", "nil"})
        AssertIfNotNil(Data.timeSec, "timeSec", "number")
        AssertDataType(Data.name, "name", "string")
        AssertDataType(Data.command, "command", "string")

        -- // Special
        assert(Data.apiVer == 1, "invalid apiVer, must be 1 (got " .. Data.apiVer .. ")")
        assert(Data.timeSec > 1 or Data.timeSec == 0, "invalid timeSec, must be above 1 or equal to 0 (got " .. Data.timeSec .. ")")

        local CommandTypes = {"Function", "Pattern", "Preset"}
        assert(table.find(CommandTypes, Data.command), "invalid command (got " .. Data.command .. ", expected " .. table.concat(CommandTypes, "|") .. ")")
    end

    -- // Sends an action. To enable LANMode, pass the url (e.g. localhost:443)
    function LovenseAPI.SendAction(self, Command, Data, LANMode)
        -- // Verify command
        local CommandTypes = {"Function", "Pattern", "Preset"}
        assert(table.find(CommandTypes, Command), "invalid command (got " .. Command .. ", expected " .. table.concat(CommandTypes, "|") .. ")")

        -- // Set and verify
        if (not LANMode) then
            Data.token = self.QRData.token
            Data.uid = self.QRData.uid
        end

        Data.command = Command
        this["Verify" .. Command .. "Data"](Data)

        -- // Send the request
        local Response = syn.request({
            Url = LANMode and "https://" .. LANMode .. "/command" or "https://api.lovense.com/api/lan/v2/command",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(Data)
        }).Body
        Response = HttpService:JSONDecode(Response)

        -- // Make sure it was successful
        if (Response.code == 200) then
            return true
        end

        -- // Error
        error(Response.message)
    end
end