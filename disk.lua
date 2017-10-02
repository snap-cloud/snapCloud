-- Disk storage utils
-- ==================

-- we store max 1000 projects per dir

directoryForId = function (id)

    -- IN PRDUCTION: Change 'store/' by final directory
    -- ================================================

    return 'store/' .. math.floor(id / 1000) .. '/' .. id
end

saveToDisk = function (id, filename, contents)
    local dir = directoryForId(id)
    os.execute('mkdir -p ' .. dir)
    local file = io.open(dir .. '/' .. filename, 'w+')
    file:write(contents)
    file:close()
end

retrieveFromDisk = function (id, filename)
    local dir = directoryForId(id)
    local file = io.open(dir .. '/' .. filename, 'r')
    if (file) then
        local contents = file:read("*all")
        file:close()
        return contents
    else
        return nil
    end
end

deleteDirectory = function (id)
    os.execute('rm -r ' .. directoryForId(id))
end
