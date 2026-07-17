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
	lang_name = "Արեւմտահայերէն",
	lang_code = "hyw",
	authors = "Անտրոհուս Կրթական Հիմնադրամ",
    last_updated = "2026/07/13", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "Գործարկել Snap@1‑ը", -- @1 becomes an italic exclamation mark (!)
	explore = "Ուսումնասիրել",
	forum = "Հրապարակ",
	join = "Միանալ",
	login = "Մուտք գործել",
	my_projects = "Իմ նախագծերս",
	my_collections = "Իմ հաւաքածոներս",
	my_public_page = "Իմ հանրային էջս",
	followed_projects = "Հետեւած նախագիծերս",
	bookmarked_projects = "Էջանշուած նախագիծեր",
	administration = "Կառավարում",
	my_profile = "Իմ անձնագիրս",
	logout = "Ելք",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "Ոչ պատշաճ",

    -- Footer
    -- ======
    -- Titles
	about = "Snap@1‑ի մասին",
	blog = "Օրագիր",
	credits = "Երախտիք",
	requirements = "Թեքնիք պահանջներ",
	partners = "Գործընկերներ",
	source = "Սկզբնաղբիւր",
	versions = "Բոլոր տարբերակները",
	events = "Իրադարձութիւններ",
	examples = "Նախագիծերու օրինակներ",
	manual = "Տեղեկանքի ուղեցոյց",
	materials = "Նիւթեր",
	bjc = "Ծրագրաւորման ուրախ եւ գեղեցիկ կողմը",
	research = "Հետազօտութիւն",
	wiki = "Ուիքի համայնք",
	offline = "Անցանց տարբերակ",
	extensions = "Ընդարձակումներ",
	old_snap = "(հին Snap@1)",
    -- forum already translated in top navigation bar
	contact = "Կապ մեզի հետ",
	mirrors = "Յղումներ",
	donate = "Նուիրաբերել Snap@1‑ին",
	dmca = "DMCA օրէնք",
	privacy = "Գաղտնիութիւն",
	tos = "Ծառայութիւններու պայմաններ",

    -- Index page
    -- ==========
    welcome = "Բարի գալուստ Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "Բարի  եկար, @1!", -- @1 becomes the current user username
    snap_description = "Snap@1‑ը կը նկատուի լայնօրէն կիրարկուող ծրագրաւորման լեզու՝ մանուկներու եւ չափահասներու համար, ինչպէս նաեւ հարթակ՝ համակարգչային գիտութիւնը լրջօրէն ուսումնասիրելու։",
    -- Buttons
    run_now = "Գործարկել @1‑ը",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "Առաջարկուած նախագիծեր",
    totm = "Ամսուան թեմա՝ @1", -- @1 becomes the actual topic of the month
	science = "Գիտական նախագիծեր",
	simulations = "Ձեւացումներ",
	three_d = "3D",
	music = "Երաժշտութիւն",
	art = "Արուեստի նախագիծեր",
	fractals = "Կրկնաձեւեր",
	animations = "Կենդանացումներ",
	games = "Խաղեր",
	cs = "Համակարգչային գիտութիւն",
	maths = "Ուսողութիւն",
	latest = "Վերջին նախագիծերը",
	more_collections = "Ուսումնասիրել այլ հաւաքածոներ",

    -- Events page
    events_title = "Snap@1‑ի նախաձեռնութիւնները",

    -- All Topics of the Month page

    totms_title = "Ամսուան բոլոր թեմաները",

    -- Collections page
    collections_title = "Հրապարակուած հաւաքածոները",

    -- User Collections page
    user_collections_title = "@1‑ի հրապարակուած հաւաքածոները",

    -- User Projects page
    user_projects_title = "@1‑ի հրապարակուած նախագիծերը",

    -- Sign up page
    -- ============
    signup_title = "Ստեղծել Snap@1‑ի հաշիւ", -- @1 becomes an italic exclamation mark (!)
	username = "Մուտքանուն",
	password = "Գաղտնաբառ",
	password_2 = "Կրկնել գաղտնաբառը",
	birth_month = "Ծննդեան ամիսը",
    -- this field is visually hidden.
    birth_year = "Ծննդեան տարի",
    birth_year = "Ծննդեան տարի", -- is preceded by a year, like "1995 or before"
    email_parent = "Ծնողի կամ խնամակալի ել․ հասցէ",
    email_user = "Ել․ հասցէ",
    email_2 = "Կրկնել ել․ հասցէն",
    tos_agree = "Կարդացած եմ եւ համաձայն եմ @1‑ին, @2‑ին", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "Գաղտնիութեան համաձայնագիր",
    signup = "Արձանագրուիլ",

    -- User signup information.
    -- One entry follows each form.
    -- Leave empty to show no help text.
	signup_username_help = "Վստահ եղէք, որ ձեր մուտքանունը չի պարունակեր անձնական տուեալներ, օրինակ՝ ուսանողական տոմս։",
	signup_password_help = "Ձեր գաղտնաբառը պէտք է ըլլայ առնուազն 6 նշան",
	signup_password_repeat_help = " ",
	signup_birth_month_help = "Մենք չենք պահեր ձեր ծննդեան թուականը արձանագրութենէն ետք",
	signup_email_help = "Ձեր ել․ հասցէն կը գործածուի, որպէսզի անհրաժեշտութեան պարագային կարենաք վերականգնել ձեր հաշիւը։",
	signup_email_repeat_help = " ",
	signup_tos_help = " ",


    -- Log in page
    -- ===========
    log_into_snap = "Մուտք գործել Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "մնալ մուտք գործած",
    i_forgot_password = "Մոռցած եմ գաղտնաբառս",
    i_forgot_username = "Մոռցած եմ մուտքանունս",

    -- Dates
    -- =====
    -- Month names
	january = "Յունուար",
	february = "Փետրուար",
	march = "Մարտ",
	april = "Ապրիլ",
	may = "Մայիս",
	june = "Յունիս",
	july = "Յուլիս",
	august = "Օգոստոս",
	september = "Սեպտեմբեր",
	october = "Հոկտեմբեր",
	november = "Նոյեմբեր",
	december = "Դեկտեմբեր",
    -- Date format
    date = "@2 @1, @3", -- @1 is the day, @2 is the month name, @3 is the year

    -- Generic dialogs
    -- ===============
	ok = "Լաւ",
	cancel = "Չեղարկել",
	confirm = "Հաստատել",
    -- Explore page
    -- ============
	published_projects = "Հրապարակուած նախագիծեր",
	published_collections = "Հրապարակուած հաւաքածոներ",

    -- Learn Snap! Page
    -- ==============
    learn_snap = "Սորվիլ @1", -- @1 becomes Snap!

    -- Search results page
    -- ===================
	search = "Որոնել",
	search_results = "Որոնման արդիւնք՝ @1",
	project_search_results = "Համընկնող նախագիծեր՝ @1",
	collection_search_results = "Համընկնող հաւաքածոներ՝ @1",
	user_search_results = "Համընկնող օգտատէրեր՝ @1",
	projects = "Նախագիծեր",
	collections = "Հաւաքածոներ",
	users = "Օգտատէրեր",

    -- Users page
    -- ==========
    last_users = "Վերջին արձանագրուած օգտատէրը",

    -- Search component in grids
    -- =========================
    matching = "Համընկնում՝ @1", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "Նոր հաւաքածոյ",
    -- New collection dialog
    collection_name = "Հաւաքածոյի անուն",
    collection_by_thumb = "@1‑ի կողմէ", -- @1 is the author's username

    -- Collection page
    -- ===============
    collection_by = "@1‑ի կողմէ", -- @1 is the author's username
    -- Dates
	collection_created_date = "Ստեղծուած է",
	collection_updated_date = "Վերջին թարմացումը",
	collection_shared_date = "Բաժնեկցուած է",
	collection_published_date = "Հրապարակուած է",
    -- Buttons
	share_collection_button = "Տարածել",
	unshare_collection_button = "Չտարածել",
	publish_collection_button = "Հրապարակել",
	unpublish_collection_button = "Չհրապարակել",
	delete_collection_button = "Ջնջել",
	make_ffa = "Նշել իբրեւ անվճար բոլորին համար",
	unmake_ffa = "Հանել անվճար նշումը բոլորին համար",
	unenroll = "Հեռացնել զիս",
    -- Project Thumbnail
    project_by_thumb = "@1‑ի կողմէ", -- @1 is the author's username
	item_shared_info = "Այս տարրը կրնայ տարածուիլ URL‑ի միջոցով։",
	item_not_shared_info = "Այս տարրը գաղտնի է, եւ միայն դուք կրնաք տեսնել։",
	item_published_info = "Այս տարրը հրապարակուած է եւ կրնայ տեսանելի ըլլալ համընդհանուր որոնման համակարգին մէջ կամ հանրային հաւաքածոներուն մէջ։",
	item_not_published_info = "Այս տարրը հրապարակուած չէ համայնքի կայքէջին մէջ։",
    confirm_uncollect = "Վստա՞հ էք, որ կ՚ուզէք հեռացնել project@1‑ը այս հաւաքածոյէն։", -- @1 becomes a new line. You can add as many as you need.
    remove_from_collection_tooltip = "Հեռացնել այս հաւաքածոյէն",
    collection_thumbnail_tooltip = "Նշանակել իբրեւ հաւաքածոյի մանրապատկեր",
    collection_no_description = "Այս հաւաքածոյին համար նկարագրութիւն չկայ",

    -- Collection dialogs
    -- ==================
	confirm_share_collection = "Իրապէ՞ս կ՚ուզէք տարածել այս հաւաքածոն։",
	confirm_unshare_collection = "Իրապէ՞ս չէք ուզեր տարածել այս հաւաքածոն։",
	confirm_publish_collection = "Իրապէ՞ս կ՚ուզէք հրապարակել այս հաւաքածոն։",
	confirm_unpublish_collection = "Իրապէ՞ս չէք ուզեր հրապարակել այս հաւաքածուն։",
    confirm_ffa = "Իրապէ՞ս կ՛ուզէք նշել collection@1‑ը անվճար բոլորին համար եւ թոյլ տալ բոլոր օգտատէրերուն աւելցնել their@1published հրապարակուած նախագիծերը անոր մէջ։", -- @1 becomes a new line. You can add as many as you need.
    confirm_unffa = "Իրապէ՞ս կ՚ուզէք հանել collection@1‑ը «անվճար բոլորին համար» նշումը եւ կանխել խմբագիր չեղողներուն adding@1 աւելցնել նախագիծերը անոր մէջ։", -- @1 becomes a new line. You can add as many as you need.
    confirm_unenroll = "Իրապէ՞ս կ՚ուզէք հեռանալ այս հաւաքածոյէն։",

    -- User public page
    -- ================
    public_page = "@1‑ի հանրային էջը", -- @1 becomes the user's username
	follow_user = "Հետեւիլ այս օգտատիրոջը",
	unfollow_user = "Չհետեւիլ այս օգտատիրոջ",
    -- Admin tools
    admin_tools = "Կառավարման գործիքներ",
	latest_published_projects = "Վերջին հրապարակուած նախագիծերը",
	latest_published_collections = "Վերջին հրապարակուած հաւաքածոները",

    -- Followed users feed
    -- ===================
	followed_feed = "Նախագիծեր՝ ըստ այն օգտատէրերու, որոնց կը հետեւիմ",
	following_nobody = "Դուք դեռ չէք հետեւիր ոեւէ օգտատիրոջ։ Այցելեցէք օգտատէրերու հանրային էջերը, սեղմեցէք @1‑ի վրայ, հետեւեցէք եւ տեսէք անոնց վերջին հանրային նախագիծերը այս էջին մէջ։",
	followed_users = "Օգտատէրեր, որոնց դուք կը հետեւիք",
	follower_users = "Օգտատէրեր, որոնք ձեզի կը հետեւին",

    -- Bookmarked projects feed
    -- ========================
	bookmarked_feed = "Իմ էջանշած նախագիծերս",
	no_bookmarks = "Դուք դեռ չէք էջանշած որեւէ նախագիծ։ Սեղմեցէք սիրտի նշանին՝ ձեր սիրած նախագիծը էջանշելու համար։",
	recent_bookmarks = "Վերջերս էջանշուած նախագիծեր",

    -- User profile
    -- ============
    profile_title = "@1‑ի անձնական էջը", -- @1 becomes the user's username
    join_date = "Միացած", -- date of user creation follows
    delete_date = "Ջնջուած", -- date of user deletion follows
	email = "Ել. նամակ",
	role = "Դեր",
	teacher = "Ուսուցիչ",
	student = "Աշակերտ",
    -- User roles
	student = "Աշակերտ",
	standard = "Չափանիշ",
	reviewer = "Վերանայող",
	moderator = "Վարող",
	admin = "Կառավարող",
	banned = "Արգիլուած",
    -- Buttons
	change_my_password = "Փոխել իմ գաղտնաբառս",
	change_my_email = "Փոխել իմ ե․ հասցէս",
	delete_my_user = "Ջնջել իմ հաշիւս",

    -- Learner Accounts
    -- ================
    -- @1 username, @2 user profile URL
    learner_first_login_meesage = [[Բարի գալուստ, @1
Ասիկա աշակերտի հաշիւ է։ Այս կը նշանակէ, որ զայն կը վերահսկէ ձեր ուսուցիչը, ոչ թէ դուք։

Հետեւաբար, խստիւ կը խորհուրդ տանք, որ ունենաք նաեւ ձեր անձնական Snap! հաշիւը։

Կը փափաքի՞ք աւելի գիտնալ։ Այցելեցէք @2]],

    -- Teacher pages
    -- =============
	teacher_title = "Ուսուցիչի էջ",
	learners_title = "Իմ ուսանողներս",

    -- Bulk account creation page
    -- ==========================
	bulk_tile = "Մեծաթիւ հաշիւներու ստեղծում",
	bulk_text = "Խնդրեմ տրամադրել CSV նիշք մը, որ կը պարունակէ <code><b>օգտատէր</b></code> եւ <code><b>գաղտնաբառ</b></code> սիւնակները ձեր բոլոր ուսանողներուն համար, իսկ եթէ փափաքիք՝ նաեւ ընտրովի <code>ել․ նամակ</code> սիւնակը։ Եթէ ձեր օգտատէրերուն համար ել․ նամակ չտրամադրեք, անոնք բոլորը կը կապուին ձեր ել․ նամակի հաշիւին։ Ել․ նամակը օգտակար է այն պարագային, երբ պէտք է վերականգնել ձեր ուսանողներուն գաղտնաբառերը։",
	bulk_make_collection = "Ստեղծել անհատական հաւաքածոյ այս խումբի ուսանողներուն համար",
	bulk_create = "Ստեղծել օգտատէրեր",

    -- Project page
    -- ============
    remixed_from = "(Ձուլուած է @1‑էն, @2‑ի կողմէ)", -- @1 is the original project name, @2 is its author's username
	project_remixes_title = "Այս նախագիծի հանրային ձուլուածքը",
	project_collections_title = "Այս նախագիծը պարունակող հանրային հաւաքածոներ",
    shift_enter_note = "Նոր տող անցնելու համար սեղմեցէք Shift + Enter", -- in the notes field
    no_notes = "Այս նախագիծը չունի նշումներ",
	no_notes = "Այս նախագիծը չունի նշումներ",
	created_date = "Ստեղծուած է",
	updated_date = "Վերջին թարմացում",
	shared_date = "Տարածուած է",
	published_date = "Հրապարակուած է",
    -- Buttons
	edit = "Խմբագրել",
	download = "Ներբեռնել",
	embed = "Ներկառուցել",
	collect = "Աւելցնել հաւաքածոյին մէջ",
	delete_button = "Ջնջել",
	publish_button = "Հրապարակել",
	share_button = "Տարածել",
	unpublish_button = "Չհրապարակել",
	unshare_button = "Չտարածել",
    -- Bookmarking tooltips
    bookmark = "Պահեցուցէ՛ք այս նախագիծը ձեր էջանիշներուն մէջ",
    unbookmark = "Հեռացուցէ՛ք այս նախագիծը ձեր էջանիշներէն",
    project_is_bookmarked = "Ձեր նախագիծը շատերու հաւնութեան արժանացած է։",
    -- Flagging
	bookmark = "Հեռացուցէ՛ք այս նախագիծը ձեր էջանիշներէն",
	unbookmark = "Պահեցուցէ՛ք այս նախագիծը ձեր էջանիշներուն մէջ",
	project_is_bookmarked = "Ձեր նախագիծը շատերու հաւնութեան արժանացած է։",

    -- Embed dialog
    -- ============
	embed_title = "Ներկառուցման ընտրանքներ",
	embed_explanation = "Խնդրեմ ընտրէք այն տարրերը, զորս կ՚ուզէք ներառել ներկառուցուած նախագիծի դիտարկիչին մէջ՝",
	project_title = "Նախագիծի վերնագիր",
	project_author = "Նախագիծի հեղինակ",
	edit_button = "Խմբագրման կոճակ",
	pause_button = "Ընդհատման կոճակ",
	embed_url = "Ներկառուցման URL",
	embed_code = "Ներկառուցման Code",

    -- Collect dialog
    -- ==============
	collect_title = "Աւելցնել նախագիծը հաւաքածոյին",
	collect_explanation = "Խնդրեմ ընտրել այն հաւաքածոն, որուն կ՚ուզէք աւելցնել այս նախագիծը`",

    -- Delete project dialog
    -- =====================
	confirm_delete_project = "Իսկապէ՞ս կ՚ուզէք ջնջել այս նախագիծը:",
	confirm_delete_user = "Իսկապէ՞ս կ՚ուզէք ջնջել այս օգտատէրը:",
	confirm_delete_collection = "Իսկապէ՞ս կ՚ուզէք ջնջել այս հաւաքածոն:",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
	confirm_share_project = "Իսկապէ՞ս կ՚ուզէք տարածել այս նախագիծը:",
	confirm_unshare_project = "Իսկապէ՞ս կ՚ուզէք չտարածել այս նախագիծը:",
	confirm_publish_project = "Իսկապէ՞ս կ՚ուզէք հրապարակել այս նախագիծը:",
	confirm_unpublish_project = "Իսկապէ՞ս կ՚ուզէք չհրապարակել այս նախագիծը:",

    -- Flag project dialogs
    -- ====================
    flag_prewarning = "Վստա՞հ էք, որ կ՚ուզէք նշել այս նախագիծը որպէս անպատշաճ։ @1@1 Ձեր օգտանունը կը նշուի որպէս հաղորդում ներկայացնող։ @1@1 Օրինական նախագիծերը դիտումնաւոր կերպով դրօշակաւորելը պիտի համարուի մեր Օգտագործման Պայմաններուն խախտում և կրնայ պատճառ դառնալ ձեր հաշիւին կասեցման։", -- @1 becomes a new line. You can add as many as you need.
	choose_flag_reason = "Նշել պատճառը",
	flag_reason_hack = "Անվտանգութեան խոցելիութիւն",
	flag_reason_coc = "Վարքագիծի կանոններու խախտում",
	flag_reason_dmca = "DMCA օրէնքի խախտում",
	flag_reason_notes = "Բացատրեցէք մեզի աւելի այն մասին, թէ ինչո՛ւ կը դրօշակաւորէք այս նախագիծը՝",
	flag_reason_notes_placeholder = "Յաւելեալ նշումներ",

    -- User admin component
    -- ====================
	user_id = "ID",
	project_count = "Նախագիծի հաշուարկը",
    -- Buttons
    become = "Դարձնել", -- as an admin, temporarily impersonate this user
	verify = "Ստուգել",
	change_email = "Փոխել ել․ նամակը",
	reset_password = "Վերականգնել գաղտնաբառը",
	get_reset_password_token = "Ստանալ գաղտնաբառի վերականգնման թոքենը",
	confirm_reset_password = "Իրապէ՞ս կ՚ուզէք վերականգնել @1 օգտատիրոջ գաղտնաբառը",
	change_username = "Փոխել օգտանունը",
	new_username = "@1-ի նոր օգտանունը՝",
	send_msg = "Ուղարկել հաղորդագրութիւն",
	ban = "Արգիլել",
	unban = "Չարգիլել",
	delete_usr = "Ջնջել",
	perma_delete_usr = "Ջնջել մնայուն կերպով",
	revive_usr = "Վերականգնել",
	confirm_revive = "Ի՞րապէս կ՚ուզէք ետ բերել @1 օգտատէրը։",
    -- New email dialog
    new_email = "Նոր ել․ նամակ",
    -- Send message dialog
	compose_email = "Հաղորդագրութիւն մը գրել",
	msg_subject = "Վերնագիր",
	msg_body = "Ել. նամակի բովանդակութիւն",

    -- Delete user dialog
    -- ==================
	confirm_delete_usr = "Վստա՞հ էք, որ կ՚ուզէք ջնջել @1 օգտատէրը",
	warning_no_return = "ՈՒՇԱԴՐՈՒԹԻՒՆ․ Այս գործողութիւնը կարելի չէ չեղարկել",

    -- Change password page
    -- ====================
	change_password_title = "Փոխել գաղտնաբառը",
	current_pwd = "Ընթացիկ գաղտնաբառ",
	new_pwd = "Նոր գաղտնաբառ",
	new_pwd_2 = "Կրկնել նոր գաղտնաբառը",

    -- Change email page
    -- =================
    new_email_2 = "Կրկնել նոր ել․ նամակը",

    -- Administration page
    -- ===================
	carousel_admin = "Յայտնաբերուած կարուսելներ",
	user_admin = "Օգտատէրերու կառավարում",
	zombie_admin = "Զոմպի կառավարում",
	flagged_projects = "Դրօշակուած նախագիծեր",
	suspicious_ips = "Կասեցուած IP‑ներ",

    -- Error messages
    -- ==============
    err_login_failed = "Մուտքը ձախողած է",
    err_password_mismatch = "Խնդրեմ վստահ եղէք, որ երկու անգամ մուտքագրած էք your@1password‑ը, եւ որ երկու գաղտնաբառերն ալ կը համընկնին։", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "Գաղտնաբառերը չեն համընկնիր",
    err_email_mismatch = "Խնդրեմ վստահ եղէք, որ երկու անգամ մուտքագրած էք ձեր your@1email‑ը, եւ որ երկու ել․ հասցէներն ալ կը համընկնին։", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "Ել․ հասցէները չեն համընկնիր",
    update_role = "Թարմացնել դերը",
    see_code = "Տեսնել քոտը",
    t_support = "Աջակցութիւն",
    project_by = "@1 կողմէ",
    t_tools = "Գործիքներ",
    unflag_project = "Հանել դրօշակաւորումը",
    flag_project = "Դրօշակաւորել այս նախագիծը",
    t_about = "Մեր մասին",
    or_before = "կամ յառաջ",
    you_flagged = "Դուք այս նախագիծը դրօշակաւորած էք որպէս անպատշաճ",
    t_legal = "Իրաւական",
    t_learning = "Ուսում",
}

return locale
