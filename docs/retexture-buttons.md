You can’t use that PNG directly in WoW. WoW only loads **`.tga`** or **`.blp`** textures from addons.

Below are the two practical ways to use it.

---

## 1) Convert the PNG to a WoW-loadable format

### Option A: convert to TGA (easiest)

* Use GIMP/Photoshop and export as **32-bit TGA** (RGBA, keep alpha).
* Name it something like:
  `Interface/AddOns/BookArchivist/media/gold_buttons.tga`

### Option B: convert to BLP (more “WoW-native”)

* Convert to `.blp` with a BLP converter (many exist).
* Put it in:
  `Interface/AddOns/BookArchivist/media/gold_buttons.blp`

Notes:

* Filenames: no weird characters, keep it simple.
* You do **not** need to list textures in the `.toc`. Being in the folder is enough.

---

## 2) Choose how to reference the texture in Lua

You have a *spritesheet* (multiple button states in one file). You can either:

### Approach A (recommended): **split it into separate files**

Cut the sheet into individual images:

* `gold_button_normal.tga`
* `gold_button_pushed.tga`
* `gold_button_highlight.tga`
* `gold_button_disabled.tga`
* etc.

Then:

```lua
local btn = CreateFrame("Button", nil, parent)
btn:SetSize(160, 28)

btn:SetNormalTexture("Interface\\AddOns\\BookArchivist\\media\\gold_button_normal")
btn:SetPushedTexture("Interface\\AddOns\\BookArchivist\\media\\gold_button_pushed")
btn:SetHighlightTexture("Interface\\AddOns\\BookArchivist\\media\\gold_button_highlight")
btn:SetDisabledTexture("Interface\\AddOns\\BookArchivist\\media\\gold_button_disabled")

btn:SetText("Resume last book")
btn:SetNormalFontObject(GameFontHighlightMedium)
```

Pros: simplest and most robust.
Cons: more files (but still small).

---

### Approach B: keep it as ONE file and use `SetTexCoord` to “crop” regions

WoW can display a sub-rectangle of a texture using normalized UV coords.

```lua
local TEX = "Interface\\AddOns\\BookArchivist\\media\\gold_buttons" -- .tga/.blp
local SHEET_W, SHEET_H = 1536, 864 -- replace with your actual image size

local function texcoord(x, y, w, h)
  local u1 = x / SHEET_W
  local v1 = y / SHEET_H
  local u2 = (x + w) / SHEET_W
  local v2 = (y + h) / SHEET_H
  return u1, u2, v1, v2
end

local function makeStateTexture(btn, layer, x, y, w, h)
  local t = btn:CreateTexture(nil, layer)
  t:SetTexture(TEX)
  t:SetAllPoints(btn)
  t:SetTexCoord(texcoord(x, y, w, h))
  return t
end

local btn = CreateFrame("Button", nil, parent)
btn:SetSize(160, 28)

-- YOU must fill these pixel rectangles from the sheet:
local normal   = makeStateTexture(btn, "BACKGROUND",  0,   0, 512, 96)
local pushed   = makeStateTexture(btn, "BACKGROUND",  0,  96, 512, 96)
local disabled = makeStateTexture(btn, "BACKGROUND",  0, 192, 512, 96)

local highlight = makeStateTexture(btn, "HIGHLIGHT", 512,  0, 512, 96)
highlight:SetBlendMode("ADD")

btn:SetNormalTexture(normal)
btn:SetPushedTexture(pushed)
btn:SetDisabledTexture(disabled)
btn:SetHighlightTexture(highlight)
```

Pros: single file.
Cons: you must measure exact rectangles (x/y/w/h) correctly.

How to get the rectangles:

* Open the image in an editor (GIMP/Photoshop) and read pixel coordinates for each element.
* Use those pixel values in the code above.

---

## Common gotchas

* Use the path **without extension** in `SetTexture`:

  * `"Interface\\AddOns\\BookArchivist\\media\\gold_buttons"` (not `.tga`)
* If it “loads but looks blurry”: you’re scaling a lot. Try to match button size to the source slice.
* If highlight looks wrong: use `highlight:SetBlendMode("ADD")` and keep alpha in the texture.
* If nothing loads: wrong format (still PNG), wrong path, or file not in addon folder.

---

If you tell me the exact pixel size of that sheet and the exact rectangle for “Normal/Highlight/Pushed/Disabled”, I can give you the final `SetTexCoord` numbers for each state so your agent can paste them directly.
