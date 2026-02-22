-- {"id":95812,"ver":"1.0.0","libVer":"1.0.0","author":"GPT-5.2-Codex"}

local baseURL = "https://m.fictionpress.com"
local imageURL = "https://www.fictionpress.com/static/icons/favicon.ico"
local USER_AGENT = "Mozilla/5.0 (compatible; Shosetsu/1.0; +https://shosetsu.app)"
local HEADERS = HeadersBuilder():add("User-Agent", USER_AGENT):add("Accept", "text/html,application/xhtml+xml"):add("Accept-Language", "en-US,en;q=0.9"):build()

local function shrinkURL(url) return url:gsub("^.-fictionpress%.com", "") end
local function expandURL(url)
    if url:find("^https?://") then return url end
    return baseURL .. (url:sub(1, 1) == "/" and url or "/" .. url)
end

local function parseNovel(novelURL)
    local url = expandURL(novelURL)
    local doc = RequestDocument(GET(url, HEADERS))
    local chapterSelect = doc:selectFirst("#chap_select")
    local sid = url:match("/s/(%d+)")
    local chapters = {}
    if chapterSelect then
        chapters = map(chapterSelect:select("option"), function(v)
            local ch = v:attr("value") or "1"
            return NovelChapter { title = v:text(), link = "/s/" .. sid .. "/" .. ch, order = tonumber(ch) or 1 }
        end)
    else
        chapters[1] = NovelChapter { title = "Chapter 1", link = shrinkURL(url), order = 1 }
    end

    local titleEl = doc:selectFirst("b.xcontrast_txt")
    local descEl = doc:selectFirst("div.xcontrast_txt")
    local authEl = doc:selectFirst("a[href*='/u/']")

    return NovelInfo {
        title = titleEl and titleEl:text() or "Unknown",
        imageURL = imageURL,
        description = descEl and descEl:text() or "",
        authors = { authEl and authEl:text() or "Unknown" },
        chapters = AsList(chapters)
    }
end

local function getPassage(chapterURL)
    local doc = RequestDocument(GET(expandURL(chapterURL), HEADERS))
    local body = doc:selectFirst("#storytext") or doc:selectFirst("#content_wrapper_inner")
    body:select("script,style,nav,header,footer,ins,.ads,.ad"):remove()
    return pageOfElem(body, true)
end

local function search(data)
    local query = data[QUERY]:gsub(" ", "+")
    local page = data[PAGE] + 1
    local url = baseURL .. "/search.php?ready=1&keywords=" .. query .. "&type=story&p=" .. page
    local doc = RequestDocument(GET(url, HEADERS))
    return map(doc:select("a[href^='/s/']"), function(v)
        return Novel { title = v:text(), link = v:attr("href"), imageURL = imageURL }
    end)
end

return {
    id = 95812,
    name = "FictionPress",
    baseURL = baseURL,
    imageURL = imageURL,
    hasSearch = true,
    chapterType = ChapterType.HTML,
    parseNovel = parseNovel,
    getPassage = getPassage,
    search = search,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    listings = {}
}
