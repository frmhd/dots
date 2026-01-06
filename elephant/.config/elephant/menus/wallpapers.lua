--
-- Wallpaper Picker Menu for Elephant/Walker
--
Name = "wallpapers"
NamePretty = "Wallpapers"

-- The main function elephant will call
function GetEntries()
    local entries = {}
    local walls_dir = os.getenv("HOME") .. "/Pictures/walls"

    -- Find all image files in the walls directory
    local find_cmd = "find -L '" .. walls_dir .. "' -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort"

    local handle = io.popen(find_cmd)
    if not handle then
        return entries
    end

    for image_path in handle:lines() do
        local filename = image_path:match(".*/(.+)$")

        if filename then
            -- Create display name from filename (without extension)
            local display_name = filename:gsub("%.[^.]+$", "")
            display_name = display_name:gsub("_", " "):gsub("%-", " ")

            table.insert(entries, {
                Text = display_name,
                Preview = image_path,
                PreviewType = "file",
                Actions = {
                    activate = "sh -c 'pkill swaybg; swaybg -i \"" .. image_path .. "\" -m fill &'",
                },
            })
        end
    end

    handle:close()
    return entries
end
