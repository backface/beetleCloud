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
	local f=io.open("views/pages/" .. slug .. ".etlua")
	if f~=nil then io.close(f) 
		return { render = "pages/" .. slug } 
	else 
		return { render = 'notfound' }
	end
end)
