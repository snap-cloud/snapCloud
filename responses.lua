-- Response utils
-- ==============

jsonResponse = function (json)
    return {
        layout = false, 
        status = 200, 
        readyState = 4, 
        json = json or {}
    }
end

okResponse = function (message)
    return jsonResponse({ message = message })
end

rawResponse = function (contents)
    return {
        layout = false, 
        status = 200, 
        readyState = 4, 
        contents
    }
end

cors_options = function (self)
    self.res.headers['access-control-allow-headers'] = 'Content-Type'
    self.res.headers['access-control-allow-method'] = 'POST, GET, DELETE, OPTIONS'
    return { status = 200, layout = false }
end

err = {
    notLoggedIn = 'you are not logged in',
    auth = 'you do not have permission to perform this action',
    nonexistentUser = 'no user with this username exists',
    nonexistentProject = 'this project does not exist, or you do not have permissions to access it'
}
