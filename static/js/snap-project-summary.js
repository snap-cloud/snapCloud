/**
 * Snap! Project Summary Generator
 *
 * Loads necessary Snap! components to generate full project summaries
 * with rendered blocks, sprites, and all visual elements.
 *
 * Uses actual Snap! source code from /snap/src/ for perfect compatibility.
 *
 * Original Snap! code by Jens Mönig - Copyright (C) 2020
 * Adapted for Snap!Cloud
 * Licensed under GNU Affero General Public License v3
 */

(function(global) {
    'use strict';

    var SnapProjectSummary = {

        /**
         * Configuration for summary generation
         * Can be modified before calling generate() to customize appearance
         */
        config: {
            // Visual settings
            useDropShadows: false,          // Add drop shadows to block images
            blockZoom: 1.0,                  // Scale factor for block rendering (0.5 to 2.0)
            fadeBlocks: 0,                   // Fade amount for blocks (0 = no fade, 100 = fully faded)

            // Content settings
            showScripts: true,               // Render script images
            showCostumes: true,              // Show costume thumbnails
            showSounds: true,                // Show sound listings
            showVariables: true,             // Show variables
            showCustomBlocks: true,          // Show custom block definitions

            // Rendering settings
            maxScriptWidth: 800,             // Maximum width for script images
            thumbnailSize: 40,               // Size for small thumbnails in TOC

            // App info
            appVersion: 'Snap! 10',

            // Localization
            locale: {
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
            },

            // Advanced: customize which categories to show
            blockCategories: null  // null = all, or array like ['motion', 'looks', 'sound']
        },

        // Internal state
        _snapLoaded: false,
        _snapIDE: null,
        _loadCallbacks: [],

        /**
         * Load Snap! IDE components for rendering
         * @param {Function} callback - Called when Snap! is ready
         */
        loadSnap: function(callback) {
            if (this._snapLoaded && this._snapIDE) {
                callback(null, this._snapIDE);
                return;
            }

            this._loadCallbacks.push(callback);

            // If already loading, just queue the callback
            if (this._loadCallbacks.length > 1) {
                return;
            }

            // Create hidden canvas for Snap! world
            var worldCanvas = document.createElement('canvas');
            worldCanvas.id = 'snap-summary-world';
            worldCanvas.width = 1;
            worldCanvas.height = 1;
            worldCanvas.style.position = 'absolute';
            worldCanvas.style.left = '-9999px';
            worldCanvas.style.visibility = 'hidden';
            document.body.appendChild(worldCanvas);

            // Load Snap! scripts in order
            var snapPath = '/snap/src/';
            var scripts = [
                'morphic.js',
                'symbols.js',
                'widgets.js',
                'blocks.js',
                'threads.js',
                'objects.js',
                'scenes.js',
                'gui.js',
                'paint.js',
                'lists.js',
                'byob.js',
                'tables.js',
                'sketch.js',
                'video.js',
                'maps.js',
                'extensions.js',
                'xml.js',
                'store.js',
                'locale.js'
            ];

            var loadedScripts = 0;
            var self = this;

            function loadScript(src, callback) {
                var script = document.createElement('script');
                script.src = src;
                script.onload = callback;
                script.onerror = function() {
                    callback(new Error('Failed to load ' + src));
                };
                document.head.appendChild(script);
            }

            function loadNext() {
                if (loadedScripts >= scripts.length) {
                    // All scripts loaded, initialize Snap!
                    self._initializeSnap();
                    return;
                }

                var scriptSrc = snapPath + scripts[loadedScripts];
                loadedScripts++;
                loadScript(scriptSrc, function(err) {
                    if (err) {
                        self._notifyCallbacks(err);
                        return;
                    }
                    loadNext();
                });
            }

            loadNext();
        },

        /**
         * Initialize Snap! IDE in hidden mode
         * @private
         */
        _initializeSnap: function() {
            var self = this;
            try {
                // Create world
                var canvas = document.getElementById('snap-summary-world');
                global.world = new WorldMorph(canvas);

                // Create IDE but don't show it
                this._snapIDE = new IDE_Morph();
                this._snapIDE.setUnpixelated(true);
                this._snapIDE.openIn(world);

                // Wait for IDE to be fully initialized
                setTimeout(function() {
                    self._snapLoaded = true;
                    self._notifyCallbacks(null, self._snapIDE);
                }, 500);
            } catch (e) {
                this._notifyCallbacks(e);
            }
        },

        /**
         * Notify all waiting callbacks
         * @private
         */
        _notifyCallbacks: function(err, ide) {
            while (this._loadCallbacks.length > 0) {
                var cb = this._loadCallbacks.shift();
                cb(err, ide);
            }
        },

        /**
         * Generate HTML summary using Snap! IDE's exportProjectSummary
         * @param {Object} projectData - Object containing project information
         * @param {string} projectData.xml - The project XML string
         * @param {Object} options - Override default config options
         * @returns {Promise<string>} HTML string
         */
        generate: function(projectData, options) {
            var self = this;
            options = options || {};

            return new Promise(function(resolve, reject) {
                self.loadSnap(function(err, ide) {
                    if (err) {
                        reject(err);
                        return;
                    }

                    try {
                        // Load project into Snap!
                        ide.rawOpenProjectString(projectData.xml);

                        // Wait for project to fully load
                        setTimeout(function() {
                            try {
                                // Apply configuration
                                var useDropShadows = options.useDropShadows !== undefined ?
                                    options.useDropShadows : self.config.useDropShadows;

                                // Capture the HTML output
                                var originalSaveFileAs = ide.saveFileAs;
                                var summaryHTML = null;

                                ide.saveFileAs = function(content, mimeType, fileName) {
                                    summaryHTML = content;
                                };

                                // Generate summary using Snap!'s native function
                                ide.exportProjectSummary(useDropShadows);

                                // Restore
                                ide.saveFileAs = originalSaveFileAs;

                                if (summaryHTML) {
                                    // Post-process HTML to apply configuration
                                    summaryHTML = self._applyConfig(summaryHTML, options);
                                    resolve(summaryHTML);
                                } else {
                                    reject(new Error('Failed to generate summary HTML'));
                                }
                            } catch (e) {
                                reject(e);
                            }
                        }, 1500); // Give more time for complex projects
                    } catch (e) {
                        reject(e);
                    }
                });
            });
        },

        /**
         * Apply configuration settings to generated HTML
         * @private
         */
        _applyConfig: function(html, options) {
            var config = Object.assign({}, this.config, options);

            // Parse HTML
            var doc = new DOMParser().parseFromString(html, 'text/html');

            // Apply block zoom
            if (config.blockZoom !== 1.0) {
                var style = doc.createElement('style');
                style.textContent = '.script img { transform: scale(' + config.blockZoom + '); transform-origin: top left; }';
                doc.head.appendChild(style);
            }

            // Apply block fade
            if (config.fadeBlocks > 0) {
                var style = doc.createElement('style');
                var opacity = 1.0 - (config.fadeBlocks / 100);
                style.textContent = '.script img { opacity: ' + opacity + '; }';
                doc.head.appendChild(style);
            }

            // Add configuration info as comment
            var comment = doc.createComment('Generated with config: ' + JSON.stringify({
                useDropShadows: config.useDropShadows,
                blockZoom: config.blockZoom,
                fadeBlocks: config.fadeBlocks
            }));
            doc.body.insertBefore(comment, doc.body.firstChild);

            return '<!DOCTYPE html>' + doc.documentElement.outerHTML;
        },

        /**
         * Render the summary to a DOM element
         * @param {HTMLElement} container - Container element to render into
         * @param {Object} projectData - Project data
         * @param {Object} options - Generation options
         */
        renderTo: function(container, projectData, options) {
            var self = this;
            container.innerHTML = '<div class="project-summary-loading">Loading Snap! and generating project summary...<br><small>This may take a few moments on first load.</small></div>';

            this.generate(projectData, options)
                .then(function(html) {
                    // Parse and inject body content
                    var parser = new DOMParser();
                    var doc = parser.parseFromString(html, 'text/html');
                    container.innerHTML = doc.body.innerHTML;
                })
                .catch(function(error) {
                    console.error('Error generating summary:', error);
                    container.innerHTML = '<div class="project-summary-error">' +
                        '<h2>Error Generating Summary</h2>' +
                        '<p>There was an error generating the project summary: ' +
                        error.message + '</p>' +
                        '<p>Please try refreshing the page or <a href="javascript:history.back()">go back</a>.</p>' +
                        '</div>';
                });
        },

        /**
         * Preset configurations for common use cases
         */
        presets: {
            // Full detail with large blocks
            detailed: {
                useDropShadows: true,
                blockZoom: 1.2,
                fadeBlocks: 0,
                showScripts: true,
                showCostumes: true,
                showSounds: true,
                showVariables: true,
                showCustomBlocks: true
            },

            // Compact view with smaller blocks
            compact: {
                useDropShadows: false,
                blockZoom: 0.7,
                fadeBlocks: 0,
                showScripts: true,
                showCostumes: true,
                showSounds: true,
                showVariables: true,
                showCustomBlocks: true
            },

            // Overview only (minimal detail)
            overview: {
                useDropShadows: false,
                blockZoom: 0.5,
                fadeBlocks: 30,
                showScripts: false,
                showCostumes: false,
                showSounds: false,
                showVariables: true,
                showCustomBlocks: false
            },

            // Print-optimized (no shadows, medium size)
            print: {
                useDropShadows: false,
                blockZoom: 0.9,
                fadeBlocks: 0,
                showScripts: true,
                showCostumes: true,
                showSounds: true,
                showVariables: true,
                showCustomBlocks: true
            }
        },

        /**
         * Apply a preset configuration
         * @param {string} presetName - Name of preset ('detailed', 'compact', 'overview', 'print')
         */
        applyPreset: function(presetName) {
            if (this.presets[presetName]) {
                Object.assign(this.config, this.presets[presetName]);
            }
        }
    };

    // Export to global scope
    global.SnapProjectSummary = SnapProjectSummary;

})(typeof window !== 'undefined' ? window : global);
