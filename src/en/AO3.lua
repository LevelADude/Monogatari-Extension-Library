-- {"id":95810,"ver":"1.0.0","libVer":"1.0.0","author":"GPT-5.2-Codex"}

local baseURL = "https://archiveofourown.org"
local imageURL = "https://archiveofourown.org/favicon.ico"
local USER_AGENT = "Mozilla/5.0 (compatible; Shosetsu/1.0; +https://shosetsu.app)"
local HEADERS = HeadersBuilder()
    :add("User-Agent", USER_AGENT)
    :add("Accept", "text/html,application/xhtml+xml")
    :add("Accept-Language", "en-US,en;q=0.9")
    :build()

local function shrinkURL(url)
    return url:gsub("^.-archiveofourown%.org", "")
end

local function expandURL(url)
    return baseURL .. (url:sub(1, 1) == "/" and url or "/" .. url)
end

local function cleanChapterBody(doc)
    doc:select("script,style,nav,header,footer,.landmark,.actions,.preface,.notes,module"):remove()
    local body = doc:selectFirst("#chapters") or doc:selectFirst(".userstuff")
    return pageOfElem(body or doc, true)
end

local function parseNovel(novelURL)
    local doc = RequestDocument(GET(expandURL(novelURL), HEADERS))
    local title = (doc:selectFirst("h2.title") or doc:selectFirst("h2.heading")):text()
    local authorNodes = doc:select("a[rel='author']")
    local chapters = {}
    local chapterNodes = doc:select("#main ol.chapter.index li a")

    if chapterNodes:size() == 0 then
        chapters[1] = NovelChapter { title = "Chapter 1", link = novelURL, order = 1 }
    else
        chapters = map(chapterNodes, function(v)
            return NovelChapter {
                title = v:text(),
                link = v:attr("href"),
                order = v
            }
        end)
    end

    return NovelInfo {
        title = title,
        imageURL = imageURL,
        description = (doc:selectFirst("blockquote.userstuff.summary") or doc:selectFirst(".summary .userstuff") or doc:selectFirst("blockquote.userstuff")):text(),
        authors = map(authorNodes, function(v) return v:text() end),
        genres = map(doc:select("dd.fandom.tags a"), function(v) return v:text() end),
        status = doc:selectFirst("dd.chapters") and NovelStatus.PUBLISHING or NovelStatus.UNKNOWN,
        chapters = AsList(chapters)
    }
end

local function getPassage(chapterURL)
    local doc = RequestDocument(GET(expandURL(chapterURL), HEADERS))
    return cleanChapterBody(doc)
end

local function search(data)
    local q = data[QUERY]
    local page = data[PAGE] + 1
    local url = baseURL .. "/works/search?work_search%5Bquery%5D=" .. q:gsub(" ", "+") .. "&page=" .. page
    local doc = RequestDocument(GET(url, HEADERS))
    return map(doc:select("ol.work.index.group li.work h4.heading a[href*='/works/']"), function(v)
        return Novel {
            title = v:text():gsub("^%s+", ""):gsub("%s+$", ""),
            link = v:attr("href"),
            imageURL = imageURL
        }
    end)
end

return {
    id = 95810,
    name = "Archive of Our Own",
    baseURL = baseURL,
    imageURL = imageURL,
    chapterType = ChapterType.HTML,
    hasSearch = true,
    listings = {},
    parseNovel = parseNovel,
    getPassage = getPassage,
    search = search,
    shrinkURL = shrinkURL,
    expandURL = expandURL
}
