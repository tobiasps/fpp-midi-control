-- print available MIDI device names to the Hammerspoon Console
print("Devices: " .. hs.inspect(hs.midi.devices()))
virtualSources = hs.midi.virtualSources()
print("VirtualSources: " .. hs.inspect(virtualSources))

-- Your FPP IP
local FPP_IP = "fpp.local"    -- change this to your Pi's IP
local PLAYLIST_NAME = "MyShow"   -- change to your FPP playlist name

-- Function to trigger FPP playlist
function triggerFPP()
    local url = "http://" .. FPP_IP .. "/api/command/StartPlaylist/" .. PLAYLIST_NAME
    hs.http.doAsyncRequest(url, "GET", nil, nil, function(status, body)
        print("FPP trigger returned status:", status)
    end)
end

function stopPlayback()
    local url = "http://" .. FPP_IP .. "/api/sequence/current/stop"
    -- Using sync call to make sure it has executed before the next command
    local status, body, headers = hs.http.doRequest(url, "GET")
    print("FPP stop returned status:", status)
end

-- Start a FPP sequence, stop any other sequence that is playing
function triggerFPPSeq(seq)
    stopPlayback()
    local url = "http://" .. FPP_IP .. "/api/sequence/" .. hs.http.encodeForQuery(seq) .. "/start"
    hs.http.doAsyncRequest(url, "GET", nil, nil, function(status, body)
        print("FPP trigger returned status:", status)
    end)
end

-- Listen to MIDI note-on from virtual source MidiToFPP
local midi = hs.midi.newVirtualSource("MidiToFPP")
if midi ~= nil then
    midi:callback(function(object, deviceName, commandType, description, metadata)
        if commandType ~= "noteOn" then
            return
        end
        print(
            "Received note:", metadata.note, 
            "on channel:", metadata.channel, 
            "with velocity:", metadata.velocity, 
            "at time:", metadata.timestamp
        )

        if metadata.note == 60 then
            triggerFPPSeq("blandet")
        elseif metadata.note == 62 then
            triggerFPPSeq("fire")
        elseif metadata.note == 64 then
            triggerFPPSeq("Plasma Parts")
        end
    end)
end

-- LPD8 midi controller
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

-- listen for midi note-on from LPD8
local lpd8_midi = hs.midi.new("LPD8")
if lpd8_midi ~= nil then
    lpd8_midi:callback(function(object, deviceName, commandType, description, metadata)
        if commandType ~= "noteOn" then
            return
        end
        print(
            "Received note:", metadata.note, 
            "on channel:", metadata.channel, 
            "with velocity:", metadata.velocity, 
            "at time:", metadata.timestamp
        )

        if metadata.note == LPD8_NOTES.PAD8 then
            triggerFPPSeq("Plasma Parts")
        elseif metadata.note == LPD8_NOTES.PAD4 then
            triggerFPPSeq("fire")
        end
    end)
end

print("Hammerspoon FPP Trigger Loaded")