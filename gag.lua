-- ==========================================
-- TrackStat Logger: Grow A Garden 2
-- Place ID: 97598239454123
-- ==========================================

local TARGET_PLACE_ID = 97598239454123

if game.PlaceId ~= TARGET_PLACE_ID then
    warn("[TrackStat] Eksekusi Dibatalkan: Ini bukan game Grow a Garden 2!")
    return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- [PENGATURAN]
-- ==========================================
-- URL Web Privat Anda (Ganti dengan IP/Domain jika dihosting online)
local WEBHOOK_URL = "http://localhost:3000/api/trackstat" 

-- Jika ingin melacak player lain, ketik username-nya di bawah ini.
-- Kosongkan ("") untuk melacak akun Anda sendiri (LocalPlayer).
local TARGET_USERNAME = "" 
-- ==========================================

local HTTP_REQUEST = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not HTTP_REQUEST then
    warn("[TrackStat] Eksekutor Anda tidak mendukung HTTP Request!")
    return
end

-- Fungsi mencari target player
local function GetTargetPlayer()
    if TARGET_USERNAME ~= "" then
        for _, p in pairs(Players:GetPlayers()) do
            if string.lower(p.Name) == string.lower(TARGET_USERNAME) or string.find(string.lower(p.Name), string.lower(TARGET_USERNAME)) then
                return p
            end
        end
        return nil -- Player tidak ditemukan di server
    end
    return LocalPlayer
end

-- Fungsi membaca status dan isi tas player
local function GetPlayerStats(player)
    local stats = {}
    
    -- 1. Membaca Leaderstats (Sheckles, dll)
    if player:FindFirstChild("leaderstats") then
        for _, stat in pairs(player.leaderstats:GetChildren()) do
            if stat:IsA("ValueBase") then
                stats[stat.Name] = stat.Value
            end
        end
    end
    
    -- 2. Membaca Backpack (Inventory)
    local backpackItems = {}
    if player:FindFirstChild("Backpack") then
        for _, item in pairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(backpackItems, item.Name)
            end
        end
    end
    
    -- Mengecek alat yang sedang dipegang di tangan (karena alat yg dipegang pindah ke Character)
    if player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(backpackItems, item.Name .. " (Di Tangan)")
            end
        end
    end
    
    -- Menggabungkan list tas menjadi satu teks
    if #backpackItems > 0 then
        stats["Backpack"] = table.concat(backpackItems, ", ")
    else
        stats["Backpack"] = "Kosong"
    end

    return stats
end

local function SendStatData()
    local targetPlayer = GetTargetPlayer()
    if not targetPlayer then return end -- Skip jika target tidak ada di game
    
    local currentStats = GetPlayerStats(targetPlayer)
    
    local payload = {
        username = targetPlayer.Name,
        userId = targetPlayer.UserId,
        placeId = game.PlaceId,
        gameName = "Grow A Garden 2",
        stats = currentStats,
        timestamp = os.time()
    }

    local success, response = pcall(function()
        return HTTP_REQUEST({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success and response.Success then
        print("[TrackStat] Data " .. targetPlayer.Name .. " berhasil dikirim!")
    else
        warn("[TrackStat] Gagal mengirim data.")
    end
end

print("[TrackStat] Memulai pelacakan untuk Grow A Garden 2 (Target: " .. (TARGET_USERNAME == "" and LocalPlayer.Name or TARGET_USERNAME) .. ")...")

-- Loop pengiriman data (otomatis update setiap 15 detik)
task.spawn(function()
    while task.wait(15) do 
        SendStatData()
    end
end)
