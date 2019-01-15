-- Database abstractions

package.loaded.Users = package.loaded.Model:extend('users', {
    primary_key = { 'username' },
    relations = {
        { 'collections', has_many = 'Collections', key = 'creator_id' }
    }
})

package.loaded.Projects = package.loaded.Model:extend('projects', {
    primary_key = { 'username', 'projectname' }
})

package.loaded.Tokens = package.loaded.Model:extend('tokens', {
    primary_key = { 'value' }
})

package.loaded.Remixes = package.loaded.Model:extend('remixes', {
    primary_key = { 'original_project_id', 'remixed_project_id' }
})

package.loaded.Collections = package.loaded.Model:extend('collections', {
    primary_key = { 'creator_id', 'slug' },
    timestamp = true,
    relations = {
        -- TODO "projects", fetch() - get projects through memberships
        -- creates Collection:get_creator()
        { 'creator', belongs_to = 'Users', key = 'creator_id'}
    },
    constraints = {
        name = function(self, value)
            if not value then
                return 'A name must be present'
            end
        end,
        -- Ensure slugs are unique.
        slug = function(self, value, column, collection)
            if package.loaded.Collections:find({ slug = value }) ~= nil then
                return 'The name "' .. collection.name .. '" is already in use.'
            end
        end
    }
})

package.loaded.CollectionMemberships = package.loaded.Model:extend(
    'collection_memberships', {
    primary_key = { 'collection_id', 'project_id' },
    timestamp = true
})
