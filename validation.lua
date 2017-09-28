-- Validation and errors
-- =====================

local yield_error = package.loaded.yield_error
local Users = package.loaded.Users
local Projects = package.loaded.Projects

err = {
    notLoggedIn = 'you are not logged in',
    impersonate = 'you are trying to perform an action in someone else\'s name',
    auth = 'you do not have permission to perform this action',
    nonexistentUser = 'no user with this username exists',
    nonexistentProject = 'this project does not exist, or you do not have permissions to access it'
}

assert_all = function (assertions, self)
    for k, assertion in pairs(assertions) do
        _G['assert_' .. assertion](self)
    end
end

assert_logged_in = function (self)
    if not self.params.username then
        yield_error(err.notLoggedIn)
    end
end

assert_admin = function (self, visitor)
    local visitor = Users:find(self.session.username)
    if not (visitor and visitor.isadmin) then
        yield_error(err.auth)
    end
end

assert_users_match = function (self)
    if (self.session.username ~= self.params.username) then
        -- Someone is trying to impersonate someone else
        yield_error(err.impersonate)
    end
end

assert_user_exists = function (self, user)
    if not (user or Users:find(self.params.username)) then
        yield_error(err.nonexistentUser)
    end
end

assert_project_exists = function (self, project)
    if not (Projects:find(self.params.username, self.params.projectname)) then
        yield_error(err.nonexistentProject)
    end
end

