--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.1
-- Dumped by pg_dump version 9.5.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
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


SET search_path = public, pg_catalog;

--
-- Name: footgun(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION footgun(_schema text, _parttionbase text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    row     record;
BEGIN
    FOR row IN 
        SELECT
            table_schema,
            table_name
        FROM
            information_schema.tables
        WHERE
            table_type = 'BASE TABLE'
        AND
            table_schema = _schema
        AND
            table_name ILIKE (_parttionbase || '%')
    LOOP
        EXECUTE 'DROP TABLE ' || quote_ident(row.table_schema) || '.' || quote_ident(row.table_name);
        RAISE INFO 'Dropped table: %', quote_ident(row.table_schema) || '.' || quote_ident(row.table_name);
    END LOOP;
END;
$$;


ALTER FUNCTION public.footgun(_schema text, _parttionbase text) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: forums; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE forums (
    siteid integer NOT NULL,
    fid integer NOT NULL,
    name character varying,
    level integer,
    parent_fid integer,
    title character varying,
    "check" integer,
    bot_updated timestamp with time zone,
    descr character varying
);


ALTER TABLE forums OWNER TO postgres;

--
-- Name: logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE logs (
    referer character varying,
    path character varying,
    ip character varying,
    uagent character varying,
    date timestamp without time zone
);


ALTER TABLE logs OWNER TO postgres;

--
-- Name: main_forums; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE main_forums (
    mfid integer NOT NULL,
    title character varying
);


ALTER TABLE main_forums OWNER TO postgres;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE posts (
    mid integer NOT NULL,
    siteid integer NOT NULL,
    body character varying,
    addedby character varying(50),
    addeduid integer,
    addeddate timestamp without time zone,
    tid integer NOT NULL,
    first integer DEFAULT 0,
    title character varying,
    marks character varying
);


ALTER TABLE posts OWNER TO postgres;

--
-- Name: site_forums; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE site_forums (
    mfid integer NOT NULL,
    siteid integer NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE site_forums OWNER TO postgres;

--
-- Name: sites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE sites (
    id integer NOT NULL,
    descr character(100),
    name character varying
);


ALTER TABLE sites OWNER TO postgres;

--
-- Name: threads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE threads (
    tid integer NOT NULL,
    siteid integer NOT NULL,
    fid integer NOT NULL,
    title character(200) NOT NULL,
    created timestamp without time zone,
    updated timestamp without time zone,
    viewers integer,
    responses integer,
    descr character(100),
    bot_updated timestamp with time zone
);


ALTER TABLE threads OWNER TO postgres;

--
-- Name: tpages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tpages (
    siteid integer NOT NULL,
    tid integer NOT NULL,
    page integer NOT NULL,
    postcount integer
);


ALTER TABLE tpages OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE users (
    name character varying(50) NOT NULL,
    uid integer,
    lastposted timestamp without time zone,
    siteid integer NOT NULL
);


ALTER TABLE users OWNER TO postgres;

--
-- Name: forums_prkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY forums
    ADD CONSTRAINT forums_prkey PRIMARY KEY (siteid, fid);


--
-- Name: mforums_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY main_forums
    ADD CONSTRAINT mforums_pkey PRIMARY KEY (mfid);


--
-- Name: posts_prkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_prkey PRIMARY KEY (mid, siteid, tid);


--
-- Name: site_forums_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY site_forums
    ADD CONSTRAINT site_forums_pkey PRIMARY KEY (mfid, siteid, fid);


--
-- Name: site_prmk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT site_prmk PRIMARY KEY (id);


--
-- Name: thrds_prk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY threads
    ADD CONSTRAINT thrds_prk PRIMARY KEY (tid, siteid, fid);


--
-- Name: tpages_prkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tpages
    ADD CONSTRAINT tpages_prkey PRIMARY KEY (siteid, tid, page);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (siteid, name);


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

