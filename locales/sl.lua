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
    lang_name = "Slovenščina",
    lang_code = "sl",
    authors = "Kinesthetic Learning",
    last_updated = "2023/06/08", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Zaženi Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "Razišči",
    forum = "Forum",
    join = "Pridruži se",
    login = "Prijava",
    -- User menu
    my_projects = "Moji projekti",
    my_collections = "Moje zbirke",
    my_public_page = "Moja javna stran",
    followed_projects = "Spremljani projekti",
    administration = "Admin",
    my_profile = "Moj profil",
    logout = "Odjava",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "Povratek",

    -- Footer
    -- ======
    -- Titles
    t_about = "O nas",
    t_learning = "Izobraževanje",
    t_tools = "Orodja",
    t_support = "Podpora",
    t_legal = "Pravno obvestilo",
    -- Links
    about = "O Snap@1",
    blog = "Blog",
    credits = "Zasluge",
    requirements = "Tehnične zahteve",
    partners = "Partnerji",
    source = "Izvorna koda",
    events = "Dogodki",
    examples = "Primeri projektov",
    manual = "Referenčni priročnik",
    materials = "Gradiva",
    bjc = "Tečaj - The Beauty and Joy of Computing",
    research = "Raziskave",
    offline = "Verzija brez povezave",
    extensions = "Razširitve",
    old_snap = "(Stari Snap@1)",
    -- forum already translated in top navigation bar
    contact = "Stopite v stik z nami",
    mirrors = "Zrcalne strani",
    dmca = "DMCA",
    privacy = "Privacy",
    tos = "Terms of Service",

    -- Index page
    -- ==========
    welcome = "Dobrodošli v Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "Dobrodošli, @1!", -- @1 becomes the current user username
    snap_description = "Snap@1 je programski jezik, ki je ustvarjen tako za mlade kot za odrasle ter omogoča resno raziskovanje računalniških znanosti.",
    -- Buttons
    run_now = "Zaženi Snap@1 zdaj",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Izbrani projekti",
    totm = "Tema meseca: @1", -- @1 becomes the actual topic of the month
    science = "Naravoslovje",
    simulations = "Simulacije",
    three_d = "3D",
    music = "Glasba",
    art = "Umetnost",
    fractals = "Fraktali",
    animations = "Animacije",
    games = "Igre",
    cs = "Računalništvo",
    maths = "Matematika",
    latest = "Nedavni projekti",
    more_collections = "Preostale zbirke",

    -- Events page
    events_title = "Snap@1 Dogodki",

    -- All Topics of the Month page
    totms_title = "Vsi tematski meseci",

    -- Collections page
    collections_title = "Objavljene zbirke",

    -- User Collections page
    user_collections_title = "Objavljene zbirke uporabnika @1",

    -- User Projects page
    user_projects_title = "Javni projekti uporabnika @1",

    -- Sign up page
    -- ============
    signup_title = "Ustvarite račun Snap@1", -- @1 becomes an italic exclamation mark (!)
    username = "Uporabniško ime",
    password = "Geslo",
    password_2 = "Ponovite geslo",
    birth_month = "Mesec rojstva",
    or_before = "ali prej", -- is preceded by a year, like "1995 or before"
    email_parent = "E-poštni naslov starša ali skrbnika",
    email_user = "E-poštni naslov",
    email_2 = "Ponovite e-poštni naslov",
    tos_agree = "Prebral/-a sem in se strinjam s @1 in @2", -- @1 becomes Terms of Service, @2 becomes     Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Pravilnik o zasebnosti",
    signup = "Nov račun",

    -- Log in page
    -- ===========
    log_into_snap = "Prijava v Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "Ostani prijavljen",
    i_forgot_password = "Pozabil sem geslo",
    i_forgot_username = "Pozabil sem uporabniško ime",

    -- Dates
    -- =====
    -- Month names
    january = "Januar",
    february = "Februar",
    march = "Marec",
    april = "April",
    may = "Maj",
    june = "Junij",
    july = "Julij",
    august = "Avgust",
    september = "September",
    october = "Oktober",
    november = "November",
    december = "December",
    -- Date format
    date = "@2 @1, @3", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
    ok = "Ok",
    cancel = "Prekliči",
    confirm = "Potrdi",

    -- Explore page
    -- ============
    published_projects = "Objavljeni projekti",
    published_collections = "Objavljene zbirke",

    -- Search results page
    -- ===================
    search_results = "Rezultati iskanja: @1",
    project_search_results = "Ujemanje projektov: @1",
    collection_search_results = "Ujemanje zbirk: @1",
    user_search_results = "Ujemanje uporabnikov: @1",
    projects = "Projekti",
    collections = "Zbirke",
    users = "Uporabniki",

    -- Users page
    -- ==========
    last_users = "Zadnji registrirani uporabniki",

    -- Search component in grids
    -- =========================
    matching = "Ujemanje: @1", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Nova zbirka",
    -- New collection dialog
    collection_name = "Ime zbirke?",
    collection_by_thumb = "avtor: @1", -- @1 is the author's username

    -- Collection page
    -- ===============
    collection_by = "avtor: @1", -- @1 is the author's username
    -- Dates
    collection_created_date = "Ustvarjeno",
    collection_updated_date = "Nazadnje posodobljeno",
    collection_shared_date = "Dostopno s povezavo",
    collection_published_date = "Objavljeno",
    -- Buttons
    share_collection_button = "Naredi dostopno s povezavo",
    unshare_collection_button = "Prekliči dostopnost",
    publish_collection_button = "Objavi",
    unpublish_collection_button = "Prekliči objavo",
    delete_collection_button = "Izbriši",
    make_ffa = "Označi kot dostopno za vse",
    unmake_ffa = "Odstrani oznako dostopno za vse",
    unenroll = "Odstrani me",
    -- Project Thumbnail
    project_by_thumb = "avtor: @1", -- @1 is the author's username
    item_shared_info = "Dostopen bo le preko URL-ja.",
    item_not_shared_info = "Ta element je zaseben in ga lahko vidiš samo ti.",
    item_published_info = "Drugi uporabniki ga lahko dodajo v svojo zbirko.",
    item_not_published_info = "Ni objavljen na spletišču skupnosti.",
    confirm_uncollect = "Potrdi odstranitev iz zbirke", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "Odstrani iz te zbirke",
    collection_thumbnail_tooltip = "Nastavi kot sličico zbirke",

    -- Collection dialogs
    -- ==================
    confirm_share_collection = "Potrdi delitev te zbirke?",
    confirm_unshare_collection = "Potrdi preklic delitve te zbirke?",
    confirm_publish_collection = "Potrdi objavo te zbirke?",
    confirm_unpublish_collection = "Potrdi preklic objave te zbirke?",
    confirm_ffa = "Potrdi označitev te zbirke@1kot prosto dostopne za dodajanje?", -- @1 becomes a new line. You can add as many as you need.
    confirm_unffa = "Potrdi preklic zbirke@1kot prosto dostopne za dodajanje?", -- @1 becomes a new line. You can add as many as you need.
    confirm_unenroll = "Potrdi odstranitev iz zbirke?",

    -- User public page
    -- ================
    public_page = "Javna stran uporabnika @1", -- @1 becomes the user's username
    follow_user = "Sledi temu uporabniku",
    unfollow_user = "Prenehaj slediti temu uporabniku",
    -- Admin tools
    admin_tools = "Orodja za skrbnike",
    latest_published_projects = "Najnovejši objavljeni projekti",
    latest_published_collections = "Najnovejše objavljene zbirke",

    -- Followed users feed
    -- ===================
    followed_feed = "Projekti uporabnikov, ki jim sledim",
    following_nobody = "Še ne sledite nobenemu uporabniku. Obiščite javno stran uporabnika in kliknite @1, da jim začnete slediti in vidite njihove najnovejše javne projekte na tej strani.",
    followed_users = "Uporabniki, ki jim sledite",
    follower_users = "Uporabniki, ki vam sledijo",

    -- User profile
    -- ============
    profile_title = "Profil uporabnika @1", -- @1 becomes the user's username
    join_date = "Pridružen/a dne", -- date of user creation follows
    delete_date = "Izbrisan/a dne", -- date of user deletion follows
    email = "E-pošta",
    role = "Vloga",
    teacher = "Učitelj",
    -- User roles
    student = "študent",
    standard = "standard",
    reviewer = "reviewer",
    moderator = "moderator",
    admin = "skrbnik",
    banned = "blokiran",
    -- Buttons
    change_my_password = "Spremeni geslo",
    change_my_email = "Spremeni email naslov",
    delete_my_user = "Izbriši moj račun",

    -- Learner Accounts
    -- ================
    -- @1 username, @2 user profile URL
    learner_first_login_meesage = [[Dobrodošli, @1
To je študentski račun. To pomeni, da ga nadzoruje vaš učitelj, ne pa vi.

Zato močno priporočamo, da imate tudi svoj osebni račun Snap!.

Želite izvedeti več? Obiščite @2]],

    -- Teacher pages
    -- =============
    teacher_title = "Stran učitelja",
    learners_title = "Moji študenti",

    -- Bulk account creation page
    -- ==========================
    bulk_tile = "Množično ustvarjanje računov",
    bulk_text = "Prosimo, zagotovite CSV datoteko s stolpcema <code><b>username</b></code> in <code><b>password</b></code> za vse vaše študente. Opcijsko tudi <code>email</code>, sicer bodo vsi vezani na vaš e-poštni naslovm. To je uporabno, če želite ponastaviti gesla vaših študentov.",
    bulk_make_collection = "Ustvarite zasebno zbirko za to skupino študentov",
    bulk_create = "Ustvari uporabnike",

    -- Project page
    -- ============
    remixed_from = "(premešano iz @1, avtor: @2)", -- @1 is the original project name, @2 is its author's username
    project_by = "avtor: @1", -- @1 is the username
    project_remixes_title = "Javna premešanja tega projekta",
    project_collections_title = "Javne zbirke, ki vsebujejo ta projekt",
    shift_enter_note = "Pritisnite Shift + Enter za prelom vrstice", -- in the notes field
    no_notes = "Ta projekt nima opomb",
    created_date = "Ustvarjeno",
    updated_date = "Nazadnje posodobljeno",
    shared_date = "Dostopno s povezavo",
    published_date = "Objavljeno",
    -- Buttons
    see_code = "Ogled kode",
    edit = "Uredi",
    download = "Prenesi",
    embed = "Vdelaj",
    collect = "Dodaj v zbirko",
    delete_button = "Izbriši",
    publish_button = "Objavi",
    share_button = "Deli",
    unpublish_button = "Prekliči objavo",
    unshare_button = "Prekliči deljenje",
    -- Flagging
    you_flagged = "Prijavili ste ta projekt kot neprimernega",
    unflag_project = "Odstrani prijavo tega projekta",
    flag_project = "Prijavi ta projekt kot neprimeren",

    -- Embed dialog
    -- ============
    embed_title = "Možnosti vdelave",
    embed_explanation = "Prosimo, izberite elemente, ki jih želite vključiti v vdelan prikazovalnik projekta:",
    project_title = "Naslov projekta",
    project_author = "Avtor projekta",
    edit_button = "Gumb za urejanje",
    pause_button = "Gumb za premor",
    embed_url = "Vdelan URL",
    embed_code = "Vdelana koda",

    -- Collect dialog
    -- ==============
    collect_title = "Add project to collection",
    collect_explanation = "Please select the collection to which you want to add this project:",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Res želite izbrisati ta projekt?",
    confirm_delete_user = "Res želite izbrisati tega uporabnika?",
    confirm_delete_collection = "Res želite izbrisati to zbirko?",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Ste prepričani, da želite deliti ta projekt?",
    confirm_unshare_project = "Res želite preklicati deljenje tega projekta?",
    confirm_publish_project = "Ste prepričani, da želite objaviti ta projekt?",
    confirm_unpublish_project = "Res želite preklicati objavo tega projekta?",

    -- Flag project dialogs
    -- ====================
    flag_prewarning = "Ali ste prepričani, da želite označiti ta projekt kot neprimernega?@1@1Vaše uporabniško ime bo vključeno v poročilo.@1@1Namereno označevanje legitimnih projektov se šteje za kršitev@1naših pogojev uporabe in lahko privede do suspenza.", -- @1 becomes a new line. You can add as many as you need.
    choose_flag_reason = "Prosimo, izberite razlog",
    flag_reason_hack = "Varnostna ranljivost",
    flag_reason_coc = "Kršitev kodeksa ravnanja",
    flag_reason_dmca = "Kršitev DMCA",
    flag_reason_notes = "Povejte nam več o razlogu za označevanje tega projekta:",
    flag_reason_notes_placeholder = "Dodatne opombe",

    -- User admin component
    -- ====================
    user_id = "ID",
    project_count = "Število projektov",
    -- Buttons
    become = "Postani", -- as an admin, temporarily impersonate this user
    verify = "Preveri",
    change_email = "Spremeni e-pošto",
    reset_password = "Ponastavi geslo",
    confirm_reset_password = "Ali ste prepričani, da želite ponastaviti geslo uporabnika @1?",
    send_msg = "Pošlji sporočilo",
    ban = "Blokiraj",
    unban = "Odblokiraj",
    delete_usr = "Izbriši",
    perma_delete_usr = "Izbriši trajno",
    revive_usr = "Obnovi",
    confirm_revive = "Ali ste prepričani, da želite obnoviti uporabnika @1?",
    -- New email dialog
    new_email = "Nova e-pošta",
    -- Send message dialog
    compose_email = "Napiši sporočilo",
    msg_subject = "Zadeva",
    msg_body = "Vsebina sporočila",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "Ste prepričani, da želite izbrisati uporabnika @1?",
    warning_no_return = "POZOR! Tega dejanja ni mogoče razveljaviti!",

    -- Change password page
    -- ====================
    change_password_title = "Spremeni geslo",
    current_pwd = "Trenutno geslo",
    new_pwd = "Novo geslo",
    new_pwd_2 = "Ponovi novo geslo",

    -- Change email page
    -- =================
    new_email_2 = "Ponovi novo e-pošto",

    -- Administration page
    -- ===================
    carousel_admin = "Izbrani Carousels",
    user_admin = "Upravljanje uporabnikov",
    zombie_admin = "Upravljanje nedejavnih uporabnikov",
    flagged_projects = "Označeni projekti",
    suspicious_ips = "Sumljivi IP-naslovi",
 
    -- Error messages
    -- ==============
    err_login_failed = "Prijava ni uspela",
    err_password_mismatch = "Prosimo, preverite ali ste vnesli geslo dvakrat@1in ali se obe gesli ujemata.",
    err_password_mismatch_title = "Gesli se ne ujemata",
    err_email_mismatch = "Prosimo, preverite ali ste vnesli e-pošto dvakrat@1in ali se obe e-pošti ujemata.",
    err_email_mismatch_title = "E-pošti se ne ujemata",
}

return locale
