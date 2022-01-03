-- English localization
-- ====================
-- Authors: Bernat Romagosa
-- Last updated: 03 January 2021

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
    my_profile = "My Profile",
    administration = "Administration",
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
    examples = "Example Projects",
    manual = "Reference Manual",
    materials = "Materials",
    bjc = "The Beauty and Joy of Computing",
    research = "Research",
    offline = "Offline Version",
    extensions = "Extensions",
    old_snap = "(old Snap@1)",
    -- forum already translated in top navigation bar
    contact = "Contact Us",
    mirrors = "Mirrors",
    dmca = "DMCA",
    privacy = "Privacy",
    tos = "Terms of Service",
    signup = "Sign Up",
    or_before = "or before", -- is preceded by a year, like "1995 or before"

    -- Index page
    -- ==========
    welcome = "Welcome to Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "Welcome, @1!", -- @1 becomes the current user username
    snap_description = "Snap@1 is a broadly inviting programming language for kids and adults that's also a platform for serious study of computer science.",
    -- Buttons
    run_now = "Run Snap@1 Now",
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

    -- Sign up page
    -- ============
    signup_title = "Create a Snap@1 account", -- @1 becomes an italic exclamation mark (!)
    username = "Username",
    password = "Password",
    password_2 = "Repeat Password",
    birth_month = "Month of Birth",
    email_parent = "Email address of parent or guardian",
    email_user = "Email address",
    email_2 = "Repeat email address",
    tos_agree = "I have read and agree to the @1 and the @2", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Privacy Agreement",

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

    -- Explore page
    -- ============
    published_projects = "Published Projects",
    published_collections = "Published Collections",

    -- Search results page
    -- ===================
    search_results = "Search Results: @1",
    projects = "Projects",
    collections = "Collections",
    users = "Users",

    -- Search component in grids
    -- =========================
    matching = "Matching: @1", -- @1 becomes the search term

    -- Dialogs
    -- =======
    cancel = "Cancel",
    ok = "Ok",
    confirm = "Confirm",

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "New Collection",
    -- New collection dialog
    collection_name = "Collection name?",

    -- User public page
    -- ================
    public_page = "@1's public page", -- @1 becomes the user's username
    -- Admin tools
    admin_tools = "Admin tools",

    -- User profile
    -- ============
    profile_title = "@1's profile", -- @1 becomes the user's username
    join_date = "Joined in", -- date of user creation follows
    email = "Email",
    role = "Role",
    -- User roles
    standard = "standard",
    reviewer = "reviewer",
    moderator = "moderator",
    admin = "admin",
    banned = "banned",
    -- Buttons
    change_my_password = "Change My Password",
    change_my_email = "Change My Email",
    delete_my_user = "Delete my Account",

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
    change_email = "Change Email",
    send_msg = "Send a Message",
    ban = "Ban",
    unban = "Unban",
    delete_usr = "Delete",
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
    user_admin = "User Administration",
    zombie_admin = "Zombie Administration",
    flagged_projects = "Flagged Projects",

    -- Error messages
    -- ==============
    err_password_mismatch = "Please make sure that you have entered your@1password twice, and that both passwords match.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "Passwords do not match",
    err_email_mismatch = "Please make sure that you have entered your@1email twice, and that both emails match.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Emails do not match",
}

return locale
