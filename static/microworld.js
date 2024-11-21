/*
    MicroWorlds for Snap!
    =====================

    A hacked together library to create Snap! microworlds.

    Copyright (C) 2020  Bernat Romagosa <bernat@romagosa.work>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

*/

function MicroWorld (ide, sprite) {
    return this.init(ide, sprite);
};

MicroWorld.prototype.init = function (ide, sprite) {
    this.ide = ide;
    this.sprite = sprite;
    this.isSetup = false;
    this.stacks = [];
    this.comments = [];
};

MicroWorld.prototype.setup = function () {
    var ide = this.ide;

    // prevent setup script from running again
    this.isSetup = true;

    // enter MicroWorld, which also hides setup script
    if (!ide.microWorldMode) { ide.enterMicroWorld(); }
};

MicroWorld.prototype.setupLogoMenu = function () {
    ide = this.ide;
    ide.logo.userMenu = function () {
        var menu = new MenuMorph(ide);
        if (ide.microWorldMode) {
            menu.addItem(
                'Escape microworld',
                function () { ide.escapeMicroWorld(); }
            );
        } else {
            menu.addItem(
                'Enter microworld',
                function () { ide.enterMicroWorld(); }
            );
        }
        return menu;
    };
};

MicroWorld.prototype.whenEnteringDo = function (body) {
    var sprite = this.sprite,
        ide = this.ide;

    this.comments = sprite.scripts.children.filter(
        function (child) {
            return child instanceof CommentMorph &&
                child.contents.text == 'hide me';
        }
    );
    this.stacks = this.comments.map(
        function (comment) { return comment.block }
    );

    sprite.searchButton = false;

    ide.enterMicroWorld = function () {
        ide.microWorldMode = true;

        // run all blocks in body
        invoke(
            body.expression,  // block
            null,             // contextArgs
            sprite            // receiver
        );

        // overwrite StageMorph >> destroy to get out of the MicroWorld
        // this method is called anytime we open a project or create a new one
        ide.stage.destroy = function () {
            SyntaxElementMorph.prototype.setScale(
                SyntaxElementMorph.prototype.oldScale);
            if (ide.microWorldMode) {
                ide.escapeMicroWorld();
            }
            StageMorph.uber.destroy.call(this);
        };
    };
};

MicroWorld.prototype.whenEscapingDo = function (body) {
    var sprite = this.sprite,
        ide = this.ide;
    this.ide.escapeMicroWorld = function () {
        ide.microWorldMode = false;
        // run all blocks in body
        invoke(
            body.expression,  // block
            null,             // contextArgs
            sprite            // receiver
        );
    };
};

MicroWorld.prototype.setBlocksScale = function (zoom) {
    // !!! EXPERIMENTAL !!!
    SyntaxElementMorph.prototype.oldScale = SyntaxElementMorph.prototype.scale;
    SyntaxElementMorph.prototype.setScale(zoom);
    CommentMorph.prototype.refreshScale();
    this.ide.sprites.asArray().concat([ ide.stage ]).forEach(
        function (each) {
            each.blocksCache = {};
            each.paletteCache = {}
            each.scripts.forAllChildren(function (child) {
                if (child.setScale) {
                    child.setScale(zoom);
                    child.drawNew();
                    child.changed();
                    child.fixLayout();
                } else if (child.fontSize) {
                    child.fontSize = 10 * zoom;
                    child.drawNew();
                    child.changed();
                } else if (child instanceof SymbolMorph) {
                    child.size = zoom * 12;
                    child.drawNew();
                    child.changed();
                }
            });
        }
    );
};

