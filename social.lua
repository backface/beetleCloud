-- Social module
-- =============
-- This is where the whole sharing site resides. Within this module there are
-- project pages and user pages

local app = require 'app'
local db = require 'lapis.db'
local md5 = require 'md5'
local Model = require('lapis.db.model').Model
local respond_to = require('lapis.application').respond_to
local unistd = require "posix.unistd"
local config = require "lapis.config".get()

require 'backend_utils'

local s = ''

-- Database abstractions

local Users = Model:extend('users', {
    primary_key = { 'username' }
})

local Projects = Model:extend('projects', {
    primary_key = { 'username', 'projectname' }
})

local Projects_by_orig = Model:extend('projects', {
    primary_key = { 'origcreator', 'origname' }
})

local Likes = Model:extend('likes', {
    primary_key = { 'id' }
})

local Comments = Model:extend('comments', {
    primary_key = { 'username', 'projectowner' }
})


-- Endpoints

-- This module only takes care of the index page
app:get('/1', function(self)
    local query = {
        newest = 'projectName, username, thumbnail from projects where isPublic = true order by id desc',
        popular = 'count(*) as likecount, projects.projectName, projects.username, projects.thumbnail from projects, likes where projects.isPublic = true and projects.projectName = likes.projectName and projects.username = likes.projectowner group by projects.projectname, projects.username order by likecount desc',
        featured  = 'projectName, username, thumbnail from projects where isPublic = true and categories ilike \'%featured%\' order by id desc',
        gettingstarted = 'projectName, username, thumbnail from projects where isPublic = true and categories ilike \'%Getting Started%\' order by id desc'
    }

	newest = db.select(query['newest'] .. ' limit ? offset ?', 15,0)
	popular = db.select(query['popular'] .. ' limit ? offset ?', 15,0)
	featured = db.select(query['featured'] .. ' limit ? offset ?', 15,0)
	gettingstarted = db.select(query['gettingstarted'] .. ' limit ? offset ?', 15,0)

  return { render = 'index2' }
end)

app:get('/signup', function(self)
    self.fail = self.params.fail
    self.reason = self.params.reason
    self.page_title = "Sign Up"
    return { render = 'signup' }
end)

app:get('/user_created', function(self)
    return { render = 'user_created' }
end)

app:get('/tos', function(self)
	self.page_title = "Terms of Services"
    return { render = 'pages/tos' }
end)

app:get('/myprojects', function(self)
    self.projects = Projects:select('where username = ? order by id desc', self.session.username, { fields = 'projectname, thumbnail, notes, ispublic, updated' })
    return { render = 'myprojects' }
end)

app:get('/login', function(self)
    self.fail = self.params.fail
    self.from = self.params.from
    self.page_title = "Login"
    return { render = 'login' }
end)

app:get('/logout', function(self)
    return { redirect_to = '/api/users/logout' }
end)

app:get('/users', function(self)
  local visitor = Users:find(self.session.username)

  if (visitor and visitor.isadmin) then
    self.page_title = "Users"
    self.s = ''
    return { render = 'usergrid' }
  else
			return { render = 'noaccess' }
		end
end)

app:get('/users/:username', function(self)
    self.user = Users:find(self.params.username)
    self.s = ''
    if self.user then
        self.user.joinedString = dateString(self.user.joined)
        self.visitor = Users:find(self.session.username)
        self.gravatar = md5.sumhexa(self.user.email)
        self.page_title = "User " .. self.params.username
        return { render = 'user' }
    else
        return { render = 'notfound' }
    end
end)

app:get('/users/:username/projects/g/:collection', function(self)
    self.collection = self.params.collection
    self.username = self.params.username
    self.page_title = "from User:" .. self.username
    return { render = 'projectgrid' }
end)

app:get('/projects/g/:collection', function(self)
    self.collection = self.params.collection
    self.username = ''
    self.s = ''
    self.page_title =  self.params.collection .. " Projects"
    return { render = 'projectgrid' }
end)

app:get('/projects/g/tag/:tag', function(self)
	self.collection = "tag"
    self.tag = self.params.tag
    self.s = ''
    self.username = ''
    self.page_title =  self.params.tag
    return { render = 'projectgrid' }
end)

app:get('/projects/g/search/:s', function(self)
	self.collection = "search"
    self.s = self.params.s
    self.username = ''
    self.page_title =  'Search ' .. self.params.s
    return { render = 'projectgrid' }
end)

app:get('/projects/g/category/:category', function(self)
	self.collection = "category"
    self.category = self.params.category
    self.username = ''
    self.s = ''
    self.page_title =  self.params.category
    return { render = 'projectgrid' }
end)

