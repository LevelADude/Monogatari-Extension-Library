-- {"id":325107,"ver":"1.0.0","libVer":"1.0.0","author":"Bigrand","dep":["novelvault>=1.0.0"]}

return Require("novelvault")("https://freewebnovel.com", {
	id = 325107,
	name = "Free Web Novel",
	imageURL = "https://shosetsuorg.gitlab.io/extensions/icons/FreeWebNovel.png",

	isSearchPOST = true,
	pageParam = "", -- No param, it's `/X`
	authorParam = "author",
	ajaxChaptersURL = "noajax",

	-- There are actually additional filters for this source,  
	-- but it's just this one source that wants to be different and special,  
	-- so it can stay missing for all I care :D
	listingConfigs = {
		{ name = "Latest Release", incrementing = true, param = "sort/latest-release" },
		{ name = "Latest Novel", incrementing = true, param = "sort/latest-novel" },
		{ name = "Completed Novel", incrementing = true, param = "sort/completed-novel" },
		{ name = "Most Popular (All)", incrementing = false, param = "sort/most-popular" },
		{ name = "Most Popular (Month)", incrementing = false, param = "most-popular/monthvisit" },
		{ name = "Most Popular (Week)", incrementing = false, param = "most-popular/weekvisit" },
		{ name = "Most Popular (Day)", incrementing = false, param = "most-popular/dayvisit" },
	},

	supportedFilters = { "genre", "author" },

	genres = {
		"Action",
		"Adult",
		"Adventure",
		"Comedy",
		"Drama",
		"Eastern",
		"Ecchi",
		"Fantasy",
		"Game",
		"Gender Bender",
		"Harem",
		"Historical",
		"Horror",
		"Josei",
		"Martial Arts",
		"Mature",
		"Mecha",
		"Mystery",
		"Psychological",
		"Reincarnation",
		"Romance",
		"School Life",
		"Sci-fi",
		"Seinen",
		"Shoujo",
		"Shounen",
		"Shounen AI",
		"Slice of Life",
		"Smut",
		"Sports",
		"Supernatural",
		"Tragedy",
		"Wuxia",
		"Xianxia",
		"Xuanhuan",
		"Yaoi",
	}
})
