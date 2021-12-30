-- English localization
-- ====================
-- Authors: Bernat Romagosa
-- Last updated: 29 December 2021

-- How to translate
-- ----------------
-- Translate each text string to the target language leaving intact the two
-- double quotes.
-- Example: "Log In" should become "Entrar"
--
-- If you need to use a double quote, either escape it with a backslash (\")
--
-- The "@" symbol followed by a number represents a parameter that the system
-- will substitute by a value, for example a username.
-- Example: "Welcome, @1!" will become "Welcome, Mary!" when Mary is logged in.
--
-- You need to leave "@" marks intact, but you can change its order in your
-- translation if your language requires so.
-- Example: "

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
    -- This option lets admins go back to their admin account when they"re
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
    email_parent = "Email address of parent or guardian",
    email_user = "Email address",
    email_2 = "Repeat email address",
    tos_agree = "I have read and agree to the @1 and the @2", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Privacy Agreement",

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
