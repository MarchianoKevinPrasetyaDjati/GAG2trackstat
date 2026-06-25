-- ==========================================
-- TrackStat Logger Bulk (Watchlist Edition): Grow A Garden 2
-- Place ID: 97598239454123
-- ==========================================

local TARGET_PLACE_ID = 97598239454123

if game.PlaceId ~= TARGET_PLACE_ID then
    warn("[TrackStat] Eksekusi Dibatalkan: Ini bukan game Grow a Garden 2!")
    return
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Ganti dengan IP/Domain web privat Anda jika dihosting online
local WEBHOOK_URL = "http://localhost:3000/api/trackstat" 

local HTTP_REQUEST = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
if not HTTP_REQUEST then
    warn("[TrackStat] Eksekutor Anda tidak mendukung HTTP Request!")
    return
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

local function SendBulkStatData()
    local payload = {}
    local timestamp = os.time()
    
    -- Mengumpulkan data semua orang di server
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(payload, {
            username = player.Name,
            userId = player.UserId,
            placeId = game.PlaceId,
            gameName = "Grow A Garden 2",
            stats = GetPlayerStats(player),
            timestamp = timestamp
        })
    end

    local success, response = pcall(function()
        return HTTP_REQUEST({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success and response.Success then
        print("[TrackStat] Bulk Data (" .. #payload .. " pemain) berhasil dikirim!")
    else
        warn("[TrackStat] Gagal mengirim bulk data.")
    end
end

print("[TrackStat] Memulai pelacakan seluruh server untuk Grow A Garden 2...")

-- Loop pengiriman data (otomatis update setiap 15 detik)
task.spawn(function()
    while task.wait(15) do 
        SendBulkStatData()
    end
end)
