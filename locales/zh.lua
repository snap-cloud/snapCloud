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
    lang_name = "简体中文",
    lang_code = "zh",
    authors = "Simon Mong, 18001767679",
    last_updated = "2022/08/11", -- YYYY/MM/DD

    -- Top navigation bar
    -- ==================
    -- Buttons
    run_snap = "运行Snap@1", -- @1 becomes an italic exclamation mark (!)
    explore = "其他人的作品",
    forum = "论坛",
    join = "注册",
    login = "登录",
    -- User menu
    my_projects = "我的作品",
    my_collections = "我的作品集",
    my_public_page = "我的展示页",
    my_profile = "我的个人主页",
    administration = "管理",
    logout = "退出登录",
    -- This option lets admins go back to their admin account when they're
    -- impersonating another user:
    unbecome = "",

    -- Footer
    -- ======
    -- Titles
    t_about = "关于",
    t_learning = "学习",
    t_tools = "工具",
    t_support = "支持",
    t_legal = "合法的",
    -- Links
    about = "关于Snap@1",
    blog = "博客",
    credits = "制作人员名单",
    requirements = "技术需求",
    partners = "合作伙伴",
    source = "源代码",
    events = "",
    examples = "",
    manual = "参考手册",
    materials = "素材",
    bjc = "BJC课程",
    research = "探索",
    offline = "离线版本",
    extensions = "模块/包",
    old_snap = "",
    -- forum already translated in top navigation bar
    contact = "联系我们",
    mirrors = "镜像",
    dmca = "DMCA",
    privacy = "隐私",
    tos = "服务条款",

    -- Index page
    -- ==========
    welcome = "欢迎使用Snap@1", -- @1 becomes an italic exclamation mark (!)
    welcome_logged_in = "", -- @1 becomes the current user username
    snap_description = "Snap@1是一种对儿童和成人具有广泛吸引力的编程语言，同时也是重要的计算机科学学习平台",
    -- Buttons
    run_now = "",
    -- examples and manual already translated in Footer
    -- Curated Collections
    featured = "精选项目",
    totm = "", -- @1 becomes the actual topic of the month
    science = "科学作品",
    simulations = "",
    three_d = "",
    music = "",
    art = "艺术作品",
    fractals = "分形艺术作品",
    animations = "",
    games = "游戏作品",
    cs = "",
    maths = "",
    latest = "最新项目",
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
    signup_title = "创建Snap@1账号", -- @1 becomes an italic exclamation mark (!)
    username = "用户名称",
    password = "密码",
    password_2 = "再次输入密码",
    birth_month = "",
    or_before = "", -- is preceded by a year, like "1995 or before"
    email_parent = "",
    email_user = "邮件地址",
    email_2 = "再次输入邮件地址",
    tos_agree = "", -- @1 becomes Terms of Service, @2 becomes Privacy Agreement
    -- tos already translated in footer
    privacy_agreement = "隐私协议",
    signup = "注册",

    -- Log in page
    -- ===========
    log_into_snap = "登录到Snap@1", -- @1 becomes an italic exclamation mark (!)
    keep_logged_in = "保持登录状态",
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
    ok = "确定",
    cancel = "取消",
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
    projects = "项目",
    collections = "作品集",
    users = "用户",

    -- Users page
    -- ==========
    last_users = "",

    -- Search component in grids
    -- =========================
    matching = "", -- @1 becomes the search term

    -- My Collections page
    -- ===================
    -- Buttons
    new_collection = "新的作品集",
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
    share_collection_button = "分享",
    unshare_collection_button = "取消分享",
    publish_collection_button = "发布",
    unpublish_collection_button = "取消发布",
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
    admin_tools = "管理工具",
    latest_published_projects = "",
    latest_published_collections = "",

    -- User profile
    -- ============
    profile_title = "", -- @1 becomes the user's username
    join_date = "", -- date of user creation follows
    email = "",
    role = "角色",
    -- User roles
    standard = "标准的",
    reviewer = "浏览者",
    moderator = "版主",
    admin = "管理员",
    banned = "被封禁",
    -- Buttons
    change_my_password = "更改密码",
    change_my_email = "更改我的邮箱",
    delete_my_user = "删除我的账号",

    -- Project page
    -- ============
    remixed_from = "", -- @1 is the original project name, @2 is its author's username
    project_by = "", -- @1 is the username
    project_remixes_title = "",
    project_collections_title = "",
    shift_enter_note = "", -- in the notes field
    no_notes = "这个项目没有说明",
    created_date = "",
    updated_date = "",
    shared_date = "",
    published_date = "",
    -- Buttons
    see_code = "",
    edit = "编辑",
    download = "下载",
    embed = "嵌入",
    collect = "添加至作品集",
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
    embed_title = "嵌入选项",
    embed_explanation = "请选择您想在嵌入式项目浏览器中包含的组件:",
    project_title = "项目标题",
    project_author = "项目作者",
    edit_button = "编辑按钮",
    pause_button = "",
    embed_url = "",
    embed_code = "",

    -- Collect dialog
    -- ==============
    collect_title = "",
    collect_explanation = "",

    -- Delete project dialog
    -- =====================
    confirm_delete_project = "确认要删除这个项目么？",
    confirm_delete_user = "",
    confirm_delete_collection = "",

    -- Share/unshare and publish/unpublish dialogs
    -- ===========================================
    confirm_share_project = "确认要分享这个项目么？",
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
    become = "成为", -- as an admin, temporarily impersonate this user
    change_email = "更改邮箱",
    send_msg = "",
    ban = "封禁",
    unban = "",
    delete_usr = "删除",
    -- New email dialog
    new_email = "",
    -- Send message dialog
    compose_email = "",
    msg_subject = "",
    msg_body = "",

    -- Delete user dialog
    -- ==================
    confirm_delete_usr = "",
    warning_no_return = "注意！这个操作无法被撤销！",

    -- Change password page
    -- ====================
    change_password_title = "更改您的密码",
    current_pwd = "当前密码",
    new_pwd = "设置新密码",
    new_pwd_2 = "再次输入新密码",

    -- Change email page
    -- =================
    new_email_2 = "再次输入新的邮件地址",

    -- Administration page
    -- ===================
    user_admin = "用户管理",
    zombie_admin = "",
    flagged_projects = "被举报的项目",

    -- Error messages
    -- ==============
    err_login_failed = "登录失败",
    err_password_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_password_mismatch_title = "",
    err_email_mismatch = "", -- @1 becomes a new line. Feel free to move it around to where it best fits your locale. You can also add additional new lines by inserting a new @1 where needed.
    err_email_mismatch_title = "邮箱不匹配",
}

return locale
