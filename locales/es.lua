-- Spanish localization
-- ====================
-- Authors: Bernat Romagosa
-- Last updated: 10 August 2022

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
    lang_name = "Castellano",
    lang_code = "es",

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Abre Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "Explora",
    forum = "Foro",
    join = "Únete",
    login = "Entra",
    -- User menu
    my_projects = "Mis proyectos",
    my_collections = "Mis colecciones",
    my_public_page = "Mi página pública",
    my_profile = "Mi perfil",
    administration = "Administración",
    logout = "Cierra la sesión",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "Dessuplantar",

    -- Footer
    -- ======
    -- Titles
    t_about = "Información",
    t_learning = "Aprendizaje",
    t_tools = "Herramientas",
    t_support = "Soporte",
    t_legal = "Legal",
    -- Links
    about = "Acerca de Snap@1",
    blog = "Blog",
    credits = "Créditos",
    requirements = "Requisitos técnicos",
    partners = "Colaboradores",
    source = "Código fuente",
    events = "Eventos",
    examples = "Proyectos de ejemplo",
    manual = "Manual de referencia",
    materials = "Materiales",
    bjc = "The Beauty and Joy of Computing",
    research = "Investigación",
    offline = "Versión sin conexión",
    extensions = "Extensiones",
    old_snap = "(Snap@1 antiguo)",
    -- forum already translated in top navigation bar
    contact = "Contacto",
    mirrors = "Réplicas",
    dmca = "Derechos de autor",
    privacy = "Privacidad",
    tos = "Condiciones del servicio",

    -- Index page
    -- ==========
    welcome = "Bienvenidos a Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "¡Hola, @1!", -- @1 becomes the current user username
    snap_description = "Snap@1 es un lenguaje ámpliamente acogedor tanto para niños y niñas como para adultos, así como también una plataforma para un estudio riguroso de las ciencias de la computación.",
    -- Buttons
    run_now = "Abre Snap@1 ahora",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Proyectos destacados",
    totm = "Tema del mes: @1", -- @1 becomes the actual topic of the month
    science = "Proyectos de ciencia",
    simulations = "Simulaciones",
    three_d = "3D",
    music = "Música",
    art = "Proyectos artísticos",
    fractals = "Fractales",
    animations = "Animaciones",
    games = "Juegos",
    cs = "Ciencias de la computación",
    maths = "Matemáticas",
    latest = "Últimos proyectos publicados",
    more_collections = "Explora más colecciones",

    -- Events page
    events_title = "Eventos de Snap@1",

    -- Collections page
    collections_title = "Colecciones públicas",

    -- User Collections page
    user_collections_title = "Colecciones públicas de @1",

    -- User Projects page
    user_projects_title = "Proyectos públicos de @1",

    -- Sign up page
    -- ============
    signup_title = "Crea una cuenta en Snap@1", -- @1 becomes an italic exclamation mark (!)
    username = "Nombre de usuario",
    password = "Contraseña",
    password_2 = "Contraseña (repetir)",
    birth_month = "Mes de nacimiento",
    email_parent = "Dirección electrónica de la madre, padre o tutor",
    email_user = "Dirección electrónica",
    email_2 = "Dirección electrónica (repetir)",
    tos_agree = "He leído y acepto las @1 y el @2", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Acuerdo de privacidad",
    signup = "Regístrate",
    or_before = "o antes", -- is preceded by a year, like "1995 or before"

    -- Log in page
    -- ===========
    log_into_snap = "Entra a Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "mantenme conectado",
    i_forgot_password = "He olvidado mi contraseña",
    i_forgot_username = "He olvidado mi nombre de usuario",

    -- Dates
    -- =====
    -- Month names
    january = "Enero",
    february = "Febrero",
    march = "Marzo",
    april = "Abril",
    may = "Mayo",
    june = "Junio",
    july = "Julio",
    august = "Agosto",
    september = "Septiembre",
    october = "Octubre",
    november = "Noviembre",
    december = "Diciembre",
    -- Date format
    date = "@1 de @2 de @3", -- @1 is the day, @2 is the month name, @3 is the year

    -- Explore page
    -- ============
    published_projects = "Proyectos públicos",
    published_collections = "Colecciones públicas",

    -- Dialogs
    -- =======
    ok = "Acepta",
    cancel = "Cancela",
    confirm = "Confirmación",

    -- Search results page
    -- ===================
    search_results = "Resultados de la búsqueda: @1",
    project_search_results = "Proyectos que contienen @1",
    collection_search_results = "Colecciones que contienen @1",
    user_search_results = "Usuarios que contienen @1",
    projects = "Proyectos",
    collections = "Colecciones",
    users = "Usuarios",

    -- Users page
    -- ==========
    last_users = "Últimos usuarios registrados",

    -- Search component in grids
    -- =========================
    matching = "Contienen: @1", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Crear colección",
    -- New collection dialog
    collection_name = "Nombre de la colección?",
    collection_by_thumb = "de @1", -- @1 is the author's username

    -- Collection page
    -- ===============
    collection_by = "por @1", -- @1 is the author's username
    -- Dates
    collection_created_date = "Creada en",
    collection_updated_date = "Actualizada en",
    collection_shared_date = "Compartida en",
    collection_published_date = "Publicada en",
    -- Buttons
    share_collection_button = "Comparte",
    unshare_collection_button = "Haz privada",
    publish_collection_button = "Publica",
    unpublish_collection_button = "Despublica",
    delete_collection_button = "Elimina",
    make_ffa = "Abre a todo el mundo",
    unmake_ffa = "No abras a todo el mundo",
    unenroll = "Deja de ser editor",
    -- Project Thumbnail
    project_by_thumb = "por @1", -- @1 is the author's username
    item_shared_info = "Este elemento se puede compartir vía URL.",
    item_not_shared_info = "Este elemento es privado. Solo puedes verlo tú.",
    item_published_info = "Este elemento está publicado en la web de la comunidad y puede ser buscado y añadido a colecciones públicas.",
    item_not_published_info = "Este elemento no ha estado publicado en la web de la comunidad.",
    confirm_uncollect = "¿Seguro que quieres eliminar este proyecto@1de la colección?", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "Elimina de la colección",
    collection_thumbnail_tooltip = "Escoge para la imagen en miniatura de la colección",

    -- Collection dialogs
    -- ===========================================
    confirm_share_collection = "¿Seguro que quieres compartir esta colección?",
    confirm_unshare_collection = "¿Seguro que quieres dejar de compartir esta colección?",
    confirm_publish_collection = "¿Seguro que quieres publicar esta colección?",
    confirm_unpublish_collection = "¿Seguro que quieres despublicar esta colección?",
    confirm_ffa = "¿Seguro que quieres abrir esta colección@1y que todo el mundo pueda contribuir sus@1proyectos publicados?", -- @1 becomes a new line. You can add as many as you need.
    confirm_unffa = "¿Seguro que quieres cerrar esta colección@1y que solo propietario y editores puedan@1contribuir sus proyectos publicados?", -- @1 becomes a new line. You can add as many as you need.
    confirm_unenroll = "¿Seguro que quieres dejar de ser editor de esta colección?",

    -- User public page
    -- ================
    public_page = "Página pública de @1", -- @1 becomes the user's username
    -- Admin tools
    admin_tools = "Herramientas de administración",
    latest_published_projects = "Últimos proyectos publicados",
    latest_published_collections = "Últimas colecciones publicadas",

    -- User profile
    -- ============
    profile_title = "Perfil de @1", -- @1 becomes the user's username
    join_date = "Fecha de registro:", -- date of user creation follows
    email = "Email:",
    role = "Rol:",
    -- User roles
    standard = "estándar",
    reviewer = "revisor",
    moderator = "moderador",
    admin = "administrador",
    banned = "suspendido",
    -- Buttons
    change_my_password = "Cambia la contraseña",
    change_my_email = "Cambia el correo electrónico",
    delete_my_user = "Elimina mi usuario",

    -- Project page
    -- ============
    remixed_from = "(reinvención de @1, de @2)", -- @1 is the original project name, @2 is its author's username
    project_by = "por @1", -- @1 is the username
    project_remixes_title = "Reinvenciones públicas de este proyecto",
    project_collections_title = "Colecciones públicas que contienen este proyecto",
    shift_enter_note = "Pulsa Shift + Intro para introducir un salto de línea", -- in the notes field
    no_notes = "Este proyecto no tiene descripción",
    created_date = "Creado el",
    updated_date = "Actualizado el",
    shared_date = "Compartido el",
    published_date = "Publicado el",
    -- Buttons
    see_code = "Examina",
    edit = "Edita",
    download = "Descarga",
    embed = "Incrusta",
    collect = "Añade a colección",
    delete_button = "Elimina",
    publish_button = "Publica",
    share_button = "Comparte",
    unpublish_button = "Despublica",
    unshare_button = "Haz privado",
    -- Flagging
    you_flagged = "Has denunciado este proyecto",
    unflag_project = "Retira la denuncia",
    flag_project = "Denuncia este proyecto",

    -- Embed dialog
    -- ============
    embed_title = "Opciones de incrustación",
    embed_explanation = "Escoge los elementos que quieres incluir en el proyecto incrustado:",
    project_title = "Título del proyecto",
    project_author = "Autor del proyecto",
    edit_button = "Botón de edición",
    pause_button = "Botó de pausa",
    embed_url = "URL de incrustación",
    embed_code = "Código de incrustación",

    -- Collect dialog
    -- ==============
    collect_title = "Añade proyecto a colección",
    collect_explanation = "Selecciona la colección a qué quieres añadir este proyecto",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "¿Seguro que quieres eliminar este proyecto?",
    confirm_delete_user = "¿Seguro que quieres eliminar este usuario?",
    confirm_delete_collection = "¿Seguro que quieres eliminar esta colección?",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "¿Seguro que quieres compartir este proyecto?",
    confirm_unshare_project = "¿Seguro que quieres dejar de compartir este proyecto?",
    confirm_publish_project = "¿Seguro que quieres publicar este proyecto?",
    confirm_unpublish_project = "¿Seguro que quieres despublicar este proyecto?",

    -- Flag project dialogs
    -- ====================
    flag_prewarning = "¿Seguro que quieres denunciar este proyecto?@1@1La denuncia incluirá tu nombre de usuario.@1@1Denunciar proyectos legítimos sin motivo se considera un incumplimiento de los@1términos de uso, y puede resultar en la suspensión de tu usuario.", -- @1 becomes a new line. You can add as many as you need.
    choose_flag_reason = "Escoge el motivo de la denuncia",
    flag_reason_hack = "Abuso de un agujero de seguridad",
    flag_reason_coc = "Incumplimiento del código de conducta",
    flag_reason_dmca = "Violación de derechos de autor",
    flag_reason_notes = "Cuéntanos más sobre los motivos de tu denuncia:",
    flag_reason_notes_placeholder = "Notas adicionales",

    -- User admin component
    -- ====================
    user_id = "ID:",
    project_count = "Número de proyectos:",
    -- Buttons
    become = "Suplantar", -- as an admin, temporarily impersonate this user
    change_email = "Cambiar email",
    send_msg = "Enviar un mensaje",
    ban = "Suspender",
    unban = "Dessuspender",
    delete_usr = "Eliminar",
    -- New email dialog
    new_email = "Nuevo email",
    -- Send message dialog
    compose_email = "Escribe un mensaje",
    msg_subject = "Asunto",
    msg_body = "Cuerpo del mensaje",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "¿Seguro que quieres eliminar el usuario @1?",
    warning_no_return = "¡ATENCIÓ! ¡Esta acción no se puede deshacer!",

    -- Change password page
    -- ====================
    change_password_title = "Cambia tu contraseña",
    current_pwd = "Contraseña actual",
    new_pwd = "Nueva contraseña",
    new_pwd_2 = "Nueva contraseña (repetir)",

    -- Change email page
    -- =================
    new_email_2 = "Nuevo email (repetir)",

    -- Administration page
    -- ===================
    user_admin = "Administración de usuarios",
    zombie_admin = "Administración de zombis",
    flagged_projects = "Proyectos denunciados",

    -- Error messages
    -- ==============
    err_login_failed = "Error de autenticación",
    err_password_mismatch = "Por favor, asegúrate de haber introducido correctamente@1tu contraseña dos veces.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "Las contraseñas no coinciden",
    err_email_mismatch = "Por favor, asegúrate de haber introducido correctamente@1tu dirección electrónica dos veces.", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Las direcciones no coinciden",
}

return locale
