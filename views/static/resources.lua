-- Snap!Cloud Learner Resources
-- ============================
-- This file contains the data rendered on the /learn page.
-- Resources are any kinds of materials that are helpful to learning Snap<em>!</em>
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
    author = 'the Snap<em>!</em> Team',
    url = "https://docs.snap.berkeley.edu/",
    language = {"English"},
    type = "documentation",
    level = 'everyone',
    date = '2026',
    description = 'An online version of the Snap! manual',
    image = nil
  },
  {
    title = "Reference Manual (PDF)",
    author = 'the Snap<em>!</em> Team',
    url = "https://snap.berkeley.edu/snap/help/SnapManual.pdf",
    language = {"English"},
    type = "documentation",
    level = 'everyone',
    date = '2022',
    description = 'A printable PDF of the Snap! manual. (Last updated for version 8)',
    image = nil
  },
  {
    title = "Get Coding with Snap<em>!</em>",
    author = 'openSAP',
    url = "https://learning.sap.com/learning-journeys/get-coding-with-snap-building-up-to-ai",
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
    url = "https://learning.sap.com/courses/from-media-computation-to-data-science",
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
    url = "https://bjc.berkeley.edu/ap-cs-principles/",
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
    title = "Algorithmen mit Snap<em>!</em>",
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
    isbn = '9781488909924',
    language = {"English"},
    type = "book",
    level = nil,
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Computer Science with Snap<em>!</em>",
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
    title = "Learn CS Concepts With Snap<em>!</em>",
    author = "Abhay B. Joshi",
    url = "http://www.abhayjoshi.net/spark/snap/bsnap.pdf",
    isbn = '9781728921716',
    links = {
      { label = "Website", url = "http://www.abhayjoshi.net/spark/snap.htm" },
      { label = "Bookshop.org", url = "https://bookshop.org/a/124937/9781728921716" },
      { label = "Amazon", url = "https://amzn.com/gp/product/1728921716?tag=calphoto-20" }
    },
    language = {"English"},
    type = "book",
    level = 'everyone',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Practice CS Concepts with Snap<em>!</em>",
    author = "Abhay B. Joshi",
    url = "http://www.abhayjoshi.net/spark/snap/book0s/PracticeWithSnap.pdf",
    isbn = '9781090818812',
    links = {
      { label = "Website", url = "http://www.abhayjoshi.net/spark/snap.htm" },
      { label = "Amazon", url = "https://amzn.com/gp/product/1090818815?tag=calphoto-20" }
    },
    language = {"English"},
    type = "book",
    level = 'everyone',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Pen Art in Snap<em>!</em> Programming",
    author = "Abhay B. Joshi, Sandesh R Gaikwad",
    url = "http://www.abhayjoshi.net/spark/snap/psnap.pdf",
    isbn = '9781093754711',
    links = {
      { label = "Website", url = "http://www.abhayjoshi.net/spark/snap.htm" },
      { label = "Bookshop.org", url = "https://bookshop.org/a/124937/9781093754711" },
      { label = "Amazon", url = "https://amzn.com/gp/product/1093754710/?tag=calphoto-20" }
    },
    language = {"English"},
    type = "book",
    level = 'everyone',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Adventures in Snap<em>!</em> Programming",
    author = "Abhay B. Joshi",
    url = "http://www.abhayjoshi.net/spark/snap.htm",
    isbn = '9798551045519',
    links = {
      { label = "Bookshop.org", url = "https://bookshop.org/a/124937/9798551045519" },
      { label = "Amazon", url = "https://amzn.com/gp/product/B08LQYLVLV?tag=calphoto-20" }
    },
    language = {"English"},
    type = "book",
    level = 'everyone',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "Learn Python in a Snap<em>!</em>",
    author = "Abhay B. Joshi",
    url = "http://www.abhayjoshi.net/spark/python/pythonsnap.pdf",
    isbn = '9798502337588',
    links = {
      { label = "Website", url = "http://www.abhayjoshi.net/spark/python_page.htm" },
      { label = "Bookshop.org", url = "https://bookshop.org/a/124937/9798502337588" },
      { label = "Amazon", url = "https://amzn.com/gp/product/B094ZQ1J62?tag=calphoto-20" }
    },
    language = {"English"},
    type = "book",
    level = 'everyone',
    date = nil,
    description = nil,
    image = nil
  },
  {
    title = "TUNESCOPE, Creating Digital Music in Snap<em>!</em>",
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
    title = "Stapel, Schlange, Liste, Baum mit Snap<em>!</em>",
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
    title = "Fehlerkorrigierende und komprimierende Codes mit Snap<em>!</em>",
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
    title = "Einführung in die Programmierung mit Snap<em>!</em>",
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
