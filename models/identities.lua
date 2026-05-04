-- Snap!Cloud Identities Model
-- ============================
--
-- Links Snap!Cloud user accounts to external identity providers
-- (Google, GitHub, etc.)
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2024 by Bernat Romagosa and Michael Ball
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

local Model = package.loaded.Model

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE identities (
--   id serial PRIMARY KEY,
--   user_id integer NOT NULL REFERENCES users(id),
--   provider text NOT NULL,
--   external_id text NOT NULL,
--   verified boolean DEFAULT false,
--   display_name text,
--   email text,
--   avatar_url text,
--   created_at timestamp with time zone,
--   updated_at timestamp with time zone,
--   last_used_at timestamp with time zone
-- );
-- CREATE UNIQUE INDEX identities_provider_external_id_idx
--   ON identities (provider, external_id);
-- CREATE INDEX identities_user_id_idx ON identities (user_id);
--
local Identities = Model:extend('identities', {
    primary_key = 'id',
    relations = {
        { 'user', belongs_to = 'Users', key = 'user_id' },
    },
})

return Identities
