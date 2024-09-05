local BD = require("ui/bidi")
local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local Device = require("device")
local Dispatcher = require("dispatcher")
local Event = require("ui/event")
local FFIUtil = require("ffi/util")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local InputDialog = require("ui/widget/inputdialog")
local LuaSettings = require("luasettings")
local Screen = require("device").screen
local SpinWidget = require("ui/widget/spinwidget")
local UIManager = require("ui/uimanager")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local util = require("util")
local T = FFIUtil.template
local time = require("ui/time")
local _ = require("gettext")
local C_ = _.pgettext

if not (Device:hasScreenKB() or Device:hasSymKey()) then
    return { disabled = true, }
end

local HotKeyShortcuts = InputContainer:extend{
    name = "hotkeyshortcuts",
    settings_data = nil,
    hotkeyshortcuts = require("device/kindle/event_map_kindle4"),
    defaults = nil,
    updated = false,
}
local hotkeyshortcuts_path = FFIUtil.joinPath(DataStorage:getSettingsDir(), "hotkeyshortcuts.lua")

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
    -- mod+Menu is already used globally for screenshots (on k4), don't add it here.
}
if not Device:hasKeyboard() then
    table.insert(hotkeyshortcuts_list, {
        modifier_plus_menu          = _("Shift + Menu"),
        -- alt
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
        alt_plus_menu               = _("Alt + Menu")
    })
end

function HotKeyShortcuts:init()
    local defaults_path = FFIUtil.joinPath(self.path, "defaults.lua")
    if not lfs.attributes(hotkeyshortcuts_path, "mode") then
        FFIUtil.copyFile(defaults_path, hotkeyshortcuts_path)
    end
    self.is_docless = self.ui == nil or self.ui.document == nil
    self.key_mode = self.is_docless and "hotkeyshortcuts_fm" or "hotkeyshortcuts_reader"
    self.defaults = LuaSettings:open(defaults_path).data[self.key_mode]
    if not self.settings_data then
        self.settings_data = LuaSettings:open(hotkeyshortcuts_path)
    end
    self.hotkeyshortcuts = self.settings_data.data[self.key_mode]

    self.ui.menu:registerToMainMenu(self)
    Dispatcher:init()
    self:registerKeyEvents()
end

function HotKeyShortcuts:hotkeyshortcutsAction(action, key, mod)
    local action_list = self.hotkeyshortcuts[action]
    if action_list == nil then
        return
    else
        -- self.ui:handleEvent(Event:new("HandledAsSwipe"))
        local exec_props = { hotkeyshortcuts = key.modifiers[mod] }
        Dispatcher:execute(action_list, exec_props)
    end
    return true
end

function HotKeyShortcuts:registerKeyEvents()
    if Device:hasScreenKB() then
        self.key_events.ModPlusUp = { { "ScreenKB", "Up" } }
        self.key_events.ModPlusDown = { { "ScreenKB", "Down" } }
        self.key_events.ModPlusLeft = { { "ScreenKB", "Left" } }
        self.key_events.ModPlusRight = { { "ScreenKB", "Right" } }
    else
        self.key_events.ModPlusUp = { { "Shift", "Up" } }
        self.key_events.ModPlusDown = { { "Shift", "Down" } }
        self.key_events.ModPlusLeft = { { "Shift", "Left" } }
        self.key_events.ModPlusRight = { { "Shift", "Right" } }
    end
end

function HotKeyShortcuts:shortcutTitleFunc(key)
    local title = hotkeyshortcuts_list[key]
    return T(_("%1: (%2)"), title, Dispatcher:menuTextFunc(self.hotkeyshortcuts[key]))
end

function HotKeyShortcuts:genMenu(key)
    local sub_items = {}
    if hotkeyshortcuts_list[key] ~= nil then
        table.insert(sub_items, {
            text = T(_("%1 (default)"), Dispatcher:menuTextFunc(self.defaults[key])),
            keep_menu_open = true,
            separator = true,
            checked_func = function()
                return util.tableEquals(self.hotkeyshortcuts[key], self.defaults[key])
            end,
            callback = function()
                self.hotkeyshortcuts[key] = util.tableDeepCopy(self.defaults[key])
                self.updated = true
            end,
        })
    end
    table.insert(sub_items, {
        text = _("Pass through"),
        keep_menu_open = true,
        checked_func = function()
            return self.hotkeyshortcuts[key] == nil
        end,
        callback = function()
            self.hotkeyshortcuts[key] = nil
            self.updated = true
        end,
    })
    Dispatcher:addSubMenu(self, sub_items, self.hotkeyshortcuts, key)
    sub_items.max_per_page = nil -- restore default, settings in page 2
    table.insert(sub_items, {
        text = _("Always active"),
        checked_func = function()
            return self.hotkeyshortcuts[key] ~= nil
            and self.hotkeyshortcuts[key].settings ~= nil
            and self.hotkeyshortcuts[key].settings.always_active
        end,
        callback = function()
            if self.hotkeyshortcuts[key] then
                if self.hotkeyshortcuts[key].settings then
                    if self.hotkeyshortcuts[key].settings.always_active then
                        self.hotkeyshortcuts[key].settings.always_active = nil
                        if next(self.hotkeyshortcuts[key].settings) == nil then
                            self.hotkeyshortcuts[key].settings = nil
                        end
                    else
                        self.hotkeyshortcuts[key].settings.always_active = true
                    end
                else
                    self.hotkeyshortcuts[key].settings = {["always_active"] = true}
                end
                self.updated = true
            end
        end,
    })
    return sub_items
end

function HotKeyShortcuts:genSubItem(key, separator, hold_callback)
    local reader_only = {
        -- these button combinations are used by FM already, don't allow users to customise them.
        modifier_plus_left_page_forward = true,
        modifier_plus_left_page_back = true,
        modifier_plus_right_page_forward = true,
        modifier_plus_right_page_back = true,
        modifier_plus_press = true,
    }
    local enabled_func
    if reader_only[key] then
       enabled_func = function() return self.key_mode == "hotkeyshortcuts_reader" end
    end
    return {
        text_func = function() return self:shortcutTitleFunc(key) end,
        enabled_func = enabled_func,
        sub_item_table_func = function() return self:genMenu(key) end,
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
                enabled_func = function() return self.key_mode == "hotkeyshortcuts_reader" end,
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
    if not Device:hasKeyboard() then
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
