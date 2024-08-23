-- How to translate
-- ----------------
-- Translate each text string to the target language leaving intact the two
-- double quotes.
-- Example: "Log In" should become "Entrar"
--
-- If you need to use a double quote, escape it with a backslash (\")
--
-- The "@" symbol followed by a number represents a parameter that the system
-- will substitute by a value, for example a username.
-- Example: "Welcome, @1!" will become "Welcome, Mary!" when Mary is logged in.
--
-- You need to leave "@" marks intact, but you can change their order in your
-- translation if your language requires so.

local locale = {
    -- Meta data
    -- =========
    lang_name = "English",
    lang_code = "en",
    authors = "Bernat Romagosa",
    last_updated = "2023/05/10", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Run Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "Explore",
    forum = "Forum",
    join = "Join",
    login = "Log In",
    -- User menu
    my_projects = "My Projects",
    my_collections = "My Collections",
    my_public_page = "My Public Page",
    followed_projects = "Followed Projects",
    administration = "Administration",
    my_profile = "My Profile",
    logout = "Log Out",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "Unbecome",

    -- Footer
    -- ======
    -- Titles
    t_about = "About",
    t_learning = "Learning",
    t_tools = "Tools",
    t_support = "Support",
    t_legal = "Legal",
    -- Links
    about = "About Snap@1",
    blog = "Blog",
    credits = "Credits",
    requirements = "Technical Requirements",
    partners = "Partners",
    source = "Source Code",
    events = "Events",
    examples = "Example Projects",
    manual = "Reference Manual",
    materials = "Materials",
    bjc = "The Beauty and Joy of Computing",
    research = "Research",
    wiki = "Community Wiki",
    offline = "Offline Version",
    extensions = "Extensions",
    old_snap = "(old Snap@1)",
    -- forum already translated in top navigation bar
    contact = "Contact Us",
    mirrors = "Mirrors",
    dmca = "DMCA",
    privacy = "Privacy",
    tos = "Terms of Service",

    -- Index page
    -- ==========
    welcome = "Welcome to Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "Welcome, @1!", -- @1 becomes the current user username
    snap_description = "Snap@1 is a broadly inviting programming language for kids and adults that's also a platform for serious study of computer science.",
    -- Buttons
    run_now = "Run @1 Now",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Featured Projects",
    totm = "Topic of the Month: @1", -- @1 becomes the actual topic of the month
    science = "Science Projects",
    simulations = "Simulations",
    three_d = "3D",
    music = "Music",
    art = "Art Projects",
    fractals = "Fractals",
    animations = "Animations",
    games = "Games",
    cs = "Computer Science",
    maths = "Maths",
    latest = "Latest Projects",
    more_collections = "Explore More Collections",

    -- Events page
    events_title = "Snap@1 Events",

    -- All Topics of the Month page

    totms_title = "All Topics of the Month",

    -- Collections page
    collections_title = "Published Collections",

    -- User Collections page
    user_collections_title = "@1's Published Collections",

    -- User Projects page
    user_projects_title = "@1's Public Projects",

    -- Sign up page
    -- ============
    signup_title = "Create a Snap@1 account", -- @1 becomes an italic exclamation mark (!)
    username = "Username",
    password = "Password",
    password_2 = "Repeat Password",
    birth_month = "Month of Birth",
    or_before = "or before", -- is preceded by a year, like "1995 or before"
    email_parent = "Email address of parent or guardian",
    email_user = "Email address",
    email_2 = "Repeat email address",
    tos_agree = "I have read and agree to the @1 and the @2", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Privacy Agreement",
    signup = "Sign Up",

    -- Log in page
    -- ===========
    log_into_snap = "Log into Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "keep me logged in",
    i_forgot_password = "I forgot my password",
    i_forgot_username = "I forgot my username",

    -- Dates
    -- =====
    -- Month names
    january = "January",
    february = "February",
    march = "March",
    april = "April",
    may = "May",
    june = "June",
    july = "July",
    august = "August",
    september = "September",
    october = "October",
    november = "November",
    december = "December",
    -- Date format
    date = "@2 @1, @3", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
    ok = "Ok",
    cancel = "Cancel",
    confirm = "Confirm",

    -- Explore page
    -- ============
    published_projects = "Published Projects",
    published_collections = "Published Collections",

    -- Search results page
    -- ===================
    search_results = "Search Results: @1",
    project_search_results = "Projects matching: @1",
    collection_search_results = "Collections matching: @1",
    user_search_results = "Users Matching: @1",
    projects = "Projects",
    collections = "Collections",
    users = "Users",

    -- Users page
    -- ==========
    last_users = "Last registered users",

    -- Search component in grids
    -- =========================
    matching = "Matching: @1", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "New Collection",
    -- New collection dialog
    collection_name = "Collection name",
    collection_by_thumb = "by @1", -- @1 is the author's username

    -- Collection page
    -- ===============
    collection_by = "by @1", -- @1 is the author's username
    -- Dates
    collection_created_date = "Created",
    collection_updated_date = "Last updated",
    collection_shared_date = "Shared",
    collection_published_date = "Published",
    -- Buttons
    share_collection_button = "Share",
    unshare_collection_button = "Unshare",
    publish_collection_button = "Publish",
    unpublish_collection_button = "Unpublish",
    delete_collection_button = "Delete",
    make_ffa = "Mark as free-for-all",
    unmake_ffa = "Unmark as free-for-all",
    unenroll = "Remove myself",
    -- Project Thumbnail
    project_by_thumb = "by @1", -- @1 is the author's username
    item_shared_info = "This item can be shared via URL.",
    item_not_shared_info = "This item is private and only you can see it.",
    item_published_info = "This item is published and can be searched and added to public collections.",
    item_not_published_info = "This item has not been published in the community site.",
    confirm_uncollect = "Are you sure you want to remove this project@1from this collection?", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "Remove from this collection",
    collection_thumbnail_tooltip = "Set as collection thumbnail",

    -- Collection dialogs
    -- ==================
    confirm_share_collection = "Are you sure you want to share this collection?",
    confirm_unshare_collection = "Are you sure you want to unshare this collection?",
    confirm_publish_collection = "Are you sure you want to publish this collection?",
    confirm_unpublish_collection = "Are you sure you want to unpublish this collection?",
    confirm_ffa = "Are you sure you want to mark this collection@1as free-for-all and let all users add their@1published projects to it?", -- @1 becomes a new line. You can add as many as you need.
    confirm_unffa = "Are you sure you want to unmark this collection@1as free-for-all and prevent non-editors from adding@1their projects to it?", -- @1 becomes a new line. You can add as many as you need.
    confirm_unenroll = "Are you sure you want to remove yourself from this collection?",

    -- User public page
    -- ================
    public_page = "@1's public page", -- @1 becomes the user's username
    follow_user = "Follow this user",
    unfollow_user = "Unfollow this user",
    -- Admin tools
    admin_tools = "Admin tools",
    latest_published_projects = "Latest Published Projects",
    latest_published_collections = "Latest Published Collections",

    -- Followed users feed
    -- ===================
    followed_feed = "Projects By Users I'm Following",
    following_nobody = "You are not following any users yet. Visit a user's public page and click on @1 to follow them and see their latest public projects in this page.",
    followed_users = "Users Followed by You",
    follower_users = "Users That Follow You",

    -- User profile
    -- ============
    profile_title = "@1's profile", -- @1 becomes the user's username
    join_date = "Joined", -- date of user creation follows
    delete_date = "Deleted", -- date of user deletion follows
    email = "Email",
    role = "Role",
    teacher = "Teacher",
    -- User roles
    student = "student",
    standard = "standard",
    reviewer = "reviewer",
    moderator = "moderator",
    admin = "admin",
    banned = "banned",
    -- Buttons
    change_my_password = "Change My Password",
    change_my_email = "Change My Email",
    delete_my_user = "Delete my Account",

    -- Learner Accounts
    -- ================
    -- @1 username, @2 user profile URL
    learner_first_login_meesage = [[Welcome, @1
This is a student account. That means your teacher controls it, not you.

We therefore strongly recommend that you should also have your own personal Snap! account.

Want to know more? Visit @2]],

    -- Teacher pages
    -- =============
    teacher_title = "Teacher Page",
    learners_title = "My Learners",

    -- Bulk account creation page
    -- ==========================
    bulk_tile = "Bulk account creation",
    bulk_text = "Please provide a CSV file with <code><b>username</b></code> and <code><b>password</b></code> columns for all of your learners, plus an optional <code>email</code> column. If you do not provide an email for your users, they will all be associated with your email account. That is useful if you want to be able to reset the passwords of your learners.",
    bulk_make_collection = "Create a private collection for this group of learners",
    bulk_create = "Create users",

    -- Project page
    -- ============
    remixed_from = "(remixed from @1, by @2)", -- @1 is the original project name, @2 is its author's username
    project_by = "by @1", -- @1 is the username
    project_remixes_title = "Public remixes of this project",
    project_collections_title = "Public collections containing this project",
    shift_enter_note = "Press Shift + Enter to enter a newline", -- in the notes field
    no_notes = "This project has no notes",
    created_date = "Created",
    updated_date = "Last updated",
    shared_date = "Shared",
    published_date = "Published",
    -- Buttons
    see_code = "See Code",
    edit = "Edit",
    download = "Download",
    embed = "Embed",
    collect = "Add to Collection",
    delete_button = "Delete",
    publish_button = "Publish",
    share_button = "Share",
    unpublish_button = "Unpublish",
    unshare_button = "Unshare",
    -- Flagging
    you_flagged = "You flagged this project as inappropriate",
    unflag_project = "Unflag this project",
    flag_project = "Report this project",

    -- Embed dialog
    -- ============
    embed_title = "Embed Options",
    embed_explanation = "Please select the elements you wish to include in the embedded project viewer:",
    project_title = "Project title",
    project_author = "Project author",
    edit_button = "Edit button",
    pause_button = "Pause button",
    embed_url = "Embed URL",
    embed_code = "Embed Code",

    -- Collect dialog
    -- ==============
    collect_title = "Add project to collection",
    collect_explanation = "Please select the collection to which you want to add this project:",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Are you sure you want to delete this project?",
    confirm_delete_user = "Are you sure you want to delete this user?",
    confirm_delete_collection = "Are you sure you want to delete this collection?",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Are you sure you want to share this project?",
    confirm_unshare_project = "Are you sure you want to unshare this project?",
    confirm_publish_project = "Are you sure you want to publish this project?",
    confirm_unpublish_project = "Are you sure you want to unpublish this project?",

    -- Flag project dialogs
    -- ====================
    flag_prewarning = "Are you sure you want to flag this project as inappropriate?@1@1Your username will be included in the flag report.@1@1Deliberately flagging legitimate projects will be considered a breach@1of our Terms of Service and can get you suspended.", -- @1 becomes a new line. You can add as many as you need.
    choose_flag_reason = "Please choose a reason",
    flag_reason_hack = "Security vulnerability",
    flag_reason_coc = "Code of Conduct violation",
    flag_reason_dmca = "DMCA violation",
    flag_reason_notes = "Tell us more about why you're flagging this project:",
    flag_reason_notes_placeholder = "Additional notes",

    -- User admin component
    -- ====================
    user_id = "ID",
    project_count = "Project count",
    -- Buttons
    become = "Become", -- as an admin, temporarily impersonate this user
    verify = "Verify",
    change_email = "Change Email",
    reset_password = "Reset Password",
    confirm_reset_password = "Are you sure you want to reset user @1's password?",
    send_msg = "Send a Message",
    ban = "Ban",
    unban = "Unban",
    delete_usr = "Delete",
    perma_delete_usr = "Delete Permanently",
    revive_usr = "Revive",
    confirm_revive = "Are you sure you want to undelete user @1?",
    -- New email dialog
    new_email = "New email",
    -- Send message dialog
    compose_email = "Compose a message",
    msg_subject = "Subject",
    msg_body = "Email Body",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "Are you sure you want to delete user @1?",
    warning_no_return = "WARNING! This action cannot be undone!",

    -- Change password page
    -- ====================
    change_password_title = "Change Your Password",
    current_pwd = "Current Password",
    new_pwd = "New Password",
    new_pwd_2 = "Repeat New Password",

    -- Change email page
    -- =================
    new_email_2 = "Repeat New Email",

    -- Administration page
    -- ===================
    carousel_admin = "Featured Carousels",
    user_admin = "User Administration",
    zombie_admin = "Zombie Administration",
    flagged_projects = "Flagged Projects",
    suspicious_ips = "Suspicious IPs",

    -- Error messages
    -- ==============
    err_login_failed = "Login failed",
    err_password_mismatch = "Please make sure that you have entered your@1password twice, and that both passwords match.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "Passwords do not match",
    err_email_mismatch = "Please make sure that you have entered your@1email twice, and that both emails match.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Emails do not match",
}

return locale
