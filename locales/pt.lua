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
    lang_name = "Português",
    lang_code = "pt",
    authors = "Manuel Menezes de Sequeira",
    last_updated = "2022/08/11", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Correr o Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "Explorar",
    forum = "Fórum",
    join = "Aderir",
    login = "Entrar",
    -- User menu
    my_projects = "Os Meus Projectos",
    my_collections = "As Minhas Colecções",
    my_public_page = "A Minha Página Pública",
    my_profile = "O Meu Perfil",
    administration = "Administração",
    logout = "Sair",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "",

    -- Footer
    -- ======
    -- Titles
    t_about = "Acerca",
    t_learning = "Aprendizagem",
    t_tools = "Ferramentas",
    t_support = "Suporte",
    t_legal = "Legal",
    -- Links
    about = "Acerca do Snap@1",
    blog = "Blogue",
    credits = "Créditos",
    requirements = "Requisitos Técnicos",
    partners = "Parceiros",
    source = "Código Fonte",
    events = "",
    examples = "",
    manual = "Manual de Referência",
    materials = "Materiais",
    bjc = "A Beleza e o Prazer da Computação",
    research = "Investigação",
    offline = "Versão Desconectada",
    extensions = "Extensões",
    old_snap = "",
    -- forum already translated in top navigation bar
    contact = "Contacte-nos",
    mirrors = "Réplicas",
    dmca = "DMCA",
    privacy = "Privacidade",
    tos = "Termos do Serviço",

    -- Index page
    -- ==========
    welcome = "Bem-vindo ao Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "", -- @1 becomes the current user username
    snap_description = "O Snap@1 é uma linguagem de programação que apela tanto a crianças como a adultos e que é simultaneamente uma plataforma para o estudo sério da ciência da computação.",
    -- Buttons
    run_now = "",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Projectos em Destaque",
    totm = "", -- @1 becomes the actual topic of the month
    science = "Projectos Científicos",
    simulations = "",
    three_d = "",
    music = "",
    art = "Projectos Artísticos",
    fractals = "Fractais",
    animations = "",
    games = "Jogos",
    cs = "",
    maths = "",
    latest = "Projectos Mais Recentes",
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
    username = "Nome de utilizador",
    password = "Palavra-passe",
    password_2 = "Confirmação da palavra-passe",
    birth_month = "",
    or_before = "", -- is preceded by a year, like "1995 or before"
    email_parent = "",
    email_user = "Endereço de correio electrónico",
    email_2 = "Confirmação do endereço de correio electrónico",
    tos_agree = "", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "",
    signup = "Aderir",

    -- Log in page
    -- ===========
    log_into_snap = "", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "manter-me autenticado",
    i_forgot_password = "",
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
    ok = "OK",
    cancel = "Cancelar",
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
    projects = "Projectos",
    collections = "Colecções",
    users = "Utilizadores",

    -- Users page
    -- ==========
    last_users = "",

    -- Search component in grids
    -- =========================
    matching = "", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Nova Colecção",
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
    share_collection_button = "Partilhar",
    unshare_collection_button = "Deixar de Partilhar",
    publish_collection_button = "Publicar",
    unpublish_collection_button = "Deixar de Publicar",
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
    admin_tools = "Ferramentas de administração",
    latest_published_projects = "",
    latest_published_collections = "",

    -- User profile
    -- ============
    profile_title = "", -- @1 becomes the user's username
    join_date = "", -- date of user creation follows
    email = "",
    role = "Papel",
    -- User roles
    standard = "padrão",
    reviewer = "revisor",
    moderator = "moderador",
    admin = "administrador",
    banned = "banido",
    -- Buttons
    change_my_password = "Alterar a Minha Palavra-Passe",
    change_my_email = "Alterar o Meu Endereço",
    delete_my_user = "Remover a minha Conta",

    -- Project page
    -- ============
    remixed_from = "", -- @1 is the original project name, @2 is its author's username
    project_by = "", -- @1 is the username
    project_remixes_title = "",
    project_collections_title = "",
    shift_enter_note = "", -- in the notes field
    no_notes = "Este projecto não tem notas",
    created_date = "",
    updated_date = "",
    shared_date = "",
    published_date = "",
    -- Buttons
    see_code = "",
    edit = "Editar",
    download = "Descarregar",
    embed = "Incorporar",
    collect = "Adicionar a um Colecção",
    delete_button = "",
    publish_button = "",
    share_button = "",
    unpublish_button = "",
    unshare_button = "",
    -- Flagging
    you_flagged = "",
    unflag_project = "",
    flag_project = "",

    -- Embed dialog
    -- ============
    embed_title = "Opções de Incorporação",
    embed_explanation = "Por favor escolha os elementos que quer incluir no visualizador de projecto incorporado:",
    project_title = "Título do projecto",
    project_author = "Autor do projecto",
    edit_button = "Botão de edição",
    pause_button = "",
    embed_url = "",
    embed_code = "",

    -- Collect dialog
    -- ==============
    collect_title = "",
    collect_explanation = "",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Quer mesmo remover este projecto?",
    confirm_delete_user = "",
    confirm_delete_collection = "",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Quer mesmo partilhar este projecto?",
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
    become = "Tornar-se", -- as an admin, temporarily impersonate this user
    change_email = "Alterar Endereço de Correio Electrónico",
    send_msg = "",
    ban = "Banir",
    unban = "",
    delete_usr = "Remover",
    -- New email dialog
    new_email = "",
    -- Send message dialog
    compose_email = "",
    msg_subject = "",
    msg_body = "",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "",
    warning_no_return = "ATENÇÃO! Esta acção não pode ser revertida!",

    -- Change password page
    -- ====================
    change_password_title = "Alterar a Sua Palavra-passe",
    current_pwd = "Palavra-Passe Actual",
    new_pwd = "Nova Palavra-Passe",
    new_pwd_2 = "Confirmação da Nova Palavra-Passe",

    -- Change email page
    -- =================
    new_email_2 = "Confirmação do Endereço de Correio Electrónico",

    -- Administration page
    -- ===================
    user_admin = "Administração de Utilizadores",
    zombie_admin = "",
    flagged_projects = "Projectos Assinalados",

    -- Error messages
    -- ==============
    err_login_failed = "",
    err_password_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "",
    err_email_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Os endereços não coincidem",
}

return locale
