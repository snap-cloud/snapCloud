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
    lang_name = "Italiano",
    lang_code = "it",
    authors = "Stefano Federici",
    last_updated = "2022/08/11", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Esegui Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "Esplora",
    forum = "Forum",
    join = "Iscriviti",
    login = "Entra",
    -- User menu
    my_projects = "I miei Progetti",
    my_collections = "Le mie Gallerie",
    my_public_page = "La Mia Pagina Pubblica",
    my_profile = "Il mio Profilo",
    administration = "Amministrazione:",
    logout = "Esci",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "",

    -- Footer
    -- ======
    -- Titles
    t_about = "Info",
    t_learning = "Apprendimento",
    t_tools = "Strumenti",
    t_support = "Supporto",
    t_legal = "Informazioni Legali",
    -- Links
    about = "",
    blog = "Blog",
    credits = "Crediti",
    requirements = "Requisiti Tecnici",
    partners = "Collaboratori",
    source = "Codice Sorgente",
    events = "",
    examples = "",
    manual = "Manuale di Riferimento",
    materials = "Materiali",
    bjc = "The Beauty and Joy of Computing",
    research = "Ricerca",
    offline = "Versione Offline",
    extensions = "Estensioni",
    old_snap = "",
    -- forum already translated in top navigation bar
    contact = "Contattaci",
    mirrors = "Mirror",
    dmca = "Copyright",
    privacy = "Privacy",
    tos = "Condizioni di Servizio",

    -- Index page
    -- ==========
    welcome = "Benvenuto in Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "", -- @1 becomes the current user username
    snap_description = "",
    -- Buttons
    run_now = "",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Progetti in Primo Piano",
    totm = "", -- @1 becomes the actual topic of the month
    science = "Scienza",
    simulations = "",
    three_d = "",
    music = "",
    art = "Arte",
    fractals = "Frattali",
    animations = "Animazioni",
    games = "Giochi",
    cs = "",
    maths = "",
    latest = "Ultimi Progetti",
    more_collections = "",

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
    signup_title = "", -- @1 becomes an italic exclamation mark (!)
    username = "Username",
    password = "Password",
    password_2 = "Ripeti la Password",
    birth_month = "Mese di Nascita",
    or_before = "", -- is preceded by a year, like "1995 or before"
    email_parent = "Indirizzo email del genitore o del tutore legale",
    email_user = "Indirizzo email",
    email_2 = "Ripeti l'indirizzo email",
    tos_agree = "", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "",
    signup = "Iscriviti",

    -- Log in page
    -- ===========
    log_into_snap = "", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "mantieni accesso",
    i_forgot_password = "",
    i_forgot_username = "",

    -- Dates
    -- =====
    -- Month names
    january = "Gennaio",
    february = "Febbraio",
    march = "Marzo",
    april = "Aprile",
    may = "Maggio",
    june = "Giugno",
    july = "Luglio",
    august = "Agosto",
    september = "Settembre",
    october = "Ottobre",
    november = "Novembre",
    december = "Dicembre",
    -- Date format
    date = "", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
    ok = "Ok",
    cancel = "Annulla",
    confirm = "",

    -- Explore page
    -- ============
    published_projects = "",
    published_collections = "",

    -- Search results page
    -- ===================
    search_results = "",
    project_search_results = "",
    collection_search_results = "",
    user_search_results = "",
    projects = "Progetti",
    collections = "Gallerie",
    users = "Utenti",

    -- Users page
    -- ==========
    last_users = "",

    -- Search component in grids
    -- =========================
    matching = "", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Nuova Galleria",
    -- New collection dialog
    collection_name = "Nome della galleria?",
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
    share_collection_button = "Condividi",
    unshare_collection_button = "Rendi non condiviso",
    publish_collection_button = "Pubblica",
    unpublish_collection_button = "Rendi non pubblico",
    delete_collection_button = "",
    make_ffa = "",
    unmake_ffa = "",
    unenroll = "",
    -- Project Thumbnail
    project_by_thumb = "", -- @1 is the author's username
    item_shared_info = "",
    item_not_shared_info = "",
    item_published_info = "",
    item_not_published_info = "",
    confirm_uncollect = "", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "",
    collection_thumbnail_tooltip = "Usa come anteprima della galleria",

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
    public_page = "", -- @1 becomes the user's username
    -- Admin tools
    admin_tools = "Strumenti di amministrazione",
    latest_published_projects = "",
    latest_published_collections = "",

    -- User profile
    -- ============
    profile_title = "", -- @1 becomes the user's username
    join_date = "", -- date of user creation follows
    email = "",
    role = "Ruolo",
    -- User roles
    standard = "standard",
    reviewer = "revisore",
    moderator = "moderatore",
    admin = "amministratore",
    banned = "bloccato",
    -- Buttons
    change_my_password = "Cambia la Mia Password",
    change_my_email = "Cambia la Mia Email",
    delete_my_user = "Cancella il mio Account",

    -- Project page
    -- ============
    remixed_from = "", -- @1 is the original project name, @2 is its author's username
    project_by = "", -- @1 is the username
    project_remixes_title = "",
    project_collections_title = "",
    shift_enter_note = "", -- in the notes field
    no_notes = "Questo progetto non ha note",
    created_date = "",
    updated_date = "",
    shared_date = "",
    published_date = "",
    -- Buttons
    see_code = "Guarda dentro",
    edit = "Modifica",
    download = "Scarica",
    embed = "Includi",
    collect = "Aggiungi alla Galleria",
    delete_button = "",
    publish_button = "",
    share_button = "",
    unpublish_button = "",
    unshare_button = "",
    -- Flagging
    you_flagged = "",
    unflag_project = "",
    flag_project = "Segnala questo progetto",

    -- Embed dialog
    -- ============
    embed_title = "Opzioni",
    embed_explanation = "Seleziona gli elementi che vorresti includere nel visualizzatore del progetto:",
    project_title = "Titolo del progetto",
    project_author = "Autore del progetto",
    edit_button = "Pulsante per la modifica",
    pause_button = "",
    embed_url = "",
    embed_code = "",

    -- Collect dialog
    -- ==============
    collect_title = "Aggiungi il progetto a una galleria",
    collect_explanation = "Seleziona la galleria alla quale vuoi aggiungere il progetto",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Sei sicuro di voler eliminare questo progetto?",
    confirm_delete_user = "",
    confirm_delete_collection = "",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Sei sicuro di voler condividere questo progetto?",
    confirm_unshare_project = "",
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
    become = "Diventa", -- as an admin, temporarily impersonate this user
    change_email = "Cambia Email",
    send_msg = "",
    ban = "Blocca",
    unban = "",
    delete_usr = "Elimina",
    -- New email dialog
    new_email = "",
    -- Send message dialog
    compose_email = "",
    msg_subject = "",
    msg_body = "",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "",
    warning_no_return = "ATTENZIONE! Questa azione non può essere annullata!",

    -- Change password page
    -- ====================
    change_password_title = "Cambia la Tua Password",
    current_pwd = "Password attuale",
    new_pwd = "Nuova Password",
    new_pwd_2 = "Ripeti la Nuova Password",

    -- Change email page
    -- =================
    new_email_2 = "Ripeti la Nuova Email",

    -- Administration page
    -- ===================
    user_admin = "Amministrazione Utenti",
    zombie_admin = "Amministrazione Utenti Rimossi",
    flagged_projects = "Progetti Segnalati",

    -- Error messages
    -- ==============
    err_login_failed = "",
    err_password_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "",
    err_email_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Le email non corrispondono",
}

return locale
