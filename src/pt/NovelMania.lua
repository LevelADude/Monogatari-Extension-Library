-- {"id":250401,"ver":"2.0.0","libVer":"1.0.0","author":"Claudemirovsky, kodmaster23","dep":["url>=1.0.0"]}

local baseURL = "https://novelmania.com.br"
local qs = Require("url").querystring

local FILTER_GENRE_ID = 100
local FILTER_GENRE_KEYS = {
  "Todos",
  "Ação",
  "Adulto",
  "Antologia",
  "Artes Marciais",
  "Aventura",
  "Comédia",
  "Conto",
  "Cotidiano",
  "Cultivo",
  "Distopia",
  "Drama",
  "Ecchi",
  "Erótico",
  "Escolar",
  "Exploração",
  "Fantasia",
  "Futurista",
  "Harém",
  "Histórico",
  "Horror",
  "Isekai",
  "Magia",
  "Mecha",
  "Medieval",
  "Militar",
  "Mistério",
  "Mitologia",
  "Psicológico",
  "Punk",
  "Realidade Virtual",
  "Romance",
  "Sci-fi",
  "Sistema de Jogo",
  "Sobrenatural",
  "Super-Herói",
  "Suspense",
  "Terror",
  "Wuxia",
  "Xianxia",
  "Xuanhuan",
  "Yaoi",
  "Yuri"
}
local FILTER_GENRE_VALUES = {
  [0] = "",
  "1", "2", "39", "7", "3", "4", "38", "16", "47", "41",
  "23", "27", "22", "13", "45", "5", "40", "21", "42", "43",
  "30", "26", "8", "31", "24", "9", "10", "11", "44", "36",
  "12", "14", "15", "17", "46", "29", "6", "18", "19", "20",
  "35", "37"
}

local FILTER_NATIONALITY_ID = 200
local FILTER_NATIONALITY_KEYS = {
  "Todas",
  "Americana",
  "Angolana",
  "Brasileira",
  "Chinesa",
  "Coreana",
  "Japonesa"
}
local FILTER_NATIONALITY_VALUES = {
  [0] = "",
  "americana",
  "angolana",
  "brasileira",
  "chinesa",
  "coreana",
  "japonesa"
}

local FILTER_STATUS_ID = 300
local FILTER_STATUS_KEYS = { "Todos", "Ativo", "Completo", "Pausado", "Parado" }
local FILTER_STATUS_VALUES = { [0] = "", "ativo", "completo", "pausado", "parado" }

local FILTER_ORDER_ID = 400
local FILTER_ORDER_KEYS = {
  "Qualquer ordem",
  "Ordem alfabética",
  "Nº de Capítulos",
  "Popularidade",
  "Novidades"
}
local FILTER_ORDER_VALUES = { [0] = "", "0", "1", "2", "3" }

local function shrinkURL(url)
  return url:gsub("^.-novelmania%.com%.br", "")
end

local function expandURL(path)
  return baseURL .. path
end

local function getPassage(chapterURL)
  local doc = GETDocument(expandURL(chapterURL))
  local content = doc:selectFirst("div#chapter-content")
  if content then
    content:select("h3, h2"):remove()
    return pageOfElem(content, true)
  end
  return ""
end

local function parseNovel(novelURL)
  local doc = GETDocument(expandURL(novelURL))
  
  local title = doc:selectFirst("div.novel-info h1")
  local img = doc:selectFirst("div.novel-img img")
  local authorElem = doc:selectFirst("span.authors:contains(Autor:)")
  local statusElem = doc:selectFirst("span.authors:contains(Status:)")
  local descElems = doc:select("div.text p")
  local genreElems = doc:select("div.tags ul.list-tags a")
  local chapterElems = doc:select("ol.list-inline li a")
  
  local chaptersArray = {}
  for i = 0, chapterElems:size() - 1 do
    local el = chapterElems:get(i)
    local strong = el:selectFirst("strong")
    local small = el:selectFirst("small")
    chaptersArray[#chaptersArray + 1] = NovelChapter {
      title = strong and strong:text() or el:text(),
      link = shrinkURL(el:attr("href")),
      release = small and small:text() or "",
      order = i + 1
    }
  end
  
  local chapters = AsList(chaptersArray)
  
  local function trim(s)
    return s and s:match("^%s*(.-)%s*$") or ""
  end
  
  local statusText = statusElem and trim(statusElem:ownText()) or "Desconhecido"
  local statusMap = {
    ["Ativo"] = NovelStatus.PUBLISHING,
    ["Completo"] = NovelStatus.COMPLETED,
    ["Pausado"] = NovelStatus.PAUSED,
    ["Parado"] = NovelStatus.PAUSED
  }
  
  local description = ""
  if descElems:size() > 0 then
    local parts = {}
    for i = 0, descElems:size() - 1 do
      parts[i + 1] = descElems:get(i):text()
    end
    description = table.concat(parts, "\n")
  end
  
  local authorText = authorElem and trim(authorElem:ownText()) or "Desconhecido"
  
  return NovelInfo {
    title = title and title:text() or "",
    imageURL = img and img:attr("src") or "",
    description = description,
    authors = { authorText },
    genres = map(genreElems, function(el) return el:text() end),
    status = statusMap[statusText] or NovelStatus.UNKNOWN,
    chapters = chapters
  }