MicroWorld.prototype.overrideBlockMenu = function () {
    var ide = this.ide,
        sprite = this.sprite;
    if (!BlockMorph.prototype.oldUserMenu) {
        BlockMorph.prototype.oldUserMenu = BlockMorph.prototype.userMenu;
        BlockMorph.prototype.userMenu = function () {
            if (ide.microWorldMode) {
                var menu = new MenuMorph(this),
                    world = this.world(),
                    myself = this,
                    proc = this.activeProcess();

                menu.addItem(
                    "help...",
                    'showHelp'
                );

                if (this.isTemplate) { return menu }

                if (this instanceof CustomCommandBlockMorph ||
                        this instanceof CustomReporterBlockMorph) {
                    menu.addItem(
                        "delete block definition...",
                        'deleteBlockDefinition'
                    );
                    menu.addItem("edit...", 'edit');
                }

                menu.addLine();

                menu.addItem(
                    "duplicate",
                    function () {
                        var dup = myself.fullCopy(),
                            ide = myself.parentThatIsA(IDE_Morph),
                            blockEditor = myself.parentThatIsA(BlockEditorMorph);
                        dup.pickUp(world);
                        // register the drop-origin, so the block can
                        // slide back to its former situation if dropped
                        // somewhere where it gets rejected
                        if (!ide && blockEditor) {
                            ide = blockEditor.target.parentThatIsA(IDE_Morph);
                        }
                        if (ide) {
                            world.hand.grabOrigin = {
                                origin: ide.palette,
                                position: ide.palette.center()
                            };
                        }
                    },
                    'make a copy\nand pick it up'
                );

                if (this instanceof CommandBlockMorph && this.nextBlock()) {
                    menu.addItem(
                        (proc ? this.fullCopy() : this).thumbnail(0.5, 60),
                        function () {
                            var cpy = myself.fullCopy(),
                                nb = cpy.nextBlock(),
                                ide = myself.parentThatIsA(IDE_Morph),
                                blockEditor = myself.parentThatIsA(BlockEditorMorph);
                            if (nb) {nb.destroy(); }
                            cpy.pickUp(world);
                            if (!ide && blockEditor) {
                                ide = blockEditor.target.parentThatIsA(IDE_Morph);
                            }
                            if (ide) {
                                world.hand.grabOrigin = {
                                    origin: ide.palette,
                                    position: ide.palette.center()
                                };
                            }
                        },
                        'only duplicate this block'
                    );
                }
                menu.addItem(
                    "turn into a block",
                    function () {
                        var target = this.scriptTarget(),
                            topBlock = this;
                        ide.prompt('Block name?', function (name) {
                            var definition = new CustomBlockDefinition(name);
                            if (topBlock instanceof CommandBlockMorph ||
                                topBlock instanceof CustomCommandBlockMorph) {
                                definition.type = 'command';
                                definition.body = Process.prototype.reify.call(
                                    null,
                                    topBlock.fullCopy(),
                                    new List(),
                                    true // ignore empty slots for custom block
                                         // reification
                                );
                            } else if (topBlock instanceof ReporterBlockMorph) {
                                if (topBlock.isPredicate) {
                                    definition.type = 'predicate';
                                } else {
                                    definition.type = 'reporter';
                                }
                                reportBlock =
                                    SpriteMorph.prototype.blockForSelector(
                                        'doReport'
                                    );
                                reportBlock.silentReplaceInput(
                                    reportBlock.inputs()[0],
                                    topBlock.fullCopy()
                                );
                                definition.body = Process.prototype.reify.call(
                                    null,
                                    reportBlock,
                                    new List(),
                                    true // ignore empty slots for custom block
                                         // reification
                                );
                            }
                            definition.category = 'other';
                            definition.isGlobal = true;
                            definition.body.outerContext = null;
                            definition.codeHeader = 'microworld'; // watermark
                            ide.stage.globalBlocks.push(definition);
                            sprite.blocksCache['microworld'].push(
                                definition.templateInstance()
                            );
                            sprite.refreshMicroWorldPalette();
                            sprite.hideSearchButton()
                            editor = new BlockEditorMorph(definition, target);
                            editor.firstTime = true;
                            editor.popUp();
                        });
                    },
                    'turn the block stack starting\nhere into a custom block.'
                );

                return menu;

            } else {
                return this.oldUserMenu();
            }
        };
        CustomReporterBlockMorph.prototype.oldUserMenu =
            CustomReporterBlockMorph.prototype.userMenu;
        CustomCommandBlockMorph.prototype.oldUserMenu =
            CustomCommandBlockMorph.prototype.userMenu;
        CustomCommandBlockMorph.prototype.userMenu =
            BlockMorph.prototype.userMenu;
        CustomReporterBlockMorph.prototype.userMenu =
            BlockMorph.prototype.userMenu;
    }
};

