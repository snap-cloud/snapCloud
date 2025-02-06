--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5 (Ubuntu 10.5-1.pgdg16.04+1)
-- Dumped by pg_dump version 10.5 (Ubuntu 10.5-1.pgdg16.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: dom_username; Type: DOMAIN; Schema: public; Owner: cloud
--

CREATE DOMAIN public.dom_username AS text;


ALTER DOMAIN public.dom_username OWNER TO cloud;

--
-- Name: snap_user_role; Type: TYPE; Schema: public; Owner: cloud
--

CREATE TYPE public.snap_user_role AS ENUM (
    'student',
    'standard',
    'reviewer',
    'moderator',
    'admin',
    'banned'
);


ALTER TYPE public.snap_user_role OWNER TO cloud;

--
-- Name: expire_token(); Type: FUNCTION; Schema: public; Owner: cloud
--

CREATE FUNCTION public.expire_token() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM tokens WHERE created < NOW() - INTERVAL '3 days';
RETURN NEW;
END;
$$;


ALTER FUNCTION public.expire_token() OWNER TO cloud;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    projectname text NOT NULL,
    ispublic boolean,
    ispublished boolean,
    notes text,
    created timestamp with time zone,
    lastupdated timestamp with time zone,
    lastshared timestamp with time zone,
    username public.dom_username NOT NULL,
    firstpublished timestamp with time zone,
    deleted timestamp with time zone
);


ALTER TABLE public.projects OWNER TO cloud;

--
-- Name: active_projects; Type: VIEW; Schema: public; Owner: cloud
--

CREATE VIEW public.active_projects AS
 SELECT projects.id,
    projects.projectname,
    projects.ispublic,
    projects.ispublished,
    projects.notes,
    projects.created,
    projects.lastupdated,
    projects.lastshared,
    projects.username,
    projects.firstpublished,
    projects.deleted
   FROM public.projects
  WHERE (projects.deleted IS NULL);


ALTER TABLE public.active_projects OWNER TO cloud;

--
-- Name: users; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.users (
    id integer NOT NULL,
    created timestamp with time zone,
    username public.dom_username NOT NULL,
    email text,
    salt text,
    password text,
    about text,
    location text,
    verified boolean,
    role public.snap_user_role DEFAULT 'standard'::public.snap_user_role,
    deleted timestamp with time zone,
    unique_email text,
    bad_flags integer DEFAULT 0 NOT NULL,
    is_teacher boolean DEFAULT false NOT NULL,
    creator_id integer
);


ALTER TABLE public.users OWNER TO cloud;

--
-- Name: active_users; Type: VIEW; Schema: public; Owner: cloud
--

CREATE VIEW public.active_users AS
 SELECT users.id,
    users.created,
    users.username,
    users.email,
    users.salt,
    users.password,
    users.about,
    users.location,
    users.verified,
    users.role,
    users.deleted,
    users.unique_email,
    users.bad_flags,
    users.is_teacher,
    users.creator_id
   FROM public.users
  WHERE (users.deleted IS NULL);


ALTER TABLE public.active_users OWNER TO cloud;

