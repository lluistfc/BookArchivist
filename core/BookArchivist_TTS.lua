---@diagnostic disable: undefined-global
-- BookArchivist_TTS.lua
-- Text-to-Speech functionality for BookArchivist

local BA = BookArchivist

local TTS = {}
BA.TTS = TTS

-- Module state
local state = TTS.__state or {}
TTS.__state = state

-- Default settings
local DEFAULTS = {
    voiceID = 0,
    speed = 0,      -- Range: -10 to 10
    volume = 50,    -- Range: 0 to 100
}

-- ============================================================================
-- Core TTS API
-- ============================================================================

-- Check if TTS APIs are available
function TTS:IsSupported()
    local hasAPIs = C_VoiceChat and C_VoiceChat.SpeakText and C_VoiceChat.StopSpeakingText
    return hasAPIs and true or false
end

-- Get available TTS voices
-- Returns array of { voiceID, name } or empty table if not available
function TTS:GetVoices()
    if not C_VoiceChat or not C_VoiceChat.GetTtsVoices then
        return {}
    end
    local voices = C_VoiceChat.GetTtsVoices()
    return voices or {}
end

-- Get current TTS settings from database
function TTS:GetSettings()
    local Repository = BA and BA.Repository
    if not Repository then
        return DEFAULTS
    end
    local db = Repository:GetDB()
    if not db or not db.options or not db.options.tts then
        return DEFAULTS
    end
    return {
        voiceID = db.options.tts.voiceID or DEFAULTS.voiceID,
        speed = db.options.tts.speed or DEFAULTS.speed,
        volume = db.options.tts.volume or DEFAULTS.volume,
    }
end

-- Set TTS settings in database
function TTS:SetSettings(settings)
    local Repository = BA and BA.Repository
    if not Repository then
        return
    end
    local db = Repository:GetDB()
    if not db then
        return
    end
    db.options = db.options or {}
    db.options.tts = db.options.tts or {}
    if settings.voiceID ~= nil then
        db.options.tts.voiceID = settings.voiceID
    end
    if settings.speed ~= nil then
        db.options.tts.speed = settings.speed
    end
    if settings.volume ~= nil then
        db.options.tts.volume = settings.volume
    end
end

-- Check if currently speaking
function TTS:IsSpeaking()
    return state.isSpeaking == true
end

