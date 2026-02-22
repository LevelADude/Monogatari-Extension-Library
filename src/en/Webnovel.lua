-- {"id":95813,"ver":"1.0.0","libVer":"1.0.0","author":"GPT-5.2-Codex"}

local baseURL = "https://www.webnovel.com"
local imageURL = "https://www.webnovel.com/favicon.ico"

local function shrinkURL(url)
    return url:gsub("^.-webnovel%.com", "")
end

local function expandURL(url)
    return baseURL .. (url:sub(1, 1) == "/" and url or "/" .. url)
end

local function unsupported()
    error("Webnovel requires dynamic JS/auth flows and aggressive anti-bot; public scraping without login is unsupported in this extension.")
end

return {
    id = 95813,
    name = "Webnovel",
    baseURL = baseURL,
    imageURL = imageURL,
    hasSearch = false,
    chapterType = ChapterType.HTML,
    listings = {},
    parseNovel = unsupported,
    getPassage = unsupported,
    search = unsupported,
    shrinkURL = shrinkURL,
    expandURL = expandURL
}
