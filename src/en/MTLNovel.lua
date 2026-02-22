-- {"id":573,"ver":"2.1.1","libVer":"1.0.0","author":"Doomsdayrs","dep":["unhtml>=1.0.0","url>=1.0.0"]}

local baseURL = "https://www.mtlnovels.com"

local function shrinkURL(url)
	return url:gsub("^.-mtlnovels%.com", "")
end

local function expandURL(url)
	return baseURL .. "/" .. url
end

---@type fun(table, string): string
local qs = Require("url").querystring
local HTMLToString = Require("unhtml").HTMLToString

---@type dkjson
local json = Require("dkjson")

---@param v Element | Elements
local function text(v)
	return v:text()
end

---@param element Element
---@return Elements
local function getDetailE(element)
	return element:select("td"):get(2)
end

---@param element Element
---@return string
local function getDetail(element)
	return text(getDetailE(element))
end

local function fixImageURL(link)
    return link
	:gsub("(mtlnovel)%.net", "%1.pics")
	:gsub("(%.%a+)%.webp", "%1")
end

local function search(data)
	local page = data[PAGE]
	if page ~= 0 then -- No pagination
		return {}
	end
	local query = data[QUERY]
	if query ~= nil then
		query = ""
	end
	local m = MediaType("multipart/form-data; boundary=----aWhhdGVrb3RsaW4K")
	local body = RequestBody("------aWhhdGVrb3RsaW4K\r\nContent-Disposition: form-data; name=\"s\"\r\n\r\n" .. data[QUERY] .. "\r\n------aWhhdGVrb3RsaW4K--\r\n", m)
	local doc = RequestDocument(POST(baseURL, nil, body))
	return map(doc:select("div.search-results > div.box"),
			function(v)
				return Novel {
					link = shrinkURL(v:selectFirst("a"):attr("href")),
					title = v:selectFirst(".list-title"):text(),
					imageURL = fixImageURL(v:selectFirst(".list-img"):attr("src"))
				}
			end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
	local url = baseURL .. "/" .. novelURL
	local document = GETDocument(url):selectFirst("article.post")
	local n = NovelInfo()
	n:setTitle(document:selectFirst("h1"):text())
	n:setImageURL(fixImageURL(document:selectFirst("amp-img.main-tmb"):selectFirst("amp-img.main-tmb"):attr("src")))

	document:select("p.descr"):remove()
	local description = HTMLToString(document:select("div.desc p"))
	n:setDescription(description)

	local details = document:selectFirst("table.info"):select("tr")
	local details2 = document:select("table.info"):get(1):select("tr")

	n:setAlternativeTitles({ getDetail(details:get(0)), getDetail(details:get(1)) })

	local sta = getDetailE(details:get(2)):selectFirst("a"):text()
	n:setStatus(NovelStatus(sta == "Completed" and 1 or sta == "Ongoing" and 0 or 3))

	n:setAuthors({ getDetail(details:get(3)) })
	n:setGenres(map(getDetailE(details2:get(0)):select("a"), text))
	n:setTags(map(getDetailE(details2:get(5)):select("a"), text))

	document = GETDocument(url .. "/chapter-list/")

	local chapterBox = document:selectFirst("div.ch-list")
	if chapterBox ~= nil then
		local chapters = chapterBox:select("a.ch-link")
		local count = chapters:size()
		local chaptersList = AsList(map(chapters, function(v)
			local c = NovelChapter()
			c:setTitle(v:text():gsub("<strong>", ""):gsub("</strong>", " "))
			c:setLink(shrinkURL(v:attr("href"):match(baseURL .. "/(.+)/?$")))
			c:setOrder(count)
			count = count - 1
			return c
		end))
		Reverse(chaptersList)
		n:setChapters(chaptersList)
	end
	return n
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
	local htmlElement = GETDocument(baseURL .. "/" .. chapterURL):selectFirst("article.post")
	local title = htmlElement:selectFirst("span.current-crumb"):text()
	htmlElement = htmlElement:selectFirst("div.par")
	-- Chapter title inserted before chapter text
	htmlElement:child(0):before("<h1>" .. title .. "</h1>");

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:select("div.ads"):remove()

	return pageOfElem(htmlElement, true)
end

local function parseItem(item)
	local a = Document(item.novel_permalink):selectFirst("a")
	return Novel {
		imageURL = fixImageURL(item.tmb),
		link = shrinkURL(a:attr("href")),
		title = a:text()
	}
end

local function getLatest(data)
	local response = json.GET(baseURL .. "/wp-admin/admin-ajax.php?action=rcnt_update&moreItemsPageIndex=" .. data[PAGE])
	return map(response.items, parseItem)
end

return {
	id = 573,
	name = "MTLNovel",
	baseURL = baseURL,
	imageURL = "https://shosetsuorg.gitlab.io/extensions/icons/MTLNovel.png",
	hasSearch = true,
	chapterType = ChapterType.HTML,

	shrinkURL = shrinkURL,
	expandURL = expandURL,
	startIndex = 0,

	listings = {
		Listing("Latest", true, getLatest)
	},

	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search
}
