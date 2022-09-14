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
    lang_name = "Français",
    lang_code = "fr",
    authors = "Anatole",
    last_updated = "2022/08/11", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Lancer Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "Explorer",
    forum = "Forum",
    join = "Rejoindre",
    login = "Se connecter",
    -- User menu
    my_projects = "Mes projets",
    my_collections = "Mes Collections",
    my_public_page = "Ma page publique",
    my_profile = "Mon profil",
    administration = "Administration",
    logout = "Déconnexion",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "",

    -- Footer
    -- ======
    -- Titles
    t_about = "",
    t_learning = "Apprendre",
    t_tools = "Outils",
    t_support = "Aide",
    t_legal = "Juridique",
    -- Links
    about = "",
    blog = "Blog",
    credits = "Remerciements",
    requirements = "Applications requises",
    partners = "Partenaires",
    source = "Code Source",
    events = "",
    examples = "",
    manual = "Manuel de Reference",
    materials = "Matériel",
    bjc = "La beauté et la joie de l'informatique",
    research = "Recherche",
    offline = "Version hors-ligne",
    extensions = "Extensions",
    old_snap = "",
    -- forum already translated in top navigation bar
    contact = "Contactez-nous",
    mirrors = "Répliques",
    dmca = "DMCA",
    privacy = "Politique de confidentialité",
    tos = "Conditions d'utilisation",

    -- Index page
    -- ==========
    welcome = "Bienvenue sur Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "", -- @1 becomes the current user username
    snap_description = "",
    -- Buttons
    run_now = "",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Projets Présentés",
    totm = "", -- @1 becomes the actual topic of the month
    science = "Projets Scientifiques",
    simulations = "",
    three_d = "",
    music = "",
    art = "Projets d'Art",
    fractals = "Formes",
    animations = "",
    games = "Jeux",
    cs = "",
    maths = "",
    latest = "Derniers projets",
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
    username = "Nom d'utilisateur",
    password = "Mot de passe",
    password_2 = "Réécrivez le mot de passe",
    birth_month = "Mois de naissance",
    or_before = "", -- is preceded by a year, like "1995 or before"
    email_parent = "Adresse e-mail du parent ou du responsable légal",
    email_user = "Adresse e-mail",
    email_2 = "Réécrire l'email",
    tos_agree = "", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Accord sur la confidentialité",
    signup = "S'inscrire",

    -- Log in page
    -- ===========
    log_into_snap = "", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "Rester connecté",
    i_forgot_password = "* J'ai oublié mon mot de passe",
    i_forgot_username = "",

    -- Dates
    -- =====
    -- Month names
    january = "Janvier",
    february = "Février",
    march = "Mars",
    april = "Avril",
    may = "Mai",
    june = "Juin",
    july = "Juillet",
    august = "Août",
    september = "Septembre",
    october = "Octobre",
    november = "Novembre",
    december = "Décembre",
    -- Date format
    date = "", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
    ok = "Ok",
    cancel = "Annuler",
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
    projects = "Projets",
    collections = "Collections",
    users = "Utilisateurs",

    -- Users page
    -- ==========
    last_users = "",

    -- Search component in grids
    -- =========================
    matching = "", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Nouvelle Collection",
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
    share_collection_button = "Partager",
    unshare_collection_button = "Annuler le partage",
    publish_collection_button = "Publier",
    unpublish_collection_button = "Dépublier",
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
    public_page = "", -- @1 becomes the user's username
    -- Admin tools
    admin_tools = "Outils administratifs",
    latest_published_projects = "",
    latest_published_collections = "",

    -- User profile
    -- ============
    profile_title = "", -- @1 becomes the user's username
    join_date = "", -- date of user creation follows
    email = "",
    role = "Rôle",
    -- User roles
    standard = "standard",
    reviewer = "critique",
    moderator = "modérateur",
    admin = "admin",
    banned = "banni",
    -- Buttons
    change_my_password = "Changer mon mot de passe",
    change_my_email = "Changer mon email",
    delete_my_user = "Supprimmer mon compte",

    -- Project page
    -- ============
    remixed_from = "", -- @1 is the original project name, @2 is its author's username
    project_by = "", -- @1 is the username
    project_remixes_title = "",
    project_collections_title = "",
    shift_enter_note = "", -- in the notes field
    no_notes = "Ce projet n'a pas de notes",
    created_date = "",
    updated_date = "",
    shared_date = "",
    published_date = "",
    -- Buttons
    see_code = "Voir le code",
    edit = "Modifier",
    download = "Télécharger",
    embed = "Intégrer",
    collect = "",
    delete_button = "",
    publish_button = "",
    share_button = "",
    unpublish_button = "",
    unshare_button = "",
    -- Flagging
    you_flagged = "",
    unflag_project = "",
    flag_project = "Signaler ce projet",

    -- Embed dialog
    -- ============
    embed_title = "Options d'intégration",
    embed_explanation = "Veuillez sélectionner les éléments que vous souhaitez inclure dans la vue du projet intégré :",
    project_title = "Nom du projet",
    project_author = "Auteur du projet",
    edit_button = "Bouton d'édition",
    pause_button = "",
    embed_url = "",
    embed_code = "",

    -- Collect dialog
    -- ==============
    collect_title = "",
    collect_explanation = "Sélectionnez la collection où vous voulez ajouter ce projet :",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Êtes-vous sûr de vouloir supprimer ce projet",
    confirm_delete_user = "",
    confirm_delete_collection = "",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Êtes-vous sûr de vouloir partager ce projet ?",
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
    become = "Devenir", -- as an admin, temporarily impersonate this user
    change_email = "Changer l'email",
    send_msg = "",
    ban = "Banni",
    unban = "",
    delete_usr = "Supprimer",
    -- New email dialog
    new_email = "",
    -- Send message dialog
    compose_email = "",
    msg_subject = "",
    msg_body = "",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "",
    warning_no_return = "ATTENTION ! Cette action est irréversible !",

    -- Change password page
    -- ====================
    change_password_title = "Changer votre mot de passe",
    current_pwd = "Mot de passe actuel",
    new_pwd = "Nouveau mot de passe",
    new_pwd_2 = "Réécrire le nouveau mot de passe",

    -- Change email page
    -- =================
    new_email_2 = "Réécrire le nouvel e-mail",

    -- Administration page
    -- ===================
    user_admin = "Administration utilisateur",
    zombie_admin = "",
    flagged_projects = "Projets Signalés",

    -- Error messages
    -- ==============
    err_login_failed = "",
    err_password_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "",
    err_email_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Les emails ne correspondent pas",
}

return locale