MicroWorld.prototype.restoreBlockMenu = function () {
    if (BlockMorph.prototype.oldUserMenu) {
        BlockMorph.prototype.userMenu = BlockMorph.prototype.oldUserMenu;
        delete BlockMorph.prototype.oldUserMenu;
        CustomReporterBlockMorph.prototype.userMenu =
            CustomReporterBlockMorph.prototype.oldUserMenu;
        delete CustomReporterBlockMorph.prototype.oldUserMenu;
        CustomCommandBlockMorph.prototype.userMenu =
            CustomCommandBlockMorph.prototype.oldUserMenu;
        delete CustomCommandBlockMorph.prototype.oldUserMenu;
    }
};

MicroWorld.prototype.overrideMakeABlockDialogs = function () {
    var sprite = this.sprite,
        ide = this.ide;

    // "Make a Block" dialogs

    if (!BlockDialogMorph.prototype.oldInit) {
        BlockDialogMorph.prototype.oldInit = BlockDialogMorph.prototype.init;
        BlockDialogMorph.prototype.init =
            function (target, action, environment) {
                // Force "microworld" category and hide category and
                // scope selectors
                this.blockType = 'command';
                this.category = 'other';
                this.isGlobal = true;
                this.types = null;
                BlockDialogMorph.uber.init.call(
                    this,
                    target,
                    action,
                    environment
                );
                this.key = 'makeABlock';
                this.types = new AlignmentMorph('row', this.padding);
                this.add(this.types);
                this.createTypeButtons();
                this.oldFixLayout = this.fixLayout;
                this.fixLayout = function () {
                    this.oldFixLayout();
                    if (this.body) {
                        this.body.setWidth(this.width() - this.padding * 2);
                    }
                };
                this.fixLayout();
            };
    }

    if (!BlockEditorMorph.prototype.oldAccept) {
        BlockEditorMorph.prototype.oldAccept =
            BlockEditorMorph.prototype.accept;
        BlockEditorMorph.prototype.accept = function () {
            this.oldAccept();
            sprite.refreshMicroWorldPalette();
            sprite.hideSearchButton();
        };
    }

    if (!BlockEditorMorph.prototype.oldCancel) {
        BlockEditorMorph.prototype.oldCancel =
            BlockEditorMorph.prototype.cancel;
        BlockEditorMorph.prototype.cancel = function () {
            var def = this.definition;
            if (this.firstTime) {
                // canceled the first time the block was created, so removing
                // the block
                sprite.deleteAllBlockInstances(def);
                stage = ide.stage;
                idx = stage.globalBlocks.indexOf(def);
                if (idx !== -1) {
                    stage.globalBlocks.splice(idx, 1);
                }
                sprite.refreshMicroWorldPalette();
                sprite.hideSearchButton();
            }
            this.oldCancel();
        };
    }

    if (!BlockEditorMorph.prototype.oldUpdateDefinition) {
        BlockEditorMorph.prototype.oldUpdateDefinition =
            BlockEditorMorph.prototype.updateDefinition;
        BlockEditorMorph.prototype.updateDefinition = function () {
            this.oldUpdateDefinition();
            sprite.refreshMicroWorldPalette();
            sprite.hideSearchButton();
        };
    }

    // Save into stage global blocks
    if (!SpriteMorph.prototype.oldMakeBlock) {
        SpriteMorph.prototype.oldMakeBlock = SpriteMorph.prototype.makeBlock;
        SpriteMorph.prototype.makeBlock = function () {
            var category = 'other',
                clr = SpriteMorph.prototype.blockColor['other'],
                sprite = this,
                dlg;
            dlg = new BlockDialogMorph(
                null,
                function (definition) {
                    if (definition.spec !== '') {
                        definition.codeHeader = 'microworld'; // watermark it
                        ide.stage.globalBlocks.push(definition);
                        sprite.blocksCache['microworld'].push(
                            definition.templateInstance()
                        );
                        sprite.refreshMicroWorldPalette();
                        sprite.hideSearchButton();
                        editor = new BlockEditorMorph(definition, sprite);
                        editor.firstTime = true;
                        editor.popUp();
                    }
                },
                sprite
            );
            dlg.types.children.forEach(function (each) {
                each.setColor(clr);
                each.refresh();
            });
            dlg.prompt(
                'Make a block',
                null,
                sprite.world()
            );
        };
    }

    // Input Slot Dialog
    // never launch it in expanded form
    InputSlotDialogMorph.prototype.isLaunchingExpanded = false;

    if (!InputSlotDialogMorph.prototype.oldCreateTypeButtons) {
        InputSlotDialogMorph.prototype.oldCreateTypeButtons =
            InputSlotDialogMorph.prototype.createTypeButtons;
        InputSlotDialogMorph.prototype.createTypeButtons = function () {
            // Just don't add the expanded form arrow
            var block,
                sprite = this,
                clr = SpriteMorph.prototype.blockColor[this.category];

            block = new JaggedBlockMorph(localize('Title text'));
            block.setColor(clr);
            this.addBlockTypeButton(
                function () { sprite.setType(null); },
                block,
                function () { return sprite.fragment.type === null; }
            );

            block = new JaggedBlockMorph('%inputName');
            block.setColor(clr);
            this.addBlockTypeButton(
                function () { sprite.setType('%s'); },
                block,
                function () { return sprite.fragment.type !== null; }
            );
        };
    }
};

