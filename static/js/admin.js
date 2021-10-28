function userButton (user, label, action, extraClass) {
    var button = document.createElement('a');
    button.setAttribute('localizable', true);
    button.classList.add('pure-button');
    button.classList.add(label.toLowerCase().replace(/\s/g,''));
    if (extraClass) {
        button.classList.add(extraClass);
    }
    button.innerHTML = localizer.localize(label);
    button.onclick = action;
    return button;
}

function verifyButton (user) {
    return userButton(
        user,
        'Verify',
        function () {
            SnapCloud.withCredentialsRequest(
                'GET',
                '/users/' + encodeURIComponent(user.username) +
                    '/verify_user/0', // token is irrelevant for admins
                function (response) {
                    alert(
                        response,
                        function () {
                            location.href = 'user?user=' +
                                encodeURIComponent(user.username);
                        }
                    );
                },
                genericError,
                'Could not verify user'
            );
        }
    );
};

function banButton (user) {
    return userButton(
        user,
        user.role == 'banned' ? 'Unban' : 'Ban',
        function () {
            confirm(
                localizer.localize('Are you sure you want to ' +
                    (user.role == 'banned' ? 'unban' : 'ban') + ' user') +
                    ' <strong>' + user.username + '</strong>?',
                function (ok) {
                    if (ok) {
                        SnapCloud.withCredentialsRequest(
                            'POST',
                            '/users/' + encodeURIComponent(user.username) +
                                '?' + SnapCloud.encodeDict({
                                    role: user.role == 'banned' ?
                                        'standard' :
                                        'banned'
                                    }),
                            function (response) {
                                alert(
                                    localizer.localize('User has been ' +
                                        (user.role == 'banned' ?
                                            'unbanned' :
                                            'banned.')),
                                    function () { location.reload(); }
                                );
                            },
                            genericError,
                            'Could not ban user'
                        );
                    }
                },
                confirmTitle('Ban user')
            );
        },
        'pure-button-warning'
    );
};

function deleteButton (user) {
    return userButton(
        user,
        'Delete',
        function () {
            confirm(
                localizer.localize('Are you sure you want to delete user') +
                ' <strong>' + user.username + '</strong>?<br>' +
                '<i class="warning fa fa-exclamation-triangle"></i> ' +
                localizer.localize('WARNING! This action cannot be undone!') +
                ' <i class="warning fa fa-exclamation-triangle"></i>',
                function (ok) {
                    if (ok) {
                       SnapCloud.withCredentialsRequest(
                           'DELETE',
                           '/users/' + encodeURIComponent(user.username),
                           function (response) {
                               alert(
                                   response,
                                   function () { location.reload(); }
                               );
                           },
                           genericError,
                           'Could not delete user'
                       );
                    }
                },
                confirmTitle('Delete user')
            );
        },
        'pure-button-warning'
    );
};

function deleteZombieButton (user) {
    return userButton(
        user,
        'Delete',
        function () {
            confirm(
                localizer.localize('Are you sure you want to delete user') +
                ' <strong>' + user.username + '</strong>?<br>' +
                '<i class="warning fa fa-exclamation-triangle"></i> ' +
                localizer.localize('WARNING! This action cannot be undone!') +
                ' <i class="warning fa fa-exclamation-triangle"></i>',
                function (ok) {
                    if (ok) {
                       SnapCloud.withCredentialsRequest(
                           'DELETE',
                           '/zombies/' + encodeURIComponent(user.username),
                           function (response) {
                               alert(
                                   response,
                                   function () { location.reload(); }
                               );
                           },
                           genericError,
                           'Could not delete user'
                       );
                    }
                },
                confirmTitle('Delete user')
            );
        },
        'pure-button-warning'
    );
};

function reviveZombieButton (user) {
    return userButton(
        user,
        'Revive',
        function () {
            confirm(
                localizer.localize('Are you sure you want to revive user') +
                ' <strong>' + user.username + '</strong>?',
                function (ok) {
                    if (ok) {
                       SnapCloud.withCredentialsRequest(
                           'POST',
                           '/zombies/' + encodeURIComponent(user.username) +
                                '/revive',
                           function (response) {
                               alert(
                                   response,
                                   function () {
                                       location.href = 'user?user=' +
                                           encodeURIComponent(user.username);
                                   }
                               );
                           },
                           genericError,
                           'Could not bring user back to life'
                       );
                    }
                },
                confirmTitle('Revive user')
            );
        },
        'pure-button'
    );
};

function becomeButton (user) {
    return userButton(
        user,
        'Become',
        function () {
            SnapCloud.login(
                user.username,
                0, // password is irrelevant
                false, // persist
                function (username, role, response) {
                    alert(
                        response.message,
                        function () {
                            sessionStorage.username = username;
                            sessionStorage.role = role;
                            location.href = 'profile';
                        }
                    );
                },
                genericError
            );
        }
    );
};