-- Test function to verify TTS works with WoW's sample text
-- Pass voiceID to test specific voice, or nil to use English voice
function TTS:TestSample(testVoiceID)
    if not self:IsSupported() then
        return false, "TTS API not available"
    end
    
    -- Get available voices
    local voices = self:GetVoices()
    if BA and BA.DebugPrint then
        BA:DebugPrint("[TTS] Available voices: " .. tostring(#voices))
        for i, v in ipairs(voices) do
            BA:DebugPrint("[TTS] Voice " .. i .. ": ID=" .. tostring(v.voiceID) .. " Name=" .. tostring(v.name))
        end
    end
    
    -- Use provided voice ID or find English voice (ID=1 is Zira English)
    local voiceID = testVoiceID
    if voiceID == nil then
        -- Try to get the user's configured TTS voice from Accessibility settings
        -- GetVoiceOptionID requires a voiceType parameter (0 = standard, 1 = alternate)
        if C_TTSSettings and C_TTSSettings.GetVoiceOptionID then
            local ok, userVoice = pcall(C_TTSSettings.GetVoiceOptionID, 0)
            if ok and userVoice and userVoice >= 0 then
                voiceID = userVoice
            end
        end
        -- Fallback: find English voice
        if voiceID == nil then
            for _, v in ipairs(voices) do
                if v.name and v.name:find("English") then
                    voiceID = v.voiceID
                    break
                end
            end
        end
        -- Final fallback to first voice
        if voiceID == nil and voices[1] then
            voiceID = voices[1].voiceID
        end
    end
    
    local speed = 0
    local volume = 100  -- Max volume for testing
    -- Try destination 4 (QueuedLocalPlayback)
    local destination = 4
    
    -- Use WoW's built-in sample text
    local sampleText = TEXT_TO_SPEECH_SAMPLE_TEXT or "This is a test of the text to speech system."
    if BA and BA.DebugPrint then
        BA:DebugPrint("[TTS] User voice setting: " .. tostring(C_TTSSettings and C_TTSSettings.GetVoiceOptionID and C_TTSSettings.GetVoiceOptionID() or "N/A"))
        BA:DebugPrint("[TTS] Testing with voiceID=" .. tostring(voiceID) .. ", dest=" .. tostring(destination) .. " (QueuedLocalPlayback), volume=" .. tostring(volume))
        BA:DebugPrint("[TTS] Sample text: " .. sampleText)
    end
    
    C_VoiceChat.SpeakText(voiceID, sampleText, destination, speed, volume)
    return true
end

-- Test all voices to find which ones work
function TTS:TestAllVoices()
    local voices = self:GetVoices()
    if not voices or #voices == 0 then
        if BA and BA.DebugPrint then
            BA:DebugPrint("[TTS] No voices available")
        end
        return
    end
    
    if BA and BA.DebugPrint then
        BA:DebugPrint("[TTS] Testing all " .. #voices .. " voices...")
    end
    
    -- Test each voice with a short delay between them
    local testText = "Testing voice"
    for i, v in ipairs(voices) do
        C_Timer.After((i-1) * 3, function()
            if BA and BA.DebugPrint then
                BA:DebugPrint("[TTS] Testing voice " .. i .. ": " .. tostring(v.name))
            end
            C_VoiceChat.SpeakText(v.voiceID, testText .. " " .. i, 1, 0, 100)
        end)
    end
end

-- Test using Blizzard's TextToSpeech system (what chat TTS uses)
function TTS:TestBlizzardTTS()
    local text = "Testing Blizzard text to speech system"
    if BA and BA.DebugPrint then
        BA:DebugPrint("[TTS] Testing Blizzard TTS with: " .. text)
    end
    
    -- Get the user's configured voice from TTS settings
    local voice = nil
    if C_TTSSettings and C_TTSSettings.GetVoiceOptionID then
        local voiceID = C_TTSSettings.GetVoiceOptionID(0)  -- 0 = standard voice type
        if voiceID then
            local voices = C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices() or {}
            for _, v in ipairs(voices) do
                if v.voiceID == voiceID then
                    voice = v
                    break
                end
            end
        end
    end
    
    -- Fallback to first available voice
    if not voice then
        local voices = C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices() or {}
        if voices[1] then
            voice = voices[1]
        end
    end
    
    if BA and BA.DebugPrint then
        BA:DebugPrint("[TTS] Using voice: " .. (voice and voice.name or "nil"))
    end
    
    -- Try TextToSpeech_Speak with voice parameter
    if TextToSpeech_Speak and voice then
        if BA and BA.DebugPrint then
            BA:DebugPrint("[TTS] Calling TextToSpeech_Speak with voice")
        end
        TextToSpeech_Speak(text, voice)
        return true
    end
    
    if BA and BA.DebugPrint then
        BA:DebugPrint("[TTS] TextToSpeech_Speak not available or no voice")
    end
    return false
end

-- Stop any ongoing speech
function TTS:Stop()
    if not self:IsSupported() then
        return
    end
    if C_VoiceChat.StopSpeakingText then
        C_VoiceChat.StopSpeakingText()
    end
    state.isSpeaking = false
end

-- Clean text for TTS (remove formatting codes, HTML, etc.)
local function cleanTextForTTS(text)
    if not text then
        return ""
    end
    -- Remove color codes |cXXXXXXXX and |r
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    -- Remove texture/atlas references
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|A.-|a", "")
    -- Remove hyperlinks
    text = text:gsub("|H.-|h(.-)|h", "%1")
    -- Remove other UI escape sequences
    text = text:gsub("|n", " ")
    text = text:gsub("|N", " ")
    
    -- Only strip HTML tags if content is actually HTML
    -- Use the same detection as the reader: look for structural HTML tags
    local lowered = text:lower()
    local isHTML = lowered:find("<%s*html", 1, false)
        or lowered:find("<%s*body", 1, false)
        or lowered:find("<%s*img", 1, false)
        or lowered:find("<%s*table", 1, false)
        or lowered:find("<%s*h%d", 1, false)
        or lowered:find("<%s*br", 1, false)
        or lowered:find("<%s*p%s*>", 1, false)
        or lowered:find("<%s*p%s[^>]*>", 1, false)
    
    if isHTML then
        -- Strip all HTML tags for TTS
        text = text:gsub("<[^>]+>", "")
    end
    -- Narrative angle brackets like <No words remain> are preserved as text
    -- but we remove the < > symbols themselves since TTS might ignore content between them
    text = text:gsub("<", "")
    text = text:gsub(">", "")
    
    -- Convert escaped pipes
    text = text:gsub("||", "|")
    -- Remove extra whitespace
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

-- Speak the given text
function TTS:Speak(text)
    if not text or text == "" then
        return false, "No text to speak"
    end
    
    -- Stop any current speech first
    self:Stop()
    
    -- Clean text for TTS
    local cleanedText = cleanTextForTTS(text)
    if cleanedText == "" then
        return false, "No speakable text"
    end
    
    -- Get voice object for TextToSpeech_Speak
    local voice = nil
    local voices = C_VoiceChat and C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices() or {}
    
    -- Try to get user's configured voice
    local settings = self:GetSettings()
    local voiceID = settings.voiceID or 0
    
    -- Find voice object matching voiceID
    if voiceID > 0 then
        for _, v in ipairs(voices) do
            if v.voiceID == voiceID then
                voice = v
                break
            end
        end
    end
    
    -- Fallback: try user's TTS settings voice
    if not voice and C_TTSSettings and C_TTSSettings.GetVoiceOptionID then
        local ok, userVoiceID = pcall(C_TTSSettings.GetVoiceOptionID, 0)
        if ok and userVoiceID then
            for _, v in ipairs(voices) do
                if v.voiceID == userVoiceID then
                    voice = v
                    break
                end
            end
        end
    end
    
    -- Final fallback: first available voice
    if not voice and voices[1] then
        voice = voices[1]
    end
    
    if not voice then
        return false, "No TTS voices available"
    end
    
    -- Use Blizzard's TextToSpeech_Speak (the same function chat TTS uses)
    if TextToSpeech_Speak then
        TextToSpeech_Speak(cleanedText, voice)
        state.isSpeaking = true
        return true
    end
    
    return false, "TextToSpeech_Speak not available"
end

-- Speak a short UI announcement (for accessibility)
-- This doesn't track speaking state as it's meant for brief announcements
function TTS:SpeakUI(text)
    if not text or text == "" then
        return false
    end
    
    -- Clean text for TTS
    local cleanedText = cleanTextForTTS(text)
    if cleanedText == "" then
        return false
    end
    
    -- Get voice object
    local voice = nil
    local voices = C_VoiceChat and C_VoiceChat.GetTtsVoices and C_VoiceChat.GetTtsVoices() or {}
    
    -- Try to get user's configured voice
    local settings = self:GetSettings()
    local voiceID = settings.voiceID or 0
    
    if voiceID > 0 then
        for _, v in ipairs(voices) do
            if v.voiceID == voiceID then
                voice = v
                break
            end
        end
    end
    
    -- Fallback: try user's TTS settings voice
    if not voice and C_TTSSettings and C_TTSSettings.GetVoiceOptionID then
        local ok, userVoiceID = pcall(C_TTSSettings.GetVoiceOptionID, 0)
        if ok and userVoiceID then
            for _, v in ipairs(voices) do
                if v.voiceID == userVoiceID then
                    voice = v
                    break
                end
            end
        end
    end
    
    -- Final fallback: first available voice
    if not voice and voices[1] then
        voice = voices[1]
    end
    
    if not voice then
        return false
    end
    
    -- Use Blizzard's TextToSpeech_Speak
    if TextToSpeech_Speak then
        TextToSpeech_Speak(cleanedText, voice)
        return true
    end
    
    return false
end

-- Toggle speech for the given text (start/stop)
function TTS:Toggle(text)
    if self:IsSpeaking() then
        self:Stop()
        return false -- Stopped
    else
        local success = self:Speak(text)
        return success -- Started (or failed)
    end
end

-- ============================================================================
-- Book-specific functions
-- ============================================================================

-- Get text from a book entry for TTS
function TTS:GetBookText(entry)
    if not entry then
        return nil
    end
    -- Combine all pages into one text
    local pages = entry.pages
    if not pages then
        return nil
    end
    local textParts = {}
    -- Check if pages is keyed by number or has pageOrder
    local pageOrder = entry.pageOrder
    if pageOrder and #pageOrder > 0 then
        for _, pageIdx in ipairs(pageOrder) do
            local pageText = pages[pageIdx]
            if pageText then
                table.insert(textParts, cleanTextForTTS(pageText))
            end
        end
    else
        -- Assume numeric keys
        local maxPage = 0
        for k in pairs(pages) do
            if type(k) == "number" and k > maxPage then
                maxPage = k
            end
        end
        for i = 1, maxPage do
            if pages[i] then
                table.insert(textParts, cleanTextForTTS(pages[i]))
            end
        end
    end
    if #textParts == 0 then
        return nil
    end
    return table.concat(textParts, ". ")
end

-- Speak the current book from UI selection
function TTS:SpeakCurrentBook()
    local Repository = BA and BA.Repository
    if not Repository then
        return false, "Repository not available"
    end
    
    local UI = BA and BA.UI
    if not UI or not UI.Internal or not UI.Internal.getSelectedKey then
        return false, "UI not available"
    end
    
    local selectedBookId = UI.Internal.getSelectedKey()
    if not selectedBookId then
        return false, "No book selected"
    end
    
    local db = Repository:GetDB()
    if not db or not db.booksById then
        return false, "Database not available"
    end
    
    local entry = db.booksById[selectedBookId]
    if not entry then
        return false, "Book not found"
    end
    
    local text = self:GetBookText(entry)
    if not text then
        return false, "Book has no text"
    end
    
    return self:Speak(text)
end

-- Toggle TTS for current book
function TTS:ToggleCurrentBook()
    if self:IsSpeaking() then
        self:Stop()
        return false, nil  -- Stopped, no error
    else
        local success, err = self:SpeakCurrentBook()
        return success, err
    end
end

-- ============================================================================
-- Event handling
-- ============================================================================

-- Register for playback events (called once during init)
function TTS:RegisterEvents(frame)
    if not frame or state.eventsRegistered then
        return
    end
    frame:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_STARTED")
    frame:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED")
    state.eventFrame = frame
    state.eventsRegistered = true
end

-- Handle TTS events
function TTS:OnEvent(event)
    if event == "VOICE_CHAT_TTS_PLAYBACK_STARTED" then
        state.isSpeaking = true
    elseif event == "VOICE_CHAT_TTS_PLAYBACK_FINISHED" then
        state.isSpeaking = false
        -- Notify UI to update button state
        if state.onPlaybackFinished then
            state.onPlaybackFinished()
        end
    end
end

-- Set callback for playback finished
function TTS:SetPlaybackFinishedCallback(callback)
    state.onPlaybackFinished = callback
end

-- ============================================================================
-- Utility functions
-- ============================================================================

-- Get default voice ID (first available voice)
function TTS:GetDefaultVoiceID()
    local voices = self:GetVoices()
    if voices and #voices > 0 and voices[1] then
        return voices[1].voiceID or 0
    end
    return 0
end

-- Get voice name by ID
function TTS:GetVoiceName(voiceID)
    local voices = self:GetVoices()
    for _, voice in ipairs(voices) do
        if voice.voiceID == voiceID then
            return voice.name
        end
    end
    return nil
end
