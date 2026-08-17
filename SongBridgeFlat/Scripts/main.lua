-- Writes song metadata to a file on each song selection, for Streamer.bot
-- to pick up via a file watcher. Output: <Ragnarock>/Binaries/Win64/SongBridge.txt

local LOG_PREFIX = "[SongBridge] "
local function log(msg)
    print(LOG_PREFIX .. tostring(msg) .. "\n")
end

log("Mod loaded. Hooking FlatStartSongPanel_C:SetSong...")

local OUTPUT_FILE = "SongBridge.txt"
local lastWrittenHash = nil

local function call_getter(obj, fname)
    local ok, result = pcall(function() return obj[fname](obj) end)
    if ok then
        return true, result
    end
    return false, result
end

local function resolve_text_value(val)
    if val == nil then return nil end
    local t = type(val)
    if t == "string" then return val end
    if t == "number" or t == "boolean" then return tostring(val) end
    local ok, resolved = pcall(function() return val:ToString() end)
    if ok and type(resolved) == "string" then
        return resolved
    end
    return nil
end

local function write_song_bridge_file(data)
    local ok, err = pcall(function()
        local file = io.open(OUTPUT_FILE, "w")
        if not file then
            log("Error: could not open file: " .. OUTPUT_FILE)
            return
        end
        file:write("Hash=" .. tostring(data.hash) .. "\n")
        file:write("IsCustom=" .. tostring(data.isCustom) .. "\n")
        file:write("Artist=" .. tostring(data.artist) .. "\n")
        file:write("Title=" .. tostring(data.title) .. "\n")
        file:write("Mapper=" .. tostring(data.mapper) .. "\n")
        file:write("Length=" .. tostring(data.length) .. "\n")
        file:write("BPM=" .. tostring(data.bpm) .. "\n")
        file:write("Level=" .. tostring(data.level) .. "\n")
        file:write("AllLevels=" .. tostring(data.allLevels) .. "\n")
        file:close()
    end)
    if not ok then
        log("Error writing file: " .. tostring(err))
    else
        log("SongBridge.txt written.")
    end
end

local function try_register()
    return pcall(function()
        RegisterHook("/Game/Flat/Blueprints/UI/InGame/FlatStartSongPanel.FlatStartSongPanel_C:SetSong", function(self, ...)
            local selfObjOk, selfObj = pcall(function() return self:get() end)
            if not selfObjOk or not selfObj then return end

            local widgetOk, levelWidget = pcall(function() return selfObj.FlatSongLevel_C_0 end)
            local selectedLevel = nil
            if widgetOk and levelWidget ~= nil then
                local levelOk, level = pcall(function() return levelWidget.Level end)
                if levelOk and type(level) == "number" then
                    selectedLevel = level
                end
            end

            local songOk, songObj = pcall(function() return selfObj.Song end)
            if not songOk or songObj == nil or selectedLevel == nil then return end

            local allLevels = {}
            pcall(function()
                local beatMaps = songObj.m_beatMaps
                beatMaps:ForEach(function(i, element)
                    local bm = element:get()
                    table.insert(allLevels, tostring(bm.m_level))
                end)
            end)
            local allLevelsStr = table.concat(allLevels, ",")

            local hash = nil
            pcall(function()
                local beatMaps = songObj.m_beatMaps
                beatMaps:ForEach(function(i, element)
                    local bm = element:get()
                    if bm.m_level == selectedLevel and hash == nil then
                        hash = bm.m_hash
                    end
                end)
            end)

            if hash == nil then
                log("  Hash konnte nicht ermittelt werden, ueberspringe.")
                return
            end

            if hash == lastWrittenHash then
                return
            end
            lastWrittenHash = hash

            log("=== New song selection detected (Hash: " .. tostring(hash) .. ") ===")

            local isCustomOk, isCustomVal = call_getter(songObj, "IsCustom")
            local isCustom
            if isCustomOk then
                isCustom = isCustomVal
            else
                isCustom = "unknown"
            end

            local _, bandRaw = call_getter(selfObj, "Get_Band_Text")
            local _, titleRaw = call_getter(selfObj, "Get_Title_Text_0")
            local _, authorRaw = call_getter(selfObj, "Get_Author_Text_0")
            local artist = resolve_text_value(bandRaw) or ""
            local title = resolve_text_value(titleRaw) or ""
            local mapper = resolve_text_value(authorRaw) or ""

            local length = 0
            pcall(function()
                local durWidget = selfObj.FlatSongDuration
                if durWidget ~= nil then
                    length = durWidget.Duration or 0
                end
            end)

            local bpmOk, bpmVal = call_getter(songObj, "GetBaseBpm")
            local bpm = bpmOk and bpmVal or 0

            log("  Artist=" .. artist .. " Title=" .. title .. " Mapper=" .. mapper
                .. " IsCustom=" .. tostring(isCustom) .. " Length=" .. tostring(length)
                .. " BPM=" .. tostring(bpm))

            write_song_bridge_file({
                hash = hash,
                isCustom = isCustom,
                artist = artist,
                title = title,
                mapper = mapper,
                length = length,
                bpm = bpm,
                level = selectedLevel,
                allLevels = allLevelsStr,
            })
        end)
    end)
end

local registered = false
LoopAsync(2000, function()
    if registered then return true end
    local ok = try_register()
    if ok then
        registered = true
        log("Hook erfolgreich registriert. Warte auf Song-Auswahl...")
        return true
    end
    return false
end)