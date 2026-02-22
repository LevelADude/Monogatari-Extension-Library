-- {"id":95811,"ver":"1.0.0","libVer":"1.0.0","author":"GPT-5.2-Codex"}

local baseURL = "https://m.fanfiction.net"
local imageURL = "https://www.fanfiction.net/static/icons/favicon.ico"
local USER_AGENT = "Mozilla/5.0 (compatible; Shosetsu/1.0; +https://shosetsu.app)"
local HEADERS = HeadersBuilder():add("User-Agent", USER_AGENT):add("Accept", "text/html,application/xhtml+xml"):add("Accept-Language", "en-US,en;q=0.9"):build()

local function shrinkURL(url)
    return url:gsub("^.-fanfiction%.net", "")
end
local function expandURL(url)
    if url:find("^https?://") then return url end
    return baseURL .. (url:sub(1, 1) == "/" and url or "/" .. url)
end

local function parseNovel(novelURL)
    local url = expandURL(novelURL)
    local doc = RequestDocument(GET(url, HEADERS))
    local titleEl = doc:selectFirst("#content_wrapper_inner b.xcontrast_txt") or doc:selectFirst("b.xcontrast_txt")
    local chapterSelect = doc:selectFirst("#chap_select")
    local chapters = {}

    if chapterSelect then
        chapters = map(chapterSelect:select("option"), function(v)
            local id = url:match("/s/(%d+)")
            local chapterNum = v:attr("value") or "1"
            return NovelChapter {
                title = v:text(),
                link = "/s/" .. id .. "/" .. chapterNum,
                order = tonumber(chapterNum) or 1
            }
        end)
    else
        chapters[1] = NovelChapter { title = "Chapter 1", link = shrinkURL(url), order = 1 }
    end

    local descEl = doc:selectFirst("div.xcontrast_txt") or doc:selectFirst("#content_wrapper_inner")
    local authEl = doc:selectFirst("a[href*='/u/']")

    return NovelInfo {
        title = (titleEl and titleEl:text()) or "Unknown",
        imageURL = imageURL,
        description = descEl and descEl:text() or "",
        authors = { authEl and authEl:text() or "Unknown" },
        chapters = AsList(chapters)
    }
end

local function getPassage(chapterURL)
    local doc = RequestDocument(GET(expandURL(chapterURL), HEADERS))
    local body = doc:selectFirst("#storytext") or doc:selectFirst("#storycontent") or doc:selectFirst("#content_wrapper_inner") or doc
    body:select("script,style,nav,header,footer,ins,.ads,.ad"):remove()
    return pageOfElem(body, true)
end

local function search(data)
    local query = data[QUERY]:gsub(" ", "+")
    local page = data[PAGE] + 1
    local doc = RequestDocument(GET(baseURL .. "/search.php?ready=1&keywords=" .. query .. "&type=story&p=" .. page, HEADERS))
    return map(doc:select("a[href^='/s/']"), function(v)
        if not v:parent() or not v:parent():selectFirst("small") then return nil end
        return Novel { title = v:text(), link = v:attr("href"), imageURL = imageURL }
    end)
end

return {
    id = 95811,
    name = "FanFiction.Net",
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
