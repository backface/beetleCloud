-- Page view module
-- =============
-- We define pages that read from the page folder in views
-- poor man's dynamic pages

local app = require 'app'

-- Endpoints

--app:get('/page', function(self)
--    return { render = 'stories' }
--end)

app:get('/page/view/:slug', function(self)
	slug  = self.params.slug:gsub('%W','')
	local f=io.open("views/dynamic_pages/" .. slug .. ".etlua")
	if f~=nil then io.close(f) 
		--return { render = "pages
		self.page_title = slug
		self.view = "views/dynamic_pages/" .. slug
		return { render = "pageview" } 
	else 
		return { render = 'notfound' }
	end
end)
