-- Catalan localization
-- ====================
-- Authors: Bernat Romagosa
-- Last updated: 25 July 2022

local locale = {
    -- Meta data
    -- =========
    lang_name = "Català",
    lang_code = "ca",

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Obre Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "Explora",
    forum = "Fòrum",
    join = "Uneix-t'hi",
    login = "Entra",
    -- User menu
    my_projects = "Els meus projectes",
    my_collections = "Les meves col·leccions",
    my_public_page = "La meva pàgina pública",
    my_profile = "El meu perfil",
    administration = "Administració",
    logout = "Tanca la sessió",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "Des-esdevingues",

    -- Footer
    -- ======
    -- Titles
    t_about = "Informació",
    t_learning = "Aprenentatge",
    t_tools = "Eines",
    t_support = "Suport",
    t_legal = "Legal",
    -- Links
    about = "Sobre Snap@1",
    blog = "Blog",
    credits = "Crèdits",
    requirements = "Requeriments tècnics",
    partners = "Col·laboradors",
    source = "Codi font",
    examples = "Projectes d'exemple",
    manual = "Manual de referència",
    materials = "Materials",
    bjc = "The Beauty and Joy of Computing",
    research = "Recerca",
    offline = "Versió sense connexió",
    extensions = "Extensions",
    old_snap = "(Snap@1 antic)",
    -- forum already translated in top navigation bar
    contact = "Contacte",
    mirrors = "Rèpliques",
    dmca = "Drets d'autor",
    privacy = "Privacitat",
    tos = "Condicions del servei",

    -- Index page
    -- ==========
    welcome = "Benvinguts a Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "Hola, @1!", -- @1 becomes the current user username
    snap_description = "Snap@1 és un llenguatge àmpliament acollidor tant per a nens i nenes com per a adults, així com una plataforma per a un estudi rigorós de les ciències de la computació.",
    -- Buttons
    run_now = "Obre Snap@1 ara",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Projectes destacats",
    totm = "Tema del mes: @1", -- @1 becomes the actual topic of the month
    science = "Projectes de ciència",
    simulations = "Simulaciions",
    three_d = "3D",
    music = "Música",
    art = "Projectes artístics",
    fractals = "Fractals",
    animations = "Animacions",
    games = "Jocs",
    cs = "Ciències de la computació",
    maths = "Matemàtiques",
    latest = "Últims projectes publicats",
    more_collections = "Explora més col·leccions",

    -- Collections page
    collections_title = "Col·leccions públiques",

    -- Sign up page
    -- ============
    signup_title = "Crea un compte d'Snap@1", -- @1 becomes an italic exclamation mark (!)
    username = "Nom d'usuari",
    password = "Contrasenya",
    password_2 = "Contrasenya (repetir)",
    birth_month = "Mes de naixement",
    email_parent = "Adreça electrònica de la mare, pare o tutor",
    email_user = "Adreça electrònica",
    email_2 = "Adreça electrònica (repetir)",
    tos_agree = "He llegit i accepto les @1 i l'@2", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Acord de privacitat",
    signup = "Registra-t'hi",
    or_before = "o abans", -- is preceded by a year, like "1995 or before"

    -- Log in page
    -- ===========
    log_into_snap = "Entra a Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "mantén-me connectat",
    i_forgot_password = "He oblidat la meva contrasenya",
    i_forgot_username = "He oblidat el meu nom d'usuari",

    -- Dates
    -- =====
    -- Month names
    january = "Gener",
    february = "Febrer",
    march = "Març",
    april = "Abril",
    may = "Maig",
    june = "Juny",
    july = "Juliol",
    august = "Agost",
    september = "Setembre",
    october = "Octubre",
    november = "Novembre",
    december = "Desembre",
    -- Date format
    date = "@1 de @2 de @3", -- @1 is the day, @2 is the month name, @3 is the year

    -- Explore page
    -- ============
    published_projects = "Projectes públics",
    published_collections = "Col·leccions públiques",

    -- Dialogs
    -- =======
    ok = "D'acord",
    cancel = "Cancel·la",
    confirm = "Confirmació",

    -- Search results page
    -- ===================
    search_results = "Resultats de la cerca: @1",
    projects = "Projectes",
    collections = "Col·leccions",
    users = "Usuaris",

    -- Search component in grids
    -- =========================
    matching = "Contenen: @1", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Crear col·lecció",
    -- New collection dialog
    collection_name = "Nom de la col·lecció?",
    collection_by_thumb = "de @1", -- @1 is the author's username

    -- Collection page
    -- ===============
    collection_by = "per @1", -- @1 is the author's username
    -- Dates
    collection_created_date = "Creada el",
    collection_updated_date = "Actualitzada el",
    collection_shared_date = "Compartida el",
    collection_published_date = "Publicada el",
    -- Buttons
    share_collection_button = "Comparteix",
    unshare_collection_button = "Fes privada",
    publish_collection_button = "Publica",
    unpublish_collection_button = "Despublica",
    delete_collection_button = "Elimina",
    make_ffa = "Obre a tothom",
    unmake_ffa = "No obris a tothom",
    unenroll = "Deixa de ser editor",
    -- Project Thumbnail
    project_by_thumb = "per @1", -- @1 is the author's username
    item_shared_info = "Aquest element es pot compartir via URL.",
    item_not_shared_info = "Aquest element és privat. Només el pots veure tu.",
    item_published_info = "Aquest element està publicat a la web de la comunitat i pot ser cercat i afegit a col·leccions públiques.",
    item_not_published_info = "Aquest element no ha estat publicat a la web de la comunitat.",
    confirm_uncollect = "Segur que vols eliminar aquest projecte@1de la col·lecció?", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "Elimina de la col·lecció",
    collection_thumbnail_tooltip = "Tria per a la imatge en miniatura de la col·lecció",

    -- Collection dialogs
    -- ===========================================
    confirm_share_collection = "Segur que vols compartir aquesta col·lecció?",
    confirm_unshare_collection = "Segur que vols deixar de compartir aquesta col·lecció?",
    confirm_publish_collection = "Segur que vols publicar aquesta col·lecció?",
    confirm_unpublish_collection = "Segur que vols despublicar aquesta col·lecció?",
    confirm_ffa = "Segur que vols obrir aquesta col·lecció@1i que tothom hi pugui contribuir els seus@1projectes publicats?", -- @1 becomes a new line. You can add as many as you need.
    confirm_unffa = "Segur que vols tancar aquesta col·lecció@1i que només propietari i editors hi puguin@1contribuir els seus projectes publicats?", -- @1 becomes a new line. You can add as many as you need.
    confirm_unenroll = "Segur que vols deixar de ser editor d'aquesta col·lecció?",

    -- User public page
    -- ================
    public_page = "Pàgina pública de @1", -- @1 becomes the user's username
    -- Admin tools
    admin_tools = "Eines d'administració",
    latest_published_projects = "Últims projectes publicats",
    latest_published_collections = "Últimes col·leccions publicades",

    -- User profile
    -- ============
    profile_title = "Perfil de @1", -- @1 becomes the user's username
    join_date = "Data de registre:", -- date of user creation follows
    email = "Email:",
    role = "Rol:",
    -- User roles
    standard = "estàndard",
    reviewer = "revisor",
    moderator = "moderador",
    admin = "administrador",
    banned = "suspès",
    -- Buttons
    change_my_password = "Canvia la contrasenya",
    change_my_email = "Canvia el correu electrònic",
    delete_my_user = "Esborra el meu usuari",

    -- Project page
    -- ============
    remixed_from = "(reinvenció de @1, de @2)", -- @1 is the original project name, @2 is its author's username
    project_by = "per @1", -- @1 is the username
    project_remixes_title = "Reinvencions públiques d'aquest projecte",
    project_collections_title = "Col·leccions públiques que contenen aquest projecte",
    shift_enter_note = "Prem Shift + Intro per introduir un salt de línia", -- in the notes field
    no_notes = "Aquest projecte no té descripció",
    created_date = "Creat el",
    updated_date = "Actualitzat el",
    shared_date = "Compartit el",
    published_date = "Publicat el",
    -- Buttons
    see_code = "Examina",
    edit = "Edita",
    download = "Descarrega",
    embed = "Incrusta",
    collect = "Afegeix a col·lecció",
    delete_button = "Elimina",
    publish_button = "Publica",
    share_button = "Comparteix",
    unpublish_button = "Despublica",
    unshare_button = "Fes privat",
    -- Flagging
    you_flagged = "Has denunciat aquest projecte",
    unflag_project = "Retira la denúncia",
    flag_project = "Denuncia aquest projecte",

    -- Embed dialog
    -- ============
    embed_title = "Opcions d'incrustació",
    embed_explanation = "Escull els elements que vols incloure al projecte incrustat:",
    project_title = "Títol del projecte",
    project_author = "Autor del projecte",
    edit_button = "Botó d'edició",
    pause_button = "Botó de pausa",
    embed_url = "URL d'incrustació",
    embed_code = "Codi d'incrustació",

    -- Collect dialog
    -- ==============
    collect_title = "Afegeix projecte a col·lecció",
    collect_explanation = "Selecciona la col·lecció a què vols afegir aquest projecte",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Segur que vols eliminar aquest projecte?",
    confirm_delete_user = "Segur que vols eliminar aquest usuari?",
    confirm_delete_collection = "Segur que vols eliminar aquesta col·lecció?",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Segur que vols compartir aquest projecte?",
    confirm_unshare_project = "Segur que vols deixar de compartir aquest projecte?",
    confirm_publish_project = "Segur que vols publicar aquest projecte?",
    confirm_unpublish_project = "Segur que vols despublicar aquest projecte?",

    -- Flag project dialogs
    -- ====================
    flag_prewarning = "Segur que vols denunciar aquest projecte?@1@1La denúncia inclourà el teu nom d'usuari.@1@1Denunciar projectes legítims sense motiu es considera un incompliment dels@1termes d'ús, i pot resultar en la suspensió del teu usuari.", -- @1 becomes a new line. You can add as many as you need.
    choose_flag_reason = "Escull el motiu de la denúncia",
    flag_reason_hack = "Abús d'un forat de seguretat",
    flag_reason_coc = "Incompliment del codi de conducta",
    flag_reason_dmca = "Violació de drets d'autor",
    flag_reason_notes = "Explica'ns més coses sobre els motius de la teva denúncia:",
    flag_reason_notes_placeholder = "Notes addicionals",

    -- User admin component
    -- ====================
    user_id = "ID:",
    project_count = "Nombre de projectes:",
    -- Buttons
    become = "Esdevindre", -- as an admin, temporarily impersonate this user
    change_email = "Canviar email",
    send_msg = "Enviar un missatge",
    ban = "Suspendre",
    unban = "Des-suspendre",
    delete_usr = "Eliminar",
    -- New email dialog
    new_email = "Nou email",
    -- Send message dialog
    compose_email = "Escriu un missatge",
    msg_subject = "Assumpte",
    msg_body = "Cos del missatge",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "Segur que vols eliminar l'usuari @1?",
    warning_no_return = "ATENCIÓ! Aquesta acció no es pot desfer!",

    -- Change password page
    -- ====================
    change_password_title = "Canvia la teva contrasenya",
    current_pwd = "Contrasenya actual",
    new_pwd = "Nova contrasenya",
    new_pwd_2 = "Nova contrasenya (repetir)",

    -- Change email page
    -- =================
    new_email_2 = "Nou email (repetir)",

    -- Administration page
    -- ===================
    user_admin = "Administració d'usuaris",
    zombie_admin = "Administració de zombis",
    flagged_projects = "Projectes denunciats",

    -- Error messages
    -- ==============
    err_login_failed = "Error d'autenticació",
    err_password_mismatch = "Si us plau, assegura't que has introduït correctament@1la teva contrasenya dues vegades.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "Les contrasenyes no coincideixen",
    err_email_mismatch = "Si us plau, assegura't que has introduït correctament@1la teva adreça electrònica dues vegades.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Les adreces no coincideixen",
}

return locale
