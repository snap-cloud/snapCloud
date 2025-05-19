-- CORS module
-- ==========
--
-- A list of allowed domains that we support.
--
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local domain_allowed = {}
domain_allowed['snap.berkeley.edu'] = true
-- This domain serves an HTTP only Snap! IDE
domain_allowed['extensions.snap.berkeley.edu'] = true

-- Aliases for App Server Domains
-- By Default CORS is not needed on the same domain.
-- However, we want to allow access on http hosted versions of Snap!.
domain_allowed['snap-cloud.cs10.org'] = true
-- App Server Staging Domains
domain_allowed['snap-staging.cs10.org'] = true
domain_allowed['staging.snap.berkeley.edu'] = true
-- Snap! Mirrors
-- CONTACT: Snap! Team
domain_allowed['cs10.org'] = true
domain_allowed['bjc.edc.org'] = true
domain_allowed['web.media.mit.edu'] = true

-- ===========================================================
-- OFFICIALLY ENDORSED 3RD PARTY HOSTS
-- Each "section" of URLs should come with a brief description and a contact.

-- Snap4Arduino, and its Chromebook version
-- CONTACT:
domain_allowed['snap4arduino.rocks'] = true
domain_allowed['chrome-extension://bdmapaboflkhdmcgdpfooeeeadejodia'] = true
domain_allowed['chrome-extension://ghipaghphhpfncbokoobcjlapbnceipg'] = true

-- UC Berkeley Sites Things:
-- CONTACT: Michael Ball
domain_allowed['cbt-dev.berkeley.edu'] = true
domain_allowed['bjc.berkeley.edu'] = true
-- Snap! Research Projects
-- CONTACT: Thomas Price
domain_allowed['isnap.csc.ncsu.edu'] = true
domain_allowed['eliza.csc.ncsu.edu'] = true
domain_allowed['arena.csc.ncsu.edu'] = true
domain_allowed['snapapps.fi.ncsu.edu'] = true
-- CONTACT Saminur Islam <sislam8@ncsu.edu>,, Tiffany Barnes <tmbarnes@ncsu.edu>,, Veronica Catete <vmcatete@ncsu.edu>, Ally Limke <anlimke@ncsu.edu>
domain_allowed['lin-class17.csc.ncsu.edu'] = true

-- CONTACT: Ken Khan
domain_allowed['ecraft2learn.github.io'] = true
-- CONTACT:
domain_allowed['microworld.edc.org'] = true

-- All edX Sites, and test sites
-- CONTACT: Michael Ball
-- domain_allowed['courses.edge.edx.org'] = true
-- domain_allowed['courses.edx.org'] = true
-- domain_allowed['d37djvu3ytnwxt.cloudfront.net'] = true
-- domain_allowed['preview.courses.edge.edx.org'] = true
-- domain_allowed['preview.courses.edx.org'] = true
-- domain_allowed['preview.edge.edx.org'] = true
-- domain_allowed['preview.edx.org'] = true
-- domain_allowed['studio.edge.edx.org'] = true
-- domain_allowed['studio.edx.org'] = true
-- domain_allowed['edge.edx.org'] = true

-- SoundScope Sites
-- CONTACT:
domain_allowed['soundscope-website-beta.s3.amazonaws.com/index.html'] = true
domain_allowed['soundscope-website-beta.s3.amazonaws.com'] = true
domain_allowed['soundscope-website.web.app'] = true
domain_allowed['tunescope.org'] = true
domain_allowed['beta.tunescope.org'] = true
domain_allowed['soundscope-website.firebaseapp.com'] = true
domain_allowed['tune-scope.web.app'] = true
domain_allowed['tune-scope.firebaseapp.com'] = true
domain_allowed['alpha-tunescope.web.app'] = true
domain_allowed['alpha-tunescope.firebaseapp.com'] = true
domain_allowed['alpha.tunescope.org'] = true
-- TensorSnap Sites
-- CONTACT:
domain_allowed['tensor-snap.web.app'] = true
domain_allowed['tensor-snap.firebaseapp.com'] = true

-- CONTACT:
domain_allowed['www.maketolearn.org'] = true
-- CONTACT:
domain_allowed['snap.techlit.org'] = true
domain_allowed['bjc.techlit.org'] = true

-- CONTACT:
domain_allowed['amazingrobots.net'] = true
-- CONTACT: Bernat
domain_allowed['microblocks.fun'] = true

-- StudyGiggle
-- CONTACT: Ben S <bfrstudios.apps@gmail.com>
domain_allowed['studygiggle.onrender.com'] = true

-- Development
-- CONTACT: Snap! Team
domain_allowed['localhost'] = true
domain_allowed['jmoenig.github.io'] = true

return domain_allowed
