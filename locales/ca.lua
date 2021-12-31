-- Catalan localization
-- ====================
-- Authors: Bernat Romagosa
-- Last updated: 29 December 2021

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
    -- This option lets admins go back to their admin account when they"re
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
    animations = "Animaciions",
    games = "Jocs",
    cs = "Ciències de la computació",
    maths = "Matemàtiques",

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

    -- Search results page
    -- ===================
    search_results = "Resultats de la cerca: @1",
    projects = "Projectes",
    collections = "Col·leccions",
    users = "Usuaris",

    -- Search component in grids
    -- =========================
    matching = "Contenen: @1", -- @1 becomes the search term

    -- Dialogs
    -- =======
    cancel = "Cancel·la",
    ok = "D'acord",
    confirm = "Confirmació",

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Crear col·lecció",
    -- New collection dialog
    collection_name = "Nom de la col·lecció?",

    -- User public page
    -- ================
    public_page = "Pàgina pública de @1", -- @1 becomes the user's username
    -- Admin tools
    admin_tools = "Eines d'administració",

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
    err_password_mismatch = "Si us plau, assegura't que has introduït correctament@1la teva contrasenya dues vegades.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "Les contrasenyes no coincideixen",
    err_email_mismatch = "Si us plau, assegura't que has introduït correctament@1la teva adreça electrònica dues vegades.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Les adreces no coincideixen",
}

return locale
