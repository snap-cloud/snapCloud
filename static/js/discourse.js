// Tiny Discourse module.
// Just the stuff we need for the blog and maybe some other pages.

function DiscourseBlog (url, category, element) {
    this.init(url, category, element);
};

DiscourseBlog.prototype.init = function (url, category, element) {
    this.url = url;
    this.category = category;
    this.element = element;
    this.posts = [];
    this.fetchPosts();
};

DiscourseBlog.prototype.fetchJSON = function (path, callback, errorString) {
    var req = new XMLHttpRequest(),
        myself = this;
    req.open('GET', this.url + path + '?random=' + Math.random(1000));
    req.onreadystatechange = function () {
        var jsonResponse;
        if (req.readyState === 4) {
            if (req.status === 200 || req.status == 0) {
                try {
                    jsonResponse = JSON.parse(req.responseText);
                    callback.call(myself, jsonResponse);
                } catch (err) {
                    genericError(err, errorString);
                }
            }
        }
    };
    req.send(null);

};

DiscourseBlog.prototype.fetchPosts =  function () {
    var myself = this;
    this.fetchJSON(
        '/c/' + this.category + '.json',
        function (jsonResponse) {
            jsonResponse.topic_list.topics.slice(1).sort(
                function (a, b) {
                    return new Date(b.created_at) - new Date(a.created_at);
                }
            ).forEach(
                function (each) {
                    var postDiv = document.createElement('div');
                    myself.element.appendChild(postDiv);
                    myself.fetchJSON(
                        '/t/' + each.id + '.json',
                        function (postJSON) {
                            myself.renderPost(
                                {
                                    title: postJSON.title,
                                    date: new Date(postJSON.created_at),
                                    author: postJSON.details.created_by.username,
                                    content: postJSON.post_stream.posts[0].cooked,
                                    commentsURL: myself.url + '/t/' + each.id + '/2'
                                },
                                postDiv
                            );
                        },
                        'Could not fetch post'
                    );
                }
            );
        },
        'Could not fetch post list'
    );
};

DiscourseBlog.prototype.renderPost = function (post, postDiv) {
    var titleHeader = document.createElement('h1'),
        dateSpan = document.createElement('span'),
        contentsDiv = document.createElement('div'),
        separatorSpan = document.createElement('span'),
        commentsAnchor = document.createElement('a');

    postDiv.classList.add('post');
    titleHeader.classList.add('title');
    dateSpan.classList.add('date');
    contentsDiv.classList.add('contents');
    separatorSpan.classList.add('separator');
    commentsAnchor.classList.add('comments');

    titleHeader.innerText = post.title;
    dateSpan.innerHTML = post.date;
    contentsDiv.innerHTML = post.content;
    commentsAnchor.innerText = localizer.localize('Discuss this in the forum');
    commentsAnchor.href = post.commentsURL;
    contentsDiv.appendChild(separatorSpan);
    contentsDiv.appendChild(commentsAnchor);

    [titleHeader, authorSpan(post.author), dateSpan, contentsDiv].forEach(
        function (element) { postDiv.appendChild(element); }
    );
};
