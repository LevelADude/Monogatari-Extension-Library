-- {"id":273754,"ver":"1.0.0","libVer":"1.0.0","author":"Bigrand","dep":["novelvault>=1.0.0"]}

return Require("novelvault")("https://allnovel.org", {
	id = 273754,
	name = "AllNovel",
	imageURL = "https://shosetsuorg.gitlab.io/extensions/icons/AllNovel.png",

	searchImgModFunc = function(imageURL)
		local url = imageURL:gsub("5c3c1127cd13ac4430ad26bdb61f11a3", "9c3d392ccc7c95187a8c6e37c6bdac6f")
		:gsub("d0168a2c54d65b7e194fda5bb80ef28b","4d27e0af8cf6e971f7ee3c995fc55190")
		return url
	end,

	listingConfigs = {
		{ name = "Hot Novel", incrementing = true, param = "hot-novel" },
		{ name = "Most Popular", incrementing = true, param = "most-popular" },
		{ name = "Completed Novel", incrementing = true, param = "completed-novel" },
		{ name = "Ongoing", incrementing = true, param = "status/Ongoing" },
		{ name = "Latest Release", incrementing = true, param = "latest-release-novel" },
	},

	supportedFilters = { "genre", "author", "status" },

	statuses = {
        { name = "Ongoing",   param = "status/Ongoing" },
        { name = "Completed", param = "completed-novel" },
    },

	genres = {
		"Action",
		"Adult",
		"Adventure",
		"Comedy",
		"Drama",
		"Ecchi",
		"Fantasy",
		"Gender Bender",
		"Harem",
		"Historical",
		"History",
		"Horror",
		"Josei",
		"Lolicon",
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
		"Shounen Ai",
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