function changeEmailButton (user) {
    return userButton(
        user,
        'Change Email',
        function () {
            var form = document.createElement('form');
            form.classList.add('email-change');
            form.classList.add('pure-form');
            form.classList.add('pure-form-aligned');
            form.innerHTML =
                '<fieldset>' +
                '<div class="pure-control-group">' +
                '<label localizable for="email">New Email Address?</label>' +
                '<input name="email" type="text"></input></div>' +
                '</fieldset>';

            dialog(
                'Change User Email',
                form,
                function () {
                    var email = form.querySelector('input[name="email"]').value;
                    SnapCloud.withCredentialsRequest(
                        'POST',
                        '/users/' + encodeURIComponent(user.username) + '?' +
                            SnapCloud.encodeDict({ email: email }),
                        function (response) {
                            alert(localizer.localize(
                                'User ' + user.username + '\'s email is now ' +
                                 email + '.')
                            );
                        },
                        genericError,
                        'Could not set user email'
                    );
                },
                nop // cancel action
            );
        }
    );
};

function messageButton (user) {
    return userButton(
        user,
        'Send a message',
        function () {
            var form = document.createElement('form');
            form.classList.add('email-compose');
            form.classList.add('pure-form');
            form.classList.add('pure-form-aligned');
            form.innerHTML =
                '<fieldset>' +
                '<div class="pure-control-group">' +
                '<label localizable for="subject">Subject</label>' +
                '<input name="subject" type="text"></input></div>' +
                '<div class="pure-control-group">' +
                '<label localizable for="body">Email body</label>' +
                '<textarea name="body"></textarea></div>' +
                '</fieldset>';

            dialog(
                'Compose a message',
                form,
                function () {
                    SnapCloud.withCredentialsRequest(
                        'POST',
                        '/users/' + encodeURIComponent(user.username) +
                        '/message',
                        function () {
                            alert('Message delivered');
                        },
                        genericError,
                        'Message could not be sent',
                        false, // wantsRawResponse
                        JSON.stringify({
                            subject: form.querySelector('input[name="subject"]').value,
                            contents: form.querySelector('textarea[name="body"]').value
                        })
                    );
                },
                nop // cancel action
            );
        }
    );
};

function canSetRole (currentRole, newRole) {
    var canSet = {
        admin: {
            admin: { admin: true, moderator: true, reviewer: true, standard: true, banned: true },
            moderator: { admin: true, moderator: true, reviewer: true, standard: true, banned: true },
            reviewer: { admin: true, moderator: true, reviewer: true, standard: true, banned: true },
            standard: { admin: true, moderator: true, reviewer: true, standard: true, banned: true },
            banned: { admin: true, moderator: true, reviewer: true, standard: true, banned: true }
        },
        moderator: {
            admin: {}, moderator: {},
            reviewer: { moderator: true, reviewer: true, standard: true, banned: true },
            standard: { moderator: true, reviewer: true, standard: true, banned: true },
            banned: { moderator: true, reviewer: true, standard: true, banned: true }
        },
        reviewer: {
            admin: {}, moderator: {}, reviewer: {}, banned: {},
            standard: { reviewer: true, standard: true }
        },
        standard: { admin: {}, moderator: {}, reviewer: {}, standard: {}, banned: {} },
        banned: { admin: {}, moderator: {}, reviewer: {}, standard: {}, banned: {} }
    }

    // ex:
    // canSet[reviewer][moderator][banned] || false → false
    // - Can a reviewer set a moderator user to banned? - No.
    // canSet[moderator][standard][reviewer] || false → true
    // - Can a moderator set a standard user to reviewer? - Yes.

    return canSet[sessionStorage.role][currentRole][newRole] || false
};

function setRole (user, role) {
    SnapCloud.withCredentialsRequest(
        'POST',
        '/users/' + encodeURIComponent(user.username) + '?' +
            SnapCloud.encodeDict({ role: role }),
        function (response) {
            alert(localizer.localize(
                'User ' + user.username + ' is now ' + role + '.')
            );
        },
        genericError,
        'Could not set user role'
    );
};

function basicUserDiv (user) {
    var userWrapperDiv = document.createElement('div'),
        detailsDiv = document.createElement('div'),
        usernameAnchor = userAnchor(user.username),
        emailSpan = document.createElement('span'),
        idSpan = document.createElement('span'),
        projectCountSpan = document.createElement('span'),
        joinedSpan = document.createElement('span');

    emailSpan.innerHTML = '<em><a target="_blank" href="mailto:' +
        escapeHtml(user.email) + '">' + escapeHtml(user.email) + '</a></em>';
    idSpan.innerHTML = '<strong>ID:</strong> ' + user.id;
    projectCountSpan.innerHTML = '<strong>Project count:</strong> ' +
        user.project_count;
    joinedSpan.innerHTML = '<strong localizable>Joined in </strong>' +
        formatDate(user.created);

    [ usernameAnchor, emailSpan, idSpan, projectCountSpan, joinedSpan ].forEach(
        function (e) { detailsDiv.appendChild(e); }
    );

    userWrapperDiv.classList.add('user');
    userWrapperDiv.classList.add('pure-u-1-2');
    detailsDiv.classList.add('details');

    userWrapperDiv.appendChild(detailsDiv);

    return userWrapperDiv;
};

