# Copilot Instructions for Writing World of Warcraft Addons in Lua

## Purpose

These instructions are intended to help GitHub Copilot provide accurate, idiomatic, and up-to-date code suggestions for creating World of Warcraft (WoW) addons using Lua.

---

## 1. Code Style

- **Use 2 spaces for indentation**.
- Prefer local variables and functions whenever possible.
- Avoid global variables unless exposing an API.
- Use snake_case for variable and function names.
- Always comment major blocks, especially for WoW API calls and event handlers.
- Use double dash (`--`) for single line comments and `--[[ ... ]]` for multi-line comments.

---

## 2. Addon Structure

**Minimal Addon Directory Example:**
```
MyAddon/
  MyAddon.toc
  MyAddon.lua
  MyAddon.xml (optional)
```

**Example `.toc` File:**
```plaintext
## Interface: 100107
## Title: MyAddon
## Notes: A simple WoW addon example
## SavedVariables: MyAddonDB
MyAddon.lua
```

---

## 3. Lua File Conventions

- Wrap addon code in a single table to avoid polluting the global namespace.
- Use WoW’s event system to initialize your addon.

**Basic Lua File Example:**
```lua
local MyAddon = {}

-- Frame for event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "MyAddon" then
    print("MyAddon loaded!")
    -- Initialization code here
  end
end)
```

---

## 4. Event Handling

- Use `CreateFrame` to register and handle events.
- Always check the event and addon name in the handler.

**Example:**
```lua
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    -- Your code here
  end
end)
```

---

## 5. Saved Variables

- Define saved variables in the `.toc` file (`## SavedVariables: MyAddonDB`).
- Always check for existence before using.

**Example:**
```lua
if not MyAddonDB then
  MyAddonDB = {}
end
MyAddonDB.someSetting = true
```

---

## 6. UI Elements (Optional)

- Use XML for complex UI or `CreateFrame` in Lua for simple UIs.
- Always parent UI elements to the UIParent frame.

**Example:**
```lua
local btn = CreateFrame("Button", "MyAddonButton", UIParent, "UIPanelButtonTemplate")
btn:SetSize(80, 22)
btn:SetText("Click Me")
btn:SetPoint("CENTER")
btn:SetScript("OnClick", function()
  print("Button clicked!")
end)
```

---

## 7. WoW API Usage

- Use official [WoW API documentation](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API) for reference.
- Prefer using Blizzard’s provided API functions.
- Avoid deprecated or protected functions.

---

## 8. Best Practices

- Clean up event registrations and UI elements on logout or reload.
- Use descriptive variable and function names.
- Encapsulate logic in functions for readability and reuse.
- Document addon commands and features for users.

---

## 9. Example: Hello World Addon

**MyAddon.toc**
```plaintext
## Interface: 100107
## Title: HelloWorld
HelloWorld.lua
```

**HelloWorld.lua**
```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
  print("Hello, World!")
end)
```

---

## 10. Resources

- [WoW API on Wowpedia](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [Lua Reference Manual](https://www.lua.org/manual/5.1/)
- [WoWInterface Forums](https://www.wowinterface.com/forums/)
- [CurseForge Addon Development](https://authors.curseforge.com/)

---

**Copilot should suggest code compatible with the latest supported WoW API version and always prefer idiomatic, safe, and maintainable Lua code for WoW addons.**