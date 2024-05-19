-- Snap!Cloud Tokens Model
-- =======================
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
-- CREATE TABLE tokens (
--   created timestamp without time zone DEFAULT now() NOT NULL,
--   username public.dom_username NOT NULL,
--   purpose text,
--   value text NOT NULL
-- );
-- ALTER TABLE ONLY tokens
--   ADD CONSTRAINT value_pkey PRIMARY KEY (value);
-- CREATE TRIGGER expire_token_trigger AFTER INSERT ON tokens FOR EACH STATEMENT EXECUTE FUNCTION public.expire_token();
-- ALTER TABLE ONLY tokens
--   ADD CONSTRAINT users_fkey FOREIGN KEY (username) REFERENCES public.users(username) ON UPDATE CASCADE;
--
local Tokens =  Model:extend('tokens', {
    primary_key = {'value'}
})

return Tokens
