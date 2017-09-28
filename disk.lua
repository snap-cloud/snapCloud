-- Disk storage utils
-- ==================

-- we store max 1000 projects per dir

saveToDisk = function (id, filename, contents)
    local dir = 'store/' .. math.floor(id / 1000) .. '/' .. id
    os.execute('mkdir -p ' .. dir)
    local file = io.open(dir .. '/' .. filename, 'w+')
    file:write(contents)
    file:close()
end

retrieveFromDisk = function (id, filename)
    local dir = 'store/' .. math.floor(id / 1000) .. '/' .. id 
    local file = io.open(dir .. '/' .. filename, 'r')
    if (file) then
        local contents = file:read("*all")
        file:close()
        return contents
    else
        return nil
    end
end
