// In-place editor

function InPlaceEditor (element, action, defaultText) {
    this.init(element, action, defaultText);
};

InPlaceEditor.prototype.init = function (element, action, defaultText) {
    var myself = this,
        hiddenDiv = document.createElement('div');
    this.element = element;

    this.defaultText = defaultText || 'This project has no notes';

    this.element.classList.add('in-place');
    this.element.contentEditable = true;
    this.fakeInput = document.createElement('input');
    this.fakeInput.style = 'opacity: 0; filter: alpha(opacity=0);';
    hiddenDiv.style = 'position: fixed; width: 0; height: 0; overflow: hidden;';
    hiddenDiv.append(this.fakeInput);
    element.append(hiddenDiv);

    this.element.onblur = function () {
        myself.element.classList.add('flash');
        action.call(myself.element, myself.element.innerText.trim());
    };
    this.element.onfocus = function () { myself.startEditing() };
    this.element.onkeypress = function (event) { myself.checkKey(event); };
};
        
InPlaceEditor.prototype.checkKey = function (event) {
    var code = (event.keyCode ? event.keyCode : event.which);
    if (code == 13 && !event.shiftKey) {
        this.element.blur();
        this.fakeInput.focus();
    }
};

InPlaceEditor.prototype.startEditing = function () {
    this.element.classList.remove('flash');
    if (this.element.innerText == localizer.localize(this.defaultText)) {
        this.element.innerText = '';
    }
};
