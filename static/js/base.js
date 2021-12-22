var snapURL = location.origin + '/snap/snap.html',
    snapDevURL = location.origin + '/snapsource/dev/snap.html',
    baseURL = location.href.replace(/(.*)\/.*/, '$1'),
    modules = [], // compatibility with cloud.js
    nop = function () {},
    localizer = new Localizer(),
    buttonDefaults =
        { done: { text: 'Ok', default: true }, cancel: { text: 'Cancel' } };

function run_selector (controller, selector, params) {
    var req = new XMLHttpRequest();
    req.open(
        'POST',
        '/call_lua/' + controller + '/' + selector + encodeParams(params),
        true
    );
    req.onreadystatechange = function () {
        if (req.readyState == 4 && req.status == 200) {
            var json;
            try { json = JSON.parse(req.responseText); } catch (err) { }
            if (json) {
                // it's a response message
                dialog(
                    json.title,
                    json.message,
                    ok => {
                        if (json.redirect) {
                            location.href = json.redirect;
                        }
                    }
                );
            } else {
                // it's a path
                location.href = req.responseText;
            }
        } else if (req.readyState == 4) {
            // handle the error
            try {
                var err = JSON.parse(req.responseText).errors[0];
            } catch (e) {
                var err = req.responseText;
            }
            alert(
                err || 'Unknown error',
                { title: req.statusText || 'Error' }
            );
        }
    };
    req.send();
};

function encodeParams (params) {
    if (params) {
        return '?' +
            Object.keys(params).map(
                paramName => 
                    encodeURIComponent(paramName) + '=' +
                        encodeURIComponent(JSON.stringify(params[paramName]))
            ).join('&');
    } else {
        return '';
    }
};

function getUrlParameter (param) {
    var regex = new RegExp('[?&]' + param + '(=([^&#]*)|&|#|$)'),
        results = regex.exec(location.href);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
};

// Error handling

function genericError (errorString, title) {
    doneLoading();
    alert(
        localizer.localize(errorString || 'Unknown error'),
        { title: localizer.localize(title || 'Error')}
    );
    console.error(errorString);
};

// Page loading

function beganLoading (selector) {
    var loader;
    if (selector) {
        loader = document.createElement('div');
        loader.className = 'loader';
        loader.innerHTML =
            '<i class="fa fa-spinner fa-spin fa-3x" aria-hidden="true"></i>';
        document.querySelector(selector).append(loader);
    }
};

function doneLoading (selector) {
    var element = document.querySelector(
            selector ?
                (selector + '> .loader') :
            '#loading');
    localizer.localizePage();
    if (element) {
        element.hidden = true;
    }
};

// Other goodies

function escapeHtml (text) {
    // Based on an answer by Kip @ StackOverflow
    var map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text ? text.replace(/[&<>"']/g, function (m) { return map[m]; }) : ''
};

function enableEnterSubmit () {
    // Submits "forms" when enter is pressed on any of their inputs
    document.querySelectorAll('.pure-form input').forEach(
        input => {
            input.onkeypress = function (evt) {
                if (evt.keyCode == 13) { submit(); }
            }
        }
    );
};

// JS additions

Array.prototype.sortBy = function (parameter, reverse) {
    return this.sort(
        function (a, b) {
            if (reverse) {
                return (a[parameter] > b[parameter]) ? 1 : -1;
            } else {
                return (a[parameter] > b[parameter]) ? -1 : 1;
            }
        }
    );
};

// CustomAlert helpers

function confirmTitle (title) {
    // there's a bug in customalert.js preventing us from
    // using a custom title unless we also specify text for
    // the ok and cancel buttons
    return {
        title: localizer.localize(title),
        done: localizer.localize('Ok'),
        cancel: localizer.localize('Cancel')
    };
};

function confirmAction(text, controller, selector, params) {
    confirm(
        text,
        ok => { if (ok) { run_selector(controller, selector, params); }}
    );
};

function confirmComponentAction(text, componentId, controller, selector, params) {
    confirm(
        text,
        ok => {
            if (ok) {
                window['update_' + componentId](
                    controller,
                    selector,
                    params
                );
            }
        }
    );
};
