-- redirect module
-- =============

local app = require 'app'


-- inbound

app:get('/faq', function(self)
	 return { redirect_to = "page/faq" }
end)

app:get('/about', function(self)
    return { redirect_to = "page/about" }
end)

app:get('/contact', function(self)
	return { redirect_to = "page/contact" }
end)

app:get('/privacy', function(self)
	return { redirect_to = "page/privacy" }
end)



-- outbound

app:get('/workshop', function(self)
    return { redirect_to = "http://www.frauhimbeer.at/blog/" }
end)

app:get('/alpha', function(self)
    return { redirect_to = 'http://m.ash.to/turtlestitch/alpha-three' }
end)

app:get('/kickstarter', function(self)
    return { redirect_to = 'https://www.kickstarter.com/projects/1206849453/turtlestitch?ref=aip0qq' }
end)
