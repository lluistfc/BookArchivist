-- TTS (Text-to-Speech) tests
-- Tests the Text-to-Speech functionality

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Load Repository for database access
helper.loadFile("core/BookArchivist_Repository.lua")

-- Load TTS module
helper.loadFile("core/BookArchivist_TTS.lua")

describe("TTS", function()
    local TTS
    local testDB
    local originalDB
    
    before_each(function()
        -- Backup original
        originalDB = BookArchivistDB
        
        -- Create test database
        testDB = {
            dbVersion = 3,
            booksById = {},
            order = {},
            indexes = {
                objectToBookId = {},
                itemToBookIds = {},
                titleToBookIds = {},
            },
            options = {},
        }
        
        _G.BookArchivistDB = testDB
        
        -- Initialize Repository
        BookArchivist.Repository:Init(testDB)
        
        -- Get reference to TTS module
        TTS = BookArchivist.TTS
        
        -- Reset TTS module state
        TTS.__state = {}
        
        -- Mock WoW APIs
        _G.C_VoiceChat = _G.C_VoiceChat or {}
        
        -- Mock TextToSpeech_Speak (Blizzard's internal function)
        _G.TextToSpeech_Speak = nil
    end)
    
    after_each(function()
        -- Restore
        _G.BookArchivistDB = originalDB
        BookArchivist.Repository:Init(originalDB or {})
    end)
    
    describe("IsSupported", function()
        it("should return false when C_VoiceChat.SpeakText is missing", function()
            _G.C_VoiceChat.SpeakText = nil
            _G.C_VoiceChat.StopSpeakingText = function() end
            
            local supported = TTS:IsSupported()
            assert.is_false(supported)
        end)
        
        it("should return false when C_VoiceChat.StopSpeakingText is missing", function()
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = nil
            
            local supported = TTS:IsSupported()
            assert.is_false(supported)
        end)
        
        it("should return true when both APIs are available", function()
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            
            local supported = TTS:IsSupported()
            assert.is_true(supported)
        end)
    end)
    
    describe("GetVoices", function()
        it("should return empty table when API not available", function()
            _G.C_VoiceChat.GetTtsVoices = nil
            
            local voices = TTS:GetVoices()
            assert.are.same({}, voices)
        end)
        
        it("should return voices from API", function()
            local mockVoices = {
                { voiceID = 1, name = "Voice 1" },
                { voiceID = 2, name = "Voice 2" },
            }
            _G.C_VoiceChat.GetTtsVoices = function() return mockVoices end
            
            local voices = TTS:GetVoices()
            assert.are.same(mockVoices, voices)
        end)
    end)
    
    describe("GetSettings", function()
        it("should return defaults when no settings stored", function()
            local settings = TTS:GetSettings()
            assert.are.equal(0, settings.voiceID)
            assert.are.equal(0, settings.speed)
            assert.are.equal(50, settings.volume)
        end)
        
        it("should return stored settings", function()
            testDB.options.tts = {
                voiceID = 5,
                speed = 3,
                volume = 75,
            }
            
            local settings = TTS:GetSettings()
            assert.are.equal(5, settings.voiceID)
            assert.are.equal(3, settings.speed)
            assert.are.equal(75, settings.volume)
        end)
    end)
    
    describe("SetSettings", function()
        it("should store settings in database", function()
            TTS:SetSettings({ voiceID = 10, speed = -5, volume = 80 })
            
            assert.are.equal(10, testDB.options.tts.voiceID)
            assert.are.equal(-5, testDB.options.tts.speed)
            assert.are.equal(80, testDB.options.tts.volume)
        end)
        
        it("should create options.tts if not present", function()
            testDB.options = nil
            
            TTS:SetSettings({ voiceID = 1 })
            
            assert.is_not_nil(testDB.options)
            assert.is_not_nil(testDB.options.tts)
            assert.are.equal(1, testDB.options.tts.voiceID)
        end)
        
        it("should only update provided settings", function()
            testDB.options.tts = {
                voiceID = 5,
                speed = 3,
                volume = 75,
            }
            
            TTS:SetSettings({ speed = 0 })
            
            assert.are.equal(5, testDB.options.tts.voiceID)  -- unchanged
            assert.are.equal(0, testDB.options.tts.speed)    -- updated
            assert.are.equal(75, testDB.options.tts.volume)  -- unchanged
        end)
    end)
    
    describe("IsSpeaking", function()
        it("should return false initially", function()
            TTS.__state.isSpeaking = nil
            assert.is_false(TTS:IsSpeaking())
        end)
        
        it("should return true after calling speak", function()
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            _G.C_VoiceChat.GetTtsVoices = function()
                return {{ voiceID = 1, name = "Test Voice" }}
            end
            _G.TextToSpeech_Speak = function() end
            
            TTS:Speak("Hello world")
            assert.is_true(TTS:IsSpeaking())
        end)
    end)
    
    describe("Stop", function()
        it("should call StopSpeakingText API", function()
            local stopCalled = false
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() stopCalled = true end
            
            TTS.__state.isSpeaking = true
            TTS:Stop()
            
            assert.is_true(stopCalled)
            assert.is_false(TTS:IsSpeaking())
        end)
    end)
    
    describe("Speak", function()
        it("should return error when TextToSpeech_Speak not available", function()
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            _G.C_VoiceChat.GetTtsVoices = function()
                return {{ voiceID = 1, name = "Test Voice" }}
            end
            _G.TextToSpeech_Speak = nil
            
            local success, err = TTS:Speak("Test text")
            assert.is_false(success)
            assert.are.equal("TextToSpeech_Speak not available", err)
        end)
        
        it("should return error for empty text", function()
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            _G.TextToSpeech_Speak = function() end
            
            local success, err = TTS:Speak("")
            assert.is_false(success)
            assert.are.equal("No text to speak", err)
        end)
        
        it("should call TextToSpeech_Speak with correct parameters", function()
            local capturedText = nil
            local capturedVoice = nil
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            _G.C_VoiceChat.GetTtsVoices = function()
                return {{ voiceID = 5, name = "Test Voice" }}
            end
            _G.TextToSpeech_Speak = function(text, voice)
                capturedText = text
                capturedVoice = voice
            end
            
            -- Set custom settings
            testDB.options.tts = {
                voiceID = 5,
                speed = 2,
                volume = 80,
            }
            
            local success = TTS:Speak("Hello world")
            
            assert.is_true(success)
            assert.are.equal("Hello world", capturedText)
            assert.is_not_nil(capturedVoice)
            assert.are.equal(5, capturedVoice.voiceID)
        end)
        
        it("should clean color codes from text", function()
            local capturedText = nil
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            _G.C_VoiceChat.GetTtsVoices = function()
                return {{ voiceID = 1, name = "Test Voice" }}
            end
            _G.TextToSpeech_Speak = function(text, voice)
                capturedText = text
            end
            
            TTS:Speak("|cFF00FF00Green|r and |cFFFF0000Red|r text")
            
            assert.are.equal("Green and Red text", capturedText)
        end)
        
        it("should clean HTML tags from text", function()
            local capturedText = nil
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            _G.C_VoiceChat.GetTtsVoices = function()
                return {{ voiceID = 1, name = "Test Voice" }}
            end
            _G.TextToSpeech_Speak = function(text, voice)
                capturedText = text
            end
            
            TTS:Speak("<p>Paragraph text</p><br/>More text")
            
            -- HTML tags are removed but no space is added between them
            assert.are.equal("Paragraph textMore text", capturedText)
        end)
    end)
    
    describe("GetBookText", function()
        it("should return nil for nil entry", function()
            local text = TTS:GetBookText(nil)
            assert.is_nil(text)
        end)
        
        it("should return nil for entry without pages", function()
            local entry = { title = "Test" }
            local text = TTS:GetBookText(entry)
            assert.is_nil(text)
        end)
        
        it("should combine pages into single text", function()
            local entry = {
                pages = {
                    [1] = "Page one content.",
                    [2] = "Page two content.",
                },
            }
            local text = TTS:GetBookText(entry)
            assert.are.equal("Page one content.. Page two content.", text)
        end)
        
        it("should use pageOrder if available", function()
            local entry = {
                pages = {
                    [1] = "First page.",
                    [2] = "Second page.",
                    [3] = "Third page.",
                },
                pageOrder = { 3, 1, 2 },  -- Read in different order
            }
            local text = TTS:GetBookText(entry)
            assert.are.equal("Third page.. First page.. Second page.", text)
        end)
        
        it("should clean formatting from pages", function()
            local entry = {
                pages = {
                    [1] = "|cFF00FF00Colored|r text",
                },
            }
            local text = TTS:GetBookText(entry)
            assert.are.equal("Colored text", text)
        end)
    end)
    
    describe("Toggle", function()
        it("should stop when already speaking", function()
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            _G.C_VoiceChat.GetTtsVoices = function()
                return {{ voiceID = 1, name = "Test Voice" }}
            end
            _G.TextToSpeech_Speak = function() end
            
            TTS.__state.isSpeaking = true
            
            local result = TTS:Toggle("Some text")
            
            assert.is_false(result)  -- Stopped
            assert.is_false(TTS:IsSpeaking())
        end)
        
        it("should start when not speaking", function()
            _G.C_VoiceChat.SpeakText = function() end
            _G.C_VoiceChat.StopSpeakingText = function() end
            _G.C_VoiceChat.GetTtsVoices = function()
                return {{ voiceID = 1, name = "Test Voice" }}
            end
            _G.TextToSpeech_Speak = function() end
            
            TTS.__state.isSpeaking = false
            
            local result = TTS:Toggle("Some text")
            
            assert.is_true(result)  -- Started
            assert.is_true(TTS:IsSpeaking())
        end)
    end)
    
    describe("GetDefaultVoiceID", function()
        it("should return 0 when no voices available", function()
            _G.C_VoiceChat.GetTtsVoices = function() return {} end
            
            local voiceID = TTS:GetDefaultVoiceID()
            assert.are.equal(0, voiceID)
        end)
        
        it("should return first voice ID when voices available", function()
            _G.C_VoiceChat.GetTtsVoices = function()
                return {
                    { voiceID = 5, name = "Voice A" },
                    { voiceID = 10, name = "Voice B" },
                }
            end
            
            local voiceID = TTS:GetDefaultVoiceID()
            assert.are.equal(5, voiceID)
        end)
    end)
    
    describe("GetVoiceName", function()
        it("should return nil for unknown voice ID", function()
            _G.C_VoiceChat.GetTtsVoices = function()
                return {
                    { voiceID = 1, name = "Voice A" },
                }
            end
            
            local name = TTS:GetVoiceName(999)
            assert.is_nil(name)
        end)
        
        it("should return voice name for known voice ID", function()
            _G.C_VoiceChat.GetTtsVoices = function()
                return {
                    { voiceID = 1, name = "Voice A" },
                    { voiceID = 2, name = "Voice B" },
                }
            end
            
            local name = TTS:GetVoiceName(2)
            assert.are.equal("Voice B", name)
        end)
    end)
end)
