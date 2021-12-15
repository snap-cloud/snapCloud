-- Dialog HTML strings
-- ===================
--
-- Escaped HTML strings for all dialogs.
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

local escape_html = function (html)
    local escaped = html
    local map = {}

    map['&'] = '&amp;'
    map['<'] = '&lt;'
    map['>'] = '&gt;'
    map['"'] = '&quot;'
    map["'"] = '&#039;'

    for k, v in pairs(map) do
        escaped = escaped:gsub(k, v)
    end
    return escaped
end

local compact = function (text)
    -- remove newlines, and escape quotes
    return text:gsub('\n', ''):gsub("'", '&#039;')
end

package.loaded.dialogs = {
    delete_project = compact([[
Are you sure you want to delete this project?<br>
<i class="warning fa fa-exclamation-triangle"></i>
 WARNING! This action cannot be undone! 
<i class="warning fa fa-exclamation-triangle"></i>
]]),
    flag_prewarning = compact([[
Are you sure you want to flag this project as inappropriate?<br><br>
Your username will be included in the flag report.<br><br>
Deliberately flagging legitimate projects will be considered a breach<br>
of our Terms of Service and can get you suspended.
]]),
    flag_reason = compact([[
<form class="reasons">
    <span class="option">
        <input type="radio" name="reason" value="hack">
        <label for="hack">Security vulnerability</label>
    </span>
    <span class="option">
        <input type="radio" name="reason" value="coc">
        <label for="coc">Code of Conduct violation</label>
    </span>
    <span class="option">
        <input type="radio" name="reason" value="dmca">
        <label for="dmca">DMCA violation</label>
    </span>
    <span class="notes-title"
        >Tell us more about why you're flagging this project:</span>
    <textarea class="notes" placeholder="Additional notes"></textarea>
    <script>
        console.log(this);
        this.dataset['form'] = document.querySelector('form.reasons');
    </script>
</form>
]])
}
