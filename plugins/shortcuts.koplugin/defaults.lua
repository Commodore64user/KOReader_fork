local Device = require("device")

return {
    button_fm = {
        modifier_plus_up = nil,
        modifier_plus_down = nil,
        modifier_plus_left = nil,
        modifier_plus_right = nil,
    },
    button_reader = {
        modifier_plus_up = nil,
        modifier_plus_down = nil,
        modifier_plus_left = {bookmarks = true,},
        modifier_plus_right = {toggle_bookmark = true,},
    },
}
