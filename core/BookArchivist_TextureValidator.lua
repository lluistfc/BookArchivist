---@diagnostic disable: undefined-global
-- BookArchivist_TextureValidator.lua
-- Security validation for texture paths in custom and imported books
-- Prevents malicious texture references from spoofing UI or accessing sensitive resources

local BA = BookArchivist

local TextureValidator = {}
BA.TextureValidator = TextureValidator

-- Maximum allowed path length
local MAX_PATH_LENGTH = 500

-- Whitelisted texture path prefixes (case-insensitive)
local SAFE_PREFIXES = {
	"interface\\icons\\",
	"interface\\pictures\\",
	"interface\\glues\\",
	"worldmap\\",
}

-- Fallback texture for invalid paths
local FALLBACK_TEXTURE = "Interface\\Icons\\INV_Misc_Book_09"

---Normalize slashes to backslashes and convert to lowercase for comparison
---@param path string
---@return string
local function normalizePath(path)
	if not path then return "" end
	-- Replace forward slashes with backslashes
	local normalized = path:gsub("/", "\\")
	-- Convert to lowercase for case-insensitive comparison
	return normalized:lower()
end

---Check if path contains parent directory traversal attempts
---@param path string
---@return boolean
local function hasParentTraversal(path)
	return path:match("%.%.") ~= nil
end

---Check if path is an absolute path
---@param path string
---@return boolean
local function isAbsolutePath(path)
	-- Check for drive letter (C:, D:, etc.)
	if path:match("^[a-zA-Z]:") then
		return true
	end
	-- Check for leading slash or backslash
	if path:match("^[/\\]") then
		return true
	end
	return false
end

---Check if path contains null bytes
---@param path string
---@return boolean
local function hasNullBytes(path)
	return path:match("%z") ~= nil
end

---Check if path starts with any whitelisted prefix
---@param normalizedPath string (already normalized and lowercased)
---@return boolean
local function isWhitelisted(normalizedPath)
	for _, prefix in ipairs(SAFE_PREFIXES) do
		if normalizedPath:sub(1, #prefix) == prefix then
			return true
		end
	end
	return false
end

---Validate a texture path for security issues
---@param path string|nil The texture path to validate
---@return boolean valid True if path is safe to use
---@return string|nil reason Reason for rejection if invalid
function TextureValidator.IsValidTexturePath(path)
	-- Check for nil or empty
	if not path or path == "" then
		return false, "Path is nil or empty"
	end
	
	-- Check for null bytes (security issue)
	if hasNullBytes(path) then
		return false, "Path contains null byte characters"
	end
	
	-- Check length
	if #path > MAX_PATH_LENGTH then
		return false, "Path is too long (max " .. MAX_PATH_LENGTH .. " characters)"
	end
	
	-- Check for trailing slashes (incomplete path)
	if path:match("[/\\]$") then
		return false, "Path has trailing slash"
	end
	
	-- Normalize for security checks
	local normalized = normalizePath(path)
	
	-- Check for parent directory traversal
	if hasParentTraversal(normalized) then
		return false, "Path contains parent directory traversal (..)"
	end
	
	-- Check against whitelist
	if not isWhitelisted(normalized) then
		return false, "Path is not in whitelist of safe directories"
	end
	
	-- Path passed all security checks
	return true, nil
end

---Get the fallback texture path for invalid textures
---@return string
function TextureValidator.GetFallbackTexture()
	return FALLBACK_TEXTURE
end

---Sanitize a texture path, returning it unchanged if valid or fallback if invalid
---@param path string|nil
---@return string sanitized The original path if valid, or fallback texture
function TextureValidator.SanitizeTexturePath(path)
	local valid = TextureValidator.IsValidTexturePath(path)
	if valid then
		return path
	else
		return FALLBACK_TEXTURE
	end
end

return TextureValidator
