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
-- Name: dom_username; Type: DOMAIN; Schema: public; Owner: cloud
--

CREATE DOMAIN public.dom_username AS text;


ALTER DOMAIN public.dom_username OWNER TO cloud;

--
-- Name: snap_user_role; Type: TYPE; Schema: public; Owner: cloud
--

CREATE TYPE public.snap_user_role AS ENUM (
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
    deleted timestamp with time zone
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
    users.deleted
   FROM public.users
  WHERE (users.deleted IS NULL);


ALTER TABLE public.active_users OWNER TO cloud;

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
    users.deleted
   FROM public.users
  WHERE (users.deleted IS NOT NULL);


ALTER TABLE public.deleted_users OWNER TO cloud;

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
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


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
-- Name: tokens value_pkey; Type: CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT value_pkey PRIMARY KEY (value);


--
-- Name: original_project_id_index; Type: INDEX; Schema: public; Owner: cloud
--

CREATE INDEX original_project_id_index ON public.remixes USING btree (original_project_id);


--
-- Name: remixed_project_id_index; Type: INDEX; Schema: public; Owner: cloud
--

CREATE INDEX remixed_project_id_index ON public.remixes USING btree (remixed_project_id);


--
-- Name: tokens expire_token_trigger; Type: TRIGGER; Schema: public; Owner: cloud
--

CREATE TRIGGER expire_token_trigger AFTER INSERT ON public.tokens FOR EACH STATEMENT EXECUTE PROCEDURE public.expire_token();


--
-- Name: projects projects_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cloud
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_username_fkey FOREIGN KEY (username) REFERENCES public.users(username);


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
    ADD CONSTRAINT users_fkey FOREIGN KEY (username) REFERENCES public.users(username);


--
-- Name: FUNCTION expire_token(); Type: ACL; Schema: public; Owner: cloud
--

GRANT ALL ON FUNCTION public.expire_token() TO snapanalytics;


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

