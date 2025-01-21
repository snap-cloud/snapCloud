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
    lang_name = "Հայերեն",
    lang_code = "hy",
    authors = "Antrohoos Educational Foundation",
    last_updated = "2025/01/19", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Գործարկել Snap@1 -ը", -- @1 becomes an italic exclamation mark (!)
    explore = "Ուսումնասիրել",
    forum = "Ֆորում",
    join = "Միանալ",
    login = "Մուտք գործել",
    -- User menu
    my_projects = "Իմ նախագծերը",
    my_collections = "Իմ հավաքածուները",
    my_public_page = "Իմ հանրային էջը",
    followed_projects = "Հետևած նախագծեր",
    administration = "Կառավարում",
    my_profile = "Իմ պրոֆիլը",
    logout = "Ելք",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "Unbecome",

    -- Footer
    -- ======
    -- Titles
    t_about = "Մեր մասին",
    t_learning = "Ուսուցում",
    t_tools = "Գործիքներ",
    t_support = "Աջակցություն",
    t_legal = "Իրավական",
    -- Links
    about = "Snap@1 -ի մասին",
    blog = "Օրագիր",
    credits = "Երախտիք",
    requirements = "Տեխնիկական պահանջներ",
    partners = "Գործընկերներ",
    source = "Սկզբնաղբյուր",
    events = "Իրադարձություններ",
    examples = "Նախագծերի օրինակներ",
    manual = "Տեղեկանքի ուղեցույց",
    materials = "Պաշարներ",
    bjc = "Ծրագրավորման ուրախալի և գեղեցիկ կողմը",
    research = "Հետազոտություն",
    wiki = "համայքային վիքի",
    offline = "Անցանց տարբերակ",
    extensions = "Ընդարձակումներ",
    old_snap = "(հին Snap@1)",
    -- forum already translated in top navigation bar
    contact = "Կապվել մեզ հետ",
    mirrors = "Հղումներ",
    dmca = "DMCA",
    privacy = "Գաղտնիություն",
    tos = "Ծառայությունների պայմաններ",

    -- Index page
    -- ==========
    welcome = "բարի գալուստ Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "բարի գալուստ, @1!", -- @1 becomes the current user username
    snap_description = "Snap@1 -ը համարվում է երեխաների և մեծահասակների շրջանում լայնորեն կիրառվող ծրագրավորման լեզու, ինչպես նաև հարթակ՝ համակարգչային գիտության խորը ուսումնասիրության համար։",
    -- Buttons
    run_now = "Գործարկե՛լ հիմա",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Առաջարկվող նախագծեր",
    totm = "Ամսվա թեմա՝ @1", -- @1 becomes the actual topic of the month
    science = "Գիտական նախագծեր",
    simulations = "Սիմուլացիաներ",
    three_d = "3D",
    music = "Երաժշտություն",
    art = "Արվետի նախագծեր",
    fractals = "Ֆրակտալներ",
    animations = "Անիմացիաներ",
    games = "Խաղեր",
    cs = "Համակարգչային գիտություն",
    maths = "Մաթեմատիկա",
    latest = "Վերջին նախագծերը",
    more_collections = "Ուսումնասիրել այլ հավաքածուներ",

    -- Events page
    events_title = "Snap@1 -ի իրադարձություններ",

    -- All Topics of the Month page

    totms_title = "Ամսվա բոլոր թեմաները",

    -- Collections page
    collections_title = "Հրապարակած հավաքածուները",

    -- User Collections page
    user_collections_title = "@1 -ի Հհրապարակած հավաքածուները",

    -- User Projects page
    user_projects_title = "@1 -ի Հրապարակած նախագծերը",

    -- Sign up page
    -- ============
    signup_title = "Ստեղծել Snap@1 -ի հաշիվ", -- @1 becomes an italic exclamation mark (!)
    username = "Մուտքանուն",
    password = "Գաղտնաբառ",
    password_2 = "Կրկնել գաղտնաբառը",
    birth_month = "Ծննդյան տարեթիվ",
    or_before = "կամ առաջ", -- is preceded by a year, like "1995 or before"
    email_parent = "Ծնողի կամ խնամակալի էլ․ հասցե",
    email_user = "Էլ․ հասցե",
    email_2 = "Կրկնել էլ․ հասցեն",
    tos_agree = "Կարդացել եմ և համաձայն եմ @1 -ին @2 -ին", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Գաղտնիության համաձայնագիր",
    signup = "Գրանցվել",

    -- Log in page
    -- ===========
    log_into_snap = "Մուտք գործել Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "մնալ մուտք գործած",
    i_forgot_password = "Մոռացել եմ գաղտնաբառս",
    i_forgot_username = "Մոռացել եմ մուտքանունս",

    -- Dates
    -- =====
    -- Month names
    january = "Հունվար",
    february = "Փետրվար",
    march = "Մարտ",
    april = "Ապրիլ",
    may = "Մայիս",
    june = "Հունիս",
    july = "Հուլիս",
    august = "Օգոստոս",
    september = "Սեպտեմբեր",
    october = "Հոկտեմբեր",
    november = "Նոյեմբեր",
    december = "Դեկտեմբեր",
    -- Date format
    date = "@2 @1, @3", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
    ok = "Լավ",
    cancel = "Չեղարկել",
    confirm = "Հաստատել",

    -- Explore page
    -- ============
    published_projects = "Հրապարակած նախագծեր",
    published_collections = "Հրապարակած հավաքածուներ",

    -- Search results page
    -- ===================
    search_results = "Որոնման արդյունք՝ @1",
    project_search_results = "Համընկնող նախագծեր՝ @1",
    collection_search_results = "Համընկնող հավաքածուներ՝ @1",
    user_search_results = "Համընկնող օգտատերեր՝ @1",
    projects = "Նախագծեր",
    collections = "Հավաքածուներ",
    users = "Օգտատերեր",

    -- Users page
    -- ==========
    last_users = "Վերջին գրանցված օգտատերը",

    -- Search component in grids
    -- =========================
    matching = "Համընկնում՝ @1", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Նոր հավաքածու",
    -- New collection dialog
    collection_name = "Հավաքածուի անուն",
    collection_by_thumb = "@1 -ի կողմից", -- @1 is the author's username

    -- Collection page
    -- ===============
    collection_by = "@1 -ի կողմից", -- @1 is the author's username
    -- Dates
    collection_created_date = "Ստեղծված է",
    collection_updated_date = "Վերջին թարմացումը",
    collection_shared_date = "Տարածված է",
    collection_published_date = "Հրապարակված է",
    -- Buttons
    share_collection_button = "Տարածել",
    unshare_collection_button = "Չտարածել",
    publish_collection_button = "Հրապարակել",
    unpublish_collection_button = "Չհրապարակել",
    delete_collection_button = "Ջնջել",
    make_ffa = "Նշել անվճար բոլորի համար",
    unmake_ffa = "Հանելանվճար բոլորի համար նշումը",
    unenroll = "Հեռացնել ինձ",
    -- Project Thumbnail
    project_by_thumb = "@1 -ի կողմից", -- @1 is the author's username
    item_shared_info = "Այս տարրը կարող է տարածվել URL-ի միջոցով։",
    item_not_shared_info = "Այս տարրը գաղտնի է և միայն դուք կարող եք տեսնել։",
    item_published_info = "Այս տարրը հրապարակված է և կարող է տեսանելի լինի համընդհանուր որոնման համակարգում կամ հանրային հավաքածուներում։",
    item_not_published_info = "Այս տարրը չի հրապարակվել համայնքի կայքէջում։",
    confirm_uncollect = "Վստա՞հ եք որ ցանկանում եք հեռացնել project@1 -ն այս հավաքածուից", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "Հեռացնել այս հավաքածուից",
    collection_thumbnail_tooltip = "Սահմանել որպես հավաքածուի մանրապատկեր",

    -- Collection dialogs
    -- ==================
    confirm_share_collection = "Իրո՞ք ցանկանում եք տարածել այս հավաքածուն:",
    confirm_unshare_collection = "Իրո՞ք ցանկանում եք չտարածել այս հավաքածուն։",
    confirm_publish_collection = "Իրո՞ք ցանկանում եք հրապարակել այս հավաքածուն։",
    confirm_unpublish_collection = "Իրո՞ք ցանկանում եք չհրապարակել այս հավաքածուն։",
    confirm_ffa = "Իրո՞ք ցանկանում եք նշել collection@1  -ն անվճար բոլորի համար և թույլ տալ բոլոր օգտատերերին ավելացնելու their@1published հրապարակել նախագծերը դրա մեջ։", -- @1 becomes a new line. You can add as many as you need.
    confirm_unffa = "Իրո՞ք ցանկանում եք նշել collection@1as -ն անվճար բոլորի համար և կանխել խմբագիր չհանդիսացողներին adding@1their ավելացնել նախագծերը դրա մեջ։", -- @1 becomes a new line. You can add as many as you need.
    confirm_unenroll = "Իրո՞ք ցանկանում եք հեռացնել ձեզ այս հավաքածուից։",

    -- User public page
    -- ================
    public_page = "@1' -ի հանրային էջը", -- @1 becomes the user's username
    follow_user = "Հետևել այս օգտատիրոջը",
    unfollow_user = "Չհետևել այս օգտատիրոջը",
    -- Admin tools
    admin_tools = "Կառավարման գործիքներ",
    latest_published_projects = "Վերջին հրապարակած նախագծերը",
    latest_published_collections = "վերջին հրապարակած հավաքածուները",

    -- Followed users feed
    -- ===================
    followed_feed = "Նագածերն ըստ օգտատերերի, որոնց ես հետևում եմ",
    following_nobody = "Դուք դեռ չեք հետևում որևիցե օգտատիրոջ։ Այցելեք օգտատերերի հանրային էջեր, սեղմեք @1 -ի վրա, հետևեք և տեսեք իրենց վերջին հանրային նախագծերն այս էջում։",
    followed_users = "Օգտատերեր ում դուք հետևում եք",
    follower_users = "Օգտատերեր որոնց դուք հետևում եք",

    -- User profile
    -- ============
    profile_title = "@1 -ի պրոֆիլ", -- @1 becomes the user's username
    join_date = "Միացած", -- date of user creation follows
    delete_date = "Ջնջած", -- date of user deletion follows
    email = "Էլ․ փոստ",
    role = "Դեր",
    teacher = "Ուսուցիչ",
    -- User roles
    student = "աշակերտ",
    standard = "ստանդարտ",
    reviewer = "վերանայող",
    moderator = "վարող",
    admin = "Կառավարող",
    banned = "արգելված",
    -- Buttons
    change_my_password = "Փոխել իմ գաղտնաբառը",
    change_my_email = "Փոխել իմ էլ․ հասցեն",
    delete_my_user = "Ջնջել իմ հաշիվը",

    -- Learner Accounts
    -- ================
    -- @1 username, @2 user profile URL
    learner_first_login_meesage = [[Բարի գալուստ, @1
Սա ուսանողի հաշիվ է։ Այն նշանակում է, որ ձեր փոխարեն ուսուցիչն է վերահսկում ձեր հաշիվը։

Ուստի խորհուրդ ենք տալիս ունենալ նաև սեփական Snap! հաշիվը։

Ցանկանո՞ւմ եք ավելին իմանալ, այցելեք @2]],

    -- Teacher pages
    -- =============
    teacher_title = "Ուսուցչի էջ",
    learners_title = "Իմ սովորողները",

    -- Bulk account creation page
    -- ==========================
    bulk_tile = "Մեծաքանակ հաշիվների ստեղծում",
    bulk_text = "Խնդրում ենք տրամադրելCSV նիշքը <code><b>օգտատեր</b></code> -ի և <code><b>գաղտնաբառ</b></code> -ի սյունակները բոլոր սովորողների համար, ցանկության դեպքում նաև ընտրովի <code>էլ․ փոստ</code> սյունակը։ Եթե ​​ձեր օգտատերերի համար էլ․ փոստ չտրամադրեք, ապա նրանք բոլորը կապված կլինեն ձեր էլփոստի հաշվին: Էլ․ փոստն օգտակար է, երբ կարիք է լինում վերականգնել ձեր սովորողների գաղտնաբառերը",
    bulk_make_collection = "Ստեղծել անհատական հավաքածու այս խմբի սովորողների համար",
    bulk_create = "Ստեղծել օգտատերեր",

    -- Project page
    -- ============
    remixed_from = "(ձուլված է @1 -ից, @2 -ի կողմից)", -- @1 is the original project name, @2 is its author's username
    project_by = "@1 -ի կողմից", -- @1 is the username
    project_remixes_title = "Այս նախագծի հանրային ձուլվածքը",
    project_collections_title = "Այս նախագիծը պարունակող հանրային հավաքածուներ",
    shift_enter_note = "Նոր տող գնալու համար սեղմեք Shift + Enter", -- in the notes field
    no_notes = "Այս նախագիծը չունի նշումներ",
    created_date = "Ստեղծված է",
    updated_date = "Վերջին թարմացում",
    shared_date = "Տարածված է",
    published_date = "Հրապարակված է",
    -- Buttons
    see_code = "Տեսնել սցենարը",
    edit = "Խմբագրել",
    download = "Ներբեռնել",
    embed = "Ներկառուցել",
    collect = "Ավելացնել հավաքածուի մեջ",
    delete_button = "Ջնջել",
    publish_button = "Հրապարակել",
    share_button = "Տարածել",
    unpublish_button = "Չհրապարակել",
    unshare_button = "Չտարածել",
    -- Flagging
    you_flagged = "Դուք դրոշակել եք այս նախագիծը որպես անպատշաճ",
    unflag_project = "Հանել նախագծի դրոշակը",
    flag_project = "Հաղորդում ներկայացնել նախագծի վերաբերյալ",

    -- Embed dialog
    -- ============
    embed_title = "Ներկառուցման ընտրանքներ",
    embed_explanation = "Խնդրում ենք ընտրել այն տարրերը, որոնք ցանկանում եք ներառել ներկառուցված նախագծի դիտարկչում՝",
    project_title = "Նախագծի վերնագիր",
    project_author = "նախագծի հեղինակ",
    edit_button = "Խմբագրման կոճակ",
    pause_button = "Կանգնեցման կոճակ",
    embed_url = "Ներկառուցման URL",
    embed_code = "Ներկառուցման Code",

    -- Collect dialog
    -- ==============
    collect_title = "Ավելացնել նախագիծը հավաքածուի մեջ",
    collect_explanation = "Խնդրում ենք ընտրել այն հավաքածուն, որին ցանկանում եք ավելացնել այս նախագիծը:",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "Իսկապե՞ս ցանկանում եք ջնջել այս նախագիծը",
    confirm_delete_user = "Իսկապե՞ս ցանկանում եք ջնջել այս օգտատիրոջը",
    confirm_delete_collection = "Իսկապե՞ս ցանկանում եք ջնջել այս հավաքածուն",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "Իսկապե՞ս ցանկանում եք տարածել այս նախագիծը",
    confirm_unshare_project = "Իսկապե՞ս ցանկանում եք չտարածել այս նախագիծը",
    confirm_publish_project = "Իսկապե՞ս ցանկանում եք հրապարակել այս նախագիծը",
    confirm_unpublish_project = "Իսկապե՞ս ցանկանում եք չհրապարակել այս նախագիծը",

    -- Flag project dialogs
    -- ====================
    flag_prewarning = "Վստա՞հ եք, որ ցանկանում եք նշել այս նախագիծը որպես inappropriate?@1@1Your օգտանունը կդորշակվի որպես report.@1@1Deliberately նախագծերի միտումնավոր դրոշակավորումը կհամարվի որպես մեր Օգտագործման պայմանների  breach@1of որի պատճառով կարող է կասեցնել ձեր հաշիվը:", -- @1 becomes a new line. You can add as many as you need.
    choose_flag_reason = "Նշել պատճառը",
    flag_reason_hack = "Անվտանգության խոցելիություն",
    flag_reason_coc = "Վարքագծի կանոնների խախտում",
    flag_reason_dmca = "DMCA խախտում",
    flag_reason_notes = "Պատմեք մեզ ավելին այն մասին, թե ինչու եք դրոշակավորում այս նախագիծը՝",
    flag_reason_notes_placeholder = "Հավելյալ նշումներ",

    -- User admin component
    -- ====================
    user_id = "ID",
    project_count = "Նախագծի հաշվարկը",
    -- Buttons
    become = "Դարձնել", -- as an admin, temporarily impersonate this user
    verify = "Ստուգել",
    change_email = "Փոխել էլ․ փոստը",
    reset_password = "Վերականգնել գաղտնաբառը",
    confirm_reset_password = "Իրո՞ք ցանկանում եք վերականգնել @1 օգտատիրոջ գաղտնաբառը",
    send_msg = "Ուղարկել հաղորդագրություն",
    ban = "Արգելել",
    unban = "Չարգելել",
    delete_usr = "Ջնջել",
    perma_delete_usr = "Ջնջել մշտապես",
    revive_usr = "Վերականգնել",
    confirm_revive = "Իրո՞ք ցանկանում եք հետ բերել @1 օգտատիրոջը։",
    -- New email dialog
    new_email = "Նոր էլ․ նամակ",
    -- Send message dialog
    compose_email = "Հավաքել հաղորդագրություն",
    msg_subject = "Վերնագիր",
    msg_body = "Էլ․ նամակի բովանդակություն",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "Վստա՞հ եք, որ ցանկանում եք ջնջել @1 օգտատիրոջը",
    warning_no_return = "ՈՒՇԱԴՐՈՒԹՅՈՒՆ! Այս գործողություն հետարկել չի՛ լինի",

    -- Change password page
    -- ====================
    change_password_title = "Փոխել գաղտնաբառը",
    current_pwd = "Ընթացիկ գաղտնաբառ",
    new_pwd = "Նոր գաղտնաբառ",
    new_pwd_2 = "Կրկնել նոր գաղտնաբառը",

    -- Change email page
    -- =================
    new_email_2 = "Կրկնել նոր էլ․ փոստը",

    -- Administration page
    -- ===================
    carousel_admin = "Հայտնաբերված կարուսելներ",
    user_admin = "Օգտատիրոջ կառավարում",
    zombie_admin = "Զոմբի կառավարում",
    flagged_projects = "Դրոշակվախ նախագծեր",
    suspicious_ips = "Կասեցված IP-ներ",

    -- Error messages
    -- ==============
    err_login_failed = "Մուտքը ձախողվեց",
    err_password_mismatch = "Խնդրում ենք համոզվել, որ երկու անգամ մուտքագրել եք your@1password, և որ երկու գաղտնաբառերն էլ համընկնում են:", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "Գաղտնաբառերը չեն համընկնում",
    err_email_mismatch = "Խնդրում ենք համոզվել, որ երկու անգամ մուտքագրել եք ձեր your@1email, և որ երկու էլ․ հասցեներն էլ համընկնում են:", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Էլ․ հասցեները չեն համընկնում",
}

return locale
