-- Writes song metadata to a file on each song selection, for Streamer.bot
-- to pick up via a file watcher. Output: <Ragnarock>/Binaries/Win64/SongBridge.txt

local LOG_PREFIX = "[SongBridgeVR] "
local function log(msg)
    print(LOG_PREFIX .. tostring(msg) .. "\n")
end

log("Mod loaded. Hooking Item_StartSong_C:Construct...")

local HOOK_PATH = "/Game/UI/InGame/Item_StartSong.Item_StartSong_C:Construct"
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

local function parse_duration_to_seconds(text)
    if type(text) ~= "string" then return 0 end
    local min, sec = text:match("^(%d+):(%d%d)$")
    if min and sec then
        return tonumber(min) * 60 + tonumber(sec)
    end
    return 0
end

local function write_song_bridge_file(data)
    local ok, err = pcall(function()
        local file = io.open(OUTPUT_FILE, "w")
        if not file then
            log("Error: could not open file " .. OUTPUT_FILE)
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

local function on_construct(Context)
    local selfObjOk, selfObj = pcall(function() return Context:get() end)
    if not selfObjOk or not selfObj then return end

    local bmOk, beatMap = pcall(function() return selfObj.BeatMap end)
    if not bmOk or beatMap == nil then return end

    local levelOk, selectedLevel = pcall(function() return beatMap.m_level end)
    local hashOk, hash = pcall(function() return beatMap.m_hash end)
    if not levelOk or type(selectedLevel) ~= "number" then return end
    if not hashOk or type(hash) ~= "number" then return end

    if hash == lastWrittenHash then
        return
    end
    lastWrittenHash = hash

    log("=== Neue Song-Auswahl erkannt (Hash: " .. tostring(hash) .. ") ===")

    local songOk, songObj = pcall(function() return selfObj.Song end)
    if not songOk or songObj == nil then
        log("  self.Song nicht lesbar, ueberspringe.")
        return
    end

    local isCustomOk, isCustomVal = call_getter(songObj, "IsCustom")
    local isCustom = isCustomOk and isCustomVal or "unknown"

    local _, bandRaw = call_getter(selfObj, "Get_Band_Text")
    local _, titleRaw = call_getter(selfObj, "Get_Title_Text_0")
    local _, authorRaw = call_getter(selfObj, "Get_Author_Text_0")
    local _, durationTextRaw = call_getter(selfObj, "Get_Duration_Text_0")
    local artist = resolve_text_value(bandRaw) or ""
    local title = resolve_text_value(titleRaw) or ""
    local mapper = resolve_text_value(authorRaw) or ""
    local durationText = resolve_text_value(durationTextRaw) or ""
    local length = parse_duration_to_seconds(durationText)

    local bpmOk, bpmVal = call_getter(songObj, "GetBaseBpm")
    local bpm = bpmOk and bpmVal or 0

    local allLevels = {}
    pcall(function()
        local beatMaps = songObj.m_beatMaps
        beatMaps:ForEach(function(i, element)
            local eOk, bm = pcall(function() return element:get() end)
            if eOk and bm ~= nil then
                local lOk, lvl = pcall(function() return bm.m_level end)
                if lOk and type(lvl) == "number" then
                    table.insert(allLevels, lvl)
                end
            end
        end)
    end)
    local allLevelsStr = table.concat(allLevels, ",")

    log("  Artist=" .. artist .. " Title=" .. title .. " Mapper=" .. mapper
        .. " IsCustom=" .. tostring(isCustom) .. " Length=" .. tostring(length)
        .. " BPM=" .. tostring(bpm) .. " Level=" .. tostring(selectedLevel)
        .. " AllLevels=" .. allLevelsStr)

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
end

local registered = false
LoopAsync(2000, function()
    if registered then return true end
    local ok = pcall(function()
        RegisterHook(HOOK_PATH, on_construct)
    end)
    if ok then
        registered = true
        log("Hook erfolgreich registriert. Warte auf Song-Auswahl...")
        return true
    end
    return false
end)