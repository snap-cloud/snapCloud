-- Strings and localization
-- ========================
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2021 by Bernat Romagosa and Michael Ball
--
-- This file is part of Snap Cloud.
--
-- Snap Cloud is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local yield_error = package.loaded.yield_error

local lfs = require('lfs')
local localizer = { locales = {} }

localizer.read_locales = function ()
    -- Read all locales from files under the "locales" directory
    for file in lfs.dir('locales') do
        if file:sub(-#'.lua') == '.lua' then
            local lang_code = file:gsub('.lua','')
            local locale = require('locales/' .. lang_code)
            localizer.locales[lang_code] = locale
        end
    end
end

localizer.apply_params = function (string, ...)
    -- Substitutes params of the type @1, @2 in strings
    local parametrized = string
    for i, v in ipairs({...}) do
        if tostring(v):find('%%') then
            v = tostring(v):gsub('%%', '%%%%') -- in case string contains "%"
        end
        parametrized =
            parametrized:gsub('@' .. i, v)
    end
    return parametrized
end

localizer.localize = function (selector, lang_code, ...)
    -- Fetches a locale string and substitutes its params, if any
    local string = localizer.locales[lang_code][selector]
    if string and (string ~= '') then
        return localizer.apply_params(
            localizer.locales[lang_code][selector],
            ...
        )
    else
        -- This string is not localized. Let's return the English one
        string = localizer.locales.en[selector]
        if not string then yield_error('Missing string for ' .. selector) end
        return localizer.apply_params(string, ...)
    end
end

localizer.get = function (selector, ...)
    -- Fetches a locale string in the current localizer language
    return localizer.localize(selector, localizer.language, ...)
end

localizer.language = 'en'

localizer.read_locales()

return localizer
