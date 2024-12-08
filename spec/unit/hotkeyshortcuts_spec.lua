describe("HotKeys", function()
    local hotkeys, LuaSettings, Dispatcher

    setup(function()
        HotKeys = require("plugins/hotkeys.koplugin/main")
        LuaSettings = require("luasettings")
        Dispatcher = require("dispatcher")
    end)

    before_each(function()
        hotkeys = HotKeys:new()
        hotkeys.settings_data = LuaSettings:open("/tmp/hotkeys_test.lua")
        hotkeys.settings_data.data = {
            hotkeys_fm = {},
            hotkeys_reader = {},
            press_key_does_hotkeys = false,
        }
        hotkeys.hotkeys = hotkeys.settings_data.data.hotkeys_fm
        hotkeys.defaults = {}
    end)

    after_each(function()
        os.remove("/tmp/hotkeys_test.lua")
    end)

    it("should initialize correctly", function()
        hotkeys:init()
        assert.is_not_nil(hotkeys.settings_data)
        assert.is_not_nil(hotkeys.hotkeys)
    end)

    it("should handle hotkey actions", function()
        local hotkey = "modifier_plus_up"
        hotkeys.hotkeys[hotkey] = { "some_action" }
        stub(Dispatcher, "execute")

        local result = hotkeys:onHotkeyAction(hotkey)
        assert.is_true(result)
        assert.stub(Dispatcher.execute).was_called_with({ "some_action" }, { hotkeys = hotkey })
    end)

    it("should register key events", function()
        stub(hotkeys, "overrideConflictingFunctions")
        hotkeys:registerKeyEvents()
        assert.is_table(hotkeys.key_events)
        assert.is_not_nil(hotkeys.key_events["some_key_event"])
        assert.stub(hotkeys.overrideConflictingFunctions).was_called()
    end)

    it("should generate menu items", function()
        local menu_items = {}
        hotkeys:addToMainMenu(menu_items)
        assert.is_not_nil(menu_items.hotkeys)
        assert.is_not_nil(menu_items.hotkeys.sub_item_table)
    end)

    it("should flush settings when updated", function()
        hotkeys.updated = true
        stub(hotkeys.settings_data, "flush")
        hotkeys:onFlushSettings()
        assert.is_false(hotkeys.updated)
        assert.stub(hotkeys.settings_data.flush).was_called()
    end)

    it("should update profiles", function()
        hotkeys.settings_data.data.hotkeys_fm["modifier_plus_up"] = {
            ["old_action"] = true,
            settings = { order = { "old_action" } }
        }
        hotkeys:updateProfiles("old_action", "new_action")
        assert.is_nil(hotkeys.settings_data.data.hotkeys_fm["modifier_plus_up"]["old_action"])
        assert.is_true(hotkeys.settings_data.data.hotkeys_fm["modifier_plus_up"]["new_action"])
    end)
end)