MicroWorld.prototype.restoreMakeABlockDialogs = function () {
    BlockDialogMorph.prototype.init = BlockDialogMorph.prototype.oldInit;
    BlockEditorMorph.prototype.accept = BlockEditorMorph.prototype.oldAccept;
    BlockEditorMorph.prototype.updateDefinition =
        BlockEditorMorph.prototype.oldUpdateDefinition;
    SpriteMorph.prototype.makeBlock = SpriteMorph.prototype.oldMakeBlock;
    InputSlotDialogMorph.prototype.createTypeButtons =
        InputSlotDialogMorph.prototype.oldCreateTypeButtons;

    delete BlockDialogMorph.prototype.oldInit;
    delete BlockEditorMorph.prototype.oldAccept;
    delete BlockEditorMorph.prototype.oldUpdateDefinition;
    delete SpriteMorph.prototype.oldMakeBlock;
    delete InputSlotDialogMorph.prototype.oldCreateTypeButtons;
};

MicroWorld.prototype.addBlocksWithSpecs = function (specs) {
    var sprite = this.sprite,
        ide = this.ide;

    SpriteMorph.prototype.blockColor['microworld'] = new Color(200, 120, 120);

    // helper functions to build block templates
    function primitiveBlock (selector) {
        var newBlock = SpriteMorph.prototype.blockForSelector(selector, true);
        if (!newBlock) { return null; }
        newBlock.isTemplate = true;
        return newBlock;
    };
    function customBlock (spec) {
        var newBlock =
            ide.stage.globalBlocks.find(function (block) {
                return block.spec == spec;
            });
        if (!newBlock) { return null; }
        return newBlock.templateInstance();
    };
    function block (selectorOrSpec) {
        if (selectorOrSpec === '-' || selectorOrSpec === '=') {
            return selectorOrSpec;
        } else {
            return primitiveBlock(selectorOrSpec) ||
                customBlock(selectorOrSpec);
        }
    };

    // create the cache for the new category and fill it up with blocks
    sprite.blocksCache['microworld'] = [];
    blocks = sprite.blocksCache['microworld'];

    specs.asArray().forEach(function (spec) {
        var aBlock = block(spec);
        if (aBlock) { blocks.push(aBlock); }
    });

    blocks.push("=");
    blocks.push(sprite.makeBlockButton('microworld'));

    sprite.refreshMicroWorldPalette = function () {
        // only refresh if in microWorld mode
        if (ide.microWorldMode) {
            blocks.forEach(
                function(block){
                    if (block.isCorpse) {
                        blocks.splice(blocks.indexOf(block), 1);
                        block.destroy();
                    }
                }
            );
            sprite.customPalette = sprite.freshPalette('microworld');
            sprite.customPalette.userMenu = nop;
            sprite.paletteCache['microworld'] = sprite.customPalette;
            ide.currentCategory = 'microworld';
            ide.refreshPalette(true);

            // toggle redraw
            ide.toggleStageSize(true, 0.5);
            ide.toggleStageSize(true, 1);
        }
    };

    sprite.refreshMicroWorldPalette();

    // flushPaletteCache should also refresh the MicroWorld palette
    // otherwise deleting custom blocks leaves it in a funny state
    if (!ide.oldFlushPaletteCache) {
        ide.oldFlushPaletteCache = ide.flushPaletteCache;
        ide.flushPaletteCache = function (category) {
            this.oldFlushPaletteCache(category);
            sprite.refreshMicroWorldPalette();
        };
    }
};

