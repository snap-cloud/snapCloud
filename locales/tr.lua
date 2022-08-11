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
    lang_name = "Türkçe",
    lang_code = "tr",
    authors = "Turgut Guneysu",
    last_updated = "2022/11/08", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Snap@1 i Deneyin", -- @1 becomes an italic exclamation mark (!)
    explore = "Keşfet",
    forum = "Forum",
    join = "Katıl",
    login = "Oturum Aç",
    -- User menu
    my_projects = "Projelerim",
    my_collections = "Koleksiyonlarım",
    my_public_page = "Sayfam",
    my_profile = "Profilim",
    administration = "Yönetim",
    logout = "Oturumu Kapat",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "",

    -- Footer
    -- ======
    -- Titles
    t_about = "Hakkında",
    t_learning = "Öğrenme",
    t_tools = "Araçlar",
    t_support = "Destek",
    t_legal = "Yasal",
    -- Links
    about = "Snap@1 Hakkında",
    blog = "Blog",
    credits = "Krediler",
    requirements = "Teknik gereksinimler",
    partners = "Ortaklar",
    source = "Kaynak kodu",
    events = "",
    examples = "",
    manual = "Başvuru Kılavuzu",
    materials = "Malzemeler",
    bjc = "The Beauty and Joy of Computing",
    research = "Araştır",
    offline = "Çevrimdışı Sürüm",
    extensions = "Uzantılar",
    old_snap = "",
    -- forum already translated in top navigation bar
    contact = "Bize Ulaşın",
    mirrors = "İkiz Siteler",
    dmca = "Dijital Binyıl Telif Hakkı Yasası (DMCA)",
    privacy = "Gizlilik",
    tos = "Kullanım Şartları",

    -- Index page
    -- ==========
    welcome = "Snap@1 e Hoşgeldiniz", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "", -- @1 becomes the current user username
    snap_description = "Snap@1; çocuklar ve yetişkinler için geniş anlamda davetkar bir programlama dilidir ve aynı zamanda bilgisayar bilimlerini ciddi şekilde incelemek için bir platformdur.",
    -- Buttons
    run_now = "",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Öne çıkan projeler",
    totm = "", -- @1 becomes the actual topic of the month
    science = "Bilim projeleri",
    simulations = "",
    three_d = "",
    music = "",
    art = "Sanat projeleri",
    fractals = "Fraktallar",
    animations = "Animasyonlar",
    games = "Oyunlar",
    cs = "",
    maths = "",
    latest = "En Son Projeler",
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
    signup_title = "Snap@1 hesabı oluştur", -- @1 becomes an italic exclamation mark (!)
    username = "Kullanıcı adı",
    password = "Şifre",
    password_2 = "Şifreyi tekrarla",
    birth_month = "Doğum Ayı",
    or_before = "", -- is preceded by a year, like "1995 or before"
    email_parent = "Ebeveyn veya velinin e-posta adresi",
    email_user = "E-posta adresi",
    email_2 = "E-posta adresini tekrarla",
    tos_agree = "", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "",
    signup = "Kaydol",

    -- Log in page
    -- ===========
    log_into_snap = "Snap@1 e giriş yap", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "Oturumumu açık tut",
    i_forgot_password = "",
    i_forgot_username = "",

    -- Dates
    -- =====
    -- Month names
    january = "Ocak",
    february = "Şubat",
    march = "Mart",
    april = "Nisan",
    may = "Mayıs",
    june = "Haziran",
    july = "Temmuz",
    august = "Ağustos",
    september = "Eylül",
    october = "Ekim",
    november = "Kasım",
    december = "Aralık",
    -- Date format
    date = "", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
    ok = "OK",
    cancel = "İptal",
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
    projects = "Projeler",
    collections = "Koleksiyonlar",
    users = "Kullanıcılar",

    -- Users page
    -- ==========
    last_users = "",

    -- Search component in grids
    -- =========================
    matching = "", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Yeni Koleksiyon",
    -- New collection dialog
    collection_name = "Koleksiyon adı?",
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
    share_collection_button = "Paylaş",
    unshare_collection_button = "Paylaşma",
    publish_collection_button = "Yayımla",
    unpublish_collection_button = "Yayımlama",
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
    collection_thumbnail_tooltip = "Koleksiyon küçük resmi olarak ayarla",

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
    admin_tools = "Yönetici araçları",
    latest_published_projects = "",
    latest_published_collections = "",

    -- User profile
    -- ============
    profile_title = "", -- @1 becomes the user's username
    join_date = "", -- date of user creation follows
    email = "",
    role = "Rol",
    -- User roles
    standard = "standart",
    reviewer = "reviewer",
    moderator = "moderatör",
    admin = "yönetici",
    banned = "yasaklandı",
    -- Buttons
    change_my_password = "Şifremi Değiştir",
    change_my_email = "E-postamı Değiştir",
    delete_my_user = "Hesabımı Sil",

    -- Project page
    -- ============
    remixed_from = "", -- @1 is the original project name, @2 is its author's username
    project_by = "", -- @1 is the username
    project_remixes_title = "",
    project_collections_title = "",
    shift_enter_note = "", -- in the notes field
    no_notes = "Bu projede not yok",
    created_date = "",
    updated_date = "",
    shared_date = "",
    published_date = "",
    -- Buttons
    see_code = "Koda Bak",
    edit = "Düzenle",
    download = "İndir",
    embed = "Göm / Yerleştir",
    collect = "Koleksiyonuma Ekle",
    delete_button = "",
    publish_button = "",
    share_button = "",
    unpublish_button = "",
    unshare_button = "",
    -- Flagging
    you_flagged = "",
    unflag_project = "",
    flag_project = "Bu projeyi ihbarla",

    -- Embed dialog
    -- ============
    embed_title = "Yerleştirme Seçenekleri",
    embed_explanation = "Lütfen katıştırılmış proje görüntüleyiciye eklemek istediğiniz öğeleri seçin:",
    project_title = "Proje Başlığı",
    project_author = "Proje yazarı",
    edit_button = "Düzenle düğmesi",
    pause_button = "",
    embed_url = "",
    embed_code = "",

    -- Collect dialog
    -- ==============
    collect_title = "Projeyi koleksiyona ekle",
    collect_explanation = "Lütfen bu projeyi eklemek istediğiniz koleksiyonu seçin:",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Bu projeyi silmek istediğinden emin misin?",
    confirm_delete_user = "",
    confirm_delete_collection = "",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Bu projeyi paylaşmak istediğinden emin misin?",
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
    become = "Ol", -- as an admin, temporarily impersonate this user
    change_email = "E-posta Değiştir",
    send_msg = "",
    ban = "Yasakla",
    unban = "",
    delete_usr = "Sil",
    -- New email dialog
    new_email = "",
    -- Send message dialog
    compose_email = "",
    msg_subject = "",
    msg_body = "",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "",
    warning_no_return = "UYARI! Bu eylem geri alınamaz!",

    -- Change password page
    -- ====================
    change_password_title = "Şifreni Değiştir",
    current_pwd = "Şimdiki Şifre",
    new_pwd = "Yeni Şifre",
    new_pwd_2 = "Yeni Şifreyi Tekrarla",

    -- Change email page
    -- =================
    new_email_2 = "Yeni e-postanı tekrarla",

    -- Administration page
    -- ===================
    user_admin = "Kullanıcı yönetimi",
    zombie_admin = "Zombi Yönetimi",
    flagged_projects = "İhbarlı projeler",

    -- Error messages
    -- ==============
    err_login_failed = "",
    err_password_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "",
    err_email_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "E-postalar uyuşmuyor",
}

return locale