app:get('/users/:username/projects/:projectname', function(self)
    self.visitor = Users:find(self.session.username)
    self.project = Projects:find(self.params.username, self.params.projectname)
    self.s = ''

    if (self.project and
        (self.project.ispublic or (self.visitor and self.visitor.isadmin) or
            self.session.username == self.project.username)) then
        self.project.modifiedString = dateString(self.project.updated)
        self.project.sharedString = self.project.ispublic and dateString(self.project.shared) or '-'
        self.project.createdString = dateString(self.project.created) or '-'

        self.project.likes =
            Likes:count('projectname = ? and projectowner = ?',
                self.params.projectname,
                self.params.username)
        self.project.likedByUser =
            Likes:count('liker = ? and projectname = ? and projectowner = ?',
                self.session.username,
                self.params.projectname,
                self.params.username) > 0
        self.project.comments =  Comments:select('where projectowner = ? and projectname = ? order by id desc',
            self.project.username,
            self.project.projectname)
        self.project.likers =
                db.select(
                    'distinct likes.liker, md5(users.email) as gravatar from likes, users where likes.projectname = ? and likes.projectowner = ? and likes.liker = users.username ',
                    self.params.projectname,
                    self.params.username)
        self.project:update({
            views = (self.project.views or 0) + 1
        })

        -- if (self.project.remixhistory) then
		--	history = explode(";",self.project.remixhistory)
		--	if (history) then
		--		orig = explode(":",history[1])
		--		origname = orig[2]
		--		origcreator = orig[1]
		--	end
		-- end

		if self.project.tags then
			self.tags = explode_and_trim(',', self.project.tags or ',')
		else
			self.tags = nil
		end


        if ( self.project.origname and
			 self.project.origcreator and
			 self.project.origcreator ~= "anonymous" and
			(self.project.origname ~= self.project.projectname or self.project.origcreator ~= self.project.username)

        ) then
			self.project.origProject = Projects:find(
				self.project.origcreator,
				self.project.origname)
		end

		--self.project.remixes = db.select(
		--	'* from projects where ispublic = True and origname =  ? and origcreator = ? and (projectname != ? or username != ?) limit 10',
		--	self.project.projectname,
		--	self.project.username,
		--	self.project.projectname,
		--	self.project.username
		--	)
		self.project.remixCount =
            Projects:count('ispublic = true and origname =  ? and origcreator = ? and (projectname != ? or username != ?)',
			self.project.projectname,
			self.project.username,
			self.project.projectname,
			self.project.username)

		self.page_title =  self.params.projectname


        return { render = 'project' }
    else
        return { render = 'notfound' }
    end
end)

app:match('forgot_password', '/forgot_password', respond_to({
    OPTIONS = cors_options,
    POST = function (self)
        local Email = Model:extend('users', {
            primary_key = { 'email'}
        })
        local user = Email:find(self.params.email);

        if (not user) then
            self.page_title = "Recover Password fail"
            self.fail = true
            self.message = "I've flown all over the database but couldn't find this email"
            return { render = 'forgot_password' }
        else
            reset_code = md5.sumhexa(string.reverse(tostring(socket.gettime() * 10000)))
            local options = {reset_code = reset_code}
            user:update(options)
            ok, err = send_mail(self.params.email, "Password reset",
                "Dear TurtleStitcher, \n\n"
                .. "You requested a reset of your password. Follow this link to create your new password:\n"
                .. self:build_url(self:url_for("password_reset", { reset_code = reset_code }))
                .. config.mail_footer
            )
            if not ok then
                self.fail = true
                self.message = "Sending E-Mail failed: " .. err
            else
                self.success = true
            end

            self.page_title = "Recover Password"
            return { render = 'forgot_password' }
        end
    end,
    GET = function(self)
        self.page_title = "Reset Password"
        return { render = 'forgot_password' }
    end
}))

app:match("password_reset", "/password_reset/:reset_code", respond_to({
    OPTIONS = cors_options,
    POST = function (self)
        self.page_title = "Reset Password"

        local rUser = Model:extend('users', {
            primary_key = { 'reset_code'}
        })
        local user = rUser:find(self.params.reset_code);

        if (not user) then
            self.page_title = "Failed: Reset Password"
            self.fail = true
            self.message = "Your reset code is invalid."
            return { render = 'password_reset' }
        elseif (not user.confirmed) then
            self.page_title = "Failed: Reset Password"
            self.fail = true
            self.message = "User is not yet confirmed."
            return { render = 'password_reset' }
        else
            if (self.params.password ~= self.params.confirm_password) then
                self.fail = true
                self.message = "Passwords do not match"
                return { render = 'password_reset' }
            end

            if (string.len(self.params.password) < 3) then
                self.fail = true
                self.message = "Password is too short"
                return { render = 'password_reset' }
            end

            options = {
                password = unistd.crypt(self.params.password, salt),
                reset_code = ""
            }
            user:update(options)

            self.success = true
            return { render = 'password_reset' }
        end
    end,
    GET = function(self)
        local rUser = Model:extend('users', {
            primary_key = { 'reset_code'}
        })
        local user = rUser:find(self.params.reset_code);
        if (not user) then
            self.page_title = "Failed: Reset Password"
            self.fail = true
            self.message = "Your reset code is invalid. Request a new reset link"
        elseif (not user.confirmed) then
            self.page_title = "Failed: Reset Password"
            self.fail = true
            self.message = "User is not yet confirmed."
            return { render = 'password_reset' }
        else
            self.page_title = "Reset Password"
        end
        return { render = 'password_reset' }
    end
}))

app:match("change_password", "/change_password", respond_to({
    OPTIONS = cors_options,
    POST = function (self)
        self.page_title = "Change Password"
        local user = Users:find(self.session.username)

        if (not user) then
            self.page_title = "Failed: Change Password"
            self.fail = true
            self.message = "You are not logged in"
            return { render = 'change_password' }
        else
			if (unistd.crypt(self.params.old_password, salt) == user.password) then
				if (self.params.password ~= self.params.confirm_password) then
					self.fail = true
					self.message = "Passwords do not match"
					return { render = 'change_password' }
				end

				if (string.len(self.params.password) < 3) then
					self.fail = true
					self.message = "Password is too short"
					return { render = 'change_password' }
				end

				options = {
            password = unistd.crypt(self.params.password, salt),
				}
				user:update(options)
			else
				self.fail = true
				self.message = "Old Password is incorrect"
				return { render = 'change_password' }
			end

            self.success = true
            return { render = 'change_password' }
        end
    end,
    GET = function(self)
		local user = Users:find(self.session.username)
		self.page_title = "Change Password"

        if (not user) then
            self.page_title = "Failed: Change Password"
            self.fail = true
            self.message = "You are not logged in"
        end
        return { render = 'change_password' }
    end
}))
