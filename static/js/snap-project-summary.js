/**
 * Snap! Project Summary Generator
 *
 * Adapted from Snap! IDE's exportProjectSummary function (gui.js)
 * Uses snap-xml.js for XML parsing
 *
 * Original code by Jens Mönig - Copyright (C) 2020
 * Adapted for Snap!Cloud
 * Licensed under GNU Affero General Public License v3
 *
 * This library parses Snap! project XML and generates HTML summaries
 * that match the format produced by the Snap! IDE.
 */

(function(global) {
    'use strict';

    // Ensure XML_Element is available (loaded from snap-xml.js)
    if (typeof global.XML_Element === 'undefined') {
        console.error('snap-xml.js must be loaded before snap-project-summary.js');
        return;
    }

    var SnapProjectSummary = {

        /**
         * Configuration options for summary generation
         */
        config: {
            // Whether to include drop shadows on images
            useDropShadows: false,
            // Localization function (can be overridden)
            localize: function(key) {
                var translations = {
                    'untitled': 'untitled',
                    'by ': 'by ',
                    'Contents': 'Contents',
                    'Variables': 'Variables',
                    'Blocks': 'Blocks',
                    'Costumes': 'Costumes',
                    'Sounds': 'Sounds',
                    'Scripts': 'Scripts',
                    'For all Sprites': 'For all Sprites',
                    'Kind of': 'Kind of',
                    'Part of': 'Part of',
                    'Parts': 'Parts'
                };
                return translations[key] || key;
            },
            // App version string
            appVersion: 'Snap! 10'
        },

        /**
         * Generate HTML summary from project XML
         * @param {Object} projectData - Object containing project information
         * @param {string} projectData.xml - The project XML string
         * @param {string} projectData.name - Project name (optional, extracted from XML if not provided)
         * @param {string} projectData.notes - Project notes (optional, extracted from XML if not provided)
         * @param {string} projectData.thumbnail - Project thumbnail URL (optional)
         * @param {Object} options - Generation options
         * @param {boolean} options.useDropShadows - Add drop shadows to images
         * @returns {string} HTML string
         */
        generate: function(projectData, options) {
            options = options || {};
            var useDropShadows = options.useDropShadows || this.config.useDropShadows;
            var localize = options.localize || this.config.localize;

            // Parse the project XML
            var projectXML = new XML_Element();
            projectXML.parseString(projectData.xml);

            // Extract project information from XML
            var project = projectXML.childNamed('project');
            if (!project) {
                throw new Error('Invalid project XML: missing <project> element');
            }

            var pname = projectData.name || project.childNamed('name');
            if (pname && pname.contents) {
                pname = pname.contents;
            } else {
                pname = localize('untitled');
            }

            var notes = projectData.notes || '';
            var notesElement = project.childNamed('notes');
            if (!notes && notesElement && notesElement.contents) {
                notes = notesElement.contents;
            }

            var thumbnailData = projectData.thumbnail || '';
            var thumbnailElement = project.childNamed('thumbnail');
            if (!thumbnailData && thumbnailElement && thumbnailElement.contents) {
                thumbnailData = thumbnailElement.contents;
            }

            // Build HTML structure using XML_Element
            var html, head, meta, css, body;

            function addNode(tag, node, contents) {
                if (!node) { node = body; }
                return new XML_Element(tag, contents, node);
            }

            function add(contents, tag, node) {
                if (!tag) { tag = 'p'; }
                if (!node) { node = body; }
                return new XML_Element(tag, contents, node);
            }

            function addImage(src, node, inline, cssClass) {
                if (!node) { node = body; }
                var para = !inline ? addNode('p', node) : null;
                var pic = addNode('img', para || node);
                pic.attributes.src = src;
                if (cssClass) {
                    pic.attributes.class = cssClass;
                }
                return pic;
            }

            // Create HTML document
            html = new XML_Element('html');
            html.attributes.lang = 'en';

            head = addNode('head', html);

            meta = addNode('meta', head);
            meta.attributes.charset = 'UTF-8';

            // CSS styles (from Snap! gui.js exportProjectSummary)
            if (useDropShadows) {
                css = 'img {' +
                    'vertical-align: top;' +
                    'filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.5));' +
                    '-webkit-filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.5));' +
                    '-ms-filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.5));' +
                    '}' +
                    '.toc {' +
                    'vertical-align: middle;' +
                    'padding: 2px 1em 2px 1em;' +
                    '}';
            } else {
                css = 'img {' +
                    'vertical-align: top;' +
                    '}' +
                    '.toc {' +
                    'vertical-align: middle;' +
                    'padding: 2px 1em 2px 1em;' +
                    '}' +
                    '.sprite {' +
                    'border: 1px solid lightgray;' +
                    '}';
            }

            addNode('style', head, css);
            add(pname, 'title', head);

            body = addNode('body', html);

            // Project title
            add(pname, 'h1');

            // App version
            add(this.config.appVersion, 'h4');

            // Thumbnail (if available)
            if (thumbnailData) {
                var thumb = addImage(thumbnailData, body, false);
                thumb.attributes.class = 'sprite';
            }

            // Project notes
            if (notes) {
                var noteLines = notes.split('\n');
                noteLines.forEach(function(line) {
                    if (line.trim()) {
                        add(line);
                    }
                });
            }

            // Table of contents
            add(localize('Contents'), 'h4');
            var toc = addNode('ul');

            // Parse and display sprites from XML
            var stage = project.childNamed('stage');
            if (stage) {
                this._processStageOrSprite(stage, body, toc, addNode, add, addImage, localize, thumbnailData, true);
            }

            // Process sprites
            var sprites = project.childNamed('sprites');
            if (sprites) {
                var spriteElements = sprites.childrenNamed('sprite');
                spriteElements.forEach(function(sprite) {
                    this._processStageOrSprite(sprite, body, toc, addNode, add, addImage, localize, thumbnailData, false);
                }.bind(this));
            }

            // Global variables and blocks
            if (stage) {
                var globalVars = stage.childNamed('variables');
                var globalBlocks = stage.childNamed('blocks');

                if ((globalVars && globalVars.children.length > 0) ||
                    (globalBlocks && globalBlocks.children.length > 0)) {

                    addNode('hr');
                    var globalLink = add(localize('For all Sprites'), 'a', addNode('li', toc));
                    globalLink.attributes.href = '#global';

                    var globalHeader = add(localize('For all Sprites'), 'h2');
                    globalHeader.attributes.id = 'global';

                    // Global variables
                    if (globalVars && globalVars.children.length > 0) {
                        this._addVariables(globalVars, body, add, addNode, localize);
                    }

                    // Global custom blocks
                    if (globalBlocks && globalBlocks.children.length > 0) {
                        this._addBlocks(globalBlocks, body, add, addNode, localize);
                    }
                }
            }

            return '<!DOCTYPE html>' + html.toString();
        },

        /**
         * Process a stage or sprite element
         * @private
         */
        _processStageOrSprite: function(element, body, toc, addNode, add, addImage, localize, thumbnailData, isStage) {
            var name = element.childNamed('name');
            var spriteName = name ? name.contents : (isStage ? 'Stage' : 'Sprite');

            // Add to table of contents
            addNode('hr');
            var tocEntry = addNode('li', toc);
            var tocLink = add(spriteName, 'a', tocEntry);
            tocLink.attributes.href = '#' + spriteName;

            // Sprite/Stage heading
            var heading = add(spriteName, 'h2');
            heading.attributes.id = spriteName;

            // Note: Full sprite rendering (thumbnail, costumes, sounds) would require
            // canvas rendering which we can't do without the full Snap! morphic system.
            // For now, we show structure without visual renders.

            // Scripts
            var scripts = element.childNamed('scripts');
            if (scripts && scripts.children.length > 0) {
                add(localize('Scripts'), 'h3');
                add('(' + scripts.children.length + ' script blocks)', 'p');
                // Note: Actual script rendering would require BlockMorph.scriptPic()
            }

            // Costumes
            var costumes = element.childNamed('costumes');
            if (costumes && costumes.children.length > 0) {
                add(localize('Costumes'), 'h3');
                var costumeList = addNode('ol');
                costumes.children.forEach(function(costume) {
                    var costumeName = costume.childNamed('name');
                    if (costumeName && costumeName.contents) {
                        add(costumeName.contents, 'li', costumeList);
                    }
                });
            }

            // Sounds
            var sounds = element.childNamed('sounds');
            if (sounds && sounds.children.length > 0) {
                add(localize('Sounds'), 'h3');
                var soundList = addNode('ol');
                sounds.children.forEach(function(sound) {
                    var soundName = sound.childNamed('name');
                    if (soundName && soundName.contents) {
                        add(soundName.contents, 'li', soundList);
                    }
                });
            }

            // Variables
            var variables = element.childNamed('variables');
            if (variables && variables.children.length > 0) {
                this._addVariables(variables, body, add, addNode, localize);
            }

            // Custom blocks
            var blocks = element.childNamed('blocks');
            if (blocks && blocks.children.length > 0) {
                this._addBlocks(blocks, body, add, addNode, localize);
            }
        },

        /**
         * Add variables section
         * @private
         */
        _addVariables: function(variablesElement, body, add, addNode, localize) {
            if (!variablesElement || variablesElement.children.length === 0) {
                return;
            }

            add(localize('Variables'), 'h3');
            var varList = addNode('ul');

            variablesElement.children.forEach(function(varElement) {
                var varName = varElement.childNamed('name') || varElement.attributes.name;
                if (varName) {
                    if (typeof varName === 'object' && varName.contents) {
                        varName = varName.contents;
                    }
                    add(varName, 'li', varList);
                }
            });
        },

        /**
         * Add custom blocks section
         * @private
         */
        _addBlocks: function(blocksElement, body, add, addNode, localize) {
            if (!blocksElement || blocksElement.children.length === 0) {
                return;
            }

            add(localize('Blocks'), 'h3');
            var blockList = addNode('ul');

            blocksElement.children.forEach(function(blockElement) {
                var blockSpec = blockElement.childNamed('spec');
                if (blockSpec && blockSpec.contents) {
                    add(blockSpec.contents, 'li', blockList);
                }
            });
        },

        /**
         * Render the summary to a DOM element
         * @param {HTMLElement} container - Container element to render into
         * @param {Object} projectData - Project data (see generate method)
         * @param {Object} options - Generation options
         */
        renderTo: function(container, projectData, options) {
            try {
                var html = this.generate(projectData, options);

                // Parse and inject only the body content to preserve page structure
                var parser = new DOMParser();
                var doc = parser.parseFromString(html, 'text/html');
                var bodyContent = doc.body.innerHTML;

                container.innerHTML = bodyContent;
            } catch (error) {
                console.error('Error generating summary:', error);
                container.innerHTML = '<div class="project-summary-error">' +
                    '<h2>Error Generating Summary</h2>' +
                    '<p>There was an error generating the project summary: ' +
                    error.message + '</p>' +
                    '</div>';
            }
        }
    };

    // Export to global scope
    global.SnapProjectSummary = SnapProjectSummary;

})(typeof window !== 'undefined' ? window : global);
