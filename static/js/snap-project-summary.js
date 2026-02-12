/**
 * Snap! Project Summary Generator
 *
 * A standalone library for generating HTML summaries from Snap! project XML files.
 * Extracted and adapted from Snap! IDE (gui.js, xml.js)
 *
 * Original code by Jens Mönig
 * Adapted for Snap!Cloud by Snap!Cloud team
 *
 * Copyright (C) 2020 by Jens Mönig
 * Licensed under GNU Affero General Public License v3
 */

(function(global) {
    'use strict';

    // ============================================
    // XML_Element - Simple XML DOM
    // ============================================

    function XML_Element(tag, contents, parent) {
        this.tag = tag || 'unnamed';
        this.attributes = {};
        this.contents = contents || '';
        this.children = [];
        this.parent = null;

        if (parent) {
            this.parent = parent;
            parent.children.push(this);
        }
    }

    XML_Element.prototype.escape = function(string, ignoreQuotes) {
        var src = (string === null || string === undefined) ? '' : string.toString();
        var result = '';
        for (var i = 0; i < src.length; i++) {
            var ch = src[i];
            switch (ch) {
                case "'":
                    result += '&apos;';
                    break;
                case '"':
                    result += ignoreQuotes ? ch : '&quot;';
                    break;
                case '<':
                    result += '&lt;';
                    break;
                case '>':
                    result += '&gt;';
                    break;
                case '&':
                    result += '&amp;';
                    break;
                case '\n':
                    result += '&#xD;';
                    break;
                case '~':
                    result += '&#126;';
                    break;
                default:
                    result += ch;
            }
        }
        return result;
    };

    XML_Element.prototype.toString = function(isFormatted, indentationLevel) {
        var result = '';
        var indent = '';
        var level = indentationLevel || 0;

        // Indentation
        if (isFormatted) {
            for (var i = 0; i < level; i++) {
                indent += '  ';
            }
            result += indent;
        }

        // Opening tag
        result += '<' + this.tag;

        // Attributes
        for (var key in this.attributes) {
            if (this.attributes.hasOwnProperty(key) && this.attributes[key]) {
                result += ' ' + key + '="' + this.escape(this.attributes[key]) + '"';
            }
        }

        // Contents and closing tag
        if (!this.contents.length && !this.children.length) {
            result += '/>';
        } else {
            result += '>';
            result += this.escape(this.contents);
            for (var j = 0; j < this.children.length; j++) {
                if (isFormatted) {
                    result += '\n';
                }
                result += this.children[j].toString(isFormatted, level + 1);
            }
            if (isFormatted && this.children.length) {
                result += '\n' + indent;
            }
            result += '</' + this.tag + '>';
        }
        return result;
    };

    // ============================================
    // Project Summary Generator
    // ============================================

    var SnapProjectSummary = {

        /**
         * Generate HTML summary from project XML data
         * @param {Object} projectData - Object containing project information
         * @param {string} projectData.xml - The project XML string
         * @param {string} projectData.name - Project name
         * @param {string} projectData.username - Project author
         * @param {string} projectData.notes - Project notes
         * @param {string} projectData.thumbnail - Project thumbnail URL
         * @param {Object} options - Generation options
         * @param {boolean} options.useDropShadows - Add drop shadows to images
         * @returns {string} HTML string
         */
        generate: function(projectData, options) {
            options = options || {};
            var useDropShadows = options.useDropShadows || false;

            var html, head, meta, css, body;
            var pname = projectData.name || 'untitled';
            var notes = projectData.notes || '';
            var username = projectData.username || '';

            // Helper functions
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

            // Build HTML structure
            html = new XML_Element('html');
            html.attributes.lang = 'en';

            head = addNode('head', html);

            meta = addNode('meta', head);
            meta.attributes.charset = 'UTF-8';

            // Add viewport meta for responsive display
            var viewport = addNode('meta', head);
            viewport.attributes.name = 'viewport';
            viewport.attributes.content = 'width=device-width, initial-scale=1.0';

            // CSS styles
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

            // Add print-specific CSS
            css += '@media print {' +
                'body { margin: 0; padding: 20px; }' +
                'h1, h2, h3, h4 { page-break-after: avoid; }' +
                'img { page-break-inside: avoid; max-width: 100%; }' +
                '.no-print { display: none !important; }' +
                'hr { page-break-after: always; border: 0; height: 0; margin: 0; }' +
                '@page { margin: 1cm; }' +
                '}' +
                'body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }' +
                'h1 { color: #333; }' +
                'h2 { color: #555; margin-top: 30px; border-bottom: 2px solid #ddd; padding-bottom: 5px; }' +
                'h3 { color: #666; margin-top: 20px; }' +
                'h4 { color: #777; }' +
                '.script { margin: 10px 0; }';

            addNode('style', head, css);
            add(pname, 'title', head);

            body = addNode('body', html);

            // Project title
            add(pname, 'h1');

            // Author
            if (username) {
                add('by ' + username, 'h4');
            }

            // Thumbnail
            if (projectData.thumbnail) {
                var thumb = addImage(projectData.thumbnail, body, false, 'sprite');
            }

            // Project notes
            if (notes) {
                var noteLines = notes.split('\n');
                for (var i = 0; i < noteLines.length; i++) {
                    if (noteLines[i].trim()) {
                        add(noteLines[i]);
                    }
                }
            }

            // Note about detailed rendering
            add('Note: This is a basic project summary. For detailed sprite information, scripts, and custom blocks, please open the project in Snap!', 'p');
            add('Project XML data is available below for programmatic access.', 'p');

            // Add XML data in a collapsible section
            if (projectData.xml) {
                add('Project XML Data', 'h2');
                var pre = addNode('pre', body);
                var code = addNode('code', pre);
                code.contents = projectData.xml.substring(0, 1000) + '...';
                add('(Truncated for display. Full XML is loaded in the page.)', 'p');
            }

            return '<!DOCTYPE html>' + html.toString();
        },

        /**
         * Render the summary to a DOM element
         * @param {HTMLElement} container - Container element to render into
         * @param {Object} projectData - Project data (see generate method)
         * @param {Object} options - Generation options
         */
        renderTo: function(container, projectData, options) {
            var html = this.generate(projectData, options);

            // Parse and inject only the body content to preserve page structure
            var parser = new DOMParser();
            var doc = parser.parseFromString(html, 'text/html');
            var bodyContent = doc.body.innerHTML;

            container.innerHTML = bodyContent;
        }
    };

    // Export to global scope
    global.SnapProjectSummary = SnapProjectSummary;
    global.XML_Element = XML_Element;

})(typeof window !== 'undefined' ? window : global);
