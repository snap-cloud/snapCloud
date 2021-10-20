-- Contracts & Contract Users
-- ==========================
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2019 by Bernat Romagosa and Michael Ball
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

local db = package.loaded.db
local Model = require('lapis.db.Model').Model

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE contracts (
--   id integer NOT NULL,
--   name text NOT NULL,
--   start_date date NOT NULL,
--   end_date date NOT NULL,
--   email_domains text[] NOT NULL,
--   contact_info text,
--   contact_email text NOT NULL,
--   notes text,
--   location text,
--   timezone text,
--   created_at timestamp with time zone NOT NULL,
--   updated_at timestamp with time zone NOT NULL
-- );
-- ALTER TABLE ONLY contracts
--   ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);
-- End contracts schema
--
local Contracts = Model:extend('contracts', {
  timestamp = true,
  relations = {
    {'members', has_many = 'ContractUsers'}
  },
  validations = {},
  is_active = function ()
    return false
  end,
  get_all_members = function ()
    -- TODO: load User models.
  end
})

package.loaded.ContractUsers = Model:extend('contract_users', {
  timestamp = true,
  relations = {
    {'contract', belongs_to = 'Contract'},
    {'user', belongs_to = 'Users'}
  },
  validations = {}
})

package.loaded.Contracts = Contracts
return Contracts