function userDiv (user) {
    var userWrapperDiv = basicUserDiv(user);
        detailsDiv = userWrapperDiv.querySelector('.details'),
        roleSpan = document.createElement('span'),
        roleSelect = document.createElement('select'),
        buttonsDiv = document.createElement('div');

    roleSpan.innerHTML = '<strong localizable>Role</strong>:';
    ['standard', 'reviewer', 'moderator', 'admin', 'banned'].forEach(
        function (role) {
            var roleOption = document.createElement('option');
            roleOption.value = role;
            roleOption.innerHTML = role;
            if (role === 'banned' || !canSetRole(user.role, role)) {
                roleOption.disabled = true;
            }
            if (user.role == role) {
                roleOption.selected = true;
            }
            roleSelect.appendChild(roleOption);
        }
    );
    roleSelect.onchange = function () { setRole(user, roleSelect.value) };
    roleSpan.appendChild(roleSelect);

    buttonsDiv.classList.add('buttons');

    [ roleSpan, buttonsDiv ].forEach(
        function (e) { detailsDiv.appendChild(e); }
    );

    if (user.role == 'admin') {
        detailsDiv.classList.add('admin');
        detailsDiv.title += localizer.localize('Administrator') + '\n';
    } else if (user.role == 'banned') {
        detailsDiv.classList.add('banned');
        detailsDiv.title += localizer.localize('Banned') + '\n';
    }

    if (!user.verified) {
        buttonsDiv.appendChild(verifyButton(user));
        detailsDiv.classList.add('unverified');
        detailsDiv.title += localizer.localize('User is not verified');
    }

    if (sessionStorage.role == 'admin') {
        buttonsDiv.appendChild(becomeButton(user));
        buttonsDiv.appendChild(changeEmailButton(user));
        buttonsDiv.appendChild(messageButton(user));
    }

    if (canSetRole(user.role, 'banned')) {
        buttonsDiv.appendChild(banButton(user));
    }

    if (sessionStorage.role == 'admin' ||
            sessionStorage.username == user.username) {
        buttonsDiv.appendChild(deleteButton(user));
    }

    return userWrapperDiv;
};

function zombieDiv (user) {
    var userWrapperDiv = basicUserDiv(user),
        detailsDiv = userWrapperDiv.querySelector('.details'),
        buttonsDiv = document.createElement('div'),
        deletedSpan = document.createElement('span');

    buttonsDiv.classList.add('buttons');

    deletedSpan.innerHTML = '<strong localizable>Deleted in </strong>' +
        formatDate(user.deleted);

    [ deletedSpan, buttonsDiv ].forEach(function (e) {
        detailsDiv.appendChild(e);
    });

    if (sessionStorage.role == 'admin') {
        buttonsDiv.appendChild(messageButton(user));
        buttonsDiv.appendChild(deleteZombieButton(user));
        buttonsDiv.appendChild(reviveZombieButton(user));
    }

    return userWrapperDiv;
};

function verifiedFilter (callback) {
    var verifiedFilter = document.createElement('div'),
        select = document.createElement('select');

    verifiedFilter.innerHTML = 'Verified:';
    verifiedFilter.classList.add('filter');
    verifiedFilter.classList.add('verification');
    select.name = 'verified';

    select.innerHTML = '<option value="">Any</option>';
    select.innerHTML += '<option value="true">Verified</option>';
    select.innerHTML += '<option value="false">Unverified</option>';

    select.onchange = function () {
        callback(this.value);
    };

    verifiedFilter.appendChild(select);
    return verifiedFilter;
};

function roleFilter (callback) {
    var roleFilter = document.createElement('div'),
        select = document.createElement('select');

    roleFilter.innerHTML = 'Role:';
    roleFilter.classList.add('filter');
    roleFilter.classList.add('role');
    select.name = 'role';

    select.innerHTML = '<option value="">Any</option>';

    ['Standard', 'Reviewer', 'Moderator', 'Admin', 'Banned'].forEach(
        function (each) {
            select.innerHTML +=
                '<option value="' + each.toLowerCase() + '">'
                    + each + '</option>';
        }
    );

    select.onchange = function () {
        callback(this.value);
    };

    roleFilter.appendChild(select);
    return roleFilter;
};
