-- The goal of this script is to collect ~10,000 projects for testing on the staging server.

-- all projects that could appear on the front pages so they look good.
WITH featured_projects AS (
    SELECT p.id, p.username, p.projectname, p.created
    FROM projects p
    JOIN collection_memberships cm ON p.id = cm.project_id
    JOIN featured_collections fc ON fc.collection_id = cm.collection_id
),
-- all admin/mod projects so testing is easy.
admin_mod_projects AS (
    SELECT p.id, p.username, p.projectname, p.created
    FROM projects p
    JOIN users u ON u.username = p.username
    WHERE u.role IN ('moderator', 'admin')
),
-- 500 recent projects for testing.
recent_projects AS (
    SELECT p.id, p.username, p.projectname, p.created
    FROM projects p
    ORDER BY p.created DESC LIMIT 500
),
-- the first 500 projects just because
early_projects AS (
    SELECT p.id, p.username, p.projectname, p.created
    FROM projects p
    ORDER BY p.created ASC LIMIT 500

),
-- all linked projects in collections of admins/mods
collection_projects AS (
    SELECT p.id, p.username, p.projectname, p.created
    FROM projects p
    JOIN collection_memberships cm ON p.id = cm.project_id
    JOIN collections c ON c.id = cm.collection_id
    JOIN users u ON c.creator_id = u.id
    WHERE u.role IN ('moderator', 'admin')
),

all_projects AS (
    SELECT * FROM collection_projects
    union
    SELECT * FROM early_projects
    union
    SELECT * FROM recent_projects
    union
    SELECT * FROM admin_mod_projects
    union
    SELECT * FROM featured_projects
)

-- SELECT COUNT(*) FROM all_projects;
<<<<<<< HEAD
-- SELECT (id / 1000) || '/' || id as project_path, *
SELECT '/mnt/snap_cloud_project_storage/store/' || (id / 1000) || '/' || id as project_path
=======
SELECT (id / 1000) || '/' || id as project_path --, *
-- SELECT '/mnt/snap_cloud_project_storage/store/' || (id / 1000) || '/' || id as project_path
>>>>>>> master
FROM all_projects
ORDER BY id ASC;
