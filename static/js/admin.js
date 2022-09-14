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