end

local function buildSearchURL(data)
  local params = {}
  
  if data[PAGE] then
    params["page[page]"] = tostring(data[PAGE])
  end
  
  if data[QUERY] and data[QUERY] ~= "" then
    params["titulo"] = data[QUERY]
  end
  
  if data[FILTER_GENRE_ID] and data[FILTER_GENRE_ID] > 0 then
    params["categoria"] = FILTER_GENRE_VALUES[data[FILTER_GENRE_ID]]
  end
  
  if data[FILTER_NATIONALITY_ID] and data[FILTER_NATIONALITY_ID] > 0 then
    params["nacionalidade"] = FILTER_NATIONALITY_VALUES[data[FILTER_NATIONALITY_ID]]
  end
  
  if data[FILTER_STATUS_ID] and data[FILTER_STATUS_ID] > 0 then
    params["status"] = FILTER_STATUS_VALUES[data[FILTER_STATUS_ID]]
  end
  
  if data[FILTER_ORDER_ID] and data[FILTER_ORDER_ID] > 0 then
    params["ordem"] = FILTER_ORDER_VALUES[data[FILTER_ORDER_ID]]
  end
  
  return qs(params, expandURL("/novels"))
end

local function parseList(url)
  local doc = GETDocument(url)
  local novelContainers = doc:select("div.top-novels")
  
  local results = {}
  for i = 0, novelContainers:size() - 1 do
    local container = novelContainers:get(i)
    local img = container:selectFirst("img.card-image")
    local link = img and img:parent():parent()
    
    if link then
      local alt = img:attr("alt")
      local title = alt:gsub("^Capa de ", ""):gsub("^Capa da novel ", "")
      
      results[#results + 1] = Novel {
        title = title,
        imageURL = img:attr("src"),
        link = shrinkURL(link:attr("href"))
      }
    end
  end
  
  return results
end

local function listing(name, order)
  return Listing(name, true, function(data)
    local params = {}
    
    if data[PAGE] then
      params["page[page]"] = tostring(data[PAGE])
    end
    
    if data[QUERY] and data[QUERY] ~= "" then
      params["titulo"] = data[QUERY]
    end
    
    if data[FILTER_GENRE_ID] and data[FILTER_GENRE_ID] > 0 then
      params["categoria"] = FILTER_GENRE_VALUES[data[FILTER_GENRE_ID]]
    end
    
    if data[FILTER_NATIONALITY_ID] and data[FILTER_NATIONALITY_ID] > 0 then
      params["nacionalidade"] = FILTER_NATIONALITY_VALUES[data[FILTER_NATIONALITY_ID]]
    end
    
    if data[FILTER_STATUS_ID] and data[FILTER_STATUS_ID] > 0 then
      params["status"] = FILTER_STATUS_VALUES[data[FILTER_STATUS_ID]]
    end
    
    if data[FILTER_ORDER_ID] and data[FILTER_ORDER_ID] > 0 then
      params["ordem"] = FILTER_ORDER_VALUES[data[FILTER_ORDER_ID]]
    elseif order ~= "" then
      params["ordem"] = order
    end
    
    return parseList(qs(params, expandURL("/novels")))
  end)
end

return {
  id = 250401,
  name = "Novel Mania",
  baseURL = baseURL,
  imageURL = expandURL("/vite/assets/logo-5etzsy8L.png"),
  
  hasSearch = true,
  isSearchIncrementing = true,
  
  listings = {
    listing("Populares", "3"),
    listing("Recentes", "4")
  },
  
  searchFilters = {
    DropdownFilter(FILTER_GENRE_ID, "Gênero", FILTER_GENRE_KEYS),
    DropdownFilter(FILTER_NATIONALITY_ID, "Nacionalidade", FILTER_NATIONALITY_KEYS),
    DropdownFilter(FILTER_STATUS_ID, "Status", FILTER_STATUS_KEYS),
    DropdownFilter(FILTER_ORDER_ID, "Ordenar por", FILTER_ORDER_KEYS)
  },
  
  search = function(data)
    return parseList(buildSearchURL(data))
  end,
  
  parseNovel = parseNovel,
  getPassage = getPassage,
  
  chapterType = ChapterType.HTML,
  
  shrinkURL = shrinkURL,
  expandURL = expandURL
}
