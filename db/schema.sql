--
-- PostgreSQL database dump
--

-- Dumped from database version 16.7 (Homebrew)
-- Dumped by pg_dump version 16.7 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: dom_username; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.dom_username AS text;


--
-- Name: snap_user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.snap_user_role AS ENUM (
    'student',
    'standard',
    'reviewer',
    'moderator',
    'admin',
    'banned'
);


--
-- Name: expire_token(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.expire_token() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM tokens WHERE created < NOW() - INTERVAL '3 days';
RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: active_projects; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.active_projects AS
 SELECT id,
    projectname,
    ispublic,
    ispublished,
    notes,
    created,
    lastupdated,
    lastshared,
    username,
    firstpublished,
    deleted
   FROM public.projects
  WHERE (deleted IS NULL);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: active_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.active_users AS
 SELECT id,
    created,
    username,
    email,
    salt,
    password,
    about,
    location,
    verified,
    role,
    deleted,
    unique_email,
    bad_flags,
    is_teacher,
    creator_id
   FROM public.users
  WHERE (deleted IS NULL);


--
-- Name: banned_ips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.banned_ips (
    ip text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    offense_count integer DEFAULT 0 NOT NULL
);


--
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookmarks (
    bookmarker_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: collection_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_memberships (
    id integer NOT NULL,
    collection_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: collection_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collection_memberships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collection_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collection_memberships_id_seq OWNED BY public.collection_memberships.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: collections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collections_id_seq OWNED BY public.collections.id;


--
-- Name: count_recent_projects; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.count_recent_projects AS
 SELECT count(*) AS count
   FROM public.projects
  WHERE (lastupdated > (('now'::text)::date - '1 day'::interval));


--
-- Name: deleted_projects; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.deleted_projects AS
 SELECT id,
    projectname,
    ispublic,
    ispublished,
    notes,
    created,
    lastupdated,
    lastshared,
    username,
    firstpublished,
    deleted
   FROM public.projects
  WHERE (deleted IS NOT NULL);


--
-- Name: deleted_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.deleted_users AS
 SELECT id,
    created,
    username,
    email,
    salt,
    password,
    about,
    location,
    verified,
    role,
    deleted,
    unique_email,
    bad_flags,
    is_teacher,
    creator_id
   FROM public.users
  WHERE (deleted IS NOT NULL);


--
-- Name: featured_collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.featured_collections (
    collection_id integer NOT NULL,
    page_path text NOT NULL,
    type text NOT NULL,
    "order" integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: flagged_projects; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: flagged_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flagged_projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flagged_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flagged_projects_id_seq OWNED BY public.flagged_projects.id;


--
-- Name: followers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.followers (
    follower_id integer NOT NULL,
    followed_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lapis_migrations (
    name character varying(255) NOT NULL
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: recent_projects_2_days; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.recent_projects_2_days AS
 SELECT count(*) AS count
   FROM public.projects
  WHERE (lastupdated > (('now'::text)::date - '2 days'::interval));


--
-- Name: remixes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.remixes (
    original_project_id integer,
    remixed_project_id integer NOT NULL,
    created timestamp with time zone
);


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tokens (
    created timestamp without time zone DEFAULT now() NOT NULL,
    username public.dom_username NOT NULL,
    purpose text,
    value text NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: collection_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_memberships ALTER COLUMN id SET DEFAULT nextval('public.collection_memberships_id_seq'::regclass);


--
-- Name: collections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections ALTER COLUMN id SET DEFAULT nextval('public.collections_id_seq'::regclass);


--
-- Name: flagged_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flagged_projects ALTER COLUMN id SET DEFAULT nextval('public.flagged_projects_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: banned_ips banned_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banned_ips
    ADD CONSTRAINT banned_ips_pkey PRIMARY KEY (ip);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (bookmarker_id, project_id);


--
-- Name: collection_memberships collection_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_memberships
    ADD CONSTRAINT collection_memberships_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: featured_collections featured_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.featured_collections
    ADD CONSTRAINT featured_collections_pkey PRIMARY KEY (collection_id, page_path);


--
-- Name: flagged_projects flagged_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flagged_projects
    ADD CONSTRAINT flagged_projects_pkey PRIMARY KEY (id);


--
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (follower_id, followed_id);


--
-- Name: lapis_migrations lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (username, projectname);


--
-- Name: projects unique_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT unique_id UNIQUE (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: users users_unique_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_unique_email_key UNIQUE (unique_email);


--
-- Name: tokens value_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT value_pkey PRIMARY KEY (value);


--
-- Name: collection_memberships_collection_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collection_memberships_collection_id_idx ON public.collection_memberships USING btree (collection_id);


--
-- Name: collection_memberships_collection_id_project_id_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX collection_memberships_collection_id_project_id_user_id_idx ON public.collection_memberships USING btree (collection_id, project_id, user_id);


--
-- Name: collection_memberships_project_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collection_memberships_project_id_idx ON public.collection_memberships USING btree (project_id);


--
-- Name: collections_creator_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collections_creator_id_idx ON public.collections USING btree (creator_id);


--
-- Name: flagged_projects_flagger_id_project_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX flagged_projects_flagger_id_project_id_idx ON public.flagged_projects USING btree (flagger_id, project_id);


--
-- Name: original_project_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX original_project_id_index ON public.remixes USING btree (original_project_id);


--
-- Name: remixed_project_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX remixed_project_id_index ON public.remixes USING btree (remixed_project_id);


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_email_idx ON public.users USING btree (email);


--
-- Name: tokens expire_token_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER expire_token_trigger AFTER INSERT ON public.tokens FOR EACH STATEMENT EXECUTE FUNCTION public.expire_token();


--
-- Name: projects projects_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_username_fkey FOREIGN KEY (username) REFERENCES public.users(username) ON UPDATE CASCADE;


--
-- Name: remixes remixes_original_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remixes
    ADD CONSTRAINT remixes_original_project_id_fkey FOREIGN KEY (original_project_id) REFERENCES public.projects(id);


--
-- Name: remixes remixes_remixed_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remixes
    ADD CONSTRAINT remixes_remixed_project_id_fkey FOREIGN KEY (remixed_project_id) REFERENCES public.projects(id);


--
-- Name: tokens users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT users_fkey FOREIGN KEY (username) REFERENCES public.users(username) ON UPDATE CASCADE;


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.7 (Homebrew)
-- Dumped by pg_dump version 16.7 (Homebrew)


--
-- Data for Name: lapis_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lapis_migrations (name) FROM stdin;
20190140
201901291
20190141
2019-01-04:0
2019-01-29:0
2019-02-01:0
2019-02-05:0
2019-02-04:0
2020-10-22:0
2020-11-03:0
2020-11-09:0
2020-11-10:0
2022-08-16:0
2022-08-17:0
2022-08-18:0
2022-09-16:0
1683536418
2023-03-14:0
2023-03-14:1
2025-02-06:0
\.


--
-- PostgreSQL database dump complete
--

