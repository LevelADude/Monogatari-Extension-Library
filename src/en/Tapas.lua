-- {"id":95814,"ver":"1.0.0","libVer":"1.0.0","author":"GPT-5.2-Codex"}

local baseURL = "https://tapas.io"
local imageURL = "https://tapas.io/favicon.ico"

local function shrinkURL(url)
    return url:gsub("^.-tapas%.io", "")
end

local function expandURL(url)
    return baseURL .. (url:sub(1, 1) == "/" and url or "/" .. url)
end

local function unsupported()
    error("Tapas novels are heavily JS-driven and often require API auth/cookies; public no-login parsing is currently unsupported.")
end

return {
    id = 95814,
    name = "Tapas",
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
