-- Page view module
-- =============
-- We define pages that read from the page folder in views
-- poor man's dynamic pages

local app = require 'app'
local respond_to = require('lapis.application').respond_to
local Model = require('lapis.db.model').Model
local config = require "lapis.config".get()

local Users = Model:extend('users', {
    primary_key = { 'username' }
})

local path = "pages/"

-- Endpoints

--app:get('/page', function(self)
--    return { render = 'stories' }
--end)

app:get('/page/view/:slug', function(self)
    self.visitor = Users:find(self.session.username)
	slug  = self.params.slug:gsub('%W','')
	local f=io.open(path .. slug .. ".etlua")
	if f~=nil then io.close(f) 
		self.page_title = slug
		self.view = path .. slug
		return { render = "pageview" } 
	else 
		return { render = 'notfound' }
	end
end)


app:get('/page/edit/:slug', function(self)
	self.visitor = Users:find(self.session.username)
	if self.visitor and self.visitor.isadmin then	
		slug  = self.params.slug:gsub('%W','')
		local f=io.open(path .. slug .. ".etlua")
		if f~=nil then
				self.content = f:read("*a")
				f:close()
			else self.content = ""
		end
		return { render = "page_edit" } 
	else
		return { render = 'noaccess' }
	end		
end)


app:match('update_page', '/page/save/:slug', respond_to({
    OPTIONS = cors_options,
    POST = function (self)
		self.visitor = Users:find(self.session.username)	
		if self.visitor and self.visitor.isadmin then			
			slug  = self.params.slug:gsub('%W','')		
			
			local f, err=io.open(path .. slug .. ".etlua",'w')
			if f~=nil  then
				f:write(self.params.content)
				f:close()
				f=io.open(path .. slug .. ".etlua",'r')
				local output = f:read('*all')
				f:close()
				 
				return { redirect_to = '/page/view/' .. slug }
			else 
				return { redirect_to = err }
			end
		else
			return { render = 'noaccess' }
		end
    end
}))