MicroWorld.prototype.loadCustomBlocks = function () {
    // We load our custom blocks from the stage.
    // They're watermarked with 'microworld' in their codeHeader
    var sprite = this.sprite,
        blocks = this.ide.stage.globalBlocks.filter(
            function (block) {
                return block.codeHeader === 'microworld';
            }
        );

    blocks.forEach(function (block) {
        sprite.blocksCache['microworld'].push(block.templateInstance());
    });

    sprite.refreshMicroWorldPalette();
};

MicroWorld.prototype.hideCategoryList = function () {
    var ide = this.ide,
        sprite = this.sprite;

    // hide categories
    ide.categories.hide();
    ide.categoriesHeight = ide.categories.height();
    ide.categories.setHeight(0);

    // resize palette to take up all vertical space
    ide.palette.setTop(ide.categories.top());
    ide.palette.setHeight(ide.height() - ide.controlBar.height());

    // adjust palette handle position
    ide.paletteHandle.fixLayout = function () {
        if (!this.target) {
            return;
        }
        this.setCenter(sprite.customPalette.center());
        this.setRight(sprite.customPalette.right());
        if (ide) { ide.add(this); } // come to front
    };
};

MicroWorld.prototype.showCategoryList = function () {
    this.ide.categories.setHeight(this.ide.categoriesHeight);
    this.ide.categories.show();
};

MicroWorld.prototype.hideSearchButton = function () {
    var sprite = this.sprite;
    sprite.hideSearchButton = function () {
        sprite.searchButton =
            sprite.customPalette.toolBar.children.find(
                function (button) {
                    return button.action === 'searchBlocks';
                }
            );
        sprite.searchButton.hide();
    };
    sprite.hideSearchButton();
};

MicroWorld.prototype.hideMakeABlockButtons = function () {
    var sprite = this.sprite;

    sprite.hideMakeABlockButtons = function () {
        sprite.makeBlockButtons =
            sprite.customPalette.allChildren().filter(
                function (morph) {
                    return morph.action == 'makeBlock';
                }
            );
        sprite.makeBlockButtons.forEach(
            function (each) {
                each.hide();
            }
        );
    };

    sprite.hideMakeABlockButtons();
};

MicroWorld.prototype.hideSpriteBar = function () {
    // hide tab bar and sprite properties panel
    this.ide.spriteBar.hide();
    this.ide.spriteBarHeight = this.ide.spriteBar.height();
    this.ide.spriteBar.setHeight(0);
    this.ide.spriteBar.hide();
    this.ide.spriteBar.tabBar.hide();
};

MicroWorld.prototype.showSpriteBar = function () {
    this.ide.spriteBar.setHeight(this.ide.spriteBarHeight);
    this.ide.spriteBar.show();
    this.ide.spriteBar.tabBar.show();
};

MicroWorld.prototype.disableKeyboardEditing = function () {
    // hide keyboard editing button
    ScriptsMorph.prototype.enableKeyboard = false;
    this.sprite.scripts.updateToolbar();
};

MicroWorld.prototype.enableKeyboardEditing = function () {
    ScriptsMorph.prototype.enableKeyboard = true;
    this.sprite.scripts.updateToolbar();
};

MicroWorld.prototype.hideButtonsWithSelectors = function (selectors) {
    // hide buttons from the top bar
    var ide = this.ide;
    selectors.asArray().forEach(
        function (selector) {
            ide.controlBar[selector].hide();
        }
    );
};

MicroWorld.prototype.showButtonsWithSelectors = function (selectors) {
    var ide = this.ide;
    selectors.asArray().forEach(
        function (selector) {
            ide.controlBar[selector].show();
        }
    );
};

