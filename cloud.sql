--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: dom_username; Type: DOMAIN; Schema: public; Owner: snap
--

CREATE DOMAIN dom_username AS text
	CONSTRAINT dom_username_check CHECK (((length(VALUE) > 1) AND (length(VALUE) < 200)));


ALTER DOMAIN dom_username OWNER TO snap;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: snap; Tablespace: 
--

CREATE TABLE projects (
    id integer NOT NULL,
    projectname text NOT NULL,
    ispublic boolean,
    ispublished boolean,
    notes text,
    created timestamp with time zone,
    lastupdated timestamp with time zone,
    lastshared timestamp with time zone,
    username dom_username NOT NULL
);


ALTER TABLE projects OWNER TO snap;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: snap
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE projects_id_seq OWNER TO snap;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snap
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: snap; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    created timestamp with time zone,
    username dom_username NOT NULL,
    email text,
    password text,
    joined timestamp with time zone,
    about text,
    location text,
    isadmin boolean
);


ALTER TABLE users OWNER TO snap;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: snap
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO snap;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snap
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: snap
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: snap
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: snap; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (username, projectname);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: snap; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: projects_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: snap
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_username_fkey FOREIGN KEY (username) REFERENCES users(username);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

