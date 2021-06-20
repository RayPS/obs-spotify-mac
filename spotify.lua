-- Name: Spotify Mac 1.1
-- Description: Display Now Playing Track Info
-- Author: Ray (rayps.com)
-- Repo: https://github.com/RayPS/obs-spotify-mac/

obs = obslua

source_name = ""
format_playing = ""
format_paused = ""
interval = 1

function update_text(source)
    local result = spotify()
    local text = "[Spofity not running]"
    if result ~= "" then
        result = split(result, ", ")
        local paused = (result[1] == "paused")
        local format = paused and format_paused or format_playing
        text = format:gsub("{n}", result[2]):gsub("{a}", result[3])
    end

    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", text)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
end

function timer()
    local source = obs.obs_get_source_by_name(source_name) --> obs_source_t
    if source ~= nil then
        local current_scene_source = obs.obs_frontend_get_current_scene() --> obs_source_t
        local current_scene = obs.obs_scene_from_source(current_scene_source) --> obs_scene_t
        local scene_item = obs.obs_scene_find_source_recursive(current_scene, source_name) --> obs_sceneitem_t

        if (scene_item ~= nil) and obs.obs_sceneitem_visible(scene_item) then
            update_text(source)
        end
        obs.obs_source_release(current_scene_source)
    end
    obs.obs_source_release(source)
end

function restart_timer(settings)
    source_name = obs.obs_data_get_string(settings, "source_name")
    format_playing = obs.obs_data_get_string(settings, "format_playing")
    format_paused = obs.obs_data_get_string(settings, "format_paused")
    interval = obs.obs_data_get_int(settings, "interval")

    obs.timer_remove(timer)
    obs.timer_add(timer, interval * 1000)
end

function spotify()
    local cmd = "osascript -e " .. [['
    if application "Spotify" is running then
        tell application "Spotify"
            return {the player state, the name of the current track, the artist of the current track}
        end tell
    else
        error "Spotify not running."
    end if
    ']]
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end

function split(s, delimiter)
    local result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function script_description()
    return [[<HTML><body><center>
        <h2>Spotify Mac</h2>
        <h4>Display Now Playing Track Info</h4>
        <p>{n} = Name &nbsp;&nbsp;&nbsp; {a} = Artist</p>
        <p style="font-size: 11pt;"><i><a href="https://github.com/RayPS/obs-spotify-mac">version 1.1</a></i></p>
    </center></body></HTML>]]
end

function script_properties()
    local props = obs.obs_properties_create()

    local p = obs.obs_properties_add_list(props, "source_name", "Text source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source in ipairs(sources) do
            source_id = obs.obs_source_get_unversioned_id(source)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(p, name, name)
            end
        end
    end
    obs.source_list_release(sources)

    obs.obs_properties_add_int(props, "interval", "Update Interval (s)", 1, 60, 1)
    obs.obs_properties_add_text(props, "format_playing", "Playing Format", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "format_paused", "Paused Format", obs.OBS_TEXT_DEFAULT)
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "format_playing", "Now Playing: {n} - {a}")
    obs.obs_data_set_default_string(settings, "format_paused", "Paused")
    obs.obs_data_set_default_int(settings, "interval", 1)
end


function script_update(settings)
    print("script_update")
    if source_name ~= nil then
        restart_timer(settings)
    else
        print("source_name not set")
    end
end
