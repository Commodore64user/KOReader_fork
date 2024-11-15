local HotKeyShortcuts = require("plugins/hotkeyshortcuts.koplugin/main")
local LuaSettings = require("luasettings")
local Dispatcher = require("dispatcher")
local Device = require("device")
local UIManager = require("ui/uimanager")

describe("HotKeyShortcuts", function()
    local hotkeyshortcuts

    before_each(function()
        hotkeyshortcuts = HotKeyShortcuts:new()
        hotkeyshortcuts.settings_data = LuaSettings:open("/tmp/hotkeyshortcuts_test.lua")
        hotkeyshortcuts.settings_data.data = {
            hotkeyshortcuts_fm = {},
            hotkeyshortcuts_reader = {},
            press_key_does_hotkeyshortcuts = false,
        }
        hotkeyshortcuts.hotkeyshortcuts = hotkeyshortcuts.settings_data.data.hotkeyshortcuts_fm
        hotkeyshortcuts.defaults = {}
    end)

    after_each(function()
        os.remove("/tmp/hotkeyshortcuts_test.lua")
    end)

    it("should initialize correctly", function()
        hotkeyshortcuts:init()
        assert.is_not_nil(hotkeyshortcuts.settings_data)
        assert.is_not_nil(hotkeyshortcuts.hotkeyshortcuts)
    end)

    it("should handle hotkey actions", function()
        local hotkey = "modifier_plus_up"
        hotkeyshortcuts.hotkeyshortcuts[hotkey] = { "some_action" }
        stub(Dispatcher, "execute")

        local result = hotkeyshortcuts:onHotkeyAction(hotkey)
        assert.is_true(result)
        assert.stub(Dispatcher.execute).was_called_with({ "some_action" }, { hotkeyshortcuts = hotkey })
    end)

    it("should register key events", function()
        stub(hotkeyshortcuts, "overrideConflictingFunctions")
        hotkeyshortcuts:registerKeyEvents()
        assert.is_table(hotkeyshortcuts.key_events)
        assert.is_not_nil(hotkeyshortcuts.key_events["some_key_event"])
        assert.stub(hotkeyshortcuts.overrideConflictingFunctions).was_called()
    end)

    it("should generate menu items", function()
        local menu_items = {}
        hotkeyshortcuts:addToMainMenu(menu_items)
        assert.is_not_nil(menu_items.hotkeyshortcuts)
        assert.is_not_nil(menu_items.hotkeyshortcuts.sub_item_table)
    end)

    it("should flush settings when updated", function()
        hotkeyshortcuts.updated = true
        stub(hotkeyshortcuts.settings_data, "flush")
        hotkeyshortcuts:onFlushSettings()
        assert.is_false(hotkeyshortcuts.updated)
        assert.stub(hotkeyshortcuts.settings_data.flush).was_called()
    end)

    it("should update profiles", function()
        hotkeyshortcuts.settings_data.data.hotkeyshortcuts_fm["modifier_plus_up"] = {
            ["old_action"] = true,
            settings = { order = { "old_action" } }
        }
        hotkeyshortcuts:updateProfiles("old_action", "new_action")
        assert.is_nil(hotkeyshortcuts.settings_data.data.hotkeyshortcuts_fm["modifier_plus_up"]["old_action"])
        assert.is_true(hotkeyshortcuts.settings_data.data.hotkeyshortcuts_fm["modifier_plus_up"]["new_action"])
    end)
end)