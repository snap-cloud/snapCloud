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

local lfs = require('lfs')
local localizer = { locales = {} }

debug_print = function (title, string)
    print('\n\n----------\n' .. (string and title or 'DEBUG') .. '\n' ..
        require('inspect').inspect(string) ..
        '\n----------\n'
    )
end

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
        parametrized = parametrized:gsub('@' .. i, v)
    end
    return parametrized
end

localizer.localize = function (selector, lang_code, ...)
    -- Fetches a locale string and substitutes its params, if any
    local string = localizer.locales[lang_code][selector]
    if string then
        return localizer.apply_params(
            localizer.locales[lang_code][selector],
            ...
        )
    else
        -- This string is not localized. Let's return the English one
        return localizer.apply_params(
            localizer.locales.en[selector],
            ...
        )
    end
end

localizer.get = function (selector, ...)
    debug_print('looking for:', selector)
    -- Fetches a locale string in the current localizer language
    return localizer.localize(selector, localizer.language, ...)
end

localizer.language = 'en'

localizer.read_locales()

return localizer
