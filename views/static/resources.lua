-- Snap! Resources
-- ===============
-- This file contains the data rendered on the /learn page.
-- Resources are any kinds of materials that are helpful to learning Snap!
--
-- Routes for all community website pages. We're in the process of starting to
-- transition the whole site to Lua.
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2025 by Bernat Romagosa and Michael Ball
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

local materials = {
    {
    title = "Reference Manual",
    author = 'the Snap! Team',
    url = "https://snap.berkeley.edu/snap/help/SnapManual.pdf",
    language = {"English"},
    type = "documentation",
    level = 'beginner',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Get Coding with Snap!",
    author = 'openSAP',
    url = "https://open.sap.com/courses/snap1",
    language = {"English"},
    type = "course",
    level = 'beginner',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "From Media Computation to Data Science",
    author = 'openSAP',
    url = "https://open.sap.com/courses/snap2",
    language = {"English"},
    type = "course",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "The Beauty and Joy of Computing",
    author = 'UC Berkeley and EDC',
    url = "https://bjc.berkeley.edu/ap-csp/",
    language = {"English", "Spanish"},
    type = "course",
    level = 'High School',
    date = nil,
    description = nil,
    image = nil
  },
    {
    title = "BJC Sparks",
    author = 'UC Berkeley and EDC',
    url = "https://bjc.berkeley.edu/sparks/",
    language = {"English"},
    type = "course",
    level = 'Middle School',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Introduction to Computer Science",
    author = 'Microsoft TEALS',
    url = "https://tealsk12.github.io/introduction-to-computer-science/",
    language = {"English"},
    type = "course",
    level = 'High School',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Learning Modules for Beginners",
    author = "SAP Young Thinkers",
    url = "https://blogs.sap.com/2022/01/13/a-summary-of-snap-learning-modules/",
    language = {"English"},
    type = "documentation",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Algorithmen mit Snap!",
    author = 'ComputingEducation.de',
    url = "https://computingeducation.de/algorithmen-mit-snap/",
    language = {"German"},
    type = "course",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Codierte Kunst",
    author = "Joachim Wedekind",
    url = "http://codiertekunst.joachim-wedekind.de/",
    language = {"German"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "The Coding Book",
    author = "Virginia King, Lee Ryall and Invent the World",
    url = "https://www.hinkler.com.au/the-coding-book",
    language = {"English"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Computer Science with Snap!",
    author = "Eckart Modrow",
    url = "http://ddi-mod.uni-goettingen.de/ComputerScienceWithSnap.pdf",
    language = {"English"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "TUNESCOPE, Creating Digital Music in Snap!",
    author = "Glen Bull, Rachel Gibson, Jo Watts, and N. Rich Nguyen",
    url = "static/doc/TuneScope%20Book.pdf",
    language = {"English"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Stapel, Schlange, Liste, Baum mit Snap!",
    author = "Fritz Hasselhorn",
    url = "static/doc/StapelListeBaum.pdf",
    language = {"German"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Automaten und Grammatiken",
    author = "Fritz Hasselhorn",
    url = "static/doc/AutomatenGrammatiken.pdf",
    language = {"German"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Fehlerkorrigierende und komprimierende Codes mit Snap!",
    author = "Fritz Hasselhorn",
    url = "static/doc/Codierung.pdf",
    language = {"German"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Einführung in die Programmierung mit Snap!",
    author = "Fritz Hasselhorn",
    url = "static/doc/Einf%C3%BChrung%20Programmierung.pdf",
    language = {"German"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  }
}

-- Types metadata table
local types = {
  course = {
    heading = "Courses and Class Materials",
    description = nil
  },
  documentation = {
    heading = "Manuals and Documentation",
    description = nil
  },
  book = {
    heading = "Books",
    description = nil
  }
}

return {
  materials = materials,
  types = types
}
