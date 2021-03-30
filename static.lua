-- Static module
-- =============
-- We define pages that don't read from the database and are generally
-- less prone to change here

local app = require 'app'

-- Endpoints

--app:get('/stories', function(self)
--    return { render = 'stories' }
--end)

app:get('/categories', function(self)
	self.s = ''
	self.page_title = "Categories"
    return { render = 'categories' }
end)

app:get('/run', function(self)
	self.s = ''
	self.page_title = "Run"
    return { render = 'run' }
end)

app:get('/beta', function(self)
	self.s = ''
	self.page_title = "Development testing"
    return { render = 'beta' }
end)


app:get('/v2.5', function(self)
	self.s = ''
	self.page_title = "legacy (old) version"
    return { render = 'old' }
end)

app:get('/v2.6', function(self)
	self.s = ''
	self.page_title = "Run"
    return { render = 'run' }
end)

app:get('/old', function(self)
	self.s = ''
	self.page_title = "legacy (old) version"
    return { render = 'old' }
end)

