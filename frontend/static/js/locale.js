// Localization

function Localizer (lang) {
    this.init(lang);
};

Localizer.prototype.init = function (lang) {
    var request = new XMLHttpRequest(),
        myself = this;

    this.locale = lang || localStorage['locale'];
    this.translations = {};

    if (!this.locale || this.locale === 'en') {
        return;
    }

    request.open('GET', 'locales/' + this.locale + '.json?random=' +
        Math.random(1000), false);
    request.setRequestHeader('Content-type',
        'application/json; charset=UTF-8');
    request.onreadystatechange = function () {
        if (this.readyState === 4) {
            if (this.status === 200 || this.status === 0) {
                myself.loadTranslations(this.responseText);
            }
        }
    };
    request.send(null);
};

Localizer.prototype.loadTranslations = function (fileContents) {
    this.translations = JSON.parse(fileContents);
};

Localizer.prototype.localizePage = function () {
    var myself = this;
    document.querySelectorAll('[localizable]').forEach(function (element) {
        element.innerHTML = myself.localize(element.innerHTML);
    })
};

Localizer.prototype.localize = function (aString) {
    return this.translations[aString] || aString;
};

Localizer.prototype.setLanguage = function (lang) {
    localStorage['locale'] = lang;
    location.reload();
};

Localizer.findMissingStrings = function (lang) {
    var localizer = new Localizer(lang);

    if (!sessionStorage['missing-strings-' + lang]) {
       sessionStorage['missing-strings-' + lang] = JSON.stringify({});
    }

    var missing = JSON.parse(sessionStorage['missing-strings-' + lang]);

    document.querySelectorAll('[localizable]').forEach(
        function (element) {
            var string = element.innerHTML;
            if (!(localizer.translations[string])) {
                missing[string] = '';
                element.style.outline = '2px dashed red';
            } else {
                element.style.outline = '2px solid green';
            }
        }
    );

    sessionStorage['missing-strings-' + lang] = JSON.stringify(missing);
    return missing;
};

Localizer.showMissingStrings = function (lang) {
    Localizer.findMissingStrings(lang);
    var win = window.open('data:application/json,' +
            encodeURIComponent(sessionStorage['missing-strings-' + lang ]),
        'Missing ' + lang + ' Strings',
            'toolbar=no,location=no,directories=no,status=no,menubar=no' +
            ',scrollbars=yes,resizable=yes,width=780,height=200,top=' +
            (screen.height-400) + ',left='+(screen.width-840));
};