--
-- Name: banned_ips; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.banned_ips (
    ip text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    offense_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.banned_ips OWNER TO cloud;

--
-- Name: collection_memberships; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.collection_memberships (
    id integer NOT NULL,
    collection_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.collection_memberships OWNER TO cloud;

--
-- Name: collection_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: cloud
--

CREATE SEQUENCE public.collection_memberships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.collection_memberships_id_seq OWNER TO cloud;

--
-- Name: collection_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cloud
--

ALTER SEQUENCE public.collection_memberships_id_seq OWNED BY public.collection_memberships.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.collections (
    id integer NOT NULL,
    name text NOT NULL,
    creator_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    description text,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    shared boolean DEFAULT false NOT NULL,
    shared_at timestamp with time zone,
    thumbnail_id integer,
    editor_ids integer[],
    free_for_all boolean DEFAULT false NOT NULL
);


ALTER TABLE public.collections OWNER TO cloud;

--
-- Name: collections_id_seq; Type: SEQUENCE; Schema: public; Owner: cloud
--

CREATE SEQUENCE public.collections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.collections_id_seq OWNER TO cloud;

--
-- Name: collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cloud
--

ALTER SEQUENCE public.collections_id_seq OWNED BY public.collections.id;


--
-- Name: count_recent_projects; Type: VIEW; Schema: public; Owner: cloud
--

CREATE VIEW public.count_recent_projects AS
 SELECT count(*) AS count
   FROM public.projects
  WHERE (projects.lastupdated > (('now'::text)::date - '1 day'::interval));


ALTER TABLE public.count_recent_projects OWNER TO cloud;

--
-- Name: deleted_projects; Type: VIEW; Schema: public; Owner: cloud
--

CREATE VIEW public.deleted_projects AS
 SELECT projects.id,
    projects.projectname,
    projects.ispublic,
    projects.ispublished,
    projects.notes,
    projects.created,
    projects.lastupdated,
    projects.lastshared,
    projects.username,
    projects.firstpublished,
    projects.deleted
   FROM public.projects
  WHERE (projects.deleted IS NOT NULL);


ALTER TABLE public.deleted_projects OWNER TO cloud;

--
-- Name: deleted_users; Type: VIEW; Schema: public; Owner: cloud
--

CREATE VIEW public.deleted_users AS
 SELECT users.id,
    users.created,
    users.username,
    users.email,
    users.salt,
    users.password,
    users.about,
    users.location,
    users.verified,
    users.role,
    users.deleted,
    users.unique_email,
    users.bad_flags,
    users.is_teacher,
    users.creator_id
   FROM public.users
  WHERE (users.deleted IS NOT NULL);


ALTER TABLE public.deleted_users OWNER TO cloud;

--
-- Name: featured_collections; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.featured_collections (
    collection_id integer NOT NULL,
    page_path text NOT NULL,
    type text NOT NULL,
    "order" integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.featured_collections OWNER TO cloud;

--
-- Name: flagged_projects; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.flagged_projects (
    id integer NOT NULL,
    flagger_id integer NOT NULL,
    project_id integer NOT NULL,
    reason text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    notes text
);


ALTER TABLE public.flagged_projects OWNER TO cloud;

--
-- Name: flagged_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: cloud
--

CREATE SEQUENCE public.flagged_projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flagged_projects_id_seq OWNER TO cloud;

--
-- Name: flagged_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cloud
--

ALTER SEQUENCE public.flagged_projects_id_seq OWNED BY public.flagged_projects.id;


--
-- Name: followers; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.followers (
    follower_id integer NOT NULL,
    followed_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.followers OWNER TO cloud;

--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.lapis_migrations (
    name character varying(255) NOT NULL
);


ALTER TABLE public.lapis_migrations OWNER TO cloud;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: cloud
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO cloud;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cloud
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: recent_projects_2_days; Type: VIEW; Schema: public; Owner: cloud
--

CREATE VIEW public.recent_projects_2_days AS
 SELECT count(*) AS count
   FROM public.projects
  WHERE (projects.lastupdated > (('now'::text)::date - '2 days'::interval));


ALTER TABLE public.recent_projects_2_days OWNER TO cloud;

--
-- Name: remixes; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.remixes (
    original_project_id integer,
    remixed_project_id integer NOT NULL,
    created timestamp with time zone
);


ALTER TABLE public.remixes OWNER TO cloud;

--
-- Name: tokens; Type: TABLE; Schema: public; Owner: cloud
--

CREATE TABLE public.tokens (
    created timestamp without time zone DEFAULT now() NOT NULL,
    username public.dom_username NOT NULL,
    purpose text,
    value text NOT NULL
);


ALTER TABLE public.tokens OWNER TO cloud;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: cloud
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO cloud;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cloud
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: collection_memberships id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.collection_memberships ALTER COLUMN id SET DEFAULT nextval('public.collection_memberships_id_seq'::regclass);


--
-- Name: collections id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.collections ALTER COLUMN id SET DEFAULT nextval('public.collections_id_seq'::regclass);


--
-- Name: flagged_projects id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.flagged_projects ALTER COLUMN id SET DEFAULT nextval('public.flagged_projects_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: banned_ips banned_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.banned_ips
    ADD CONSTRAINT banned_ips_pkey PRIMARY KEY (ip);


--
-- Name: collection_memberships collection_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.collection_memberships
    ADD CONSTRAINT collection_memberships_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: featured_collections featured_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.featured_collections
    ADD CONSTRAINT featured_collections_pkey PRIMARY KEY (collection_id, page_path);


--
-- Name: flagged_projects flagged_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.flagged_projects
    ADD CONSTRAINT flagged_projects_pkey PRIMARY KEY (id);


--
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (follower_id, followed_id);


--
-- Name: lapis_migrations lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (username, projectname);


--
-- Name: projects unique_id; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT unique_id UNIQUE (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: users users_unique_email_key; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_unique_email_key UNIQUE (unique_email);


--
-- Name: tokens value_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT value_pkey PRIMARY KEY (value);


--
-- Name: collection_memberships_collection_id_idx; Type: INDEX; Schema: public; Owner: cloud
--

CREATE INDEX collection_memberships_collection_id_idx ON public.collection_memberships USING btree (collection_id);


--
-- Name: collection_memberships_collection_id_project_id_user_id_idx; Type: INDEX; Schema: public; Owner: cloud
--

CREATE UNIQUE INDEX collection_memberships_collection_id_project_id_user_id_idx ON public.collection_memberships USING btree (collection_id, project_id, user_id);


--
-- Name: collection_memberships_project_id_idx; Type: INDEX; Schema: public; Owner: cloud
--

CREATE INDEX collection_memberships_project_id_idx ON public.collection_memberships USING btree (project_id);


--
-- Name: collections_creator_id_idx; Type: INDEX; Schema: public; Owner: cloud
--

CREATE INDEX collections_creator_id_idx ON public.collections USING btree (creator_id);


--
-- Name: flagged_projects_flagger_id_project_id_idx; Type: INDEX; Schema: public; Owner: cloud
--

CREATE UNIQUE INDEX flagged_projects_flagger_id_project_id_idx ON public.flagged_projects USING btree (flagger_id, project_id);


--
-- Name: original_project_id_index; Type: INDEX; Schema: public; Owner: cloud
--

CREATE INDEX original_project_id_index ON public.remixes USING btree (original_project_id);


--
-- Name: remixed_project_id_index; Type: INDEX; Schema: public; Owner: cloud
--

CREATE INDEX remixed_project_id_index ON public.remixes USING btree (remixed_project_id);


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: cloud
--

CREATE INDEX users_email_idx ON public.users USING btree (email);


--
-- Name: tokens expire_token_trigger; Type: TRIGGER; Schema: public; Owner: cloud
--

CREATE TRIGGER expire_token_trigger AFTER INSERT ON public.tokens FOR EACH STATEMENT EXECUTE PROCEDURE public.expire_token();


--
-- Name: projects projects_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_username_fkey FOREIGN KEY (username) REFERENCES public.users(username) ON UPDATE CASCADE;


--
-- Name: remixes remixes_original_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.remixes
    ADD CONSTRAINT remixes_original_project_id_fkey FOREIGN KEY (original_project_id) REFERENCES public.projects(id);


--
-- Name: remixes remixes_remixed_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.remixes
    ADD CONSTRAINT remixes_remixed_project_id_fkey FOREIGN KEY (remixed_project_id) REFERENCES public.projects(id);


--
-- Name: tokens users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT users_fkey FOREIGN KEY (username) REFERENCES public.users(username) ON UPDATE CASCADE;


--
-- Name: FUNCTION expire_token(); Type: ACL; Schema: public; Owner: cloud
--

GRANT ALL ON FUNCTION public.expire_token() TO snapanalytics;


--
-- Name: TABLE pg_stat_bgwriter; Type: ACL; Schema: pg_catalog; Owner: postgres
--

GRANT SELECT ON TABLE pg_catalog.pg_stat_bgwriter TO newrelic;


--
-- Name: TABLE pg_stat_database; Type: ACL; Schema: pg_catalog; Owner: postgres
--

GRANT SELECT ON TABLE pg_catalog.pg_stat_database TO newrelic;


--
-- Name: TABLE pg_stat_database_conflicts; Type: ACL; Schema: pg_catalog; Owner: postgres
--

GRANT SELECT ON TABLE pg_catalog.pg_stat_database_conflicts TO newrelic;


--
-- Name: TABLE projects; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.projects TO snapanalytics;


--
-- Name: TABLE active_projects; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.active_projects TO snapanalytics;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.users TO snapanalytics;


--
-- Name: COLUMN users.email; Type: ACL; Schema: public; Owner: cloud
--

GRANT UPDATE(email) ON TABLE public.users TO snapanalytics;


--
-- Name: TABLE active_users; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.active_users TO snapanalytics;


--
-- Name: TABLE banned_ips; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.banned_ips TO snapanalytics;


--
-- Name: TABLE collection_memberships; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.collection_memberships TO snapanalytics;


--
-- Name: TABLE collections; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.collections TO snapanalytics;


--
-- Name: TABLE count_recent_projects; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.count_recent_projects TO snapanalytics;


--
-- Name: TABLE deleted_projects; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.deleted_projects TO snapanalytics;


--
-- Name: TABLE deleted_users; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.deleted_users TO snapanalytics;


--
-- Name: TABLE featured_collections; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.featured_collections TO snapanalytics;


--
-- Name: TABLE flagged_projects; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.flagged_projects TO snapanalytics;


--
-- Name: TABLE followers; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.followers TO snapanalytics;


--
-- Name: TABLE lapis_migrations; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.lapis_migrations TO snapanalytics;


--
-- Name: TABLE recent_projects_2_days; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.recent_projects_2_days TO snapanalytics;


--
-- Name: TABLE remixes; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.remixes TO snapanalytics;


--
-- Name: TABLE tokens; Type: ACL; Schema: public; Owner: cloud
--

GRANT SELECT ON TABLE public.tokens TO snapanalytics;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: cloud
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud IN SCHEMA public REVOKE ALL ON TABLES  FROM cloud;
ALTER DEFAULT PRIVILEGES FOR ROLE cloud IN SCHEMA public GRANT SELECT ON TABLES  TO snapanalytics;


--
-- PostgreSQL database dump complete
--

