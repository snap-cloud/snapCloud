-- Response utils
-- ==============

-- Responses

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

-- OPTIONS

cors_options = function (self)
    self.res.headers['access-control-allow-headers'] = 'Content-Type'
    self.res.headers['access-control-allow-methods'] = 'GET, POST, DELETE, OPTIONS'
    return { status = 200, layout = false }
end

