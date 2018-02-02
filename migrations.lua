local db = require("lapis.db")
local schema = db.schema

--[[
    Make sure to use a date string YYYYMMDDHHMMSS as the migration key.
]]

return {
    -- Initial setup.
    [20180201061411] = function() {
        
        schema.create_table("users", {
        
        })
    }
}