-- =========================================================================
--  FPP LIGHTING CONTROLLER (OPTIMIZED)
-- =========================================================================

-- 1. CONFIGURATION
-- Use IP Address instead of ".local" for faster response (less DNS lag)
local FPP_CONFIG = {
    IP = "fpp.local", -- CHANGE THIS to your actual IP (e.g. 100.x.x.x)
    VIRTUAL_PORT_NAME = "MidiToFpp",
    CONTROLLER_NAME = "LPD8"
}

-- 2. COMMAND MAPPING
-- Define what each note does. 
-- Type "playlist" = Replaces background, loops forever.
-- Type "effect"   = Plays ON TOP of background (transparent), does not stop music.

local LPD8_NOTES = {
    PAD1 = 36,
    PAD2 = 37,
    PAD3 = 38,
    PAD4 = 39,
    PAD5 = 40,
    PAD6 = 41,
    PAD7 = 42,
    PAD8 = 43
}

local MIDI_MAP = {
    -- Ableton / Virtual Port Triggers
    [48] = { type = "playlist", name = "gulvet" }, -- Song 2
    [60] = { type = "effect", name = "shock4" },      -- Song 1
    
    -- LPD8 / Drum Triggers
    [LPD8_NOTES.PAD4] = { type = "sequence", name = "fire" },        -- Pad 4 (Example)
    [LPD8_NOTES.PAD8] = { type = "sequence-effect", name = "Shockwave" },     -- Pad 8 (Example)
    
    -- Panic Button
    [127] = { type = "stop_all" }
}

-- =========================================================================
--  HELPER FUNCTIONS
-- =========================================================================

-- Send Command to FPP (Fire and Forget - Non-Blocking)
local function sendFPP(endpoint)
    local url = "http://" .. FPP_CONFIG.IP .. endpoint
    print("FPP Sending: " .. url)
    
    hs.http.asyncGet(url, nil, function(status, body, headers)
        if status ~= 200 then
            print("FPP Error: " .. status)
        end
    end)
end

-- Action: Switch the Sequence
local function playSequence(name)
    stopCurrentSequence()
    sendFPP("/api/sequence/" .. hs.http.encodeForQuery(seq) .. "/start")
end

-- Action: Stop current Sequence
function stopCurrentSequence()
    local url = "http://" .. FPP_CONFIG.IP .. "/api/sequence/current/stop"
    -- Using sync call to make sure it has executed before the next command
    print("FPP Stopping: " .. url)
    local status, body, headers = hs.http.doRequest(url, "GET")
    if status ~= 200 then
        print("FPP Error: " .. status)
    end
end

-- Action: Switch the Background Song
local function playPlaylist(name)
    -- NOTE: Starting a playlist automatically stops the previous one in FPP.
    -- We do NOT need a manual stop command (which reduces lag).
    -- Ensure you have created a "Playlist" in FPP for each song.
    sendFPP("/api/playlist/start/" .. hs.http.encodeForQuery(name))
end

-- Action: Fire an Overlay Effect (Drum Hit)
local function playEffect(name)
    -- This uses the Command API to play an .eseq over the top
    -- Argument 1: Command ("Play Effect")
    -- Argument 2: Effect Name
    local StartChannel = 0
    local Loop = 'false'
    local Background = 'false'
    local IfNotRunning = 'false'
    -- TODO: Add support for parameters
    local url = "/api/command/" .. hs.http.encodeForQuery("Effect Start") .. 
                "/" .. hs.http.encodeForQuery(name) .. 
                "/" .. StartChannel .. 
                "/" .. Loop .. 
                "/" .. Background .. 
                "/" .. IfNotRunning
    sendFPP(url)
end

-- Action: Fire an Overlay Effect (Drum Hit)
local function playSequenceAsEffect(name)
    -- This uses the Command API to play an .eseq over the top
    -- Argument 1: Command ("Play Effect")
    -- Argument 2: Effect Name
    local Loop = 'false'
    local Background = 'false'
    -- TODO: Add support for parameters
    local url = "/api/command/" .. hs.http.encodeForQuery("Effect Start") .. 
                "/" .. Loop .. 
                "/" .. Background
    sendFPP(url)
end

-- Action: Stop Everything
local function stopAll()
    sendFPP("/api/playlists/stop") -- Stops background
    sendFPP("/api/command/Stop%20All%20Effects") -- Stops overlays
end

-- Central Logic Handler
local function handleMidi(metadata)
    -- Ignore Note-Offs (Velocity 0)
    if metadata.velocity == 0 then return end
    
    local action = MIDI_MAP[metadata.note]
    
    if action then
        print("Triggering: " .. (action.name or "Stop"))
        
        if action.type == "playlist" then
            playPlaylist(action.name)
        elseif action.type == "effect" then
            playEffect(action.name)
        elseif action.type == "sequence" then
            playSequence(action.name)
        elseif action.type == "sequence-effect" then
            playSequenceAsEffect(action.name)
        elseif action.type == "stop_all" then
            stopAll()
        end
    else
        print("Unmapped Note: " .. metadata.note)
    end
end

-- =========================================================================
--  MIDI LISTENERS
-- =========================================================================

-- print available MIDI device names to the Hammerspoon Console
print("Devices: " .. hs.inspect(hs.midi.devices()))
print("VirtualSources: " .. hs.inspect(hs.midi.virtualSources()))

-- 1. Virtual Source (From Ableton)
local virtualMidi = hs.midi.newVirtualSource(FPP_CONFIG.VIRTUAL_PORT_NAME)
if virtualMidi then
    virtualMidi:callback(function(_, _, commandType, _, metadata)
        if commandType == "noteOn" then handleMidi(metadata) end
    end)
else
    print("Warning: Virtual MIDI " .. FPP_CONFIG.VIRTUAL_PORT_NAME .. " not found")
end

-- 2. Physical Controller (LPD8)
local lpd8Midi = hs.midi.new(FPP_CONFIG.CONTROLLER_NAME)
if lpd8Midi then
    print("Connected to LPD8")
    lpd8Midi:callback(function(_, _, commandType, _, metadata)
        if commandType == "noteOn" then handleMidi(metadata) end
    end)
else
    print("Warning: LPD8 not found")
end

print("Hammerspoon FPP Controller: ONLINE")