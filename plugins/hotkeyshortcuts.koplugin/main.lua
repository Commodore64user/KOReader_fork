local DataStorage = require("datastorage")
local Device = require("device")
local Dispatcher = require("dispatcher")
local Event = require("ui/event")
local FFIUtil = require("ffi/util")
local InputContainer = require("ui/widget/container/inputcontainer")
local LuaSettings = require("luasettings")
local lfs = require("libs/libkoreader-lfs")
local util = require("util")
local T = FFIUtil.template
local _ = require("gettext")

if not (Device:hasScreenKB() or Device:hasSymKey()) then
    return { disabled = true, }
end

local HotKeyShortcuts = InputContainer:extend{
    name = "hotkeyshortcuts",
    settings_data = nil,
    hotkeyshortcuts = nil,--require("device/kindle/event_map_kindle4"),
    defaults = nil,
    updated = false,
}
local hotkeyshortcuts_path = FFIUtil.joinPath(DataStorage:getSettingsDir(), "hotkeyshortcuts.lua")

-- mofifier *here* refers to either screenkb or shift
local hotkeyshortcuts_list = {
    modifier_plus_up                 = Device:hasScreenKB() and _("ScreenKB + Up")      or _("Shift + Up"),
    modifier_plus_down               = Device:hasScreenKB() and _("ScreenKB + Down")    or _("Shift + Down"),
    modifier_plus_left               = Device:hasScreenKB() and _("ScreenKB + Left")    or _("Shift + Left"),
    modifier_plus_right              = Device:hasScreenKB() and _("ScreenKB + Right")   or _("Shift + Right"),
    modifier_plus_left_page_forward  = Device:hasScreenKB() and _("ScreenKB + LPgFwd")  or _("Shift + LPgFwd"),
    modifier_plus_left_page_back     = Device:hasScreenKB() and _("ScreenKB + LPgBack") or _("Shift + LPgBack"),
    modifier_plus_right_page_forward = Device:hasScreenKB() and _("ScreenKB + RPgFwd")  or _("Shift + RPgFwd"),
    modifier_plus_right_page_back    = Device:hasScreenKB() and _("ScreenKB + RPgBack") or _("Shift + RPgBack"),
    modifier_plus_back               = Device:hasScreenKB() and _("ScreenKB + Back")    or _("Shift + Back"),
    modifier_plus_home               = Device:hasScreenKB() and _("ScreenKB + Home")    or _("Shift + Home"),
    modifier_plus_press              = Device:hasScreenKB() and _("ScreenKB + Press")   or _("Shift + Press"),
    -- modifier_plus_menu (screenkb+menu) is already used globally for screenshots (on k4), don't add it here.
}
if Device:hasKeyboard() then
    table.insert(hotkeyshortcuts_list, {
        modifier_plus_menu          = _("Alt + Up"),
        alt_plus_up                 = _("Alt + Up"),
        alt_plus_down               = _("Alt + Down"),
        alt_plus_left               = _("Alt + Left"),
        alt_plus_right              = _("Alt + Right"),
        alt_plus_left_page_forward  = _("Alt + LPgFwd"),
        alt_plus_left_page_back     = _("Alt + LPgBack"),
        alt_plus_right_page_forward = _("Alt + RPgFwd"),
        alt_plus_right_page_back    = _("Alt + RPgBack"),
        alt_plus_back               = _("Alt + Back"),
        alt_plus_home               = _("Alt + Home"),
        alt_plus_press              = _("Alt + Press"),
        alt_plus_menu               = _("Alt + Menu"),
    })
end

function HotKeyShortcuts:init()
    local defaults_path = FFIUtil.joinPath(self.path, "defaults.lua")
    if not lfs.attributes(hotkeyshortcuts_path, "mode") then
        FFIUtil.copyFile(defaults_path, hotkeyshortcuts_path)
    end
    self.is_docless = self.ui == nil or self.ui.document == nil
    self.hotkey_mode = self.is_docless and "hotkeyshortcuts_fm" or "hotkeyshortcuts_reader"
    self.defaults = LuaSettings:open(defaults_path).data[self.hotkey_mode]
    if not self.settings_data then
        self.settings_data = LuaSettings:open(hotkeyshortcuts_path)
    end
    self.hotkeyshortcuts = self.settings_data.data[self.hotkey_mode]

    self.ui.menu:registerToMainMenu(self)
    Dispatcher:init()
    self:registerKeyEvents()
end

--[[
function HotKeyShortcuts:hotkeyshortcutsAction(action, hotkey, mod)
    local action_list = self.hotkeyshortcuts[action]
    if action_list == nil then
        return
    else
        -- self.ui:handleEvent(Event:new("HandledAsSwipe"))
        local exec_props = { hotkeyshortcuts = hotkey.modifiers[mod] }
        Dispatcher:execute(action_list, exec_props)
    end
    return true
end ]]

