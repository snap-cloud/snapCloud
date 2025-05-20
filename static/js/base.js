var snapURL = location.origin + '/snap/snap.html',
    snapDevURL = location.origin + '/snapsource/dev/snap.html',
    nop = function () {},
    localizer = new Localizer(),
    buttonDefaults =
        { done: { text: 'Ok', default: true }, cancel: { text: 'Cancel' } };

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

function escapeHtml (text) {
    if (text === null || text === undefined) { return; }

    if (text.toString) { text = text.toString(); }
    // Based on an answer by Kip @ StackOverflow
    let map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
}

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

function enableEnterSubmit () {
    // Submits "forms" when enter is pressed on any of their inputs
    // TODO-BS: Remove pure CSS when transition to Bootstrap 5 is complete
    document.querySelectorAll('.pure-form input, input.form-control').forEach(
        input => {
            input.onkeypress = function (evt) {
                if (evt.keyCode == 13) { submit(); }
            }
        }
    );
};

function flash (element, callback, warning) {
    element.classList.add(warning ? 'warning-flash' : 'flash');
    setTimeout(() => {
        element.classList.remove(warning ? 'warning-flash' : 'flash');
        if (callback) { callback.call(element); }
    }, 500);
};

function setupCarouselPageIndicator (id) {
    function setCarouselText(carousel, current, total) {
        let textContainer = carousel.querySelector('.js-textStatus');
        textContainer.querySelector('.page-link').innerHTML = `${current} / ${total}`;
        textContainer.querySelector('.visually-hidden').innerHTML = `${current} of ${total}`;
    }

    let carousel = document.getElementById(`${id}_container`);
    let totalItems = carousel.querySelectorAll('.carousel-item').length;
    let currentIndex = Array.prototype.indexOf.call(carousel.querySelectorAll('.carousel-item'), carousel.querySelector('div.active')) + 1;
    setCarouselText(carousel, currentIndex, totalItems);

    carousel.addEventListener('slid.bs.carousel', function() {
        currentIndex = Array.prototype.indexOf.call(carousel.querySelectorAll('.carousel-item'), carousel.querySelector('div.active')) + 1;
        setCarouselText(carousel, currentIndex, totalItems);
    });
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

Cloud.redirect = function (response) {
    if (!(response && response.redirect)) {
        location.reload();
    } else {
        if (response.title || response.message) {
            alert(
                localizer.localize(response.message),
                { title: localizer.localize(response.title) },
                () => location.href = response.redirect
            );
        } else {
            location.href = response.redirect;
        }
    }
};

// Cloud additions
Cloud.prototype.post = function (path, onSuccess, body) {
    this.apiRequest('POST', path, onSuccess, body);
};

// Cloud additions
Cloud.prototype.delete = function (path, onSuccess, body) {
    this.apiRequest('DELETE', path, onSuccess, body);
};

// TODO: We should extract the onSuccess / onError handlers to a better location.
Cloud.prototype.apiRequest = function (method, path, onSuccess, body) {
    // By default, redirect. If you don't want to do that,
    // set onSuccess to nop or any other value.
    if (onSuccess == null) { onSuccess = Cloud.redirect; }

    if (body && (method != 'POST')) {
        // append params to path
        path += '?' + this.encodeDict(body);
    }

    cloud.request(
        method,
        path,
        okResponse => {
            var response = JSON.parse(okResponse);
            if (response && response.title) {
                alert(
                    localizer.localize(response.message),
                    { title: escapeHtml(localizer.localize(response.title)) },
                    function () { onSuccess.call(this, response) }
                );
            } else {
                onSuccess.call(this, response)
            }
        },
        errorMessage => {
            alert(
                localizer.localize(errorMessage),
                { title: escapeHtml(localizer.localize('Error')) },
                Cloud.redirect
            )
        },
        null,
        true,
        (method == 'POST') ? body : null
    );
};
