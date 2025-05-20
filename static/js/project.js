function fillCollectionDescription (collection, descriptionElement) {
    var noDescriptionHTML = '<small>' +
            localizer.localize('This collection has no description') +
            '</small>';

    descriptionElement.innerHTML =
        collection.description ?
            escapeHtml(collection.description).replace(
                /(https?:\/\/[^\s,\(\)\[\]]+)/g, // good enough
                '<a href="$1" target="_blank">$1</a>') :
        noDescriptionHTML;

    descriptionElement.title =
        localizer.localize('Press Shift + Enter to enter a newline');
    if (canEditDescription(collection)) {
        new InPlaceEditor(
            descriptionElement,
            function () {
                SnapCloud.updateCollectionDescription(
                    collection.username,
                    collection.name,
                    descriptionElement.innerText,
                    function () {
                        if (descriptionElement.innerText == '') {
                            descriptionElement.innerHTML = noDescriptionHTML;
                        }
                    },
                    genericError
                );
            },
            'This collection has no description'
        );
    }
};

function setupCollectionEditorControls (collection, editorsElement) {
    var addEditorAnchor = editorsElement.querySelector('.add-editor'),
        editorListUl = editorsElement.querySelector('.editor-list');

    // set up "add editor" anchor
    addEditorAnchor.hidden = !owns(collection);
    addEditorAnchor.onclick = function () {
        var newEditorInput = editorsElement.querySelector('.new-editor');
        this.hidden = true;
        newEditorInput.placeholder = localizer.localize('Username');
        newEditorInput.value = '';
        newEditorInput.hidden = false;
        newEditorInput.classList.add('flash');
        newEditorInput.focus();
        newEditorInput.onkeypress = function (event) {
            var code = (event.keyCode ? event.keyCode : event.which);
            if (code == 13 && !event.shiftKey) {
                SnapCloud.addEditorToCollection(
                    collection.username,
                    collection.name,
                    newEditorInput.value,
                    function () {
                        var li = newEditorLi(newEditorInput.value);
                        newEditorInput.hidden = true;
                        newEditorInput.classList.remove('flash');
                        addEditorAnchor.hidden = false;

                        editorListUl.append(li);
                        li.classList.add('flash');
                    },
                    function () {
                        newEditorInput.value = '';
                        newEditorInput.classList.remove('flash');
                        newEditorInput.classList.remove('warning-flash');
                        setTimeout(
                            function () {
                                newEditorInput.classList.add('warning-flash');
                            },
                            10
                        );
                        newEditorInput.focus();
                    }
                );
            }
        };
    }

    addEditorAnchor.title =
        localizer.localize('Add an editor to this collection');
    editorListUl.title =
        localizer.localize('Users who can edit this collection');
    editorListUl.append(newEditorLi(collection.username));

    function newEditorLi (username) {
        var editorLi = document.createElement('li'),
            removeAnchor = document.createElement('a'),
            icon = document.createElement('i');

        editorLi.classList.add('editor');
        editorLi.append(userAnchor(username));

        if (owns(collection) && username !== collection.username) {
            icon.classList.add('fas');
            icon.classList.add('fa-times-circle');
            removeAnchor.classList.add('remove');
            removeAnchor.classList.add('clickable');
            removeAnchor.append(icon);
            removeAnchor.onclick = function () {
                SnapCloud.removeEditorFromCollection(
                    collection.username,
                    collection.name,
                    username,
                    function () {
                        editorLi.classList.add('warning-flash');
                        setTimeout( function () { editorLi.remove(); }, 1000);
                    },
                    genericError
                );
            };
            editorLi.append(removeAnchor);
        }
        return editorLi;
    };

    if (collection.editors && collection.editors[0]) {
        collection.editors.forEach(function (editor) {
            editorListUl.append(newEditorLi(editor.username));
        });

        if (!owns(collection) &&
            collection.editors.find(
                function (editor) {
                    return editor.username === sessionStorage.username;
                }
            )
        ) {
            // User is an editor of this collection, but doesn't own it
            editorsElement.querySelector('.unenroll').hidden = false;
        }
    }

    if (isAdmin()) {
        if (collection.free_for_all) {
            editorsElement.querySelector('.ffa').hidden = true;
            editorsElement.querySelector('.un-ffa').hidden = false;
        } else if (collection.published) {
            editorsElement.querySelector('.ffa').hidden = false;
            editorsElement.querySelector('.un-ffa').hidden = true;
        }
    }
};

function toggleFullScreen () {
    var embed = document.querySelector('.embed'),
        container = document.querySelector('.viewer'),
        iframe = document.querySelector('.embed iframe'),
        world = iframe.contentWindow.world;

    if (embed.fullScreen) {
        embed.fullScreen = false;
        container.classList.remove('full-screen');
        document.body.style.overflow = 'auto';
    } else {
        embed.fullScreen = true;
        container.classList.add('full-screen');
        document.body.style.overflow = 'hidden';
    }
    world.worldCanvas.focus();
};

function runProject (event) {
    var iframe = document.querySelector('.embed iframe'),
        world = iframe.contentWindow.world,
        ide = world.children[0];
    if (event.shiftKey) {
        ide.toggleFastTracking();
    } else {
        ide.stage.threads.pauseCustomHatBlocks = false;
        ide.runScripts();
        if (ide.embedOverlay) {
            ide.embedOverlay.destroy();
            ide.embedPlayButton.destroy();
        }
    }
    world.worldCanvas.focus();
    refreshFlagButton(ide);
    refreshPauseButton(ide);
    refreshStopButton(ide);
};

function refreshFlagButton (ide) {
    var button = document.querySelector('.start-button');
    if (ide.stage.isFastTracked) {
        button.classList.replace('fa-flag', 'fa-bolt');
    } else {
        button.classList.replace('fa-bolt', 'fa-flag');
    }
};

function togglePauseProject () {
    var iframe = document.querySelector('.embed iframe'),
        world = iframe.contentWindow.world,
        ide = world.children[0];
    ide.togglePauseResume();
    refreshPauseButton(ide);
};

function refreshPauseButton (ide) {
    var button = document.querySelector('.pause-button');
    if (ide.stage.threads.isPaused()) {
        button.classList.replace('fa-pause', 'fa-play');
    } else {
        button.classList.replace('fa-play', 'fa-pause');
    }
};

function stopProject () {
    var iframe = document.querySelector('.embed iframe'),
        ide = iframe.contentWindow.world.children[0];
    ide.stopAllScripts();
    if (ide.embedOverlay) {
        ide.embedOverlay.destroy();
        ide.embedPlayButton.destroy();
    }
    refreshStopButton(ide);
    refreshPauseButton(ide);
};

function refreshStopButton (ide) {
    var button = document.querySelector('.stop-button');
    if (ide.stage.threads.pauseCustomHatBlocks) {
        button.classList.replace('fa-octagon', 'fa-stop');
    } else {
        button.classList.replace('fa-stop', 'fa-octagon');
    }
};