function HotKeyShortcuts:registerKeyEvents()
    if Device:hasScreenKB() then
        self.key_events.HotKey = { { "ScreenKB", "Up" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "ScreenKB", "Down" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "ScreenKB", "Left" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "ScreenKB", "Right" }, event = self.hotkeyshortcuts[hotkey] }
        if self.hotkey_mode == "hotkeyshortcuts_reader" then
            self.key_events.HotKey = { { "ScreenKB", "LPgFwd" }, event = self.hotkeyshortcuts[hotkey] }
            self.key_events.HotKey = { { "ScreenKB", "LPgBack" }, event = self.hotkeyshortcuts[hotkey] }
            self.key_events.HotKey = { { "ScreenKB", "RPgFwd" }, event = self.hotkeyshortcuts[hotkey] }
            self.key_events.HotKey = { { "ScreenKB", "RPgBack" }, event = self.hotkeyshortcuts[hotkey] }
            self.key_events.HotKey = { { "ScreenKB", "Press" }, event = self.hotkeyshortcuts[hotkey] }
        end
        self.key_events.HotKey = { { "ScreenKB", "Back" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "ScreenKB", "Home" }, event = self.hotkeyshortcuts[hotkey] }
        -- no event for screenkb+menu
    else
        self.key_events.HotKey = { { "Shift", "Up" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Down" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Left" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Right" }, event = self.hotkeyshortcuts[hotkey] }
        if self.hotkey_mode == "hotkeyshortcuts_reader" then
            self.key_events.HotKey = { { "Shift", "LPgFwd" }, event = self.hotkeyshortcuts[hotkey] }
            self.key_events.HotKey = { { "Shift", "LPgBack" }, event = self.hotkeyshortcuts[hotkey] }
            self.key_events.HotKey = { { "Shift", "RPgFwd" }, event = self.hotkeyshortcuts[hotkey] }
            self.key_events.HotKey = { { "Shift", "RPgBack" }, event = self.hotkeyshortcuts[hotkey] }
            self.key_events.HotKey = { { "Shift", "Press" }, event = self.hotkeyshortcuts[hotkey] }
        end
        self.key_events.HotKey = { { "Shift", "Back" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Home" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Menu" }, event = self.hotkeyshortcuts[hotkey] }
    end
    if Device:hasKeyboard() then
        self.key_events.HotKey = { { "Shift", "Up" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Down" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Left" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Right" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "LPgFwd" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "LPgBack" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "RPgFwd" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "RPgBack" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Press" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Back" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Home" }, event = self.hotkeyshortcuts[hotkey] }
        self.key_events.HotKey = { { "Shift", "Menu" }, event = self.hotkeyshortcuts[hotkey] }
    end
end

function HotKeyShortcuts:shortcutTitleFunc(hotkey)
    local title = hotkeyshortcuts_list[hotkey]
    return T(_("%1: (%2)"), title, Dispatcher:menuTextFunc(self.hotkeyshortcuts[hotkey]))
end

function HotKeyShortcuts:genMenu(hotkey)
    local sub_items = {}
    if hotkeyshortcuts_list[hotkey] ~= nil then
        table.insert(sub_items, {
            text = T(_("%1 (default)"), Dispatcher:menuTextFunc(self.defaults[hotkey])),
            keep_menu_open = true,
            separator = true,
            checked_func = function()
                return util.tableEquals(self.hotkeyshortcuts[hotkey], self.defaults[hotkey])
            end,
            callback = function()
                self.hotkeyshortcuts[hotkey] = util.tableDeepCopy(self.defaults[hotkey])
                self.updated = true
            end,
        })
    end
    table.insert(sub_items, {
        text = _("Pass through"),
        keep_menu_open = true,
        checked_func = function()
            return self.hotkeyshortcuts[hotkey] == nil
        end,
        callback = function()
            self.hotkeyshortcuts[hotkey] = nil
            self.updated = true
        end,
    })
    Dispatcher:addSubMenu(self, sub_items, self.hotkeyshortcuts, hotkey)
    sub_items.max_per_page = nil -- restore default, settings in page 2
    table.insert(sub_items, {
        text = _("Always active"),
        checked_func = function()
            return self.hotkeyshortcuts[hotkey] ~= nil
            and self.hotkeyshortcuts[hotkey].settings ~= nil
            and self.hotkeyshortcuts[hotkey].settings.always_active
        end,
        callback = function()
            if self.hotkeyshortcuts[hotkey] then
                if self.hotkeyshortcuts[hotkey].settings then
                    if self.hotkeyshortcuts[hotkey].settings.always_active then
                        self.hotkeyshortcuts[hotkey].settings.always_active = nil
                        if next(self.hotkeyshortcuts[hotkey].settings) == nil then
                            self.hotkeyshortcuts[hotkey].settings = nil
                        end
                    else
                        self.hotkeyshortcuts[hotkey].settings.always_active = true
                    end
                else
                    self.hotkeyshortcuts[hotkey].settings = {["always_active"] = true}
                end
                self.updated = true
            end
        end,
    })
    return sub_items
end

function HotKeyShortcuts:genSubItem(hotkey, separator, hold_callback)
    local reader_only = {
        -- these button combinations are used by FM already, don't allow users to customise them.
        modifier_plus_left_page_forward = true,
        modifier_plus_left_page_back = true,
        modifier_plus_right_page_forward = true,
        modifier_plus_right_page_back = true,
        modifier_plus_press = true,
    }
    local enabled_func
    if reader_only[hotkey] then
       enabled_func = function() return self.hotkey_mode == "hotkeyshortcuts_reader" end
    end
    return {
        text_func = function() return self:shortcutTitleFunc(hotkey) end,
        enabled_func = enabled_func,
        sub_item_table_func = function() return self:genMenu(hotkey) end,
        separator = separator,
        hold_callback = hold_callback,
        ignored_by_menu_search = true, -- This item is not strictly duplicated, but its subitems are.
        --                                Ignoring it speeds up search.
    }
end

function HotKeyShortcuts:genSubItemTable(hotkeyshortcuts)
    local sub_item_table = {}
    for _, item in ipairs(hotkeyshortcuts) do
        table.insert(sub_item_table, self:genSubItem(item))
    end
    return sub_item_table
end

function HotKeyShortcuts:addToMainMenu(menu_items)
    menu_items.hotkeyshortcuts = {
        text = _("Shortcuts"),
        sub_item_table = {
            {
                text = _("Cursor keys"),
                sub_item_table = self:genSubItemTable({
                    "modifier_plus_up",
                    "modifier_plus_down",
                    "modifier_plus_left",
                    "modifier_plus_right"
                }),
            },
            {
                text = _("Page-turn buttons"),
                enabled_func = function() return self.hotkey_mode == "hotkeyshortcuts_reader" end,
                sub_item_table = self:genSubItemTable({
                    "modifier_plus_left_page_forward",
                    "modifier_plus_left_page_back",
                    "modifier_plus_right_page_forward",
                    "modifier_plus_right_page_back"
                }),
            },
            {
                text = _("Function keys"),
                sub_item_table = self:genSubItemTable({
                    "modifier_plus_back",
                    "modifier_plus_home",
                    "modifier_plus_press"
                }),
            },
        },
    }
    if Device:hasKeyboard() then
        table.insert(menu_items.hotkeyshortcuts.sub_item_table, {
            text = _("Alt-cursor keys"),
            sub_item_table = self:genSubItemTable({
                "alt_plus_up",
                "alt_plus_down",
                "alt_plus_left",
                "alt_plus_right"
            }),
        })
        table.insert(menu_items.hotkeyshortcuts.sub_item_table, {
            text = _("Alt-page-turn buttons"),
            sub_item_table = self:genSubItemTable({
                "alt_plus_left_page_forward",
                "alt_plus_left_page_back",
                "alt_plus_right_page_back",
                "alt_plus_right_page_back"
            }),
        })
        table.insert(menu_items.hotkeyshortcuts.sub_item_table, {
            text = _("Alt-function keys"),
            sub_item_table = self:genSubItemTable({
                "modifier_plus_menu",
                "alt_plus_back",
                "alt_plus_home",
                "alt_plus_press",
                "alt_plus_menu"
            }),
        })
    end -- if Device:hasKeyboard
end

function HotKeyShortcuts:onFlushSettings()
    if self.settings_data and self.updated then
        self.settings_data:flush()
        self.updated = false
    end
end

function HotKeyShortcuts:updateProfiles(action_old_name, action_new_name)
    for _, section in ipairs({ "hotkeyshortcuts_fm", "hotkeyshortcuts_reader" }) do
        local hotkeyshortcuts = self.settings_data.data[section]
        for shortcut_name, shortcut in pairs(hotkeyshortcuts) do
            if shortcut[action_old_name] then
                if shortcut.settings and shortcut.settings.order then
                    for i, action in ipairs(shortcut.settings.order) do
                        if action == action_old_name then
                            if action_new_name then
                                shortcut.settings.order[i] = action_new_name
                            else
                                table.remove(shortcut.settings.order, i)
                                if #shortcut.settings.order == 0 then
                                    shortcut.settings.order = nil
                                    if next(shortcut.settings) == nil then
                                        shortcut.settings = nil
                                    end
                                end
                            end
                            break
                        end
                    end
                end
                shortcut[action_old_name] = nil
                if action_new_name then
                    shortcut[action_new_name] = true
                else
                    if next(shortcut) == nil then
                        self.settings_data.data[section][shortcut_name] = nil
                    end
                end
                self.updated = true
            end
        end
    end
end

return HotKeyShortcuts
