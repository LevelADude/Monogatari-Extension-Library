-- {"id":233218,"ver":"1.0.0","libVer":"1.0.0","author":"Bigrand","dep":["novelvault>=1.0.0"]}

return Require("novelvault")("https://allnovelfull.blog", {
	id = 233218,
	name = "All Novel Full",
	imageURL = "https://shosetsuorg.gitlab.io/extensions/icons/AllNovelFull.png",

	novelParam = "book",
	authorParam = "all-novel-full-author",
	genreParam = "all-novel-full-genres",
	genreSpace = "-",
	ajaxChaptersURL = "ajax/chapter-archive",

	searchImgModFunc = function(imageURL)
		return imageURL:gsub("_80_113", "")
	end,

	listingConfigs = {
		{ name = "Hot Novel", incrementing = true, param = "sort/all-novel-full-hot" },
		{ name = "Most Popular", incrementing = true, param = "sort/all-novel-full-popular" },
		{ name = "Completed Novel", incrementing = true, param = "sort/all-novel-full-complete" },
		{ name = "Ongoing", incrementing = true, param = "sort/all-novel-full-ongoing" },
		{ name = "Latest Release", incrementing = true, param = "sort/all-novel-full-daily-update" },
	},

	supportedFilters = { "genre", "author", "status", "tag" },

	statuses = {
		{ name = "Ongoing",   param = "sort/all-novel-full-ongoing" },
		{ name = "Completed", param = "sort/all-novel-full-complete" },
	},

	genres = {
		"Action",
		"Adventure",
		"Anime & comics",
		"Comedy",
		"Drama",
		"Eastern",
		"Fan-fiction",
		"Fanfiction",
		"Fantasy",
		"Game",
		"Gender Bender",
		"General",
		"Harem",
		"Historical",
		"Horror",
		"Isekai",
		"Josei",
		"Litrpg",
		"Magic",
		"Magical Realism",
		"Martial Arts",
		"Mature",
		"Mecha",
		"Modern Life",
		"Mystery",
		"Other",
		"Psychological",
		"Reincarnation",
		"Romance",
		"School life",
		"Sci-Fi",
		"Seinen",
		"Shoujo",
		"Shoujo AI",
		"Shounen",
		"Shounen AI",
		"Slice of Life",
		"Smut",
		"Sports",
		"Supernatural",
		"System",
		"Thriller",
		"Tragedy",
		"Urban",
		"Urban Life",
		"Video Games",
		"War",
		"Wuxia",
		"Xianxia",
		"Xuanhuan",
		"Yaoi",
		"Yuri"
	}
})