MicroWorld.prototype.restrictFileMenuToIndices = function (indices) {
    if (!IDE_Morph.prototype.oldProjectMenu) {
        IDE_Morph.prototype.oldProjectMenu = IDE_Morph.prototype.projectMenu;
        IDE_Morph.prototype.projectMenu = function () {
            this.oldProjectMenu();
            if (this.microWorldMode) {
                var menu = this.world().activeMenu,
                    items = [];
                // can't use filter because we also want to reorder
                indices.contents.forEach(function (index) {
                    items.push(menu.items[index]);
                });
                menu.items = items;
                menu.popup(
                    this.world(),
                    this.controlBar.projectButton.bottomLeft()
                );
            }
        };
    }
};

MicroWorld.prototype.restoreFileMenu = function () {
    if (IDE_Morph.prototype.oldProjectMenu) {
        IDE_Morph.prototype.projectMenu = IDE_Morph.prototype.oldProjectMenu;
        delete IDE_Morph.prototype.oldProjectMenu;
    }
};

MicroWorld.prototype.hideSpriteCorral = function () {
    var ide = this.ide;

    // hide corral and corral bar
    ide.corral.hide();
    ide.corralBar.hide();

    // prevent switching to a sprite on stage by double clicking on it
    SpriteMorph.prototype.oldMouseDoubleClick =
        SpriteMorph.prototype.mouseDoubleClick;
    SpriteMorph.prototype.mouseDoubleClick = function () {
        if (!ide.microWorldMode) {
            this.oldMouseDoubleClick();
        }
    }
};

MicroWorld.prototype.showSpriteCorral = function () {
    this.ide.corral.show();
    this.ide.corralBar.show();
};

MicroWorld.prototype.overrideShowForSomeMorphs = function () {
    // Hard to refactor. Need to revisit later.
    // overwrite show for a bunch of morphs
    // it gets called when coming back from appMode
    var ide = this.ide;
    [
        ide.controlBar.steppingButton,
        ide.spriteBar.tabBar,
        ide.corralBar,
        ide.corral,
        this.sprite.searchButton
    ].concat(this.comments).concat(this.stacks).forEach(
        function (each) {
            if (!each.oldShow) {
                each.oldShow = each.show;
            }
            each.show = function () {
                if (!ide.microWorldMode) {
                    this.oldShow();
                }
            };
        }
    );
};

MicroWorld.prototype.makeButtonFor = function (label, body) {
    var sprite = this.sprite,
        sf = sprite.scripts.parentThatIsA(ScrollFrameMorph);

    if (!sprite.buttons) {
        sprite.buttons = [];
    }

    var button = new PushButtonMorph(
        sprite,
        function () {
            ide.stage.threads.startProcess(body.expression, sprite);
        },
        label
    );

    if (!sprite.buttons[label]) {
        sf.toolBar.add(button);
    }

    sprite.buttons[label] = button;
    sf.toolBar.fixLayout();
    sf.adjustToolBar();
};

MicroWorld.prototype.hideTaggedScripts = function () {
    // hide this stack and prevent blocks from dropping into it
    this.comments.forEach(
        function (comment) {
            comment.hide();
        }
    );
    this.stacks.forEach(
        function (stack) {
            stack.hide();
            // prevent inputs from receiving blocks
            stack.forAllChildren(
                function (child) {
                    if (!child.oldAllInputs && child.allInputs) {
                        child.oldAllInputs = child.allInputs;
                        child.allInputs = function () { return []; };
                    }
                }
            );
            // prevent command blocks to attach anywhere
            stack.isTemplate = true;
        }
    );
};

MicroWorld.prototype.showTaggedScripts = function () {
    this.comments.forEach(
        function (comment) {
            comment.show();
        }
    );
    this.stacks.forEach(
        function (stack) {
            stack.show();
            // restore ability to drop blocks into inputs
            stack.forAllChildren(
                function (child) {
                    if (child.oldAllInputs) {
                        child.allInputs = child.oldAllInputs;
                        delete(child.oldAllInputs);
                    }
                }
            );
            // restore ability to attach command blocks
            stack.isTemplate = false;
        }
    );
};

MicroWorld.prototype.toggleIdeRedraw = function () {
    // toggle redraw
    this.ide.toggleStageSize(true, 0.5);
    this.ide.toggleStageSize(true, 1);
};
