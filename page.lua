-- Page view module
-- =============
-- We define pages that read from the page folder in views
-- poor man's dynamic pages

local app = require 'app'
local respond_to = require('lapis.application').respond_to
local db = require 'lapis.db'
local Model = require('lapis.db.model').Model
local config = require "lapis.config".get()
local slugify = require("lapis.util").slugify

local Users = Model:extend('users', {
    primary_key = { 'username' }
})

local Pages = Model:extend('pages', {
    primary_key = { 'slug' }
})

local path = "pages/"

-- Endpoints

--app:get('/page', function(self)
--    return { render = 'stories' }
--end)

app:get('pageview', '/page/:slug', function(self)

	self.visitor = Users:find(self.session.username)
	self.slug = slugify(self.params.slug)
    self.page = Pages:find(self.slug)
    
    if self.page then		
		self.content = self.page.content
		self.title = self.page.title
		page_title = self.title		
		return { render = "pageview" } 
	else
		return { render = "notfound" } 
	end	
end)

app:get('/page/view/:slug', function(self)
	slug  = slugify(self.params.slug)
    return { redirect_to = '/page/' .. slug }
end)



app:get('/page/edit/:slug', function(self)
	self.visitor = Users:find(self.session.username)
	self.slug = slugify(self.params.slug)
    self.page = Pages:find(self.slug)

	if self.visitor and self.visitor.isadmin then	

		if self.page then
			self.content = self.page.content or ""
			self.title = self.page.title or ""
		else
			self.content = ""
			self.title = ""			
				
	--	else 	
	--		slug  = self.params.slug:gsub('%W','')
	--		local f=io.open(path .. slug .. ".etlua")
	--		if f~=nil then
	--				self.content = f:read("*a")
	--				f:close()
	--			else self.content = ""
	--		end
	--		return { render = "page_edit" } 
		end
		
		return { render = "page_edit" }  

	else
		return { render = 'noaccess' }
	end		
end)


app:match('update_page', '/page/save/:slug', respond_to({
    OPTIONS = cors_options,
    POST = function (self)
		self.slug = slugify(self.params.slug)
		
		self.visitor = Users:find(self.session.username)
		self.page = Pages:find(self.slug)

		if self.visitor and self.visitor.isadmin then			
			
			if self.page then
				self.page:update({
					title = self.params.title or "",
					content = self.params.content or "",
					last_edit_by = self.session.username,
					last_edit_at = db.format_date()
				})
			else
				page = Pages:create({
					slug = slugify(self.slug),
					title = self.params.title or "",
					content = self.params.content or "",
					last_edit_by = self.session.username,
					last_edit_at = db.format_date()
				})
				
				if not page then
					return { redirect_to = err }
				end
			end
			
			return { redirect_to = '/page/' .. self.slug }

		else
			return { render = 'noaccess' }
		end
    end
}))
