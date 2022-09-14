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
    lang_name = "Deutsch",
    lang_code = "de",
    authors = "Jadga Hügle",
    last_updated = "2022/08/11", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Snap@1 starten", -- @1 becomes an italic exclamation mark (!)
    explore = "Entdecken",
    forum = "Forum",
    join = "Mitmachen",
    login = "Anmelden",
    -- User menu
    my_projects = "Meine Projekte",
    my_collections = "",
    my_public_page = "Meine öffentliche Seite",
    my_profile = "Mein Profil",
    administration = "Administration",
    logout = "Abmelden",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "",

    -- Footer
    -- ======
    -- Titles
    t_about = "Über",
    t_learning = "Lernen",
    t_tools = "Tools",
    t_support = "Support",
    t_legal = "Rechtliches",
    -- Links
    about = "Über Snap<em>!</em>",
    blog = "",
    credits = "Credits",
    requirements = "Technische Voraussetzungen",
    partners = "Partner",
    source = "Quellcode",
    events = "",
    examples = "",
    manual = "Reference Manual",
    materials = "",
    bjc = "The Beauty and Joy of Computing",
    research = "",
    offline = "",
    extensions = "Erweiterungen",
    old_snap = "",
    -- forum already translated in top navigation bar
    contact = "Kontakt",
    mirrors = "Spiegelserver",
    dmca = "DMCA",
    privacy = "Datenschutz",
    tos = "Nutzungsbedingungen",

    -- Index page
    -- ==========
    welcome = "Herzliche Willkommen bei Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "Willkommen, @1!", -- @1 becomes the current user username
    snap_description = "Snap@1 ist eine blockbasierte Programmiersprache, die Kinder und Erwachsene einlädt, spielerisch und experimentierend Informatik zu erfahren, ist aber auch eine Plattform für Informatik-Studierende sowie Forscherinnen und Forscher.",
    -- Buttons
    run_now = "",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "",
    totm = "", -- @1 becomes the actual topic of the month
    science = "",
    simulations = "",
    three_d = "",
    music = "",
    art = "",
    fractals = "",
    animations = "",
    games = "",
    cs = "",
    maths = "",
    latest = "Neueste Projekte",
    more_collections = "Explore More Collections",

    -- Events page
    events_title = "",

    -- Collections page
    collections_title = "",

    -- User Collections page
    user_collections_title = "",

    -- User Projects page
    user_projects_title = "",

    -- Sign up page
    -- ============
    signup_title = "Snap@1 Benutzerkonto erstellen", -- @1 becomes an italic exclamation mark (!)
    username = "Benutzername",
    password = "Passwort",
    password_2 = "Passwort bestätigen",
    birth_month = "",
    or_before = "", -- is preceded by a year, like "1995 or before"
    email_parent = "",
    email_user = "E-Mail-Adresse",
    email_2 = "",
    tos_agree = "Ich habe die @1 und die @2 gelesen und stimme ihnen zu", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Datenschutzerklärung",
    signup = "Registrieren",

    -- Log in page
    -- ===========
    log_into_snap = "Anmelden in Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "Eingeloggt bleiben",
    i_forgot_password = "Ich habe mein Passwort vergessen",
    i_forgot_username = "",

    -- Dates
    -- =====
    -- Month names
    january = "",
    february = "",
    march = "",
    april = "",
    may = "",
    june = "",
    july = "",
    august = "",
    september = "",
    october = "",
    november = "",
    december = "",
    -- Date format
    date = "", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
    ok = "Ok",
    cancel = "Abbrechen",
    confirm = "",

    -- Explore page
    -- ============
    published_projects = "",
    published_collections = "",

    -- Search results page
    -- ===================
    search_results = "Suchergebnisse: @1",
    project_search_results = "",
    collection_search_results = "",
    user_search_results = "",
    projects = "",
    collections = "",
    users = "",

    -- Users page
    -- ==========
    last_users = "",

    -- Search component in grids
    -- =========================
    matching = "", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "",
    -- New collection dialog
    collection_name = "",
    collection_by_thumb = "", -- @1 is the author's username

    -- Collection page
    -- ===============
    collection_by = "", -- @1 is the author's username
    -- Dates
    collection_created_date = "",
    collection_updated_date = "",
    collection_shared_date = "",
    collection_published_date = "",
    -- Buttons
    share_collection_button = "",
    unshare_collection_button = "",
    publish_collection_button = "",
    unpublish_collection_button = "",
    delete_collection_button = "",
    make_ffa = "",
    unmake_ffa = "",
    unenroll = "",
    -- Project Thumbnail
    project_by_thumb = "von @1", -- @1 is the author's username
    item_shared_info = "Dieses Projekt kann mit der Projekt-URL geteilt werden.",
    item_not_shared_info = "",
    item_published_info = "",
    item_not_published_info = "",
    confirm_uncollect = "", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "",
    collection_thumbnail_tooltip = "",

    -- Collection dialogs
    -- ==================
    confirm_share_collection = "",
    confirm_unshare_collection = "",
    confirm_publish_collection = "",
    confirm_unpublish_collection = "",
    confirm_ffa = "", -- @1 becomes a new line. You can add as many as you need.
    confirm_unffa = "", -- @1 becomes a new line. You can add as many as you need.
    confirm_unenroll = "",

    -- User public page
    -- ================
    public_page = "@1s öffentliche Seite", -- @1 becomes the user's username
    -- Admin tools
    admin_tools = "",
    latest_published_projects = "",
    latest_published_collections = "",

    -- User profile
    -- ============
    profile_title = "", -- @1 becomes the user's username
    join_date = "Mitglied seit", -- date of user creation follows
    email = "E-Mail",
    role = "",
    -- User roles
    standard = "",
    reviewer = "",
    moderator = "",
    admin = "",
    banned = "",
    -- Buttons
    change_my_password = "Mein Passwort ändern",
    change_my_email = "",
    delete_my_user = "",

    -- Project page
    -- ============
    remixed_from = "", -- @1 is the original project name, @2 is its author's username
    project_by = "", -- @1 is the username
    project_remixes_title = "",
    project_collections_title = "",
    shift_enter_note = "", -- in the notes field
    no_notes = "Dieses Projekt hat keine Notizen",
    created_date = "",
    updated_date = "",
    shared_date = "",
    published_date = "",
    -- Buttons
    see_code = "",
    edit = "Bearbeiten",
    download = "Herunterladen",
    embed = "",
    collect = "",
    delete_button = "Löschen",
    publish_button = "Veröffentlichen",
    share_button = "Teilen",
    unpublish_button = "Veröffentlichen rückgängig machen",
    unshare_button = "Teilen rückgängig machen",
    -- Flagging
    you_flagged = "",
    unflag_project = "",
    flag_project = "",

    -- Embed dialog
    -- ============
    embed_title = "",
    embed_explanation = "",
    project_title = "",
    project_author = "",
    edit_button = "",
    pause_button = "",
    embed_url = "",
    embed_code = "",

    -- Collect dialog
    -- ==============
    collect_title = "",
    collect_explanation = "",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Bist du sicher, dass du dieses Projekt löschen möchtest?",
    confirm_delete_user = "",
    confirm_delete_collection = "",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Bist du sicher, dass du dieses Projekt teilen möchtest?",
    confirm_unshare_project = "Bist du sicher, dass dieses Projekt nicht mehr geteilt werden soll?",
    confirm_publish_project = "",
    confirm_unpublish_project = "",

    -- Flag project dialogs
    -- ====================
    flag_prewarning = "", -- @1 becomes a new line. You can add as many as you need.
    choose_flag_reason = "",
    flag_reason_hack = "",
    flag_reason_coc = "",
    flag_reason_dmca = "",
    flag_reason_notes = "",
    flag_reason_notes_placeholder = "",

    -- User admin component
    -- ====================
    user_id = "",
    project_count = "",
    -- Buttons
    become = "", -- as an admin, temporarily impersonate this user
    change_email = "",
    send_msg = "",
    ban = "",
    unban = "",
    delete_usr = "",
    -- New email dialog
    new_email = "",
    -- Send message dialog
    compose_email = "",
    msg_subject = "",
    msg_body = "",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "",
    warning_no_return = "WARNUNG! Diese Aktion kann nicht rückgängig gemacht werden!",

    -- Change password page
    -- ====================
    change_password_title = "Passwort ändern",
    current_pwd = "Aktuelles Passwort",
    new_pwd = "Neues Passwort",
    new_pwd_2 = "Neues Passwort bestätigen",

    -- Change email page
    -- =================
    new_email_2 = "",

    -- Administration page
    -- ===================
    user_admin = "",
    zombie_admin = "",
    flagged_projects = "",

    -- Error messages
    -- ==============
    err_login_failed = "",
    err_password_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "",
    err_email_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "",
}

return locale
