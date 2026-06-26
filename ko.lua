-- Remembers your key locally so you don't have to re-enter it every time.

local HttpService = game:GetService("HttpService")

-- File path for saved key (stored locally on the user's executor)
local KEY_FILE = "KienHub_Key.txt"
local PlaceId = game.PlaceId
local UniverseId = game.GameId

-- Game Detection
local GameName = "Kairsh Studio"
local BloxFruitsUniverse = 994732206
local DBOGUniverse = 1374118848
local DBOGPlaceId = 4638110048
local VolleyBallLegendUniverse = 6931042565

print("[Kairsh Studio] Initializing... PlaceId: " .. tostring(PlaceId) .. " | UniverseId: " .. tostring(UniverseId))

if UniverseId == BloxFruitsUniverse then
    GameName = "Kairsh Studio â€” Blox Fruits"
elseif UniverseId == DBOGUniverse or PlaceId == DBOGPlaceId then
    GameName = "Kairsh Studio â€” DBOG"
elseif PlaceId == 77747658251236 then
    GameName = "Kairsh Studio â€” Sailor Piece"
elseif UniverseId == VolleyBallLegendUniverse then
    GameName = "Kairsh Studio â€” Volleyball Legend"
end
getgenv().CurrentGameName = GameName

-- Helper: check if executor supports file functions
local hasFileSupport = (typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function")

-- Helper: validate a key with the server
local function validateKey(key)
    -- Bypass: key "khanhhuy" is always valid
    if key == "khanhhuy" then
        return true
    end

    local ok, response = pcall(function()
        return game:HttpGet("https://kairshstudio.com/validate-key.php?key=" .. key)
    end)
    if not ok or not response then return false end
    local decodeOk, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not decodeOk or not data then return false end
    return data.valid == true
end

-- Helper: save key locally
local function saveKey(key)
    if hasFileSupport then
        pcall(function() writefile(KEY_FILE, key) end)
    end
end

-- Helper: load saved key
local function loadSavedKey()
    if hasFileSupport then
        local ok, key = pcall(function()
            if isfile(KEY_FILE) then
                return readfile(KEY_FILE)
            end
            return nil
        end)
        if ok and key and key ~= "" then
            return key
        end
    end
    return nil
end

-- Helper: load the hub
local function loadHub(key)
    print("[Kairsh Studio] Requesting Hub Script from server...")
    print("[Kairsh Studio] Debug -> PlaceId: " .. tostring(PlaceId) .. " | UniverseId: " .. tostring(UniverseId))
    local hubOk, hubErr = pcall(function()
        local scriptSource = game:HttpGet("https://kairshstudio.com/hub.php?key=" .. key .. "&placeId=" .. PlaceId .. "&universeId=" .. UniverseId)
        print("[Kairsh Studio] Script source received (length: " .. #scriptSource .. ")")
        loadstring(scriptSource)()
    end)
    if not hubOk then
        warn("[Kairsh Studio] Hub failed to load/execute: " .. tostring(hubErr))
    else
        print("[Kairsh Studio] Hub executed successfully for: " .. GameName)
    end
    if key == "FreeKey" then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Trial Version",
                Text = "You are using the free trial version. Join discord to get a free key!",
                Duration = 10,
            })
        end)

        task.spawn(function()
            task.wait(1800) -- 30 minutes
            local player = game:GetService("Players").LocalPlayer
            if player then
                player:Kick("30 Minute Free Trial Expired! Please join our Discord to get the unlimited free key. Link: discord.gg/QhA9nBeSuz")
            end
        end)
    end
end

-- Step 2: Show auth UI or Auto-login
local WindUI = loadstring(game:HttpGet("https://kairshstudio.com/get-script.php"))()
if not WindUI then
    warn("[Kairsh Studio] Failed to load UI library.")
    return
end

-- Step 1: Try auto-login with saved key
local savedKey = loadSavedKey()
if savedKey and savedKey ~= "FreeKey" then
    if validateKey(savedKey) then
        WindUI:Notify({
            Title = "Access Granted",
            Content = "Welcome back! Loading Hub for " .. GameName .. "...",
            Icon = "solar:check-circle-bold",
            Duration = 3,
        })
        task.wait(1)
        loadHub(savedKey)
        return
    else
        -- Key was revoked or invalid â€” delete saved file
        if hasFileSupport then
            pcall(function() delfile(KEY_FILE) end)
        end
    end
end

-- Step 2: No saved key or it was invalid â€” show auth UI
local AuthWindow = WindUI:CreateWindow({
    Title = GameName,
    Icon = "solar:lock-password-bold-duotone",
    Folder = "Kairsh Studio",
    Size = UDim2.fromOffset(440, 400),
    OpenButton = { Enabled = false },
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

local AuthTab = AuthWindow:Tab({
    Title = "Authentication",
    Icon = "solar:key-bold",
    Border = true,
})

AuthTab:Section({
    Title = "Access Key Required",
    TextSize = 20,
    FontWeight = Enum.FontWeight.SemiBold,
})

AuthTab:Space()

AuthTab:Section({
    Title = "Enter your key below to access the hub. Contact the owner if you don't have one.",
    TextSize = 14,
    TextTransparency = 0.35,
    FontWeight = Enum.FontWeight.Medium,
})

-- ĐÃ XÓA: Section "Use Key FreeKey" và nút "Join Discord to Get Key"

AuthTab:Space()

local enteredKey = ""

AuthTab:Input({
    Title = "Access Key",
    Placeholder = "XXXX-XXXX-XXXX-XXXX",
    Icon = "key",
    Callback = function(value)
        enteredKey = value
    end,
})

AuthTab:Space()

AuthTab:Button({
    Title = "Verify & Enter Hub",
    Icon = "solar:shield-check-bold",
    Color = Color3.fromHex("#30FF6A"),
    Justify = "Center",
    Callback = function()
        if enteredKey == "" then
            WindUI:Notify({
                Title = "No Key Entered",
                Content = "Please paste your access key into the field above.",
                Icon = "solar:danger-triangle-bold",
                Duration = 4,
            })
            return
        end

        if validateKey(enteredKey) then
            -- Save key for next time
            saveKey(enteredKey)

            WindUI:Notify({
                Title = "Access Granted",
                Content = "Key verified! Loading Hub for " .. GameName .. "...",
                Icon = "solar:check-circle-bold",
                Duration = 2,
            })

            task.wait(1.5)
            AuthWindow:Destroy()
            loadHub(enteredKey)
        else
            WindUI:Notify({
                Title = "Access Denied",
                Content = "That key is invalid or has been revoked. Contact the hub owner.",
                Icon = "solar:close-circle-bold",
                Duration = 6,
            })
        end
    end,
})