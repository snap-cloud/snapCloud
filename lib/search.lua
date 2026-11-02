-- SQL fragments for the site search; the ILIKE patterns are served by the trigram indexes.
local db = package.loaded.db

local search = {}

-- Shorter terms have no trigram to index, so they match as a name prefix.
search.MIN_LENGTH = 3

local function escape_like(str)
    return (str:gsub('[\\%%_]', '\\%0'))
end

-- Trims and collapses whitespace; '' means "not searching".
function search.normalize(term)
    if term == nil then return '' end
    return (tostring(term):gsub('%s+', ' '):match('^ ?(.-) ?$'))
end

-- Every word must appear in one of the columns.
function search.match_clause(term, columns)
    if #term < search.MIN_LENGTH then
        return db.interpolate_query(
            ' AND ' .. columns[1] .. ' ILIKE ?', escape_like(term) .. '%')
    end
    local words = {}
    for word in term:gmatch('%S+') do
        local alternatives = {}
        for _, column in ipairs(columns) do
            table.insert(alternatives, db.interpolate_query(
                column .. ' ILIKE ?', '%' .. escape_like(word) .. '%'))
        end
        table.insert(words, '(' .. table.concat(alternatives, ' OR ') .. ')')
    end
    return ' AND ' .. table.concat(words, ' AND ')
end

-- Rows whose column resembles the term (pg_trgm word similarity).
function search.fuzzy_clause(term, column)
    return db.interpolate_query(' AND ? <% ' .. column, term)
end

-- Leading ORDER BY terms: whole-term name matches first, then by resemblance.
function search.rank_clause(term, column)
    return db.interpolate_query(
        '(' .. column .. ' ILIKE ?) DESC, word_similarity(?, ' .. column ..
            ') DESC, ',
        '%' .. escape_like(term) .. '%', term)
end

function search.can_retry_fuzzy(self, term)
    return term ~= '' and #term >= search.MIN_LENGTH and not self.fuzzy_search
        and (tonumber(self.params.page_number) or 1) == 1
end

return search
