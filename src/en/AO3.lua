-- {"id":95810,"ver":"1.1.0","libVer":"1.0.0","author":"Monogatari"}

local baseURL = "https://archiveofourown.org"
local imageURL = "https://raw.githubusercontent.com/LevelADude/Monogatari-Extension-Library/main/icons/AO3.png"

local function shrinkURL(url)
	return url:gsub("^.-archiveofourown%.org", "")
end

local function expandURL(url)
	if url:find("^https?://") then
		return url
	end
	return baseURL .. (url:sub(1, 1) == "/" and url or "/" .. url)
end

--- AO3 hides adult works behind an interstitial unless view_adult is passed.
local function viewAdult(url)
	return url .. (url:find("%?") and "&" or "?") .. "view_adult=true"
end

local function workID(url)
	return url:match("/works/(%d+)")
end

local function encode(str)
	return str:gsub("[^%w%-%._~ ]", function(c)
		return string.format("%%%02X", c:byte())
	end):gsub(" ", "+")
end

--- Parses work blurbs from search/listing result pages.
local function parseBlurbs(doc)
	return map(doc:select("ol.work.index.group > li.work h4.heading > a[href*='/works/']"), function(v)
		return Novel {
			title = v:text(),
			link = shrinkURL(v:attr("href")),
			imageURL = imageURL
		}
	end)
end

local function parseNovel(novelURL, loadChapters)
	local id = workID(novelURL)
	if id == nil then
		error("Invalid AO3 work URL: " .. novelURL)
	end
	local doc = GETDocument(viewAdult(baseURL .. "/works/" .. id))

	local title = doc:selectFirst("h2.title.heading")
	local summary = doc:selectFirst("div.summary.module blockquote.userstuff")

	local status = NovelStatus.UNKNOWN
	local chaptersStat = doc:selectFirst("dl.stats dd.chapters")
	if chaptersStat ~= nil then
		local done, total = chaptersStat:text():match("(%d+)%s*/%s*(%d+)")
		if done ~= nil and done == total then
			status = NovelStatus.COMPLETED
		else
			status = NovelStatus.PUBLISHING
		end
	end

	local info = NovelInfo {
		title = title ~= nil and title:text() or ("Work " .. id),
		imageURL = imageURL,
		description = summary ~= nil and summary:text() or "",
		authors = map(doc:select("h3.byline.heading a[rel='author']"), function(v)
			return v:text()
		end),
		genres = map(doc:select("dd.fandom.tags a.tag"), function(v)
			return v:text()
		end),
		status = status
	}

	if loadChapters then
		local nav = GETDocument(baseURL .. "/works/" .. id .. "/navigate")
		local items = nav:select("ol.chapter.index.group li > a")
		local chapters = {}
		for i = 0, items:size() - 1 do
			local v = items:get(i)
			chapters[i + 1] = NovelChapter {
				title = v:text(),
				link = shrinkURL(v:attr("href")),
				order = i + 1
			}
		end
		info:setChapters(AsList(chapters))
	end

	return info
end

local function getPassage(chapterURL)
	local doc = GETDocument(viewAdult(expandURL(chapterURL)))
	local content = doc:selectFirst("#chapters")
	if content == nil then
		content = doc
	end
	content:select("h3.landmark"):remove()
	content:select("#show-comments-link, .feedback, script, style"):remove()
	return pageOfElem(content, true)
end

local function search(data)
	local doc = GETDocument(
		baseURL .. "/works/search?page=" .. data[PAGE]
			.. "&work_search%5Bquery%5D=" .. encode(data[QUERY])
	)
	return parseBlurbs(doc)
end

return {
	id = 95810,
	name = "Archive of Our Own",
	baseURL = baseURL,
	imageURL = imageURL,
	chapterType = ChapterType.HTML,
	hasSearch = true,

	listings = {
		Listing("Latest", true, function(data)
			local doc = GETDocument(
				baseURL .. "/works/search?work_search%5Bsort_column%5D=revised_at&page=" .. data[PAGE]
			)
			return parseBlurbs(doc)
		end)
	},

	parseNovel = parseNovel,
	getPassage = getPassage,
	search = search,
	shrinkURL = shrinkURL,
	expandURL = expandURL
}
