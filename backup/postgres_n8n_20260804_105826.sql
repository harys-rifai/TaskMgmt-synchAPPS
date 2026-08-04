--
-- PostgreSQL database dump
--

\restrict V6TrDheoqkmpLN8HlxcaDsvMUWU1zgTdqNoVWJQLqfgsIhkhTbNhkkSgcFVrQjR

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: increment_workflow_version(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_workflow_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
			BEGIN
				IF NEW."versionCounter" IS NOT DISTINCT FROM OLD."versionCounter"
					AND (NEW."nodes"::text IS DISTINCT FROM OLD."nodes"::text
						OR NEW."settings"::text IS DISTINCT FROM OLD."settings"::text) THEN
					NEW."versionCounter" = OLD."versionCounter" + 1;
				END IF;
				RETURN NEW;
			END;
			$$;


ALTER FUNCTION public.increment_workflow_version() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agent_chat_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_chat_subscriptions (
    "agentId" character varying(36) NOT NULL,
    "integrationType" character varying(64) NOT NULL,
    "credentialId" character varying(255) NOT NULL,
    "threadId" character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agent_chat_subscriptions_integrationType" CHECK ((("integrationType")::text = ANY ((ARRAY['telegram'::character varying, 'slack'::character varying, 'linear'::character varying])::text[])))
);


ALTER TABLE public.agent_chat_subscriptions OWNER TO postgres;

--
-- Name: COLUMN agent_chat_subscriptions."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_chat_subscriptions."agentId" IS 'Agent that owns this subscription';


--
-- Name: COLUMN agent_chat_subscriptions."integrationType"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_chat_subscriptions."integrationType" IS 'Chat integration platform for this subscription';


--
-- Name: COLUMN agent_chat_subscriptions."credentialId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_chat_subscriptions."credentialId" IS 'Credential connection that owns this subscription';


--
-- Name: COLUMN agent_chat_subscriptions."threadId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_chat_subscriptions."threadId" IS 'Platform thread ID the agent is subscribed to';


--
-- Name: agent_checkpoints; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_checkpoints (
    "runId" character varying(255) NOT NULL,
    "agentId" character varying(255),
    state text,
    expired boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_checkpoints OWNER TO postgres;

--
-- Name: agent_execution; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_execution (
    id character varying(36) NOT NULL,
    "threadId" character varying(128) NOT NULL,
    status character varying(16) NOT NULL,
    "startedAt" timestamp(3) with time zone,
    "stoppedAt" timestamp(3) with time zone,
    duration integer DEFAULT 0 NOT NULL,
    "userMessage" text,
    model character varying(255),
    "promptTokens" integer,
    "completionTokens" integer,
    "totalTokens" integer,
    cost double precision,
    timeline json,
    error text,
    "hitlStatus" character varying(16),
    source character varying(32),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agent_execution_hitlStatus" CHECK ((("hitlStatus")::text = ANY ((ARRAY['suspended'::character varying, 'resumed'::character varying])::text[]))),
    CONSTRAINT "CHK_agent_execution_status" CHECK (((status)::text = ANY ((ARRAY['success'::character varying, 'error'::character varying])::text[])))
);


ALTER TABLE public.agent_execution OWNER TO postgres;

--
-- Name: agent_execution_threads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_execution_threads (
    id character varying(128) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "agentName" character varying(255) NOT NULL,
    "projectId" character varying(255) NOT NULL,
    "sessionNumber" integer DEFAULT 0 NOT NULL,
    "totalPromptTokens" integer DEFAULT 0 NOT NULL,
    "totalCompletionTokens" integer DEFAULT 0 NOT NULL,
    "totalCost" double precision DEFAULT 0 NOT NULL,
    "totalDuration" integer DEFAULT 0 NOT NULL,
    title character varying(255),
    emoji character varying(8),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "taskId" character varying(32),
    "taskVersionId" character varying(36),
    "parentThreadId" character varying(128),
    "parentAgentId" character varying(36)
);


ALTER TABLE public.agent_execution_threads OWNER TO postgres;

--
-- Name: COLUMN agent_execution_threads."taskId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_execution_threads."taskId" IS 'Published task ID that triggered this session; not an FK because published runs can outlive draft task definition rows';


--
-- Name: COLUMN agent_execution_threads."taskVersionId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_execution_threads."taskVersionId" IS 'Published agent_history version that supplied the task snapshot';


--
-- Name: COLUMN agent_execution_threads."parentThreadId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_execution_threads."parentThreadId" IS 'Parent session thread id that delegated this subagent run.';


--
-- Name: COLUMN agent_execution_threads."parentAgentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_execution_threads."parentAgentId" IS 'Saved agent id of the parent that delegated this subagent run.';


--
-- Name: agent_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_files (
    id character varying(16) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "binaryDataId" text NOT NULL,
    "fileName" character varying(255) NOT NULL,
    "mimeType" character varying(255) NOT NULL,
    "fileSizeBytes" integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_files OWNER TO postgres;

--
-- Name: COLUMN agent_files.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_files.id IS 'Application-generated n8n nano ID';


--
-- Name: COLUMN agent_files."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_files."agentId" IS 'Agent that owns this uploaded file';


--
-- Name: COLUMN agent_files."binaryDataId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_files."binaryDataId" IS 'Opaque BinaryDataService reference (mode-prefixed, e.g. "filesystem-v2:<uuid>"); not an FK to binary_data, which only has rows in DB storage mode';


--
-- Name: COLUMN agent_files."fileSizeBytes"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_files."fileSizeBytes" IS 'Uploaded file size in bytes';


--
-- Name: agent_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_history (
    "versionId" character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    schema json,
    tools json,
    skills json,
    "publishedById" uuid,
    author character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_history OWNER TO postgres;

--
-- Name: COLUMN agent_history.schema; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_history.schema IS 'Frozen snapshot of the published AgentJsonConfig';


--
-- Name: COLUMN agent_history.tools; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_history.tools IS 'Frozen map of `toolId → { code, descriptor }` at publish time';


--
-- Name: COLUMN agent_history.skills; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_history.skills IS 'Frozen map of `skillId → AgentSkill` at publish time';


--
-- Name: agent_task_definition; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_task_definition (
    id character varying(32) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    objective text NOT NULL,
    "cronExpression" character varying(128) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_task_definition OWNER TO postgres;

--
-- Name: COLUMN agent_task_definition.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_definition.id IS 'Application-generated task ID referenced from agent JSON config';


--
-- Name: COLUMN agent_task_definition."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_definition."agentId" IS 'Owning agent; task definitions are deleted when the agent is deleted';


--
-- Name: COLUMN agent_task_definition.objective; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_definition.objective IS 'User-authored instruction sent to the agent when this task runs';


--
-- Name: COLUMN agent_task_definition."cronExpression"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_definition."cronExpression" IS 'Cron schedule evaluated using the instance timezone';


--
-- Name: agent_task_run_lock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_task_run_lock (
    "agentId" character varying(36) NOT NULL,
    "taskId" character varying(32) NOT NULL,
    "holderId" uuid NOT NULL,
    "heldUntil" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_task_run_lock OWNER TO postgres;

--
-- Name: COLUMN agent_task_run_lock."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_run_lock."agentId" IS 'Published agent whose scheduled task run is locked';


--
-- Name: COLUMN agent_task_run_lock."taskId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_run_lock."taskId" IS 'Published task ID whose scheduled run is locked';


--
-- Name: COLUMN agent_task_run_lock."holderId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_run_lock."holderId" IS 'Ephemeral lock owner token generated by the running main';


--
-- Name: COLUMN agent_task_run_lock."heldUntil"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_run_lock."heldUntil" IS 'Time after which another main can claim this task run lock';


--
-- Name: agent_task_snapshot; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_task_snapshot (
    "versionId" character varying(36) NOT NULL,
    "taskId" character varying(32) NOT NULL,
    enabled boolean NOT NULL,
    name character varying(128) NOT NULL,
    objective text NOT NULL,
    "cronExpression" character varying(128) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agent_task_snapshot OWNER TO postgres;

--
-- Name: COLUMN agent_task_snapshot."versionId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_snapshot."versionId" IS 'Published agent_history version this task snapshot belongs to';


--
-- Name: COLUMN agent_task_snapshot."taskId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_snapshot."taskId" IS 'Stable task ID referenced from the published agent JSON config';


--
-- Name: COLUMN agent_task_snapshot.enabled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_snapshot.enabled IS 'Published enabled state for this task at publish time';


--
-- Name: COLUMN agent_task_snapshot.objective; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_snapshot.objective IS 'User-authored instruction sent to the agent when this task runs';


--
-- Name: COLUMN agent_task_snapshot."cronExpression"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_task_snapshot."cronExpression" IS 'Cron schedule evaluated using the instance timezone';


--
-- Name: agents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    "projectId" character varying(255) NOT NULL,
    integrations json DEFAULT '[]'::json NOT NULL,
    schema json,
    tools json DEFAULT '{}'::json NOT NULL,
    skills json DEFAULT '{}'::json NOT NULL,
    "versionId" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "activeVersionId" character varying(36)
);


ALTER TABLE public.agents OWNER TO postgres;

--
-- Name: agents_memory_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_memory_entries (
    id character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    content text NOT NULL,
    "contentHash" character varying(64) NOT NULL,
    status character varying(16) NOT NULL,
    "supersededBy" character varying(36),
    "embeddingModel" character varying(128),
    embedding json,
    metadata json,
    "lastSeenAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agents_memory_entries_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'superseded'::character varying, 'dropped'::character varying])::text[])))
);


ALTER TABLE public.agents_memory_entries OWNER TO postgres;

--
-- Name: COLUMN agents_memory_entries."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entries."agentId" IS 'Agent that owns this episodic memory entry';


--
-- Name: COLUMN agents_memory_entries."resourceId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entries."resourceId" IS 'agents_resources.id partition used for episodic recall scope';


--
-- Name: COLUMN agents_memory_entries."supersededBy"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entries."supersededBy" IS 'Self-reference to replacement memory entry';


--
-- Name: COLUMN agents_memory_entries."embeddingModel"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entries."embeddingModel" IS 'Embedding model used to produce embedding';


--
-- Name: COLUMN agents_memory_entries.embedding; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entries.embedding IS 'Embedding vector for episodic recall';


--
-- Name: COLUMN agents_memory_entries.metadata; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entries.metadata IS 'Optional system metadata for ranking and debugging';


--
-- Name: COLUMN agents_memory_entries."lastSeenAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entries."lastSeenAt" IS 'Last time equivalent content was observed; updatedAt tracks row mutation time';


--
-- Name: agents_memory_entry_cursors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_memory_entry_cursors (
    "agentId" character varying(36) NOT NULL,
    "observationScopeId" character varying(255) NOT NULL,
    "lastIndexedObservationId" character varying(36) NOT NULL,
    "lastIndexedObservationCreatedAt" timestamp(3) with time zone CONSTRAINT "agents_memory_entry_cursors_lastIndexedObservationCrea_not_null" NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_memory_entry_cursors OWNER TO postgres;

--
-- Name: COLUMN agents_memory_entry_cursors."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_cursors."agentId" IS 'Agent that owns this cursor';


--
-- Name: COLUMN agents_memory_entry_cursors."observationScopeId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_cursors."observationScopeId" IS 'agents_threads.id source stream indexed into episodic memory';


--
-- Name: COLUMN agents_memory_entry_cursors."lastIndexedObservationId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_cursors."lastIndexedObservationId" IS 'Last observation-log row indexed into episodic memory';


--
-- Name: COLUMN agents_memory_entry_cursors."lastIndexedObservationCreatedAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_cursors."lastIndexedObservationCreatedAt" IS 'Creation timestamp for the last indexed observation-log row';


--
-- Name: agents_memory_entry_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_memory_entry_locks (
    "agentId" character varying(36) NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    "holderId" character varying(64) NOT NULL,
    "heldUntil" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_memory_entry_locks OWNER TO postgres;

--
-- Name: COLUMN agents_memory_entry_locks."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_locks."agentId" IS 'Agent that owns this lock';


--
-- Name: COLUMN agents_memory_entry_locks."resourceId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_locks."resourceId" IS 'agents_resources.id partition locked for episodic indexing';


--
-- Name: COLUMN agents_memory_entry_locks."holderId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_locks."holderId" IS 'Ephemeral background-task lock owner token';


--
-- Name: agents_memory_entry_sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_memory_entry_sources (
    id character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "memoryEntryId" character varying(36) NOT NULL,
    "observationId" character varying(36) NOT NULL,
    "threadId" character varying(255) NOT NULL,
    "evidenceHash" character varying(64) NOT NULL,
    "evidenceText" text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_memory_entry_sources OWNER TO postgres;

--
-- Name: COLUMN agents_memory_entry_sources."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_sources."agentId" IS 'Agent that owns the linked episodic memory entry source';


--
-- Name: COLUMN agents_memory_entry_sources."memoryEntryId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_sources."memoryEntryId" IS 'Episodic memory entry linked to this source evidence';


--
-- Name: COLUMN agents_memory_entry_sources."observationId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_sources."observationId" IS 'Observation-log row used as source evidence';


--
-- Name: COLUMN agents_memory_entry_sources."threadId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_sources."threadId" IS 'Source conversation thread that produced the linked observation';


--
-- Name: COLUMN agents_memory_entry_sources."evidenceHash"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_sources."evidenceHash" IS 'Bounded hash used to deduplicate exact evidence links';


--
-- Name: COLUMN agents_memory_entry_sources."evidenceText"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_memory_entry_sources."evidenceText" IS 'Exact source evidence text from the observation, not recall scope';


--
-- Name: agents_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_messages (
    id character varying(36) NOT NULL,
    "threadId" character varying(255) NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    role character varying(36) NOT NULL,
    type character varying(36),
    content json NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_messages OWNER TO postgres;

--
-- Name: agents_observation_cursors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_observation_cursors (
    "agentId" character varying(36) NOT NULL,
    "observationScopeId" character varying(255) NOT NULL,
    "lastObservedMessageId" character varying(36) NOT NULL,
    "lastObservedAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_observation_cursors OWNER TO postgres;

--
-- Name: COLUMN agents_observation_cursors."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_observation_cursors."agentId" IS 'Agent that owns this cursor';


--
-- Name: COLUMN agents_observation_cursors."observationScopeId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_observation_cursors."observationScopeId" IS 'agents_threads.id source stream checkpointed by this cursor';


--
-- Name: agents_observation_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_observation_locks (
    "agentId" character varying(36) NOT NULL,
    "observationScopeId" character varying(255) NOT NULL,
    "taskKind" character varying(20) NOT NULL,
    "holderId" character varying(64) NOT NULL,
    "heldUntil" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agents_observation_locks_taskKind" CHECK ((("taskKind")::text = ANY ((ARRAY['observer'::character varying, 'reflector'::character varying])::text[])))
);


ALTER TABLE public.agents_observation_locks OWNER TO postgres;

--
-- Name: COLUMN agents_observation_locks."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_observation_locks."agentId" IS 'Agent that owns this lock';


--
-- Name: COLUMN agents_observation_locks."observationScopeId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_observation_locks."observationScopeId" IS 'agents_threads.id source stream locked for observation tasks';


--
-- Name: COLUMN agents_observation_locks."holderId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_observation_locks."holderId" IS 'Ephemeral background-task lock owner token, not a user ID';


--
-- Name: agents_observations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_observations (
    id character varying(36) NOT NULL,
    "agentId" character varying(36) NOT NULL,
    "observationScopeId" character varying(255) NOT NULL,
    marker character varying(16) NOT NULL,
    text text NOT NULL,
    "parentId" character varying(36),
    "tokenCount" integer DEFAULT 0 NOT NULL,
    status character varying(16) NOT NULL,
    "supersededBy" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_agents_observations_marker" CHECK (((marker)::text = ANY ((ARRAY['critical'::character varying, 'important'::character varying, 'info'::character varying, 'completion'::character varying])::text[]))),
    CONSTRAINT "CHK_agents_observations_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'superseded'::character varying, 'dropped'::character varying])::text[])))
);


ALTER TABLE public.agents_observations OWNER TO postgres;

--
-- Name: COLUMN agents_observations.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_observations.id IS 'Application-generated n8n string ID, not a database UUID';


--
-- Name: COLUMN agents_observations."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_observations."agentId" IS 'Agent that owns this observation row';


--
-- Name: COLUMN agents_observations."observationScopeId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_observations."observationScopeId" IS 'agents_threads.id source stream for this observation log';


--
-- Name: agents_resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_resources (
    id character varying(255) NOT NULL,
    metadata text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_resources OWNER TO postgres;

--
-- Name: agents_threads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_threads (
    id character varying(128) NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    title character varying(255),
    metadata text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.agents_threads OWNER TO postgres;

--
-- Name: ai_builder_temporary_workflow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ai_builder_temporary_workflow (
    "workflowId" character varying(36) NOT NULL,
    "threadId" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.ai_builder_temporary_workflow OWNER TO postgres;

--
-- Name: annotation_tag_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.annotation_tag_entity (
    id character varying(16) NOT NULL,
    name character varying(24) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.annotation_tag_entity OWNER TO postgres;

--
-- Name: auth_identity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_identity (
    "userId" uuid,
    "providerId" character varying(255) NOT NULL,
    "providerType" character varying(32) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.auth_identity OWNER TO postgres;

--
-- Name: auth_provider_sync_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_provider_sync_history (
    id integer NOT NULL,
    "providerType" character varying(32) NOT NULL,
    "runMode" text NOT NULL,
    status text NOT NULL,
    "startedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    scanned integer NOT NULL,
    created integer NOT NULL,
    updated integer NOT NULL,
    disabled integer NOT NULL,
    error text
);


ALTER TABLE public.auth_provider_sync_history OWNER TO postgres;

--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_provider_sync_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auth_provider_sync_history_id_seq OWNER TO postgres;

--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_provider_sync_history_id_seq OWNED BY public.auth_provider_sync_history.id;


--
-- Name: binary_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.binary_data (
    "fileId" uuid NOT NULL,
    "sourceType" character varying(50) NOT NULL,
    "sourceId" character varying(255) NOT NULL,
    data bytea NOT NULL,
    "mimeType" character varying(255),
    "fileName" character varying(255),
    "fileSize" integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_binary_data_sourceType" CHECK ((("sourceType")::text = ANY ((ARRAY['execution'::character varying, 'chat_message_attachment'::character varying, 'agent_file'::character varying])::text[])))
);


ALTER TABLE public.binary_data OWNER TO postgres;

--
-- Name: COLUMN binary_data."sourceType"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.binary_data."sourceType" IS 'Source the file belongs to, e.g. ''execution''';


--
-- Name: COLUMN binary_data."sourceId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.binary_data."sourceId" IS 'ID of the source, e.g. execution ID';


--
-- Name: COLUMN binary_data.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.binary_data.data IS 'Raw, not base64 encoded';


--
-- Name: COLUMN binary_data."fileSize"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.binary_data."fileSize" IS 'In bytes';


--
-- Name: chat_hub_agent_tools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_hub_agent_tools (
    "agentId" uuid NOT NULL,
    "toolId" uuid NOT NULL
);


ALTER TABLE public.chat_hub_agent_tools OWNER TO postgres;

--
-- Name: chat_hub_agents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_hub_agents (
    id uuid NOT NULL,
    name character varying(256) NOT NULL,
    description character varying(512),
    "systemPrompt" text NOT NULL,
    "ownerId" uuid NOT NULL,
    "credentialId" character varying(36),
    provider character varying(16) NOT NULL,
    model character varying(64) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    icon json,
    files json DEFAULT '[]'::json NOT NULL,
    "suggestedPrompts" json DEFAULT '[]'::json NOT NULL
);


ALTER TABLE public.chat_hub_agents OWNER TO postgres;

--
-- Name: COLUMN chat_hub_agents.provider; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_agents.provider IS 'ChatHubProvider enum: "openai", "anthropic", "google", "n8n"';


--
-- Name: COLUMN chat_hub_agents.model; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_agents.model IS 'Model name used at the respective Model node, ie. "gpt-4"';


--
-- Name: chat_hub_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_hub_messages (
    id uuid NOT NULL,
    "sessionId" uuid NOT NULL,
    "previousMessageId" uuid,
    "revisionOfMessageId" uuid,
    "retryOfMessageId" uuid,
    type character varying(16) NOT NULL,
    name character varying(128) NOT NULL,
    content text NOT NULL,
    provider character varying(16),
    model character varying(256),
    "workflowId" character varying(36),
    "executionId" integer,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "agentId" uuid,
    status character varying(16) DEFAULT 'success'::character varying NOT NULL,
    attachments json
);


ALTER TABLE public.chat_hub_messages OWNER TO postgres;

--
-- Name: COLUMN chat_hub_messages.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_messages.type IS 'ChatHubMessageType enum: "human", "ai", "system", "tool", "generic"';


--
-- Name: COLUMN chat_hub_messages.provider; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_messages.provider IS 'ChatHubProvider enum: "openai", "anthropic", "google", "n8n"';


--
-- Name: COLUMN chat_hub_messages.model; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_messages.model IS 'Model name used at the respective Model node, ie. "gpt-4"';


--
-- Name: COLUMN chat_hub_messages."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_messages."agentId" IS 'ID of the custom agent (if provider is "custom-agent")';


--
-- Name: COLUMN chat_hub_messages.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_messages.status IS 'ChatHubMessageStatus enum, eg. "success", "error", "running", "cancelled"';


--
-- Name: COLUMN chat_hub_messages.attachments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_messages.attachments IS 'File attachments for the message (if any), stored as JSON. Files are stored as base64-encoded data URLs.';


--
-- Name: chat_hub_session_tools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_hub_session_tools (
    "sessionId" uuid NOT NULL,
    "toolId" uuid NOT NULL
);


ALTER TABLE public.chat_hub_session_tools OWNER TO postgres;

--
-- Name: chat_hub_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_hub_sessions (
    id uuid NOT NULL,
    title character varying(256) NOT NULL,
    "ownerId" uuid NOT NULL,
    "lastMessageAt" timestamp(3) with time zone NOT NULL,
    "credentialId" character varying(36),
    provider character varying(16),
    model character varying(256),
    "workflowId" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "agentId" uuid,
    "agentName" character varying(128),
    type character varying(16) DEFAULT 'production'::character varying NOT NULL,
    CONSTRAINT "CHK_chat_hub_sessions_type" CHECK (((type)::text = ANY ((ARRAY['production'::character varying, 'manual'::character varying])::text[])))
);


ALTER TABLE public.chat_hub_sessions OWNER TO postgres;

--
-- Name: COLUMN chat_hub_sessions.provider; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_sessions.provider IS 'ChatHubProvider enum: "openai", "anthropic", "google", "n8n"';


--
-- Name: COLUMN chat_hub_sessions.model; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_sessions.model IS 'Model name used at the respective Model node, ie. "gpt-4"';


--
-- Name: COLUMN chat_hub_sessions."agentId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_sessions."agentId" IS 'ID of the custom agent (if provider is "custom-agent")';


--
-- Name: COLUMN chat_hub_sessions."agentName"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chat_hub_sessions."agentName" IS 'Cached name of the custom agent (if provider is "custom-agent")';


--
-- Name: chat_hub_tools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_hub_tools (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    "typeVersion" double precision NOT NULL,
    "ownerId" uuid NOT NULL,
    definition json NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.chat_hub_tools OWNER TO postgres;

--
-- Name: credential_dependency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.credential_dependency (
    id integer NOT NULL,
    "credentialId" character varying(36) NOT NULL,
    "dependencyType" character varying(64) NOT NULL,
    "dependencyId" character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.credential_dependency OWNER TO postgres;

--
-- Name: credential_dependency_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.credential_dependency ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.credential_dependency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: credentials_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.credentials_entity (
    name character varying(128) NOT NULL,
    data text NOT NULL,
    type character varying(128) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    id character varying(36) CONSTRAINT credentials_entity_id_not_null1 NOT NULL,
    "isManaged" boolean DEFAULT false NOT NULL,
    "isGlobal" boolean DEFAULT false NOT NULL,
    "isResolvable" boolean DEFAULT false NOT NULL,
    "resolvableAllowFallback" boolean DEFAULT false NOT NULL,
    "resolverId" character varying(16)
);


ALTER TABLE public.credentials_entity OWNER TO postgres;

--
-- Name: data_table; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.data_table (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    "projectId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.data_table OWNER TO postgres;

--
-- Name: data_table_column; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.data_table_column (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    type character varying(32) NOT NULL,
    index integer NOT NULL,
    "dataTableId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.data_table_column OWNER TO postgres;

--
-- Name: COLUMN data_table_column.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.data_table_column.type IS 'Expected: string, number, boolean, or date (not enforced as a constraint)';


--
-- Name: COLUMN data_table_column.index; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.data_table_column.index IS 'Column order, starting from 0 (0 = first column)';


--
-- Name: data_table_user_VBZ0QdgF869s7cES; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."data_table_user_VBZ0QdgF869s7cES" (
    id integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public."data_table_user_VBZ0QdgF869s7cES" OWNER TO postgres;

--
-- Name: data_table_user_VBZ0QdgF869s7cES_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."data_table_user_VBZ0QdgF869s7cES" ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public."data_table_user_VBZ0QdgF869s7cES_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: deployment_key; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.deployment_key (
    id character varying(36) NOT NULL,
    type character varying(64) NOT NULL,
    value text NOT NULL,
    algorithm character varying(20),
    status character varying(20) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.deployment_key OWNER TO postgres;

--
-- Name: dynamic_credential_entry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dynamic_credential_entry (
    credential_id character varying(16) CONSTRAINT tmp_dynamic_credential_entry_credential_id_not_null NOT NULL,
    subject_id character varying(2048) CONSTRAINT tmp_dynamic_credential_entry_subject_id_not_null NOT NULL,
    resolver_id character varying(16) CONSTRAINT tmp_dynamic_credential_entry_resolver_id_not_null NOT NULL,
    data text CONSTRAINT tmp_dynamic_credential_entry_data_not_null NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) CONSTRAINT "tmp_dynamic_credential_entry_createdAt_not_null" NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) CONSTRAINT "tmp_dynamic_credential_entry_updatedAt_not_null" NOT NULL
);


ALTER TABLE public.dynamic_credential_entry OWNER TO postgres;

--
-- Name: dynamic_credential_resolver; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dynamic_credential_resolver (
    id character varying(16) NOT NULL,
    name character varying(128) NOT NULL,
    type character varying(128) NOT NULL,
    config text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.dynamic_credential_resolver OWNER TO postgres;

--
-- Name: COLUMN dynamic_credential_resolver.config; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.dynamic_credential_resolver.config IS 'Encrypted resolver configuration (JSON encrypted as string)';


--
-- Name: dynamic_credential_user_entry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dynamic_credential_user_entry (
    "credentialId" character varying(16) NOT NULL,
    "userId" uuid NOT NULL,
    "resolverId" character varying(16) NOT NULL,
    data text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.dynamic_credential_user_entry OWNER TO postgres;

--
-- Name: email_tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_tasks (
    id integer NOT NULL,
    email_message_id character varying(255),
    sender_email character varying(255),
    subject text,
    task_title text,
    task_description text,
    priority character varying(50),
    status character varying(50) DEFAULT 'OPEN'::character varying,
    due_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.email_tasks OWNER TO postgres;

--
-- Name: email_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_tasks_id_seq OWNER TO postgres;

--
-- Name: email_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_tasks_id_seq OWNED BY public.email_tasks.id;


--
-- Name: evaluation_collection; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evaluation_collection (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    description text,
    "workflowId" character varying(36) NOT NULL,
    "evaluationConfigId" character varying(36) NOT NULL,
    "createdById" uuid,
    "insightsCache" json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.evaluation_collection OWNER TO postgres;

--
-- Name: evaluation_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.evaluation_config (
    id character varying(36) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    status character varying(16) DEFAULT 'valid'::character varying NOT NULL,
    "invalidReason" character varying(64),
    "datasetSource" character varying(32) NOT NULL,
    "datasetRef" json NOT NULL,
    "startNodeName" character varying(255) NOT NULL,
    "endNodeName" character varying(255) NOT NULL,
    metrics json NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.evaluation_config OWNER TO postgres;

--
-- Name: event_destinations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_destinations (
    id uuid NOT NULL,
    destination jsonb NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.event_destinations OWNER TO postgres;

--
-- Name: execution_annotation_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.execution_annotation_tags (
    "annotationId" integer NOT NULL,
    "tagId" character varying(24) NOT NULL
);


ALTER TABLE public.execution_annotation_tags OWNER TO postgres;

--
-- Name: execution_annotations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.execution_annotations (
    id integer NOT NULL,
    "executionId" integer NOT NULL,
    vote character varying(6),
    note text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.execution_annotations OWNER TO postgres;

--
-- Name: execution_annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.execution_annotations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.execution_annotations_id_seq OWNER TO postgres;

--
-- Name: execution_annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.execution_annotations_id_seq OWNED BY public.execution_annotations.id;


--
-- Name: execution_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.execution_data (
    "executionId" integer NOT NULL,
    "workflowData" json NOT NULL,
    data text NOT NULL,
    "workflowVersionId" character varying(36)
);


ALTER TABLE public.execution_data OWNER TO postgres;

--
-- Name: execution_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.execution_entity (
    id integer NOT NULL,
    finished boolean NOT NULL,
    mode character varying NOT NULL,
    "retryOf" character varying,
    "retrySuccessId" character varying,
    "startedAt" timestamp(3) with time zone,
    "stoppedAt" timestamp(3) with time zone,
    "waitTill" timestamp(3) with time zone,
    status character varying NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "deletedAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "storedAt" character varying(2) DEFAULT 'db'::character varying NOT NULL,
    "tracingContext" json,
    "deduplicationKey" character varying(255),
    "jsonSizeBytes" bigint DEFAULT 0 NOT NULL,
    "workflowVersionId" character varying(36) DEFAULT NULL::character varying,
    "binaryDataSizeBytes" bigint DEFAULT 0 NOT NULL,
    "usedPrivateCredentials" boolean DEFAULT false NOT NULL,
    CONSTRAINT "CHK_execution_entity_storedAt" CHECK ((("storedAt")::text = ANY ((ARRAY['db'::character varying, 'fs'::character varying, 's3'::character varying, 'az'::character varying])::text[])))
);


ALTER TABLE public.execution_entity OWNER TO postgres;

--
-- Name: COLUMN execution_entity."jsonSizeBytes"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.execution_entity."jsonSizeBytes" IS 'Byte size of the JSON execution data bundle (run data, workflow snapshot, version id); excludes binary data. 0 means unknown.';


--
-- Name: COLUMN execution_entity."workflowVersionId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.execution_entity."workflowVersionId" IS 'Version id of the workflow run by this execution; denormalized from the data bundle.';


--
-- Name: COLUMN execution_entity."binaryDataSizeBytes"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.execution_entity."binaryDataSizeBytes" IS 'Byte size of binary data offloaded to separate storage (db/fs/S3), deduplicated by blob; excludes inline binary counted in jsonSizeBytes. 0 means unknown.';


--
-- Name: COLUMN execution_entity."usedPrivateCredentials"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.execution_entity."usedPrivateCredentials" IS 'Whether this execution ran with at least one dynamically-resolved private credential.';


--
-- Name: execution_entity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.execution_entity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.execution_entity_id_seq OWNER TO postgres;

--
-- Name: execution_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.execution_entity_id_seq OWNED BY public.execution_entity.id;


--
-- Name: execution_metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.execution_metadata (
    id integer CONSTRAINT execution_metadata_temp_id_not_null NOT NULL,
    "executionId" integer CONSTRAINT "execution_metadata_temp_executionId_not_null" NOT NULL,
    key character varying(255) CONSTRAINT execution_metadata_temp_key_not_null NOT NULL,
    value text CONSTRAINT execution_metadata_temp_value_not_null NOT NULL
);


ALTER TABLE public.execution_metadata OWNER TO postgres;

--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.execution_metadata_temp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.execution_metadata_temp_id_seq OWNER TO postgres;

--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.execution_metadata_temp_id_seq OWNED BY public.execution_metadata.id;


--
-- Name: folder; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder (
    id character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    "parentFolderId" character varying(36),
    "projectId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.folder OWNER TO postgres;

--
-- Name: folder_tag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folder_tag (
    "folderId" character varying(36) NOT NULL,
    "tagId" character varying(36) NOT NULL
);


ALTER TABLE public.folder_tag OWNER TO postgres;

--
-- Name: insights_by_period; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insights_by_period (
    id integer NOT NULL,
    "metaId" integer NOT NULL,
    type integer NOT NULL,
    value bigint NOT NULL,
    "periodUnit" integer NOT NULL,
    "periodStart" timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.insights_by_period OWNER TO postgres;

--
-- Name: COLUMN insights_by_period.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.insights_by_period.type IS '0: time_saved_minutes, 1: runtime_milliseconds, 2: success, 3: failure';


--
-- Name: COLUMN insights_by_period."periodUnit"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.insights_by_period."periodUnit" IS '0: hour, 1: day, 2: week';


--
-- Name: insights_by_period_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.insights_by_period ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.insights_by_period_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: insights_metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insights_metadata (
    "metaId" integer NOT NULL,
    "workflowId" character varying(36),
    "projectId" character varying(36),
    "workflowName" character varying(128) NOT NULL,
    "projectName" character varying(255) NOT NULL
);


ALTER TABLE public.insights_metadata OWNER TO postgres;

--
-- Name: insights_metadata_metaId_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.insights_metadata ALTER COLUMN "metaId" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public."insights_metadata_metaId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: insights_raw; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insights_raw (
    id integer NOT NULL,
    "metaId" integer NOT NULL,
    type integer NOT NULL,
    value bigint NOT NULL,
    "timestamp" timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.insights_raw OWNER TO postgres;

--
-- Name: COLUMN insights_raw.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.insights_raw.type IS '0: time_saved_minutes, 1: runtime_milliseconds, 2: success, 3: failure';


--
-- Name: insights_raw_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.insights_raw ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.insights_raw_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: installed_nodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.installed_nodes (
    name character varying(200) NOT NULL,
    type character varying(200) NOT NULL,
    "latestVersion" integer DEFAULT 1 NOT NULL,
    package character varying(241) NOT NULL
);


ALTER TABLE public.installed_nodes OWNER TO postgres;

--
-- Name: installed_packages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.installed_packages (
    "packageName" character varying(214) NOT NULL,
    "installedVersion" character varying(50) NOT NULL,
    "authorName" character varying(70),
    "authorEmail" character varying(70),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.installed_packages OWNER TO postgres;

--
-- Name: instance_ai_checkpoints; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_checkpoints (
    key character varying(255) NOT NULL,
    "runId" character varying(255),
    "threadId" uuid NOT NULL,
    "resourceId" character varying(255),
    state json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "expiredAt" timestamp(3) with time zone,
    "hostRunId" character varying(64),
    CONSTRAINT instance_ai_checkpoints_state_tombstone_check CHECK (((("expiredAt" IS NOT NULL) AND (state IS NULL)) OR ("expiredAt" IS NULL)))
);


ALTER TABLE public.instance_ai_checkpoints OWNER TO postgres;

--
-- Name: COLUMN instance_ai_checkpoints.key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_checkpoints.key IS 'Opaque checkpoint key from the agent runtime.';


--
-- Name: COLUMN instance_ai_checkpoints."runId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_checkpoints."runId" IS 'Run ID parsed from the checkpoint key when available.';


--
-- Name: COLUMN instance_ai_checkpoints."threadId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_checkpoints."threadId" IS 'Instance AI thread that owns the checkpoint.';


--
-- Name: COLUMN instance_ai_checkpoints."resourceId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_checkpoints."resourceId" IS 'Resource ID recorded by the agent runtime.';


--
-- Name: COLUMN instance_ai_checkpoints.state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_checkpoints.state IS 'Serializable agent state snapshot stored as JSON.';


--
-- Name: COLUMN instance_ai_checkpoints."expiredAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_checkpoints."expiredAt" IS 'Soft-delete timestamp: null means live; non-null marks the row as a tombstone.';


--
-- Name: COLUMN instance_ai_checkpoints."hostRunId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_checkpoints."hostRunId" IS 'Host (Instance AI) run id; distinct from the agent-SDK runId parsed from the checkpoint key.';


--
-- Name: instance_ai_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_events (
    "threadId" uuid NOT NULL,
    seq integer NOT NULL,
    "runId" character varying(64) NOT NULL,
    type character varying(64) NOT NULL,
    payload text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_events OWNER TO postgres;

--
-- Name: COLUMN instance_ai_events.seq; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_events.seq IS 'Per-thread monotonic sequence — the SSE replay cursor';


--
-- Name: COLUMN instance_ai_events."runId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_events."runId" IS 'Run that emitted the event — opaque ID from the agent runtime';


--
-- Name: COLUMN instance_ai_events.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_events.type IS 'Event type discriminator, duplicated out of the payload';


--
-- Name: COLUMN instance_ai_events.payload; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_events.payload IS 'JSON of the canonical InstanceAiEvent';


--
-- Name: instance_ai_iteration_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_iteration_logs (
    id character varying(36) NOT NULL,
    "threadId" uuid NOT NULL,
    "taskKey" character varying NOT NULL,
    entry text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_iteration_logs OWNER TO postgres;

--
-- Name: instance_ai_mcp_registry_connections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_mcp_registry_connections (
    id uuid NOT NULL,
    "credentialId" character varying(36) NOT NULL,
    "serverSlug" character varying(255) NOT NULL,
    "toolFilter" json,
    "userId" uuid NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_mcp_registry_connections OWNER TO postgres;

--
-- Name: COLUMN instance_ai_mcp_registry_connections."toolFilter"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_mcp_registry_connections."toolFilter" IS 'Optional MCP tool filter per registry connection: { mode: "allow" | "exclude", tools: string[] }';


--
-- Name: instance_ai_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_messages (
    id character varying(36) NOT NULL,
    "threadId" uuid NOT NULL,
    content text NOT NULL,
    role character varying(16) NOT NULL,
    type character varying(32),
    "resourceId" character varying(255),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_messages OWNER TO postgres;

--
-- Name: instance_ai_observation_cursors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_observation_cursors (
    "observationScopeId" uuid NOT NULL,
    "lastObservedMessageId" character varying(36) NOT NULL,
    "lastObservedAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_observation_cursors OWNER TO postgres;

--
-- Name: COLUMN instance_ai_observation_cursors."observationScopeId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_observation_cursors."observationScopeId" IS 'instance_ai_threads.id source stream checkpointed by this cursor';


--
-- Name: instance_ai_observation_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_observation_locks (
    "observationScopeId" uuid NOT NULL,
    "taskKind" character varying(20) NOT NULL,
    "holderId" character varying(64) NOT NULL,
    "heldUntil" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_instance_ai_observation_locks_taskKind" CHECK ((("taskKind")::text = ANY ((ARRAY['observer'::character varying, 'reflector'::character varying])::text[])))
);


ALTER TABLE public.instance_ai_observation_locks OWNER TO postgres;

--
-- Name: COLUMN instance_ai_observation_locks."observationScopeId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_observation_locks."observationScopeId" IS 'instance_ai_threads.id source stream locked for observation tasks';


--
-- Name: COLUMN instance_ai_observation_locks."holderId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_observation_locks."holderId" IS 'Ephemeral background-task lock owner token, not a user ID';


--
-- Name: instance_ai_observational_memory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_observational_memory (
    id character varying(36) NOT NULL,
    "lookupKey" character varying(255) NOT NULL,
    scope character varying(16) NOT NULL,
    "threadId" uuid,
    "resourceId" character varying(255) NOT NULL,
    "activeObservations" text DEFAULT ''::text NOT NULL,
    "originType" character varying(32) NOT NULL,
    config text NOT NULL,
    "generationCount" integer DEFAULT 0 NOT NULL,
    "lastObservedAt" timestamp(3) with time zone,
    "pendingMessageTokens" integer DEFAULT 0 NOT NULL,
    "totalTokensObserved" integer DEFAULT 0 NOT NULL,
    "observationTokenCount" integer DEFAULT 0 NOT NULL,
    "isObserving" boolean DEFAULT false NOT NULL,
    "isReflecting" boolean DEFAULT false NOT NULL,
    "observedMessageIds" json,
    "observedTimezone" character varying,
    "bufferedObservations" text,
    "bufferedObservationTokens" integer,
    "bufferedMessageIds" json,
    "bufferedReflection" text,
    "bufferedReflectionTokens" integer,
    "bufferedReflectionInputTokens" integer,
    "reflectedObservationLineCount" integer,
    "bufferedObservationChunks" json,
    "isBufferingObservation" boolean DEFAULT false CONSTRAINT "instance_ai_observational_memor_isBufferingObservation_not_null" NOT NULL,
    "isBufferingReflection" boolean DEFAULT false NOT NULL,
    "lastBufferedAtTokens" integer DEFAULT 0 NOT NULL,
    "lastBufferedAtTime" timestamp(3) with time zone,
    metadata json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_observational_memory OWNER TO postgres;

--
-- Name: instance_ai_observations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_observations (
    id character varying(36) NOT NULL,
    "observationScopeId" uuid NOT NULL,
    marker character varying(16) NOT NULL,
    text text NOT NULL,
    "parentId" character varying(36),
    "tokenCount" integer DEFAULT 0 NOT NULL,
    status character varying(16) NOT NULL,
    "supersededBy" character varying(36),
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_instance_ai_observations_marker" CHECK (((marker)::text = ANY ((ARRAY['critical'::character varying, 'important'::character varying, 'info'::character varying, 'completion'::character varying])::text[]))),
    CONSTRAINT "CHK_instance_ai_observations_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'superseded'::character varying, 'dropped'::character varying])::text[])))
);


ALTER TABLE public.instance_ai_observations OWNER TO postgres;

--
-- Name: COLUMN instance_ai_observations.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_observations.id IS 'Application-generated n8n string ID, not a database UUID';


--
-- Name: COLUMN instance_ai_observations."observationScopeId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_observations."observationScopeId" IS 'instance_ai_threads.id source stream for this observation log';


--
-- Name: instance_ai_pending_confirmations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_pending_confirmations (
    "requestId" character varying(36) NOT NULL,
    "threadId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    kind character varying(16) NOT NULL,
    "runId" character varying(36) NOT NULL,
    "toolCallId" character varying(64),
    "messageGroupId" character varying(36),
    "checkpointKey" character varying(255),
    "checkpointTaskId" character varying(36),
    "expiresAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_instance_ai_pending_confirmations_kind" CHECK (((kind)::text = ANY ((ARRAY['suspended'::character varying, 'inline'::character varying])::text[])))
);


ALTER TABLE public.instance_ai_pending_confirmations OWNER TO postgres;

--
-- Name: COLUMN instance_ai_pending_confirmations."requestId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."requestId" IS 'HITL confirmation request identifier.';


--
-- Name: COLUMN instance_ai_pending_confirmations."threadId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."threadId" IS 'Instance AI thread that owns the confirmation.';


--
-- Name: COLUMN instance_ai_pending_confirmations."userId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."userId" IS 'User who is expected to confirm or cancel.';


--
-- Name: COLUMN instance_ai_pending_confirmations.kind; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations.kind IS '''suspended'' (resumable from checkpoint) or ''inline'' (orchestrator-held Promise).';


--
-- Name: COLUMN instance_ai_pending_confirmations."runId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."runId" IS 'External run ID; reused on resume for SSE correlation.';


--
-- Name: COLUMN instance_ai_pending_confirmations."toolCallId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."toolCallId" IS 'Suspended tool call awaiting confirmation.';


--
-- Name: COLUMN instance_ai_pending_confirmations."messageGroupId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."messageGroupId" IS 'SSE event correlation group.';


--
-- Name: COLUMN instance_ai_pending_confirmations."checkpointKey"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."checkpointKey" IS 'FK to instance_ai_checkpoints.key; also the SDK runId used to resume.';


--
-- Name: COLUMN instance_ai_pending_confirmations."checkpointTaskId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."checkpointTaskId" IS 'Set when the suspended run was a planned-task checkpoint follow-up.';


--
-- Name: COLUMN instance_ai_pending_confirmations."expiresAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_pending_confirmations."expiresAt" IS 'TTL for the leader-only sweep; null disables auto-expiry.';


--
-- Name: instance_ai_resources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_resources (
    id character varying(255) NOT NULL,
    "workingMemory" text,
    metadata json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_resources OWNER TO postgres;

--
-- Name: instance_ai_run_snapshots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_run_snapshots (
    "threadId" uuid NOT NULL,
    "runId" character varying(36) NOT NULL,
    "messageGroupId" character varying(36),
    "runIds" json,
    tree text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "langsmithRunId" character varying(36),
    "langsmithTraceId" character varying(36),
    "traceId" character varying(64),
    "spanId" character varying(64)
);


ALTER TABLE public.instance_ai_run_snapshots OWNER TO postgres;

--
-- Name: COLUMN instance_ai_run_snapshots."langsmithRunId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_run_snapshots."langsmithRunId" IS 'LangSmith run ID (UUID v4, e.g. "f47ac10b-58cc-4372-a567-0e02b2c3d479").';


--
-- Name: COLUMN instance_ai_run_snapshots."langsmithTraceId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_run_snapshots."langsmithTraceId" IS 'LangSmith trace ID (UUID v4, e.g. "f47ac10b-58cc-4372-a567-0e02b2c3d479").';


--
-- Name: COLUMN instance_ai_run_snapshots."traceId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_run_snapshots."traceId" IS 'OpenTelemetry trace ID for the root Instance AI run.';


--
-- Name: COLUMN instance_ai_run_snapshots."spanId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_run_snapshots."spanId" IS 'OpenTelemetry span ID for the root Instance AI run.';


--
-- Name: instance_ai_thread_grants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_thread_grants (
    "threadId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "grantKey" character varying(512) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_thread_grants OWNER TO postgres;

--
-- Name: COLUMN instance_ai_thread_grants."grantKey"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_thread_grants."grantKey" IS 'Namespaced "always allow" grant the user approved for the thread, e.g. "executions:run:<workflowId>". Wide enough to hold a namespace prefix plus a resource identifier.';


--
-- Name: instance_ai_threads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_threads (
    id uuid NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    title text DEFAULT ''::text NOT NULL,
    metadata json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "projectId" character varying(36) NOT NULL
);


ALTER TABLE public.instance_ai_threads OWNER TO postgres;

--
-- Name: COLUMN instance_ai_threads."projectId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instance_ai_threads."projectId" IS 'Project this thread is scoped to';


--
-- Name: instance_ai_workflow_snapshots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_ai_workflow_snapshots (
    "runId" character varying(36) NOT NULL,
    "workflowName" character varying(255) NOT NULL,
    "resourceId" character varying(255),
    status character varying,
    snapshot text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_ai_workflow_snapshots OWNER TO postgres;

--
-- Name: instance_version_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instance_version_history (
    id integer NOT NULL,
    major integer NOT NULL,
    minor integer NOT NULL,
    patch integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.instance_version_history OWNER TO postgres;

--
-- Name: instance_version_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.instance_version_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.instance_version_history_id_seq OWNER TO postgres;

--
-- Name: instance_version_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.instance_version_history_id_seq OWNED BY public.instance_version_history.id;


--
-- Name: invalid_auth_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invalid_auth_token (
    token character varying(512) NOT NULL,
    "expiresAt" timestamp(3) with time zone NOT NULL
);


ALTER TABLE public.invalid_auth_token OWNER TO postgres;

--
-- Name: items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items (
    id bigint NOT NULL,
    code integer,
    name text
);


ALTER TABLE public.items OWNER TO postgres;

--
-- Name: items2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items2 (
    id bigint NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.items2 OWNER TO postgres;

--
-- Name: items2_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.items2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.items2_id_seq OWNER TO postgres;

--
-- Name: items2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.items2_id_seq OWNED BY public.items2.id;


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.items_id_seq OWNER TO postgres;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: mcp_registry_server; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mcp_registry_server (
    slug character varying(255) CONSTRAINT tmp_mcp_registry_server_slug_not_null NOT NULL,
    status character varying(50) CONSTRAINT tmp_mcp_registry_server_status_not_null NOT NULL,
    version character varying(50) CONSTRAINT tmp_mcp_registry_server_version_not_null NOT NULL,
    "registryUpdatedAt" timestamp(3) without time zone CONSTRAINT "tmp_mcp_registry_server_registryUpdatedAt_not_null" NOT NULL,
    data json DEFAULT '{}'::json CONSTRAINT tmp_mcp_registry_server_data_not_null NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) CONSTRAINT "tmp_mcp_registry_server_createdAt_not_null" NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) CONSTRAINT "tmp_mcp_registry_server_updatedAt_not_null" NOT NULL,
    CONSTRAINT "CHK_tmp_mcp_registry_server_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'deprecated'::character varying])::text[])))
);


ALTER TABLE public.mcp_registry_server OWNER TO postgres;

--
-- Name: COLUMN mcp_registry_server.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mcp_registry_server.status IS 'Server status in the MCP registry. Deprecated servers are not surfaced to users.';


--
-- Name: COLUMN mcp_registry_server.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mcp_registry_server.data IS 'JSON object containing server metadata (icons, remotes, tools, etc.)';


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    "timestamp" bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.migrations OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_access_tokens (
    token character varying NOT NULL,
    "clientId" character varying NOT NULL,
    "userId" uuid NOT NULL
);


ALTER TABLE public.oauth_access_tokens OWNER TO postgres;

--
-- Name: oauth_authorization_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_authorization_codes (
    code character varying(255) NOT NULL,
    "clientId" character varying NOT NULL,
    "userId" uuid NOT NULL,
    "redirectUri" character varying NOT NULL,
    "codeChallenge" character varying NOT NULL,
    "codeChallengeMethod" character varying(255) NOT NULL,
    "expiresAt" bigint NOT NULL,
    state character varying,
    used boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    resource character varying,
    scope json DEFAULT '["tool:listWorkflows","tool:getWorkflowDetails"]'::json NOT NULL
);


ALTER TABLE public.oauth_authorization_codes OWNER TO postgres;

--
-- Name: COLUMN oauth_authorization_codes."expiresAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oauth_authorization_codes."expiresAt" IS 'Unix timestamp in milliseconds';


--
-- Name: COLUMN oauth_authorization_codes.resource; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oauth_authorization_codes.resource IS 'RFC 8707 resource indicator URI (e.g. https://n8n.example.com/mcp-server/http). NULL = legacy flow predating resource indicator support; defaults to the instance canonical MCP resource URL.';


--
-- Name: COLUMN oauth_authorization_codes.scope; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oauth_authorization_codes.scope IS 'OAuth scopes granted for this authorization code';


--
-- Name: oauth_clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_clients (
    id character varying NOT NULL,
    name character varying(255) NOT NULL,
    "redirectUris" json NOT NULL,
    "grantTypes" json NOT NULL,
    "clientSecret" character varying(255),
    "clientSecretExpiresAt" bigint,
    "tokenEndpointAuthMethod" character varying(255) DEFAULT 'none'::character varying NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.oauth_clients OWNER TO postgres;

--
-- Name: COLUMN oauth_clients."tokenEndpointAuthMethod"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oauth_clients."tokenEndpointAuthMethod" IS 'Possible values: none, client_secret_basic or client_secret_post';


--
-- Name: oauth_refresh_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_refresh_tokens (
    token character varying(255) NOT NULL,
    "clientId" character varying NOT NULL,
    "userId" uuid NOT NULL,
    "expiresAt" bigint NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    scope json DEFAULT '["tool:listWorkflows","tool:getWorkflowDetails"]'::json NOT NULL
);


ALTER TABLE public.oauth_refresh_tokens OWNER TO postgres;

--
-- Name: COLUMN oauth_refresh_tokens."expiresAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oauth_refresh_tokens."expiresAt" IS 'Unix timestamp in milliseconds';


--
-- Name: COLUMN oauth_refresh_tokens.scope; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oauth_refresh_tokens.scope IS 'OAuth scopes granted for this refresh token';


--
-- Name: oauth_user_consents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oauth_user_consents (
    id integer NOT NULL,
    "userId" uuid NOT NULL,
    "clientId" character varying NOT NULL,
    "grantedAt" bigint NOT NULL,
    scope json NOT NULL
);


ALTER TABLE public.oauth_user_consents OWNER TO postgres;

--
-- Name: COLUMN oauth_user_consents."grantedAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oauth_user_consents."grantedAt" IS 'Unix timestamp in milliseconds';


--
-- Name: COLUMN oauth_user_consents.scope; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oauth_user_consents.scope IS 'OAuth scopes granted on the consent screen';


--
-- Name: oauth_user_consents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.oauth_user_consents ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.oauth_user_consents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: processed_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.processed_data (
    "workflowId" character varying(36) NOT NULL,
    context character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.processed_data OWNER TO postgres;

--
-- Name: project; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    icon json,
    description character varying(512),
    "creatorId" uuid,
    "customTelemetryTags" json DEFAULT '[]'::json NOT NULL
);


ALTER TABLE public.project OWNER TO postgres;

--
-- Name: COLUMN project."creatorId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.project."creatorId" IS 'ID of the user who created the project';


--
-- Name: project_relation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_relation (
    "projectId" character varying(36) NOT NULL,
    "userId" uuid NOT NULL,
    role character varying NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.project_relation OWNER TO postgres;

--
-- Name: project_secrets_provider_access; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_secrets_provider_access (
    "secretsProviderConnectionId" integer CONSTRAINT "project_secrets_provider_ac_secretsProviderConnectionI_not_null" NOT NULL,
    "projectId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    role character varying(128) DEFAULT 'secretsProviderConnection:user'::character varying NOT NULL,
    CONSTRAINT "CHK_project_secrets_provider_access_role" CHECK (((role)::text = ANY ((ARRAY['secretsProviderConnection:owner'::character varying, 'secretsProviderConnection:user'::character varying])::text[])))
);


ALTER TABLE public.project_secrets_provider_access OWNER TO postgres;

--
-- Name: role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role (
    slug character varying(128) NOT NULL,
    "displayName" text,
    description text,
    "roleType" text,
    "systemRole" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.role OWNER TO postgres;

--
-- Name: COLUMN role.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.role.slug IS 'Unique identifier of the role for example: "global:owner"';


--
-- Name: COLUMN role."displayName"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.role."displayName" IS 'Name used to display in the UI';


--
-- Name: COLUMN role.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.role.description IS 'Text describing the scope in more detail of users';


--
-- Name: COLUMN role."roleType"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.role."roleType" IS 'Type of the role, e.g., global, project, or workflow';


--
-- Name: COLUMN role."systemRole"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.role."systemRole" IS 'Indicates if the role is managed by the system and cannot be edited';


--
-- Name: role_mapping_rule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_mapping_rule (
    id character varying(16) NOT NULL,
    expression text NOT NULL,
    role character varying(128) NOT NULL,
    type character varying(64) NOT NULL,
    "order" integer NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.role_mapping_rule OWNER TO postgres;

--
-- Name: COLUMN role_mapping_rule.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.role_mapping_rule.type IS 'Expected values: ''instance'' (maps to a global role) or ''project'' (maps to a project role; projects linked via role_mapping_rule_project).';


--
-- Name: role_mapping_rule_project; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_mapping_rule_project (
    "roleMappingRuleId" character varying(16) NOT NULL,
    "projectId" character varying(36) NOT NULL
);


ALTER TABLE public.role_mapping_rule_project OWNER TO postgres;

--
-- Name: role_scope; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_scope (
    "roleSlug" character varying(128) NOT NULL,
    "scopeSlug" character varying(128) NOT NULL
);


ALTER TABLE public.role_scope OWNER TO postgres;

--
-- Name: scheduled_job; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduled_job (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "workflowId" character varying(36),
    "nodeId" character varying(36),
    "taskType" character varying(128) NOT NULL,
    payload json DEFAULT '{}'::json NOT NULL,
    kind character varying(16) NOT NULL,
    "cronExpression" character varying(255),
    timezone character varying(64),
    "intervalSeconds" integer,
    "fireAt" timestamp(3) with time zone,
    enabled boolean DEFAULT true NOT NULL,
    "nextRunAt" timestamp(3) with time zone,
    "lastFiredAt" timestamp(3) with time zone,
    "maxAttempts" integer DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "recurrenceUnit" character varying(16),
    "recurrenceSize" integer,
    CONSTRAINT "CHK_scheduled_job_cron_expression" CHECK ((((kind)::text <> 'cron'::text) OR ("cronExpression" IS NOT NULL))),
    CONSTRAINT "CHK_scheduled_job_fire_at" CHECK ((((kind)::text <> 'one_off'::text) OR ("fireAt" IS NOT NULL))),
    CONSTRAINT "CHK_scheduled_job_interval_seconds" CHECK ((((kind)::text <> 'interval'::text) OR ("intervalSeconds" IS NOT NULL))),
    CONSTRAINT "CHK_scheduled_job_kind" CHECK (((kind)::text = ANY ((ARRAY['cron'::character varying, 'interval'::character varying, 'one_off'::character varying, 'recurring_cron'::character varying])::text[]))),
    CONSTRAINT "CHK_scheduled_job_recurrence_size" CHECK (("recurrenceSize" >= 2)),
    CONSTRAINT "CHK_scheduled_job_recurrence_unit" CHECK ((("recurrenceUnit")::text = ANY ((ARRAY['hours'::character varying, 'days'::character varying, 'weeks'::character varying, 'months'::character varying])::text[]))),
    CONSTRAINT "CHK_scheduled_job_recurring_cron" CHECK ((((kind)::text <> 'recurring_cron'::text) OR (("cronExpression" IS NOT NULL) AND ("recurrenceUnit" IS NOT NULL) AND ("recurrenceSize" IS NOT NULL))))
);


ALTER TABLE public.scheduled_job OWNER TO postgres;

--
-- Name: COLUMN scheduled_job.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job.name IS 'Human-readable job name. A well-known scheduler key for system jobs; generated for workflow trigger jobs.';


--
-- Name: COLUMN scheduled_job."workflowId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."workflowId" IS 'References the workflow''s published version, since only published trigger nodes get scheduled; NULL for system jobs not tied to a workflow. Unpublishing the workflow deletes its jobs.';


--
-- Name: COLUMN scheduled_job."nodeId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."nodeId" IS 'Trigger node within the workflow that owns this job; NULL for non-trigger jobs.';


--
-- Name: COLUMN scheduled_job."taskType"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."taskType" IS 'Selects which registered handler runs the task.';


--
-- Name: COLUMN scheduled_job.payload; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job.payload IS 'Input passed to the task handler when an occurrence runs.';


--
-- Name: COLUMN scheduled_job.kind; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job.kind IS 'Recurrence kind; selects which of the schedule columns below apply.';


--
-- Name: COLUMN scheduled_job."cronExpression"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."cronExpression" IS 'Cron expression. For kind ''cron'' it is the schedule; for ''recurring_cron'' it lists the candidate run times that the every-N-periods filter then keeps every Nth of.';


--
-- Name: COLUMN scheduled_job.timezone; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job.timezone IS 'IANA timezone the cron expression is evaluated in; NULL uses the instance default.';


--
-- Name: COLUMN scheduled_job."intervalSeconds"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."intervalSeconds" IS 'Gap between fires in seconds; set only when kind is ''interval''.';


--
-- Name: COLUMN scheduled_job."fireAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."fireAt" IS 'Absolute time the job fires once; set only when kind is ''one_off''.';


--
-- Name: COLUMN scheduled_job.enabled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job.enabled IS 'Whether the scheduler considers this job for firing.';


--
-- Name: COLUMN scheduled_job."nextRunAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."nextRunAt" IS 'Next time an occurrence is due; the scheduler sweep reads this to find work. NULL once disabled or a one-off has fired.';


--
-- Name: COLUMN scheduled_job."lastFiredAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."lastFiredAt" IS 'Last time an occurrence was materialized; used to recompute nextRunAt.';


--
-- Name: COLUMN scheduled_job."maxAttempts"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."maxAttempts" IS 'Retry ceiling copied onto each occurrence this job materializes.';


--
-- Name: COLUMN scheduled_job."recurrenceUnit"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."recurrenceUnit" IS 'Calendar period counted by a recurring_cron schedule''s every-N-periods filter (hours, days, weeks, months). Set only when kind is ''recurring_cron''.';


--
-- Name: COLUMN scheduled_job."recurrenceSize"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_job."recurrenceSize" IS 'The N in a recurring_cron schedule''s every-N-periods filter, e.g. 3 for every 3 weeks; at least 2. Set only when kind is ''recurring_cron''.';


--
-- Name: scheduled_job_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.scheduled_job ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.scheduled_job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: scheduled_task; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduled_task (
    id bigint NOT NULL,
    "jobId" integer NOT NULL,
    "taskType" character varying(128) NOT NULL,
    payload json DEFAULT '{}'::json NOT NULL,
    "scheduledFor" timestamp(3) with time zone NOT NULL,
    "runAt" timestamp(3) with time zone NOT NULL,
    status character varying(16) DEFAULT 'pending'::character varying NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    "maxAttempts" integer DEFAULT 1 NOT NULL,
    "claimedBy" character varying(255),
    "leaseExpiresAt" timestamp(3) with time zone,
    "leaseEpoch" integer DEFAULT 0 NOT NULL,
    "startedAt" timestamp(3) with time zone,
    "finishedAt" timestamp(3) with time zone,
    "errorMessage" text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "dispatchedAt" timestamp(3) with time zone,
    CONSTRAINT "CHK_scheduled_task_running_lease" CHECK ((((status)::text <> 'running'::text) OR ("leaseExpiresAt" IS NOT NULL))),
    CONSTRAINT "CHK_scheduled_task_status" CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'running'::character varying, 'succeeded'::character varying, 'failed'::character varying, 'missed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.scheduled_task OWNER TO postgres;

--
-- Name: COLUMN scheduled_task."jobId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."jobId" IS 'The scheduled_job this occurrence belongs to.';


--
-- Name: COLUMN scheduled_task."taskType"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."taskType" IS 'What kind of work to run, copied from the job so a run is self-contained (no join to execute it). Also lets a run exist without a parent job in future.';


--
-- Name: COLUMN scheduled_task.payload; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task.payload IS 'Handler input copied from the job. A snapshot, so editing the job later doesn''t change runs already queued.';


--
-- Name: COLUMN scheduled_task."scheduledFor"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."scheduledFor" IS 'The logical fire time this occurrence represents; unique per job, so the same instant cannot be queued twice.';


--
-- Name: COLUMN scheduled_task."runAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."runAt" IS 'Earliest time the executor may pick this up; starts at scheduledFor and is pushed out by retry backoff.';


--
-- Name: COLUMN scheduled_task.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task.status IS 'Lifecycle state; drives which occurrences the claim and reaper scans consider.';


--
-- Name: COLUMN scheduled_task.attempts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task.attempts IS 'Execution attempts started so far; compared against maxAttempts.';


--
-- Name: COLUMN scheduled_task."maxAttempts"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."maxAttempts" IS 'Attempt ceiling; once attempts reaches it, a failure is final rather than retried.';


--
-- Name: COLUMN scheduled_task."claimedBy"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."claimedBy" IS 'Id of the instance currently holding the lease; NULL when unclaimed.';


--
-- Name: COLUMN scheduled_task."leaseExpiresAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."leaseExpiresAt" IS 'When the current lease expires; the reaper reclaims running occurrences past this.';


--
-- Name: COLUMN scheduled_task."leaseEpoch"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."leaseEpoch" IS 'Fencing token bumped on each claim; lets a reaped worker detect it lost ownership and not overwrite the new owner''s results.';


--
-- Name: COLUMN scheduled_task."startedAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."startedAt" IS 'When the current attempt started running.';


--
-- Name: COLUMN scheduled_task."finishedAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."finishedAt" IS 'When the occurrence reached a terminal state; drives retention pruning.';


--
-- Name: COLUMN scheduled_task."errorMessage"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."errorMessage" IS 'Failure detail from the last attempt.';


--
-- Name: COLUMN scheduled_task."dispatchedAt"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scheduled_task."dispatchedAt" IS 'When the current attempt handed off its effect; NULL until then. Splits dispatch-attempted (startedAt) from effect-happened, so the reaper completes a dispatched occurrence rather than redelivering it.';


--
-- Name: scheduled_task_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.scheduled_task ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.scheduled_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: scope; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scope (
    slug character varying(128) NOT NULL,
    "displayName" text,
    description text
);


ALTER TABLE public.scope OWNER TO postgres;

--
-- Name: COLUMN scope.slug; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scope.slug IS 'Unique identifier of the scope for example: "project:create"';


--
-- Name: COLUMN scope."displayName"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scope."displayName" IS 'Name used to display in the UI';


--
-- Name: COLUMN scope.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.scope.description IS 'Text describing the scope in more detail of users';


--
-- Name: secrets_provider_connection; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.secrets_provider_connection (
    id integer NOT NULL,
    "providerKey" character varying(128) NOT NULL,
    type character varying(36) NOT NULL,
    "encryptedSettings" text NOT NULL,
    "isEnabled" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.secrets_provider_connection OWNER TO postgres;

--
-- Name: COLUMN secrets_provider_connection.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.secrets_provider_connection.type IS 'Type of secrets provider. Possible values: awsSecretsManager, gcpSecretsManager, vault, azureKeyVault, infisical';


--
-- Name: secrets_provider_connection_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.secrets_provider_connection ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.secrets_provider_connection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settings (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    "loadOnStartup" boolean DEFAULT false NOT NULL
);


ALTER TABLE public.settings OWNER TO postgres;

--
-- Name: shared_credentials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shared_credentials (
    "credentialsId" character varying(36) CONSTRAINT "shared_credentials_2_credentialsId_not_null" NOT NULL,
    "projectId" character varying(36) CONSTRAINT "shared_credentials_2_projectId_not_null" NOT NULL,
    role text CONSTRAINT shared_credentials_2_role_not_null NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) CONSTRAINT "shared_credentials_2_createdAt_not_null" NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) CONSTRAINT "shared_credentials_2_updatedAt_not_null" NOT NULL
);


ALTER TABLE public.shared_credentials OWNER TO postgres;

--
-- Name: shared_workflow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shared_workflow (
    "workflowId" character varying(36) CONSTRAINT "shared_workflow_2_workflowId_not_null" NOT NULL,
    "projectId" character varying(36) CONSTRAINT "shared_workflow_2_projectId_not_null" NOT NULL,
    role text CONSTRAINT shared_workflow_2_role_not_null NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) CONSTRAINT "shared_workflow_2_createdAt_not_null" NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) CONSTRAINT "shared_workflow_2_updatedAt_not_null" NOT NULL
);


ALTER TABLE public.shared_workflow OWNER TO postgres;

--
-- Name: tag_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tag_entity (
    name character varying(24) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    id character varying(36) CONSTRAINT tag_entity_id_not_null1 NOT NULL
);


ALTER TABLE public.tag_entity OWNER TO postgres;

--
-- Name: test_case_execution; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_case_execution (
    id character varying(36) NOT NULL,
    "testRunId" character varying(36) NOT NULL,
    "executionId" integer,
    status character varying NOT NULL,
    "runAt" timestamp(3) with time zone,
    "completedAt" timestamp(3) with time zone,
    "errorCode" character varying,
    "errorDetails" json,
    metrics json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    inputs json,
    outputs json,
    "runIndex" integer
);


ALTER TABLE public.test_case_execution OWNER TO postgres;

--
-- Name: test_run; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.test_run (
    id character varying(36) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    status character varying NOT NULL,
    "errorCode" character varying,
    "errorDetails" json,
    "runAt" timestamp(3) with time zone,
    "completedAt" timestamp(3) with time zone,
    metrics json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "runningInstanceId" character varying(255),
    "cancelRequested" boolean DEFAULT false NOT NULL,
    "workflowVersionId" character varying(36),
    "evaluationConfigId" character varying(36),
    "evaluationConfigSnapshot" jsonb,
    "collectionId" character varying(36)
);


ALTER TABLE public.test_run OWNER TO postgres;

--
-- Name: token_exchange_jti; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.token_exchange_jti (
    jti character varying(255) NOT NULL,
    "expiresAt" timestamp(3) with time zone NOT NULL,
    "createdAt" timestamp(3) with time zone NOT NULL
);


ALTER TABLE public.token_exchange_jti OWNER TO postgres;

--
-- Name: trusted_key; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trusted_key (
    "sourceId" character varying(36) NOT NULL,
    kid character varying(255) NOT NULL,
    data text NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.trusted_key OWNER TO postgres;

--
-- Name: trusted_key_source; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trusted_key_source (
    id character varying(36) NOT NULL,
    type character varying(32) NOT NULL,
    config text NOT NULL,
    status character varying(32) DEFAULT 'pending'::character varying NOT NULL,
    "lastError" text,
    "lastRefreshedAt" timestamp(3) with time zone,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.trusted_key_source OWNER TO postgres;

--
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255),
    "firstName" character varying(32),
    "lastName" character varying(32),
    password character varying(255),
    "personalizationAnswers" json,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    settings json,
    disabled boolean DEFAULT false NOT NULL,
    "mfaEnabled" boolean DEFAULT false NOT NULL,
    "mfaSecret" text,
    "mfaRecoveryCodes" text,
    "lastActiveAt" date,
    "roleSlug" character varying(128) DEFAULT 'global:member'::character varying NOT NULL
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- Name: user_api_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_api_keys (
    id character varying(36) NOT NULL,
    "userId" uuid NOT NULL,
    label character varying(100) NOT NULL,
    "apiKey" character varying NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    scopes json,
    audience character varying DEFAULT 'public-api'::character varying NOT NULL,
    "lastUsedAt" timestamp(3) with time zone
);


ALTER TABLE public.user_api_keys OWNER TO postgres;

--
-- Name: user_favorites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_favorites (
    id integer NOT NULL,
    "userId" uuid NOT NULL,
    "resourceId" character varying(255) NOT NULL,
    "resourceType" character varying(64) NOT NULL
);


ALTER TABLE public.user_favorites OWNER TO postgres;

--
-- Name: user_favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_favorites ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: variables; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.variables (
    key character varying(50) NOT NULL,
    type character varying(50) DEFAULT 'string'::character varying NOT NULL,
    value text,
    id character varying(36) CONSTRAINT variables_id_not_null1 NOT NULL,
    "projectId" character varying(36),
    CONSTRAINT variables_value_max_len CHECK (((value IS NULL) OR (char_length(value) <= 1000)))
);


ALTER TABLE public.variables OWNER TO postgres;

--
-- Name: webhook_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.webhook_entity (
    "webhookPath" character varying NOT NULL,
    method character varying NOT NULL,
    node character varying NOT NULL,
    "webhookId" character varying,
    "pathLength" integer,
    "workflowId" character varying(36) CONSTRAINT "webhook_entity_workflowId_not_null1" NOT NULL
);


ALTER TABLE public.webhook_entity OWNER TO postgres;

--
-- Name: workflow_builder_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_builder_session (
    id uuid NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "userId" uuid NOT NULL,
    messages json DEFAULT '[]'::json NOT NULL,
    "previousSummary" text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "activeVersionCardId" character varying(255),
    "resumeAfterRestoreMessageId" character varying(255)
);


ALTER TABLE public.workflow_builder_session OWNER TO postgres;

--
-- Name: COLUMN workflow_builder_session."previousSummary"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_builder_session."previousSummary" IS 'Summary of prior conversation from compaction (/compact or auto-compact)';


--
-- Name: workflow_dependency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_dependency (
    id integer NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "workflowVersionId" integer NOT NULL,
    "dependencyType" character varying(32) NOT NULL,
    "dependencyKey" character varying(255) NOT NULL,
    "dependencyInfo" json,
    "indexVersionId" smallint DEFAULT 1 NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "publishedVersionId" character varying(36)
);


ALTER TABLE public.workflow_dependency OWNER TO postgres;

--
-- Name: COLUMN workflow_dependency."workflowVersionId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_dependency."workflowVersionId" IS 'Version of the workflow';


--
-- Name: COLUMN workflow_dependency."dependencyType"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_dependency."dependencyType" IS 'Type of dependency: "credential", "nodeType", "webhookPath", or "workflowCall"';


--
-- Name: COLUMN workflow_dependency."dependencyKey"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_dependency."dependencyKey" IS 'ID or name of the dependency';


--
-- Name: COLUMN workflow_dependency."dependencyInfo"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_dependency."dependencyInfo" IS 'Additional info about the dependency, interpreted based on type';


--
-- Name: COLUMN workflow_dependency."indexVersionId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_dependency."indexVersionId" IS 'Version of the index structure';


--
-- Name: workflow_dependency_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.workflow_dependency ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.workflow_dependency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_entity (
    name character varying(128) NOT NULL,
    active boolean NOT NULL,
    nodes json NOT NULL,
    connections json NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    settings json,
    "staticData" json,
    "pinData" json,
    "versionId" character(36) NOT NULL,
    "triggerCount" integer DEFAULT 0 NOT NULL,
    id character varying(36) CONSTRAINT workflow_entity_id_not_null1 NOT NULL,
    meta json,
    "parentFolderId" character varying(36) DEFAULT NULL::character varying,
    "isArchived" boolean DEFAULT false NOT NULL,
    "versionCounter" integer DEFAULT 1 NOT NULL,
    description text,
    "activeVersionId" character varying(36),
    "nodeGroups" json DEFAULT '[]'::json NOT NULL,
    "sourceWorkflowId" character varying
);


ALTER TABLE public.workflow_entity OWNER TO postgres;

--
-- Name: workflow_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_history (
    "versionId" character varying(36) NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    authors character varying(255) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    nodes json NOT NULL,
    connections json NOT NULL,
    name character varying(128),
    autosaved boolean DEFAULT false NOT NULL,
    description text,
    "nodeGroups" json DEFAULT '[]'::json NOT NULL
);


ALTER TABLE public.workflow_history OWNER TO postgres;

--
-- Name: workflow_publication_outbox; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_publication_outbox (
    id integer NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "publishedVersionId" character varying(36) NOT NULL,
    status character varying(20) NOT NULL,
    "errorMessage" text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_workflow_publication_outbox_status" CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'partial_success'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.workflow_publication_outbox OWNER TO postgres;

--
-- Name: COLUMN workflow_publication_outbox."workflowId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_publication_outbox."workflowId" IS 'References workflow_entity.id.';


--
-- Name: COLUMN workflow_publication_outbox."publishedVersionId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_publication_outbox."publishedVersionId" IS 'References workflow_history.versionId.';


--
-- Name: COLUMN workflow_publication_outbox."errorMessage"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_publication_outbox."errorMessage" IS 'Error details for surfacing failed publications to the user.';


--
-- Name: workflow_publication_outbox_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.workflow_publication_outbox ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.workflow_publication_outbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_publication_trigger_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_publication_trigger_status (
    "workflowId" character varying(36) NOT NULL,
    "nodeId" character varying(36) NOT NULL,
    "versionId" character varying(36) NOT NULL,
    status character varying(20) NOT NULL,
    "errorMessage" text,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "triggerKind" character varying(20) NOT NULL,
    CONSTRAINT "CHK_workflow_publication_trigger_status_status" CHECK (((status)::text = ANY ((ARRAY['activated'::character varying, 'failed'::character varying])::text[]))),
    CONSTRAINT "CHK_workflow_publication_trigger_status_triggerKind" CHECK ((("triggerKind")::text = ANY ((ARRAY['in-memory'::character varying, 'persisted'::character varying])::text[])))
);


ALTER TABLE public.workflow_publication_trigger_status OWNER TO postgres;

--
-- Name: COLUMN workflow_publication_trigger_status."versionId"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_publication_trigger_status."versionId" IS 'References workflow_history.versionId: the published version these statuses were recorded for';


--
-- Name: COLUMN workflow_publication_trigger_status."triggerKind"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_publication_trigger_status."triggerKind" IS 'Where the trigger lives once activated: in-memory (registered on the owning instance) vs persisted (webhook row in webhook_entity)';


--
-- Name: workflow_publish_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_publish_history (
    id integer NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    "versionId" character varying(36),
    event character varying(36) NOT NULL,
    "userId" uuid,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    CONSTRAINT "CHK_workflow_publish_history_event" CHECK (((event)::text = ANY ((ARRAY['activated'::character varying, 'deactivated'::character varying])::text[])))
);


ALTER TABLE public.workflow_publish_history OWNER TO postgres;

--
-- Name: COLUMN workflow_publish_history.event; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow_publish_history.event IS 'Type of history record: activated (workflow is now active), deactivated (workflow is now inactive)';


--
-- Name: workflow_publish_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.workflow_publish_history ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.workflow_publish_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_published_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_published_version (
    "workflowId" character varying(36) NOT NULL,
    "publishedVersionId" character varying(36) NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL,
    "updatedAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP(3) NOT NULL
);


ALTER TABLE public.workflow_published_version OWNER TO postgres;

--
-- Name: workflow_statistics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_statistics (
    count bigint DEFAULT 0,
    "latestEvent" timestamp(3) with time zone,
    name character varying(128) NOT NULL,
    "workflowId" character varying(36) CONSTRAINT "workflow_statistics_workflowId_not_null1" NOT NULL,
    "rootCount" bigint DEFAULT 0,
    id integer NOT NULL,
    "workflowName" character varying(128)
);


ALTER TABLE public.workflow_statistics OWNER TO postgres;

--
-- Name: workflow_statistics_delta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_statistics_delta (
    id bigint NOT NULL,
    "workflowId" character varying(36) NOT NULL,
    name character varying(128) NOT NULL,
    "rootCountDelta" smallint NOT NULL,
    "createdAt" timestamp(3) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "workflowName" character varying(128)
)
WITH (autovacuum_vacuum_scale_factor='0.0', autovacuum_vacuum_threshold='1000', autovacuum_vacuum_cost_delay='0');


ALTER TABLE public.workflow_statistics_delta OWNER TO postgres;

--
-- Name: workflow_statistics_delta_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.workflow_statistics_delta ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.workflow_statistics_delta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflow_statistics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.workflow_statistics_id_seq OWNER TO postgres;

--
-- Name: workflow_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflow_statistics_id_seq OWNED BY public.workflow_statistics.id;


--
-- Name: workflows_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflows_tags (
    "workflowId" character varying(36) CONSTRAINT "workflows_tags_workflowId_not_null1" NOT NULL,
    "tagId" character varying(36) CONSTRAINT "workflows_tags_tagId_not_null1" NOT NULL
);


ALTER TABLE public.workflows_tags OWNER TO postgres;

--
-- Name: auth_provider_sync_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_provider_sync_history ALTER COLUMN id SET DEFAULT nextval('public.auth_provider_sync_history_id_seq'::regclass);


--
-- Name: email_tasks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_tasks ALTER COLUMN id SET DEFAULT nextval('public.email_tasks_id_seq'::regclass);


--
-- Name: execution_annotations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_annotations ALTER COLUMN id SET DEFAULT nextval('public.execution_annotations_id_seq'::regclass);


--
-- Name: execution_entity id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_entity ALTER COLUMN id SET DEFAULT nextval('public.execution_entity_id_seq'::regclass);


--
-- Name: execution_metadata id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_metadata ALTER COLUMN id SET DEFAULT nextval('public.execution_metadata_temp_id_seq'::regclass);


--
-- Name: instance_version_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_version_history ALTER COLUMN id SET DEFAULT nextval('public.instance_version_history_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: items2 id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items2 ALTER COLUMN id SET DEFAULT nextval('public.items2_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: workflow_statistics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_statistics ALTER COLUMN id SET DEFAULT nextval('public.workflow_statistics_id_seq'::regclass);


--
-- Data for Name: agent_chat_subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_chat_subscriptions ("agentId", "integrationType", "credentialId", "threadId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_checkpoints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_checkpoints ("runId", "agentId", state, expired, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_execution; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_execution (id, "threadId", status, "startedAt", "stoppedAt", duration, "userMessage", model, "promptTokens", "completionTokens", "totalTokens", cost, timeline, error, "hitlStatus", source, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_execution_threads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_execution_threads (id, "agentId", "agentName", "projectId", "sessionNumber", "totalPromptTokens", "totalCompletionTokens", "totalCost", "totalDuration", title, emoji, "createdAt", "updatedAt", "taskId", "taskVersionId", "parentThreadId", "parentAgentId") FROM stdin;
\.


--
-- Data for Name: agent_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_files (id, "agentId", "binaryDataId", "fileName", "mimeType", "fileSizeBytes", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_history ("versionId", "agentId", schema, tools, skills, "publishedById", author, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_task_definition; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_task_definition (id, "agentId", name, objective, "cronExpression", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_task_run_lock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_task_run_lock ("agentId", "taskId", "holderId", "heldUntil", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agent_task_snapshot; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_task_snapshot ("versionId", "taskId", enabled, name, objective, "cronExpression", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents (id, name, "projectId", integrations, schema, tools, skills, "versionId", "createdAt", "updatedAt", "activeVersionId") FROM stdin;
\.


--
-- Data for Name: agents_memory_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_memory_entries (id, "agentId", "resourceId", content, "contentHash", status, "supersededBy", "embeddingModel", embedding, metadata, "lastSeenAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_memory_entry_cursors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_memory_entry_cursors ("agentId", "observationScopeId", "lastIndexedObservationId", "lastIndexedObservationCreatedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_memory_entry_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_memory_entry_locks ("agentId", "resourceId", "holderId", "heldUntil", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_memory_entry_sources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_memory_entry_sources (id, "agentId", "memoryEntryId", "observationId", "threadId", "evidenceHash", "evidenceText", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_messages (id, "threadId", "resourceId", role, type, content, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_observation_cursors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_observation_cursors ("agentId", "observationScopeId", "lastObservedMessageId", "lastObservedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_observation_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_observation_locks ("agentId", "observationScopeId", "taskKind", "holderId", "heldUntil", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_observations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_observations (id, "agentId", "observationScopeId", marker, text, "parentId", "tokenCount", status, "supersededBy", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_resources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_resources (id, metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: agents_threads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_threads (id, "resourceId", title, metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: ai_builder_temporary_workflow; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ai_builder_temporary_workflow ("workflowId", "threadId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: annotation_tag_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.annotation_tag_entity (id, name, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: auth_identity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_identity ("userId", "providerId", "providerType", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: auth_provider_sync_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_provider_sync_history (id, "providerType", "runMode", status, "startedAt", "endedAt", scanned, created, updated, disabled, error) FROM stdin;
\.


--
-- Data for Name: binary_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.binary_data ("fileId", "sourceType", "sourceId", data, "mimeType", "fileName", "fileSize", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: chat_hub_agent_tools; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_hub_agent_tools ("agentId", "toolId") FROM stdin;
\.


--
-- Data for Name: chat_hub_agents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_hub_agents (id, name, description, "systemPrompt", "ownerId", "credentialId", provider, model, "createdAt", "updatedAt", icon, files, "suggestedPrompts") FROM stdin;
\.


--
-- Data for Name: chat_hub_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_hub_messages (id, "sessionId", "previousMessageId", "revisionOfMessageId", "retryOfMessageId", type, name, content, provider, model, "workflowId", "executionId", "createdAt", "updatedAt", "agentId", status, attachments) FROM stdin;
\.


--
-- Data for Name: chat_hub_session_tools; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_hub_session_tools ("sessionId", "toolId") FROM stdin;
\.


--
-- Data for Name: chat_hub_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_hub_sessions (id, title, "ownerId", "lastMessageAt", "credentialId", provider, model, "workflowId", "createdAt", "updatedAt", "agentId", "agentName", type) FROM stdin;
\.


--
-- Data for Name: chat_hub_tools; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_hub_tools (id, name, type, "typeVersion", "ownerId", definition, enabled, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: credential_dependency; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.credential_dependency (id, "credentialId", "dependencyType", "dependencyId", "createdAt") FROM stdin;
\.


--
-- Data for Name: credentials_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.credentials_entity (name, data, type, "createdAt", "updatedAt", id, "isManaged", "isGlobal", "isResolvable", "resolvableAllowFallback", "resolverId") FROM stdin;
Google Service Account account	U2FsdGVkX19xz5VdauXDkQ6E1NUovAN2PCp84HmESvW2SpDHUHjFkjsjP8ZSOthLEaKUAkpRYQgepbX/k1txfM4hs6fpBC8HKWEPLSfSmCdlTXrxvjjWHLPQgLIkQYBB3Q5m5N8IzPWgFT3aeqE2wTTY1Kyv3CwdGcGMrDlFNs0tHwjWChNAa9kC1FvAGx2h	googleApi	2026-08-03 12:10:06.102+07	2026-08-03 12:15:47.994+07	NaMyFYvBO9XCMEhG	f	f	f	f	\N
Telegram account	U2FsdGVkX1/myuK6R/PiKFMe3LhcW7z4+kb7hqhqdnaRkVWlDq2hfnNbQUJM7Ckd9PviN4riDPBwHK5+MWoTKQaC/8esEllNTtUzV91eS6rVt/P4F+Pa1vVlP4YI5EdR	telegramApi	2026-08-03 18:58:15.55+07	2026-08-03 18:58:15.547+07	SXr9kdhP2pbmSSl5	f	f	f	f	\N
Postgres account	U2FsdGVkX18tmrElCXhbu76pXEBglpFL62nGNoV19cHWDalIikxldN/wSGjxnwdv1YLC5AAWLdsQHIHr0GO9k/lsN4sFyT1jwQrPKIk0ZPY=	postgres	2026-08-03 19:02:29.198+07	2026-08-03 19:02:29.193+07	aYolIV9R7XB2uz9G	f	f	f	f	\N
SMTP account	U2FsdGVkX18cpNmIfYtp7EBSRVPV37mx1/bVRjic9XtGdHbSLLrRf3RWghrwF6svmpV47eWH6B+obddpTM/jo4jCiQhcbTsPpm9oG5mQ7IaRorHS4J9EEPdIKmoC0NfSTFeGGQHLy02Nq4xYuDcUAsn3eDSTQfwPwVSBCKdvDDqlZ7yIQRXdP4nTAl8JkMf/A8eEpbb10xbLEbdCFnZDmBgKLW6h+HHDXqSkNF3b3dfKy65q8WUNG7gxMYhvZOqo	smtp	2026-08-03 19:27:49.558+07	2026-08-03 19:32:26.218+07	vUrbIYd7RrDZxipc	f	f	f	f	\N
\.


--
-- Data for Name: data_table; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.data_table (id, name, "projectId", "createdAt", "updatedAt") FROM stdin;
VBZ0QdgF869s7cES	n8n_flow	vWagCZseTzZf36H9	2026-08-03 12:27:46.93+07	2026-08-03 12:27:46.93+07
\.


--
-- Data for Name: data_table_column; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.data_table_column (id, name, type, index, "dataTableId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: data_table_user_VBZ0QdgF869s7cES; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."data_table_user_VBZ0QdgF869s7cES" (id, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: deployment_key; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.deployment_key (id, type, value, algorithm, status, "createdAt", "updatedAt") FROM stdin;
jcAvXRO4gUlI2C1G	instance.id	5b95d89aacf9ea5669b5baffc7ad20851417f611bbc70631755c5f369451232e	\N	active	2026-08-03 09:11:00.669+07	2026-08-03 09:11:00.669+07
WfrbwXxyFhUZ9wXi	signing.hmac	a7e62d674ad91a237698b7248343aebf80b5921dc43d4622f699046a1f850ec8	\N	active	2026-08-03 09:11:00.675+07	2026-08-03 09:11:00.675+07
DrF2bPyf4uXnnu1O	signing.jwt	4b396597343dc9f6a168cf58097f972f647c151582cdf60dce8dd8362c46024a	\N	active	2026-08-03 09:11:00.68+07	2026-08-03 09:11:00.68+07
SxvbsQKTbWd99eYQ	signing.binary_data	qKZghwD3uF9E/czPaQcatdNqJjYcdBlemNWmhb3M7wY=	\N	active	2026-08-03 09:11:00.683+07	2026-08-03 09:11:00.683+07
\.


--
-- Data for Name: dynamic_credential_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dynamic_credential_entry (credential_id, subject_id, resolver_id, data, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: dynamic_credential_resolver; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dynamic_credential_resolver (id, name, type, config, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: dynamic_credential_user_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dynamic_credential_user_entry ("credentialId", "userId", "resolverId", data, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: email_tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_tasks (id, email_message_id, sender_email, subject, task_title, task_description, priority, status, due_date, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: evaluation_collection; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.evaluation_collection (id, name, description, "workflowId", "evaluationConfigId", "createdById", "insightsCache", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: evaluation_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.evaluation_config (id, "workflowId", name, status, "invalidReason", "datasetSource", "datasetRef", "startNodeName", "endNodeName", metrics, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: event_destinations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.event_destinations (id, destination, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: execution_annotation_tags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.execution_annotation_tags ("annotationId", "tagId") FROM stdin;
\.


--
-- Data for Name: execution_annotations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.execution_annotations (id, "executionId", vote, note, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: execution_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.execution_data ("executionId", "workflowData", data, "workflowVersionId") FROM stdin;
1	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","event":"messageReceived","simple":true,"maxResults":10,"filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"@JourneyDevBot","text":"Hi","replyMarkup":"none","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}],"connections":{},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"353d08cbf23bba27749f2bbf738ae06f11ab2b2ffeecadf45a36722585250569",{"nodeName":"10","mode":"17"},["10"],{"level":"18","shouldReport":true,"description":"19","tags":"20","timestamp":1785758315960,"context":"21","functionality":"22","name":"23","node":"24","messages":"25","httpCode":"26","message":"27","stack":"28"},{"Send a text message":"29"},{},"Send a text message",{},["30"],{},{},{},{"version":1,"establishedAt":1785758314985,"source":"31","triggerNode":"32","redaction":"33","credentials":"34"},"inclusive","warning","Forbidden: the bot can't send messages to the bot",{},{},"regular","NodeApiError",{"parameters":"35","type":"36","typeVersion":1.2,"position":"37","id":"38","name":"10","webhookId":"39","credentials":"40"},["41"],"403","Forbidden - perhaps check your credentials?","NodeApiError: Forbidden - perhaps check your credentials?\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["42"],{"node":"43","data":"44","source":null},"manual",{"name":"10","type":"36"},{"version":2,"production":false,"manual":false,"source":"45"},"U2FsdGVkX1/DSJ/maw2R2UoSAy+/i6ArpR6DxIcOrc40Unx81p58c856CkLz9NuVL0rGJjuyfjA2QbpdnzrXDoTjZlNtM9El1ZfaePviMHg2lmSyOPcnTIIvP3AYsJSBKQSfZFfimyURatupCXdg9gHASg5FmtpZ5q+NG6IVME9oD9WsLaaA5/9RQENbV0yBvP3UnScTqxnhYTO48aZ2VkWS2r+VmZdMtxXnL59qp+AxMX0JyKMJEPIbpuE/70nlOM1JhZD1F1hhHBj68roib3cym0hs+jwTKWGgRdDC4FlY1mjlTny7sXEmCZi7mq9q5epsSkepGAtg1FY0COoaoHNllKg7UXtxmbTxUuqaliDxyiVmrjtvB/AReYbMviBOGP5ocpsOXGNUNmCl3k+zKV1lRwUDi8xZiWEYJ2PiLwuzNYUvxmpR3Usl/mbG1JVWJ8E62GUpN9rqhI87puuRy74i/NAnMaUbU62kt69QVP26eIg7wI8QKuTETxQvoKxDlSAT+1D/K1NOueXrWKJdHg==",{"resource":"46","operation":"47","chatId":"48","text":"49","replyMarkup":"50","additionalFields":"51"},"n8n-nodes-base.telegram",[144,144],"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","ca51bb74-2f84-4703-b48a-74c3da97dc24",{"telegramApi":"52"},"403 - {\\"ok\\":false,\\"error_code\\":403,\\"description\\":\\"Forbidden: the bot can't send messages to the bot\\"}",{"startTime":1785758315030,"executionIndex":0,"source":"53","hints":"54","executionTime":946,"executionStatus":"55","error":"56"},{"parameters":"57","type":"36","typeVersion":1.2,"position":"58","id":"38","name":"10","webhookId":"39","credentials":"59"},{"main":"60"},"workflow","message","sendMessage","@JourneyDevBot","Hi","none",{},{"id":"61","name":"62"},[],[],"error",{"level":"18","shouldReport":true,"description":"19","tags":"20","timestamp":1785758315960,"context":"21","functionality":"22","name":"23","node":"24","messages":"25","httpCode":"26","message":"27","stack":"28"},{"resource":"46","operation":"47","chatId":"48","text":"49","replyMarkup":"50","additionalFields":"63"},[144,144],{"telegramApi":"64"},["65"],"SXr9kdhP2pbmSSl5","Telegram account",{},{"id":"61","name":"62"},["66"],{"json":"67","pairedItem":"68"},{},{"item":0}]	f7587b4f-b56c-40e7-a058-72af7fcd292d
2	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","event":"messageReceived","simple":true,"maxResults":10,"filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"JourneyDevBot","text":"HI all","replyMarkup":"none","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}],"connections":{},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"0b0555acf5962705f4f934258cc02babe3175e78aab05f411bdf7464848b8c46",{"nodeName":"10","mode":"17"},["10"],{"level":"18","shouldReport":true,"description":"19","tags":"20","timestamp":1785758402141,"context":"21","functionality":"22","name":"23","node":"24","messages":"25","httpCode":"26","message":"27","stack":"28"},{"Send a text message":"29"},{},"Send a text message",{},["30"],{},{},{},{"version":1,"establishedAt":1785758401494,"source":"31","triggerNode":"32","redaction":"33","credentials":"34"},"inclusive","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"35","type":"36","typeVersion":1.2,"position":"37","id":"38","name":"10","webhookId":"39","credentials":"40"},["41"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["42"],{"node":"43","data":"44","source":null},"manual",{"name":"10","type":"36"},{"version":2,"production":false,"manual":false,"source":"45"},"U2FsdGVkX1+Sean2Uzn1bOWswYv7Bo8RjzbCDbrKpfo8LwcHqiJ6Lbacoemef4iYofSoGCJYIhcpwHjGZykp9KU0YHq2xLaElItCbIa7AZZtO1aRX8Tx9uuw2trcqVEems/ZHyUcC2Yv5/uCH287aLYI2u7TWI+uvheU6STYWVpeuRoItpoEL28P9hsqSERWfxigA5vBOp6bYF2I6YVTHGO8mKxR/iKbuUiqdK2dwqVyCi1ECN6wLhcSaumkl0SDg9g7sdDSfu+vCUnq27FwblH9GA4es2f24pIiAVt+pSFawHfH4sR2I3XO4jtYiSo8B1Yrp4L+Iof0gxxID3cYc5dc1WAWtLR58PkKnmQHmwYBwyfX8+zP8ZdmA+dsvQBxZ+i6CxJYfSzwFdsPZtEgZbtdIJ/cebBedRKEeBr5TwRFktjc93rrEHmvmm3YlC0bAeDOMFR81SoV2R70TsnT7TT3MA2bcSQfJ2oJstaXaIDlW/5kOZFdCELy5F1vf5YmuAFZkSIH42aetjMIB0HzHA==",{"resource":"46","operation":"47","chatId":"48","text":"49","replyMarkup":"50","additionalFields":"51"},"n8n-nodes-base.telegram",[144,144],"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","ca51bb74-2f84-4703-b48a-74c3da97dc24",{"telegramApi":"52"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785758401550,"executionIndex":0,"source":"53","hints":"54","executionTime":592,"executionStatus":"55","error":"56"},{"parameters":"57","type":"36","typeVersion":1.2,"position":"58","id":"38","name":"10","webhookId":"39","credentials":"59"},{"main":"60"},"workflow","message","sendMessage","JourneyDevBot","HI all","none",{},{"id":"61","name":"62"},[],[],"error",{"level":"18","shouldReport":true,"description":"19","tags":"20","timestamp":1785758402141,"context":"21","functionality":"22","name":"23","node":"24","messages":"25","httpCode":"26","message":"27","stack":"28"},{"resource":"46","operation":"47","chatId":"48","text":"49","replyMarkup":"50","additionalFields":"63"},[144,144],{"telegramApi":"64"},["65"],"SXr9kdhP2pbmSSl5","Telegram account",{},{"id":"61","name":"62"},["66"],{"json":"67","pairedItem":"68"},{},{"item":0}]	e1c87199-65be-4386-ba56-6731852c03a7
3	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","event":"messageReceived","simple":true,"maxResults":10,"filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"JourneyDevBot","text":"HI all","replyMarkup":"none","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","alwaysOutputData":true,"executeOnce":true,"retryOnFail":true,"notesInFlow":true,"credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}],"connections":{},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"1f6dc7196e294549e52f1b1ab56af85eea613a02e5d4e84ed34485699c76dd79",{"nodeName":"10","mode":"17"},["10"],{"level":"18","shouldReport":true,"description":"19","tags":"20","timestamp":1785758416793,"context":"21","functionality":"22","name":"23","node":"24","messages":"25","httpCode":"26","message":"27","stack":"28"},{"Send a text message":"29"},{},"Send a text message",{},["30"],{},{},{},{"version":1,"establishedAt":1785758413012,"source":"31","triggerNode":"32","redaction":"33","credentials":"34"},"inclusive","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"35","type":"36","typeVersion":1.2,"position":"37","id":"38","name":"10","webhookId":"39","alwaysOutputData":true,"executeOnce":true,"retryOnFail":true,"notesInFlow":true,"credentials":"40"},["41"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["42"],{"node":"43","data":"44","source":null},"manual",{"name":"10","type":"36"},{"version":2,"production":false,"manual":false,"source":"45"},"U2FsdGVkX1+ZO4k7WC9mCX7sLlG3uFjpEBgvPI+2UVTOKF3NGRyWve90GfuZD4z11kktkZNSBwI5fsWbxs1DEPBBHse6F0Ty2X7qF1eQM+Hu3Oyo93EGs2wtLGqJzQHg2EdkMzQ88ZnTenBBLhjP0QJ71F17RB9hv+gRsVnZlIHMT8ev5VrY1rlTowpoQlhYt3AEJ00FteAQX462UswZM6uwTM9D5rcP14BI7PxX3uKxMwMSL7BklvIBwcXUEmkiQ8ebQZ9t1mrCbRohYpM+IcCrItYC40kVUjZCOF0vUREIYAfdNvwkdfvabKqbOOtFOa3fPHzlv72Wz9GIahIU65B1qw4YZWjyqIaBqUxGKKt4gi0VsdYCkvGztiKc2zkEHC6ZYX3295T4BAj3CIjtUWf1WyehccNgTIDMI8DTVouFo1aokUhlfJH61St4JHSMs5OBdmK87PoGkPPCHXO6H505wtRhAGNGJFIebTl2lcWZUEhE6Orv7gujqEDH3dBLg8UNwykvdrF72MCs6uaPNQ==",{"resource":"46","operation":"47","chatId":"48","text":"49","replyMarkup":"50","additionalFields":"51"},"n8n-nodes-base.telegram",[144,144],"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","ca51bb74-2f84-4703-b48a-74c3da97dc24",{"telegramApi":"52"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785758413052,"executionIndex":0,"source":"53","hints":"54","executionTime":3742,"executionStatus":"55","error":"56"},{"parameters":"57","type":"36","typeVersion":1.2,"position":"58","id":"38","name":"10","webhookId":"39","alwaysOutputData":true,"executeOnce":true,"retryOnFail":true,"notesInFlow":true,"credentials":"59"},{"main":"60"},"workflow","message","sendMessage","JourneyDevBot","HI all","none",{},{"id":"61","name":"62"},[],[],"error",{"level":"18","shouldReport":true,"description":"19","tags":"20","timestamp":1785758416793,"context":"21","functionality":"22","name":"23","node":"24","messages":"25","httpCode":"26","message":"27","stack":"28"},{"resource":"46","operation":"47","chatId":"48","text":"49","replyMarkup":"50","additionalFields":"63"},[144,144],{"telegramApi":"64"},["65"],"SXr9kdhP2pbmSSl5","Telegram account",{},{"id":"61","name":"62"},["66"],{"json":"67","pairedItem":"68"},{},{"item":0}]	5768c14e-efc0-4d02-bff7-1b95e745acc6
4	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"mode":"list","value":""}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table"}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"4d4ab0e95faf5fe4742d2c85d3027b3ca69967e618228a4c5f1e7a9487f23b45",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785758498330,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Insert rows in a table' node has issues:\\n- Parameter \\"Table\\" is required.","WorkflowHasIssuesError: The 'Insert rows in a table' node has issues:\\n- Parameter \\"Table\\" is required.\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	42e0e936-da46-4444-be1f-a447dad7b7e0
7	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"b1f9d3ecbb5893d51e0117a2398236ea67c963d9683b4330c730361f147be0b3",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785758758099,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Insert rows in a table' node has issues:\\n- Column \\"payload\\" is required","WorkflowHasIssuesError: The 'Insert rows in a table' node has issues:\\n- Column \\"payload\\" is required\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	dfa4f148-53a4-458e-9443-fc023d4c12f5
5	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{"payload":"Hi"},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"0e9e8df90ace50bdf09969782a98ae569f49b1df45cf2e768670d5498248acef",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785758746780,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Insert rows in a table' node has issues:\\n- 'payload' expects a object but we got 'Hi'","WorkflowHasIssuesError: The 'Insert rows in a table' node has issues:\\n- 'payload' expects a object but we got 'Hi'\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	61acc561-d139-4cf5-87ea-5e721bb7287f
6	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"fa916fb5901f229819537b6a7294d9cb28fe5a7c5a46f6e256a1bce5805ec741",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785758755646,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Insert rows in a table' node has issues:\\n- Column \\"payload\\" is required","WorkflowHasIssuesError: The 'Insert rows in a table' node has issues:\\n- Column \\"payload\\" is required\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	dfa4f148-53a4-458e-9443-fc023d4c12f5
12	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":[],"schema":[{"id":"code","displayName":"code","required":true,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true},{"id":"name","displayName":"name","required":true,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"runData":"7","pinData":"8","lastNodeExecuted":"9"},{"contextData":"10","nodeExecutionStack":"11","metadata":"12","waitingExecution":"13","waitingExecutionSource":"14","runtimeData":"15"},"0a6e0db4d27b04f221b2e66dc140834cd0f2e83efc5484df5c033d6c414178c9",{"nodeName":"9","mode":"16"},["17","9"],{"When clicking ‘Execute workflow’":"18","Insert rows in a table":"19"},{},"Insert rows in a table",{},[],{},{},{},{"version":1,"establishedAt":1785759082758,"source":"20","triggerNode":"21","redaction":"22","credentials":"23"},"inclusive","When clicking ‘Execute workflow’",["24"],["25"],"manual",{"name":"9","type":"26"},{"version":2,"production":false,"manual":false,"source":"27"},"U2FsdGVkX19CN0ctTHdHOO2zhhPPT98en9K1+DffaZY+EGdkfLznblLtwf93Nye7XOLn5dS/DFJiQIGGGFokatPpxnYFXCbyo02Y1li+f4soCRp0iqVJVZJiHAAi+lrclictOgSO03UwSqpbJQt2x/oIraK2udZzpQIloEBvWzjNosN6uL0o+kZtunPhkycvLHjAOS45E5pMAitPtJzC2bbJ88oXuj2wc9g5V3N6XClDGXl4urY4GWO4N2NvouN4I1xq0iEgzyFDbta9vfBmt+TsG3IzKSbauQrY5T7oc5i9ZDJf3JddLXaOCEmFxZ7aIhrc+J8MLZstnrfiTM93vha6uZPCFqYa/Ye+BGLlHuXwvjj3dM2pO1C69k93wuxYKQAjHCJg+bL5IVnhuvtgrPEN9h8XeAfshbDeEJXtj9NvMfYMhNq/jyodHu9s9/As7DqgzNcuMBF22Fvu0h3HRWNzdDYu9mG1SAHIpzEkb1saynGUP30dYRWPNR9aNSX0yNqBFbmiW7/mR9Zg4hWsug==",{"startTime":1785759026319,"executionIndex":0,"source":"28","hints":"29","executionTime":2,"executionStatus":"30","data":"31"},{"startTime":1785759082777,"executionIndex":1,"source":"32","hints":"33","executionTime":64,"executionStatus":"30","data":"34"},"n8n-nodes-base.postgres","workflow",[],[],"success",{"main":"35"},["36"],[],{"main":"37"},["38"],{"previousNode":"17","previousNodeOutput":0,"previousNodeRun":0},["39"],["40"],["41"],{"json":"42","pairedItem":"43"},{"json":"44","pairedItem":"45"},{},{"item":0},{"code":0,"name":"46"},{"item":0},""]	6f648c2c-478f-4d22-93aa-b88bc345efee
14	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":[],"schema":[{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"runData":"7","pinData":"8","lastNodeExecuted":"9"},{"contextData":"10","nodeExecutionStack":"11","metadata":"12","waitingExecution":"13","waitingExecutionSource":"14","runtimeData":"15"},"6d0d8aadc5c80a25b02d9504890d33697b09423f74b66387b7572cbde3483c81",{"nodeName":"9","mode":"16"},["17","9"],{"When clicking ‘Execute workflow’":"18","Insert rows in a table":"19"},{},"Insert rows in a table",{},[],{},{},{},{"version":1,"establishedAt":1785759165017,"source":"20","triggerNode":"21","redaction":"22","credentials":"23"},"inclusive","When clicking ‘Execute workflow’",["24"],["25"],"manual",{"name":"9","type":"26"},{"version":2,"production":false,"manual":false,"source":"27"},"U2FsdGVkX18ff/OadRqb9UVCRumvhVd8xaCnXrPKsS6vPpgseGnSfWfONE6tN+ONsAqATbBhOqYqoPrTpM/VhLDJe31UNgjhvHwKTE+3JEfr6XxBvXiPdMHo3i5wY6q7AdHRDDLTyRdZOtWEaLGFCA8BRKy4+vxB1/8yHNmsf4WF2WzTO06b6iNxlRhWYbuCtv+UZa7tmBfyMB7FOoHopDPYTM9RdXxJ7acF8WhECcwLGVqdXmc2TwOGoMSYO54TgAUaunofIdWf6ZHssLPYKCviTaINhqDUPtZiw5vDmTyVUebmX2pxCItRO6U1IbYJZ96dtgHBORbYK2Qa23MIHVUXdPqz/jc7m9USWlEk8bLj70g6ztjJTbF5UDv1/SerLjvtfS8Tu9zi0ZEdJH0fPdwzjjDmrvzC0SjJxnYLC5anHLxLzB5GkFlj2xucGnQ0JTO4dmA8GNao/aF9njep/kOo+wBk42VQfbsMm5MkMAC7MHdXV7ifVoa5q1ZatR2NOcHUXiCWuYSmMbpnJbltEQ==",{"startTime":1785759026319,"executionIndex":0,"source":"28","hints":"29","executionTime":2,"executionStatus":"30","data":"31"},{"startTime":1785759165039,"executionIndex":1,"source":"32","hints":"33","executionTime":98,"executionStatus":"30","data":"34"},"n8n-nodes-base.postgres","workflow",[],[],"success",{"main":"35"},["36"],[],{"main":"37"},["38"],{"previousNode":"17","previousNodeOutput":0,"previousNodeRun":0},["39"],["40"],["41"],{"json":"42","pairedItem":"43"},{"json":"44","pairedItem":"45"},{},{"item":0},{"id":"46","code":null,"name":null},{"item":0},"1"]	b1c61506-057e-4560-b4fc-441b85ee6f70
8	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"5810c0580f4df78fcb7711e32af7eeadf101a0fe46690370b52df9360a7807af",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785758812579,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Insert rows in a table' node has issues:\\n- Column \\"payload\\" is required","WorkflowHasIssuesError: The 'Insert rows in a table' node has issues:\\n- Column \\"payload\\" is required\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	dfa4f148-53a4-458e-9443-fc023d4c12f5
9	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"164b334ec18f7557deda774f14e41cdebd099fe48f4ff856df060fef97f5b74b",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785758846291,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Insert rows in a table' node has issues:\\n- Column \\"payload\\" is required","WorkflowHasIssuesError: The 'Insert rows in a table' node has issues:\\n- Column \\"payload\\" is required\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	dfa4f148-53a4-458e-9443-fc023d4c12f5
10	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":[],"schema":[{"id":"code","displayName":"code","required":true,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true},{"id":"name","displayName":"name","required":true,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"e9eaa3832a32510b330ee509349e1d9af68833d7d0eac4f55edad6377a9a36e0",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785758867673,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Insert rows in a table' node has issues:\\n- Column \\"code\\" is required\\n- Column \\"name\\" is required","WorkflowHasIssuesError: The 'Insert rows in a table' node has issues:\\n- Column \\"code\\" is required\\n- Column \\"name\\" is required\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	86317178-537d-45b9-aeaf-924bbfacf25b
11	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":[],"schema":[{"id":"code","displayName":"code","required":true,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true},{"id":"name","displayName":"name","required":true,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"e983f6cfe1b4914d47b3e177cad469a40202997fcecee005c9f9b13c32d8e27a",{"nodeName":"10","mode":"17"},["18","10"],{"level":"19","shouldReport":true,"description":"20","tags":"21","timestamp":1785759026462,"context":"22","functionality":"23","name":"24","node":"25","messages":"26","message":"27","stack":"28"},{"When clicking ‘Execute workflow’":"29","Insert rows in a table":"30"},{},"Insert rows in a table",{},["31"],{},{},{},{"version":1,"establishedAt":1785759026288,"source":"32","triggerNode":"33","redaction":"34","credentials":"35"},"inclusive","When clicking ‘Execute workflow’","warning","Failing row contains (null, null).",{},{},"regular","NodeOperationError",{"parameters":"36","type":"37","typeVersion":2.7,"position":"38","id":"39","name":"10","credentials":"40"},[],"null value in column \\"code\\" of relation \\"items\\" violates not-null constraint","NodeOperationError: null value in column \\"code\\" of relation \\"items\\" violates not-null constraint\\n    at parsePostgresError (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\helpers\\\\utils.ts:123:9)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\helpers\\\\utils.ts:398:19\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at runQueriesAndHandleErrors (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\helpers\\\\utils.ts:794:21)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\actions\\\\database\\\\insert.operation.ts:265:9)\\n    at ExecuteContext.router (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\actions\\\\router.ts:45:17)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\PostgresV2.node.ts:26:10)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27",["41"],["42"],{"node":"43","data":"44","source":"45"},"manual",{"name":"18","type":"46"},{"version":2,"production":false,"manual":false,"source":"47"},"U2FsdGVkX18bwv3M63CUEazXip/6Vw89ym2QaCBiuWeluFNQkQtta9d6SU2SJzHd7AYk3e0pjGUBZQP3waxI7PU03oGU4PkVSa60PUdc1GKg/JyMaz/K10JGsdARFer14nJvHfBiJ7LiQb/OiPZTTok+qP5TxwHH/atqMKwpitit+vCbq9DWFnvrRXnt47dXlEvZtTbUfYH0WsknNvxKW//9tUZ5bfB8PGwt8NjJEJrEWdVN6l/zp1BItO52GnRp59j7jr1MHBvpZmBvktvPm1l8fPtW78POUtTcjOijq7rIrhbbF3PeorO6TYVZitFyfuFKAxO6pa1v8fuJK3i9vZJy+v/LePBp7qaAHTGjd94whcbLFP2YtMBGQpn8BBoSL7xYpZSY15+/xkzyNKl31AaWZAXWRltEDqT72EEGim1v21Hy2gmswGvChxPP1+g8FnElqG9/f+0qG/RXbVOyFj79E6XYl5Znyx21KNaHmsjJ960VMMQa2RRgkMQqe+EDWWATDouuQTOqezblRrmKDA==",{"resource":"48","operation":"49","schema":"50","table":"51","columns":"52","options":"53"},"n8n-nodes-base.postgres",[-416,-96],"5e4ecc83-c3a8-44df-a88e-84c428cb745c",{"postgres":"54"},{"startTime":1785759026319,"executionIndex":0,"source":"55","hints":"56","executionTime":2,"executionStatus":"57","data":"58"},{"startTime":1785759026330,"executionIndex":1,"source":"59","hints":"60","executionTime":166,"executionStatus":"61","error":"62"},{"parameters":"63","type":"37","typeVersion":2.7,"position":"64","id":"39","name":"10","credentials":"65"},{"main":"66"},{"main":"59"},"n8n-nodes-base.manualTrigger","workflow","database","insert",{"__rl":true,"mode":"67","value":"68"},{"__rl":true,"value":"69","mode":"70"},{"mappingMode":"71","value":"72","matchingColumns":"73","schema":"74","attemptToConvertTypes":false,"convertFieldsToString":false},{"connectionTimeout":30},{"id":"75","name":"76"},[],[],"success",{"main":"77"},["78"],[],"error",{"level":"19","shouldReport":true,"description":"20","tags":"21","timestamp":1785759026462,"context":"22","functionality":"23","name":"24","node":"25","messages":"26","message":"27","stack":"28"},{"resource":"48","operation":"49","schema":"79","table":"80","columns":"81","options":"82"},[-416,-96],{"postgres":"83"},["84"],"list","public","items","name","autoMapInputData",{},[],["85","86"],"aYolIV9R7XB2uz9G","Postgres account",["87"],{"previousNode":"18","previousNodeOutput":0,"previousNodeRun":0},{"__rl":true,"mode":"67","value":"68"},{"__rl":true,"value":"69","mode":"70"},{"mappingMode":"71","value":"88","matchingColumns":"89","schema":"90","attemptToConvertTypes":false,"convertFieldsToString":false},{"connectionTimeout":30},{"id":"75","name":"76"},["91"],{"id":"92","displayName":"92","required":true,"defaultMatch":false,"display":true,"type":"93","canBeUsedToMatch":true},{"id":"70","displayName":"70","required":true,"defaultMatch":false,"display":true,"type":"94","canBeUsedToMatch":true},["95"],{},[],["96","97"],{"json":"98","pairedItem":"99"},"code","number","string",{"json":"98","pairedItem":"100"},{"id":"92","displayName":"92","required":true,"defaultMatch":false,"display":true,"type":"93","canBeUsedToMatch":true},{"id":"70","displayName":"70","required":true,"defaultMatch":false,"display":true,"type":"94","canBeUsedToMatch":true},{},{"item":0},{"item":0}]	6f648c2c-478f-4d22-93aa-b88bc345efee
13	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":[],"schema":[{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"21a46c1a6c8d782079c89adbaf4ec8ec5ae002fe0026730f8c1188eae6b0eca4",{"nodeName":"10","mode":"17"},["18","10"],{"level":"19","shouldReport":true,"description":"20","tags":"21","timestamp":1785759085843,"context":"22","functionality":"23","name":"24","node":"25","messages":"26","message":"27","stack":"28"},{"When clicking ‘Execute workflow’":"29","Insert rows in a table":"30"},{},"Insert rows in a table",{},["31"],{},{},{},{"version":1,"establishedAt":1785759085814,"source":"32","triggerNode":"33","redaction":"34","credentials":"35"},"inclusive","When clicking ‘Execute workflow’","warning","Key (code)=(0) already exists.",{},{},"regular","NodeOperationError",{"parameters":"36","type":"37","typeVersion":2.7,"position":"38","id":"39","name":"10","credentials":"40"},[],"duplicate key value violates unique constraint \\"items_pkey\\"","NodeOperationError: duplicate key value violates unique constraint \\"items_pkey\\"\\n    at parsePostgresError (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\helpers\\\\utils.ts:123:9)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\helpers\\\\utils.ts:398:19\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at runQueriesAndHandleErrors (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\helpers\\\\utils.ts:794:21)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\actions\\\\database\\\\insert.operation.ts:265:9)\\n    at ExecuteContext.router (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\actions\\\\router.ts:45:17)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Postgres\\\\v2\\\\PostgresV2.node.ts:26:10)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27",["41"],["42"],{"node":"43","data":"44","source":"45"},"manual",{"name":"10","type":"37"},{"version":2,"production":false,"manual":false,"source":"46"},"U2FsdGVkX19scqxUBnOx1wKs5r7XF7P/SfQiXxN9vfv4kwyRzX+SKSN2IWXSC1f+6bLhaDBncxGxjwgmcTjJvb7xmMVZL37SL3asxLjclZVic8J5WQhVR+RS1dl44fUDjF6paLLUwfE70MXaxKXZMYtPLV0mAk+p6LQL4v2ggiTypncsB7aKghHwhaX6z0ySnJYk9Qlq7topATqXrNzSwfWLtEhBCbwPbnGtdrPu00I/xqH2PTBqHsxUAVIe4MMLKGPEfGygVbHeRnm6omcfiABosvwqHDpEUA4HacOJ3wdSgT9X0hQ6VWLud44AW40CYn7T0wT/BerVEWmZkCMXUbpjCEDxwsLunntiwzX9aHEwD/ZOQNWoHm3+pdwa3Mmit910V/2dSNsBK2j9EX5tbxSNIOOJpGeStx1qJ+bVSpFBgU09nJgiaT7FUFc1ko5s/V5ulhKsVEy70bNkssHGC32prtU4Eikg6tQiOYM/JOimYaaxMJbc6sbrWxfPJzZe5gT4d+wDm7TmAJVuCCA8ug==",{"resource":"47","operation":"48","schema":"49","table":"50","columns":"51","options":"52"},"n8n-nodes-base.postgres",[-416,-96],"5e4ecc83-c3a8-44df-a88e-84c428cb745c",{"postgres":"53"},{"startTime":1785759026319,"executionIndex":0,"source":"54","hints":"55","executionTime":2,"executionStatus":"56","data":"57"},{"startTime":1785759085829,"executionIndex":1,"source":"58","hints":"59","executionTime":16,"executionStatus":"60","error":"61"},{"parameters":"62","type":"37","typeVersion":2.7,"position":"63","id":"39","name":"10","credentials":"64"},{"main":"65"},{"main":"58"},"workflow","database","insert",{"__rl":true,"mode":"66","value":"67"},{"__rl":true,"value":"68","mode":"69"},{"mappingMode":"70","value":"71","matchingColumns":"72","schema":"73","attemptToConvertTypes":false,"convertFieldsToString":false},{"connectionTimeout":30},{"id":"74","name":"75"},[],[],"success",{"main":"76"},["77"],[],"error",{"level":"19","shouldReport":true,"description":"20","tags":"21","timestamp":1785759085843,"context":"22","functionality":"23","name":"24","node":"25","messages":"26","message":"27","stack":"28"},{"resource":"47","operation":"48","schema":"78","table":"79","columns":"80","options":"81"},[-416,-96],{"postgres":"82"},["83"],"list","public","items","name","autoMapInputData",{},[],["84","85"],"aYolIV9R7XB2uz9G","Postgres account",["86"],{"previousNode":"18","previousNodeOutput":0,"previousNodeRun":0},{"__rl":true,"mode":"66","value":"67"},{"__rl":true,"value":"68","mode":"69"},{"mappingMode":"70","value":"87","matchingColumns":"88","schema":"89","attemptToConvertTypes":false,"convertFieldsToString":false},{"connectionTimeout":30},{"id":"74","name":"75"},["90"],{"id":"91","displayName":"91","required":false,"defaultMatch":false,"display":true,"type":"92","canBeUsedToMatch":true,"removed":false},{"id":"69","displayName":"69","required":false,"defaultMatch":false,"display":true,"type":"93","canBeUsedToMatch":true,"removed":false},["94"],{},[],["95","96"],{"json":"97","pairedItem":"98"},"code","number","string",{"json":"97","pairedItem":"99"},{"id":"91","displayName":"91","required":false,"defaultMatch":false,"display":true,"type":"92","canBeUsedToMatch":true,"removed":false},{"id":"69","displayName":"69","required":false,"defaultMatch":false,"display":true,"type":"93","canBeUsedToMatch":true,"removed":false},{},{"item":0},{"item":0}]	b1c61506-057e-4560-b4fc-441b85ee6f70
15	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"runData":"7","pinData":"8","lastNodeExecuted":"9"},{"contextData":"10","nodeExecutionStack":"11","metadata":"12","waitingExecution":"13","waitingExecutionSource":"14","runtimeData":"15"},"cdb7b6e01b7f53a5352469084a0a3a3065a8683ecd58eb7ed1e00af502b45649",{"nodeName":"9","mode":"16"},["17","9"],{"When clicking ‘Execute workflow’":"18","Insert rows in a table":"19"},{},"Insert rows in a table",{},[],{},{},{},{"version":1,"establishedAt":1785759166433,"source":"20","triggerNode":"21","redaction":"22","credentials":"23"},"inclusive","When clicking ‘Execute workflow’",["24"],["25"],"manual",{"name":"9","type":"26"},{"version":2,"production":false,"manual":false,"source":"27"},"U2FsdGVkX1+rZApZH5DyPuKNXBQCMDo2wsi+RFihbi5JMVFI0MomU0z9I7L+BCLnkvVLNEGK4ePn47H6q03DIfYn6Xcxmk3K+kun12AuID3lkb1fPqTcptezHgTxm3gfG99/s5IR0vF6a1HNNTAIa9aITh+0QDxcjHzmun1EtDFJ+ha/SJHsh0Wk9nVwLyjtmK2buLcNj0diNMjWuV892/gvYt5gQvZAUTpTQciecSJ8CuYxBK6tiNTz/xq7pV5jC69a1vuAL2BH6adoIeBnlK+6EBE2X0m28WPjsj99CmVygiype5OQZqtuQfEVX+IaoHw6SAiAavBzAQyKpuQ8eXSq7KH/la6LTeGVm7GkWqTiYCBDYy9FNl/JxNXlGL+Cobx5FhA4C443cMEFUFEaF88t+psvYQ/LGmsehG79kne7gGLoms8bTioFf6Lr7hM4Li+5lf8pJe+T9OIT8mOp9d2/4lvU5t6hjGZuQqVlxlE3geKqx7uKTEm7vxnn+LtvL/741ENgCCmGBOj0YwlSmg==",{"startTime":1785759026319,"executionIndex":0,"source":"28","hints":"29","executionTime":2,"executionStatus":"30","data":"31"},{"startTime":1785759166449,"executionIndex":1,"source":"32","hints":"33","executionTime":13,"executionStatus":"30","data":"34"},"n8n-nodes-base.postgres","workflow",[],[],"success",{"main":"35"},["36"],[],{"main":"37"},["38"],{"previousNode":"17","previousNodeOutput":0,"previousNodeRun":0},["39"],["40"],["41"],{"json":"42","pairedItem":"43"},{"json":"44","pairedItem":"45"},{},{"item":0},{"id":"46","code":null,"name":null},{"item":0},"2"]	b0431185-9ba0-44eb-af73-ba35927e2be4
16	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"runData":"7","pinData":"8","lastNodeExecuted":"9"},{"contextData":"10","nodeExecutionStack":"11","metadata":"12","waitingExecution":"13","waitingExecutionSource":"14","runtimeData":"15"},"98fdab2bc1695cb19aa46850a66bc6004332c09089cd81169ea13fd2372981e3",{"nodeName":"9","mode":"16"},["17","9"],{"When clicking ‘Execute workflow’":"18","Insert rows in a table":"19"},{},"Insert rows in a table",{},[],{},{},{},{"version":1,"establishedAt":1785759167631,"source":"20","triggerNode":"21","redaction":"22","credentials":"23"},"inclusive","When clicking ‘Execute workflow’",["24"],["25"],"manual",{"name":"9","type":"26"},{"version":2,"production":false,"manual":false,"source":"27"},"U2FsdGVkX18TQQivBHXM/DDCk92QWKySyfyY0AToSuVd5zR1r+iQsNbAbX2nD4/zxv7UxJ5boS/smcqNW/Vc1z6nqWtgK9nvLBBD8vRbsfrARm0qLYA+h5ILYYkI4TlNskToWTbnAxRORsJrQaF0JMZvXd1s8/OjulFQTQ+xWK9mQpVoDAe7E4nI4z2x45KwZQvM+N0JORGlp5ylHQ7ckkRWoz/bPJU2Vcx2l2W1sGkpV+1u++LD/higxltBc586UpE/T5C+GqELQSeomREYdJUh/k0J5Pl9R76uPAX7Nl1b+GxMYntjw/gg9fNz4G0TFYJKUFBJ7YD7gf4BL93fU31wJ52VKpjUe89la+mLmgYOccjKDHcCMygpoD5s4aQODhAoWiUPTAVZjO2SXMh5flxmhQuTIXcSDiKh+l8vJzmRRxJevKBFGEoEerMHY5oCSOwGemVaWOuZJWAWdbjYemfV69NO4zKrpGZcA+whfazJnvYNXMyLwZL+pSuZe+ew4UnxfNndLSdPBDRXVsibeA==",{"startTime":1785759026319,"executionIndex":0,"source":"28","hints":"29","executionTime":2,"executionStatus":"30","data":"31"},{"startTime":1785759167657,"executionIndex":1,"source":"32","hints":"33","executionTime":10,"executionStatus":"30","data":"34"},"n8n-nodes-base.postgres","workflow",[],[],"success",{"main":"35"},["36"],[],{"main":"37"},["38"],{"previousNode":"17","previousNodeOutput":0,"previousNodeRun":0},["39"],["40"],["41"],{"json":"42","pairedItem":"43"},{"json":"44","pairedItem":"45"},{},{"item":0},{"id":"46","code":null,"name":null},{"item":0},"3"]	b0431185-9ba0-44eb-af73-ba35927e2be4
17	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"runData":"7","pinData":"8","lastNodeExecuted":"9"},{"contextData":"10","nodeExecutionStack":"11","metadata":"12","waitingExecution":"13","waitingExecutionSource":"14","runtimeData":"15"},"8ee7e31aa01de2032dbb1346328e7d04d8dd5fa96c30e98ccf41db38e5550526",{"nodeName":"9","mode":"16"},["17","9"],{"When clicking ‘Execute workflow’":"18","Insert rows in a table":"19"},{},"Insert rows in a table",{},[],{},{},{},{"version":1,"establishedAt":1785759168819,"source":"20","triggerNode":"21","redaction":"22","credentials":"23"},"inclusive","When clicking ‘Execute workflow’",["24"],["25"],"manual",{"name":"9","type":"26"},{"version":2,"production":false,"manual":false,"source":"27"},"U2FsdGVkX1/NJZ4Ash6XY6wYBz4o/bW6ftGT2StlYJ9/z7/pvcHaaLPNtKr8fDs0vQ1H4MJU6icJOOFB1SUeXEfgah1Jzn0BGXK9GG6ivbe8X1d3Wa/1U6KsKKOaPykbuKeujmBbK1tr6d+eE+KeJeDsv2AIMNljgHBWm2nwBfuXPUP0Uz2wpfEvHrhnJ3FvrGADqI4ThCHOF/2Eadh0URUVtoZ065TpFzBLwKBTdUfi9AXL+XVeG/MBnUvPUZs/8x2CD6u0bMEFHUGed/GyL4Tfl8rUG8IWkJv9Kga/t2+unyy5fX1/YmPY9Gv1gY6S6v+mAQRBiO5x9xrC5sjtxVNiLPwhZcQMzUnhhRQsd4Wjj6FI2FDv0VFtAwOwGPDHeWQiRpbDopQ8jnokKPfF6ZesaZ5WL8Bpk2Ps4bl1z29iwvM0jYQOx3c5jKmk/QGoz3OvhcikfJLNoulEydgNANaTUouqK9HbYPfxMZU/8XP+bPDfaKc3F4NqVg1ZTri5tGH3alSGBYMSJSv35oLDUg==",{"startTime":1785759026319,"executionIndex":0,"source":"28","hints":"29","executionTime":2,"executionStatus":"30","data":"31"},{"startTime":1785759168830,"executionIndex":1,"source":"32","hints":"33","executionTime":16,"executionStatus":"30","data":"34"},"n8n-nodes-base.postgres","workflow",[],[],"success",{"main":"35"},["36"],[],{"main":"37"},["38"],{"previousNode":"17","previousNodeOutput":0,"previousNodeRun":0},["39"],["40"],["41"],{"json":"42","pairedItem":"43"},{"json":"44","pairedItem":"45"},{},{"item":0},{"id":"46","code":null,"name":null},{"item":0},"4"]	b0431185-9ba0-44eb-af73-ba35927e2be4
18	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"runData":"7","pinData":"8","lastNodeExecuted":"9"},{"contextData":"10","nodeExecutionStack":"11","metadata":"12","waitingExecution":"13","waitingExecutionSource":"14","runtimeData":"15"},"dc98687a5adc08bb759105033be1013a2a8b7941d6120ea92110d584da4aa3db",{"nodeName":"9","mode":"16"},["17","9"],{"When clicking ‘Execute workflow’":"18","Insert rows in a table":"19"},{},"Insert rows in a table",{},[],{},{},{},{"version":1,"establishedAt":1785759210580,"source":"20","triggerNode":"21","redaction":"22","credentials":"23"},"inclusive","When clicking ‘Execute workflow’",["24"],["25"],"manual",{"name":"9","type":"26"},{"version":2,"production":false,"manual":false,"source":"27"},"U2FsdGVkX19vEZw4mKXEyQlCF44h2VdhJnJaJ5zxX0LQh8T/ClyYaBoi5AO5mpOXIS2W+umUlMxQhfCCnIzDZZn/MAFSmOaoOIWwhZHkEWwXCvg9FYUvGNrP1oRHpv1e5T8rgmm1bATb2fiuICVdqy30ZLHPgns1afdsEv0h97GItPeeXjFluYUpGqhetebk//DETM2g/Wy0u/JjP6q9cEOZWAU26sOdkYVQIq00ZpW7NfP2of9nT0To/i4LiNWJd3k5ikngUuL8AmzZHZMZMfg1yAvC4OntzPmHig0RmQW4yF2jrbZoP8WyexXLb50xFfO/4qwbP5G32cqfCA4A+KtuqliwqzYxXKR+cwjFUwqFSGVGBvDKqydn0hws1cFqSwIpUyqoybLkhnmKuR0V/DvFSsM45QVv721Kx7NrA/Q9hWt1PasOvZmEu0hIWZuAeS5i3x46M+V96EQQuSzqUClvlzhIDMq1ZKp7mk1J8GZkWILXAJ/4i9Z8GgecQn5PMK1d5yPPy0nXX0y8fwbB3Q==",{"startTime":1785759026319,"executionIndex":0,"source":"28","hints":"29","executionTime":2,"executionStatus":"30","data":"31"},{"startTime":1785759210598,"executionIndex":1,"source":"32","hints":"33","executionTime":73,"executionStatus":"30","data":"34"},"n8n-nodes-base.postgres","workflow",[],[],"success",{"main":"35"},["36"],[],{"main":"37"},["38"],{"previousNode":"17","previousNodeOutput":0,"previousNodeRun":0},["39"],["40"],["41"],{"json":"42","pairedItem":"43"},{"json":"44","pairedItem":"45"},{},{"item":0},{"id":"46","code":null,"name":null},{"item":0},"5"]	b0431185-9ba0-44eb-af73-ba35927e2be4
19	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"runData":"5","pinData":"6","lastNodeExecuted":"7"},{"contextData":"8","nodeExecutionStack":"9","metadata":"10","waitingExecution":"11","waitingExecutionSource":"12","runtimeData":"13"},"8947b7edce6d367eb6a4936e2c0db42786bd442738fb49f5876dc8caa58647bb",{"When clicking ‘Execute workflow’":"14","Insert rows in a table":"15"},{},"Insert rows in a table",{},[],{},{},{},{"version":1,"establishedAt":1785759218729,"source":"16","triggerNode":"17","redaction":"18","credentials":"19"},["20"],["21"],"manual",{"name":"22","type":"23"},{"version":2,"production":false,"manual":false,"source":"24"},"U2FsdGVkX19Hpy19qPMjGm6q7PYX3Djxin91nfVgI4HuNPesQyEoLXhIvDxbmzFEX+CllhubW6KM+QnszCQksg9jPZ9K/tlEkBum8KEjXFg4g1XJuzzLN5FdaTQox/DiQvUFtLRHZFA0LxN6yIzN3a8QT5NuWMmmVMYOVWvKuCejPADQE2lR4AWSPNs37MLyivKeXIfGTm+GJ88B2/NxctLI0+QYXJ/oBwVRMoP9XxI8MwVgUWTBamZO4VYUIeM+O90tzQsRO8cj2r7F/eqldNaccQO3kZpIY1CQNGDQL91a/78iWM3yypskavccIWZzEEGfWK7QzngTHPz2QaXNqNmsO4KiLBl6Utn0Cp5w4VTfV4PrZXJmJ1+ib94d2xzDn6qgD1mGLTaiXrt4j1eiahUhIJ1S/e8Z6/tm7cP1taSu99YJd0GZq513XACuA7l3Urx9VfLBfPYuxvFyRmyjZX00V2bJrV4M6QbqaH0q9tvFLZ7W/itMMhq/L8b8tygkHAZ3Qdg22A/xIDrygFu3sw==",{"startTime":1785759218742,"executionIndex":0,"source":"25","hints":"26","executionTime":1,"executionStatus":"27","data":"28"},{"startTime":1785759218744,"executionIndex":1,"source":"29","hints":"30","executionTime":23,"executionStatus":"27","data":"31"},"When clicking ‘Execute workflow’","n8n-nodes-base.manualTrigger","workflow",[],[],"success",{"main":"32"},["33"],[],{"main":"34"},["35"],{"previousNode":"22","previousNodeOutput":0,"previousNodeRun":0},["36"],["37"],["38"],{"json":"39","pairedItem":"40"},{"json":"41","pairedItem":"42"},{},{"item":0},{"id":"43","code":null,"name":null},{"item":0},"6"]	b0431185-9ba0-44eb-af73-ba35927e2be4
20	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"","text":"","replyMarkup":"none","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-208,-96],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"f48a939ffb410772d9412fd732d851429167db2cb6554d27dd3d5f2628cb9417",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785759263444,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Send a text message' node has issues:\\n- Parameter \\"Chat ID\\" is required.\\n- Parameter \\"Text\\" is required.","WorkflowHasIssuesError: The 'Send a text message' node has issues:\\n- Parameter \\"Chat ID\\" is required.\\n- Parameter \\"Text\\" is required.\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.runPartialWorkflow2 (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:328:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:191:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	14802506-f2f9-41b6-bb75-bb3cd06705e6
24	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"runData":"7","pinData":"8","lastNodeExecuted":"9"},{"contextData":"10","nodeExecutionStack":"11","metadata":"12","waitingExecution":"13","waitingExecutionSource":"14","runtimeData":"15"},"14f2ca4ba41c22e10f9aa8ad0a20d82eec3dabc29792bd224e71aa9660914ca8",{"nodeName":"9","mode":"16"},["17","9"],{"When clicking ‘Execute workflow’":"18","Select rows from a table":"19"},{},"Select rows from a table",{},[],{},{},{},{"version":1,"establishedAt":1785759376516,"source":"20","triggerNode":"21","redaction":"22","credentials":"23"},"inclusive","When clicking ‘Execute workflow’",["24"],["25"],"manual",{"name":"9","type":"26"},{"version":2,"production":false,"manual":false,"source":"27"},"U2FsdGVkX1+TitKE2NFH7GmZQiMDYHLvu0PR+CAM0zQP5PC4TWTDwSIQYfq1GwbUoFgAmb8P3YRjzjmI5ry6yoJG+An3AhnAX+0cLKJv+vIxodjYUBRuEDCCJMIGzGTFg16gkwjqMb/kBevWvTCim79V3G5qAQ2rhoq1of1g8vA0nIbSJamqXB9Yqr49/2TjnAOCA1DbZKbQm14GazHKPmWzHnI9tga5O5tpHmZ1i4d71F5m0tEPTSl0MSijxLcx3rGbHMOlY3j9v0gjGAb6Vvr/cPf/6QpZMIIn7r8oAC3pYeEG6FQjKc4edwu4YZj8dLDZRdgpMJHVtCRRMneIh+W+vcrYfTipxcP3j9HXCYspysKhqbFql7vAidTygndit/W/7fpzjdlt8iP20Z1MaG/C1n8g3htlE5olSEoklMi2q+oKRbVYOAxmMSKZ29IVeQmp7v7XymqVIy7gK/NC88mm2BeyCU5thufZA35ILLdH5vOcMOC/KfKpf38yVUsiZ/3e/3X78ztvQMdS/GGAuA==",{"startTime":1785759284602,"executionIndex":0,"source":"28","hints":"29","executionTime":2,"executionStatus":"30","data":"31"},{"startTime":1785759376606,"executionIndex":1,"source":"32","hints":"33","executionTime":79,"executionStatus":"30","data":"34"},"n8n-nodes-base.postgres","workflow",[],[],"success",{"main":"35"},["36"],[],{"main":"37"},["38"],{"previousNode":"17","previousNodeOutput":0,"previousNodeRun":0},["39"],["40"],["41","42","43","44","45","46","47","48"],{"json":"49","pairedItem":"50"},{"json":"51","pairedItem":"52"},{"json":"53","pairedItem":"52"},{"json":"54","pairedItem":"52"},{"json":"55","pairedItem":"52"},{"json":"56","pairedItem":"52"},{"json":"57","pairedItem":"52"},{"json":"58","pairedItem":"52"},{"json":"59","pairedItem":"52"},{},{"item":0},{"id":"60","code":null,"name":null},{"item":0},{"id":"61","code":null,"name":null},{"id":"62","code":null,"name":null},{"id":"63","code":null,"name":null},{"id":"64","code":null,"name":null},{"id":"65","code":null,"name":null},{"id":"66","code":null,"name":null},{"id":"67","code":null,"name":null},"1","2","3","4","5","6","7","8"]	3bf80a3f-03a4-4623-9cf8-577c2fc04ba1
21	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"none","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-208,-96],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"ad33c01f149c7d4f8f00f54f303c99d6d6c9a84d52cc1aa04257420b599a34d9",{"nodeName":"10","mode":"17"},["18","19","10"],{"level":"20","shouldReport":true,"description":"21","tags":"22","timestamp":1785759285873,"context":"23","functionality":"24","name":"25","node":"26","messages":"27","httpCode":"28","message":"29","stack":"30"},{"When clicking ‘Execute workflow’":"31","Insert rows in a table":"32","Send a text message":"33"},{},"Send a text message",{},["34"],{},{},{},{"version":1,"establishedAt":1785759284570,"source":"35","triggerNode":"36","redaction":"37","credentials":"38"},"inclusive","When clicking ‘Execute workflow’","Insert rows in a table","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"39","type":"40","typeVersion":1.2,"position":"41","id":"42","name":"10","webhookId":"43","credentials":"44"},["45"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["46"],["47"],["48"],{"node":"49","data":"50","source":"51"},"manual",{"name":"18","type":"52"},{"version":2,"production":false,"manual":false,"source":"53"},"U2FsdGVkX19X2GGjfiwayPmZxI4ZIShIzsdIyhxEgNuMS+Ic8C9XJ85v54GEAYaJYXEZUt8AKF0ovrJ0jfDksym2vO3z3IghO9NmDPXakQJtGEcsXk3kqT0mjcarf/kLv0DlcYKdTqAvJfCY2hgJ0IeDC9P9QdibyQlbjCCCJ4y0tyQ96KJlZ8lNDEta82YckTSbbUyaDK/hdx0pJ0zmS5doi3FHd36rzeCSarDFJnTJlh8b4DwBQEqTf5XjRQZZWUVDPzYo3rkwQ7L4YW/m86zMNfVM2oE5DfFeGR0/EXfIvJHfjBHHytLoFRo16a3KJxvGbipFYK/3tRxnkuw5e9UCfVa5amfx426LRVtRRvlfivw6wX7zwosI/uF0ZIqaCDWACfmtJScbzsJ4QlEcrBmB7vGoTbHMFfpejWwsRye1kBBl0vALpwhzlN9spA3rpADx7Qr1SSC1qR0+5t4rgRw4JEWxgNHd96lkr02qgt23Q4XAMd8ybWPEF5H8inkVJ7Dh3JV/N5mn9iDDTfh+pg==",{"resource":"54","operation":"55","chatId":"56","text":"56","replyMarkup":"57","additionalFields":"58"},"n8n-nodes-base.telegram",[-208,-96],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"59"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785759284602,"executionIndex":0,"source":"60","hints":"61","executionTime":2,"executionStatus":"62","data":"63"},{"startTime":1785759284605,"executionIndex":1,"source":"64","hints":"65","executionTime":131,"executionStatus":"62","data":"66"},{"startTime":1785759284740,"executionIndex":2,"source":"67","hints":"68","executionTime":1146,"executionStatus":"69","error":"70"},{"parameters":"71","type":"40","typeVersion":1.2,"position":"72","id":"42","name":"10","webhookId":"43","credentials":"73"},{"main":"74"},{"main":"67"},"n8n-nodes-base.manualTrigger","workflow","message","sendMessage","1","none",{},{"id":"75","name":"76"},[],[],"success",{"main":"77"},["78"],[],{"main":"79"},["80"],[],"error",{"level":"20","shouldReport":true,"description":"21","tags":"22","timestamp":1785759285873,"context":"23","functionality":"24","name":"25","node":"26","messages":"27","httpCode":"28","message":"29","stack":"30"},{"resource":"54","operation":"55","chatId":"56","text":"56","replyMarkup":"57","additionalFields":"81"},[-208,-96],{"telegramApi":"82"},["83"],"SXr9kdhP2pbmSSl5","Telegram account",["84"],{"previousNode":"18","previousNodeOutput":0,"previousNodeRun":0},["85"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},{},{"id":"75","name":"76"},["86"],["87"],["88"],{"json":"89","pairedItem":"90"},{"json":"91","pairedItem":"92"},{"json":"89","pairedItem":"93"},{"id":"94","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"7"]	1d17aef2-32be-41a4-994b-a91dd007fc2e
22	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-208,-96],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"2771b2082bd6765bea953cad7cccc509e3319e62d0188df410a22274ee960fd3",{"nodeName":"10","mode":"17"},["18","19","10"],{"level":"20","shouldReport":true,"description":"21","tags":"22","timestamp":1785759310552,"context":"23","functionality":"24","name":"25","node":"26","messages":"27","httpCode":"28","message":"29","stack":"30"},{"When clicking ‘Execute workflow’":"31","Insert rows in a table":"32","Send a text message":"33"},{},"Send a text message",{},["34"],{},{},{},{"version":1,"establishedAt":1785759309453,"source":"35","triggerNode":"36","redaction":"37","credentials":"38"},"inclusive","When clicking ‘Execute workflow’","Insert rows in a table","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"39","type":"40","typeVersion":1.2,"position":"41","id":"42","name":"10","webhookId":"43","credentials":"44"},["45"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["46"],["47"],["48"],{"node":"49","data":"50","source":"51"},"manual",{"name":"10","type":"40"},{"version":2,"production":false,"manual":false,"source":"52"},"U2FsdGVkX1+2Tlpqu3fEYnaSCxiIpq+YLOj7+Vdk/p1pR5RjJlHIaTtAc4ZKSYUiwV7tYEzjl5ovnqu34pbHOyDjZa0nLDsGmw/m4tJDPZ+4RPLwmdALJ/lhBMa+DrqMs+apUKWpwxGwUx53iJdkpVoeQIYpDDR54C+40P2lGQ3KYniyv7tfslfSRW6Gq12M35a6Rj8ySGNMMhrI/O2EcYcfbQGa6P7I+aHz0uG6uM6/mAuESMVewKAjIW7zr1XfYhyn9VbKGMvocoQj06kRr92P8Taj+mgMpUbWPGKl4BnGR5sRUmAu7cXRMQ7aF9tAjkfzImhN41kY/CJlcgvyOGfqECaXoGRTUAViE6/ORvVBUrTV/OpGmz0IWnIC64SB4dH7PDw6e2CPiZT6aM06Z8OsFs/dwOFHvxue9GsoP23f1bpMAjydyPXm63aZ61JmBufRxadPnvk8WzkSrqTPMTIGy2Y/eudeHWeJheVqwWD02wSN9iC0I87ZbxuXgM9tYWpkPc5JGlHSyhl9CBYBGQ==",{"resource":"53","operation":"54","chatId":"55","text":"55","replyMarkup":"56","forceReply":"57","additionalFields":"58"},"n8n-nodes-base.telegram",[-208,-96],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"59"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785759284602,"executionIndex":0,"source":"60","hints":"61","executionTime":2,"executionStatus":"62","data":"63"},{"startTime":1785759284605,"executionIndex":1,"source":"64","hints":"65","executionTime":131,"executionStatus":"62","data":"66"},{"startTime":1785759309471,"executionIndex":2,"source":"67","hints":"68","executionTime":1085,"executionStatus":"69","error":"70"},{"parameters":"71","type":"40","typeVersion":1.2,"position":"72","id":"42","name":"10","webhookId":"43","credentials":"73"},{"main":"74"},{"main":"67"},"workflow","message","sendMessage","1","forceReply",{"force_reply":false},{},{"id":"75","name":"76"},[],[],"success",{"main":"77"},["78"],[],{"main":"79"},["80"],[],"error",{"level":"20","shouldReport":true,"description":"21","tags":"22","timestamp":1785759310552,"context":"23","functionality":"24","name":"25","node":"26","messages":"27","httpCode":"28","message":"29","stack":"30"},{"resource":"53","operation":"54","chatId":"55","text":"55","replyMarkup":"56","forceReply":"81","additionalFields":"82"},[-208,-96],{"telegramApi":"83"},["84"],"SXr9kdhP2pbmSSl5","Telegram account",["85"],{"previousNode":"18","previousNodeOutput":0,"previousNodeRun":0},["86"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},{"force_reply":false},{},{"id":"75","name":"76"},["87"],["88"],["89"],{"json":"90","pairedItem":"91"},{"json":"92","pairedItem":"93"},{"json":"90","pairedItem":"94"},{"id":"95","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"7"]	0de289c3-316f-4ecc-a7d4-10f0ce924711
23	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"runData":"7","pinData":"8","lastNodeExecuted":"9"},{"contextData":"10","nodeExecutionStack":"11","metadata":"12","waitingExecution":"13","waitingExecutionSource":"14","runtimeData":"15"},"081b98482a5e7e5884051b18735eee6d4b326d1dc021ae005df97bb0e2270168",{"nodeName":"9","mode":"16"},["17","9"],{"When clicking ‘Execute workflow’":"18","Insert rows in a table":"19"},{},"Insert rows in a table",{},[],{},{},{},{"version":1,"establishedAt":1785759341470,"source":"20","triggerNode":"21","redaction":"22","credentials":"23"},"inclusive","When clicking ‘Execute workflow’",["24"],["25"],"manual",{"name":"9","type":"26"},{"version":2,"production":false,"manual":false,"source":"27"},"U2FsdGVkX1+80nT5EWAecw5fJJQtt3JM6fP+7+/8NxjuLkJ+BXRHIsv+QWTMnAFark0IdZhBzQbdWVSHN4glX5zqnB76OoGdUPGwsJF1gYWlaSrYD8vw4ZBpdf4aMa04Tu5S04y2JlgRfDgdagBM5ceKYGQEXpm0tuwLzJEnd4AyubYOx+TQhHXDR6WGMqrslLlltxl6IE+PQj6truPBa+pmnmy5JjmayznINFhGeUUJKXJ/IWf80qMNze6WyV/2eaESXX17shYg/4c1yHQ5a2Bx/cOWHX3b0r/y8aOP5uFUoYE/hlB7/ZTM9Zuhkv2pShuQiAiuXkmHbVRNN1NzwG0bRDm+aRVR18TgfSZaIxORP4+SjgY3ic8xuK1fDvMyLJq7Z+JMB267E9UNBTFUdSUO/G9w5eDpi9QFnPyhfwXHprd7k4hUNQbb3nemjtxeezzbGzcD/1ZF6x8F4yLqhduB+aeECEo+ITvYRM8WvPQHP5cFfv6S2vHWnnWTnUWBvkf/LCeUEJTh1jIYMLf+6A==",{"startTime":1785759284602,"executionIndex":0,"source":"28","hints":"29","executionTime":2,"executionStatus":"30","data":"31"},{"startTime":1785759341513,"executionIndex":1,"source":"32","hints":"33","executionTime":193,"executionStatus":"30","data":"34"},"n8n-nodes-base.postgres","workflow",[],[],"success",{"main":"35"},["36"],[],{"main":"37"},["38"],{"previousNode":"17","previousNodeOutput":0,"previousNodeRun":0},["39"],["40"],["41"],{"json":"42","pairedItem":"43"},{"json":"44","pairedItem":"45"},{},{"item":0},{"id":"46","code":null,"name":null},{"item":0},"8"]	b9b16aa7-8765-4348-af12-78c63cdbb451
25	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6","pinData":"7","lastNodeExecuted":"8"},{"contextData":"9","nodeExecutionStack":"10","metadata":"11","waitingExecution":"12","waitingExecutionSource":"13","runtimeData":"14"},"12c220258689d58fe1a135c4df3d33980552812afc2b5be290d7ea9476d92e30",{"level":"15","shouldReport":true,"description":"16","tags":"17","timestamp":1785759396818,"context":"18","functionality":"19","name":"20","node":"21","messages":"22","httpCode":"23","message":"24","stack":"25"},{"When clicking ‘Execute workflow’":"26","Insert rows in a table":"27","Send a text message":"28"},{},"Send a text message",{},["29","30"],{},{},{},{"version":1,"establishedAt":1785759395597,"source":"31","triggerNode":"32","redaction":"33","credentials":"34"},"warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"35","type":"36","typeVersion":1.2,"position":"37","id":"38","name":"8","webhookId":"39","credentials":"40"},["41"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["42"],["43"],["44"],{"node":"45","data":"46","source":"47"},{"node":"48","data":"49","source":"50"},"manual",{"name":"51","type":"52"},{"version":2,"production":false,"manual":false,"source":"53"},"U2FsdGVkX19y5kbBsZ3UltDEqFoYtWtIZ3Nwu0HIwn95v2uauyPLDGkFS1WNgHxHf0DgcCEx/DEJCVKXGCT4hxgQeq5iVnWW3nKMwylQhxufGY36/wP+HpKP5ublhU71vwWSx1GbuV6Zvqt9B8Xqj5AotJmuueDiqB9N3Y+fuw1+jZPBmaX8spsUJMAcg7Ke6PXZDSyePMTzMqfBaUeqbQBjCOeQdaxO3IJtu7qD6J+3V+gTCyruEXKqXJrIkUQIpROoIb3hTWLYpJmaPYFEd3+keSIfqAWJppIVDhcrwQuILdTbKa2aK6hZUjREY8tgq3LxuxG8RF+poJNsMBzxs+A80Y+gfLdREW+5nix0NbfI9UxfSDE/cyQanuCHSJWu9VVtwwoD2qSBbpK8Am7qhI2SsQzgyHDQYEZsyQafw6zWdPBqCxBIXc72RElmG+UqOqPL9WphqtCBxAvqdefw5+qo7RTxl+1+EmTTfcfvBmwj3msNqpUFJZyrlysNQ9HexxdC2icye3Up+4MGM2F6JA==",{"resource":"54","operation":"55","chatId":"56","text":"56","replyMarkup":"57","forceReply":"58","additionalFields":"59"},"n8n-nodes-base.telegram",[-224,-80],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"60"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785759395627,"executionIndex":0,"source":"61","hints":"62","executionTime":1,"executionStatus":"63","data":"64"},{"startTime":1785759395630,"executionIndex":1,"source":"65","hints":"66","executionTime":102,"executionStatus":"63","data":"67"},{"startTime":1785759395733,"executionIndex":2,"source":"68","hints":"69","executionTime":1086,"executionStatus":"70","error":"71"},{"parameters":"72","type":"36","typeVersion":1.2,"position":"73","id":"38","name":"8","webhookId":"39","credentials":"74"},{"main":"75"},{"main":"68"},{"parameters":"76","type":"77","typeVersion":2.7,"position":"78","id":"79","name":"80","credentials":"81"},{"main":"82"},{"main":"83"},"When clicking ‘Execute workflow’","n8n-nodes-base.manualTrigger","workflow","message","sendMessage","1","forceReply",{"force_reply":false},{},{"id":"84","name":"85"},[],[],"success",{"main":"86"},["87"],[],{"main":"88"},["89"],[],"error",{"level":"15","shouldReport":true,"description":"16","tags":"17","timestamp":1785759396818,"context":"18","functionality":"19","name":"20","node":"21","messages":"22","httpCode":"23","message":"24","stack":"25"},{"resource":"54","operation":"55","chatId":"56","text":"56","replyMarkup":"57","forceReply":"90","additionalFields":"91"},[-224,-80],{"telegramApi":"92"},["93"],{"resource":"94","operation":"95","schema":"96","table":"97","returnAll":false,"limit":50,"where":"98","combineConditions":"99","sort":"100","options":"101"},"n8n-nodes-base.postgres",[-512,112],"3c35274e-a775-413c-9f2d-b3981e7964d5","Select rows from a table",{"postgres":"102"},["103"],["104"],"SXr9kdhP2pbmSSl5","Telegram account",["103"],{"previousNode":"51","previousNodeOutput":0,"previousNodeRun":0},["105"],{"previousNode":"106","previousNodeOutput":0,"previousNodeRun":0},{"force_reply":false},{},{"id":"84","name":"85"},["107"],"database","select",{"__rl":true,"mode":"108","value":"109"},{"__rl":true,"value":"110","mode":"111"},{},"AND",{},{"connectionTimeout":30},{"id":"112","name":"113"},["114"],{"previousNode":"51","previousNodeOutput":0,"previousNodeRun":0},["115"],"Insert rows in a table",{"json":"116","pairedItem":"117"},"list","public","items","name","aYolIV9R7XB2uz9G","Postgres account",{"json":"118","pairedItem":"119"},{"json":"116","pairedItem":"120"},{"id":"121","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"9"]	3bf80a3f-03a4-4623-9cf8-577c2fc04ba1
26	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"triggerNotice":"","operation":"page","defineForm":"fields","formFields":{},"limitWaitTime":false,"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"resource":"database","operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES ($1, $2);","options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"e0b8092b9d4ef310f3b0f14f290e583889b3a8c13b2f1305fbbc2d6744d14f31",{"nodeName":"17","mode":"18"},["19","10","17","20","21","22"],{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759792500,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"When clicking ‘Execute workflow’":"34","Insert rows in a table":"35","Send a text message":"36"},{},"Send a text message",{},["37","38"],{},{},{},{"version":1,"establishedAt":1785759791324,"source":"39","triggerNode":"40","redaction":"41","credentials":"42"},"Execute a SQL query","inclusive","When clicking ‘Execute workflow’","Insert rows in a table","Select rows from a table","Form","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"43","type":"44","typeVersion":1.2,"position":"45","id":"46","name":"10","webhookId":"47","credentials":"48"},["49"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["50"],["51"],["52"],{"node":"53","data":"54","source":"55"},{"node":"56","data":"57","source":"58"},"manual",{"name":"10","type":"44"},{"version":2,"production":false,"manual":false,"source":"59"},"U2FsdGVkX18sN6OOjbzP27ZvG3JYoZ84aqhDRDjUiORuUO5unxAEPLueLPeGqbIYAa1blmisV1jleyGpgsUpHH0eY1nediY1VrbCSedFWF+J0koW/sLs0qVAAF/N19gpmvqE1ZBz2y/j0rxcEuTKn3Y73iyY170TkYImxD4v0y6UxSlYqR0NWYoXtoNdYpZr0+f+VTh0jDbtvOZC/ZhhTTtguYRQlvbghA7vuVwB3bYa/kZeJ5BFt9jvajAbuRlzQkQJxm691vpIC4r0YV66k6hHOdhSXty1ENQ+1HKGTUIJYZl0w7Skn7mG+65ISb9zf+c6vWeaHgBX1SjKcAEAIad3ww8HcEYnChuZiDvZw3ID7/RE4drr0cE5BIWQhTrmnwMPf/lXBksfhXaIDWN1m74VPV9U0FRwce/XNrrha+fDnMcfxnzykuyTBD3VAWB5uC11SiEPIPLv4siisuu4ZtHn/zJuxiwoU8DBO7ZO2nmSiW4g6S86PwCVnXKQw5LoIMdUwpYcOw3zh/mS8ZiVTg==",{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"64","additionalFields":"65"},"n8n-nodes-base.telegram",[-224,-80],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"66"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785759395627,"executionIndex":0,"source":"67","hints":"68","executionTime":1,"executionStatus":"69","data":"70"},{"startTime":1785759395630,"executionIndex":1,"source":"71","hints":"72","executionTime":102,"executionStatus":"69","data":"73"},{"startTime":1785759791375,"executionIndex":2,"source":"74","hints":"75","executionTime":1128,"executionStatus":"76","error":"77"},{"parameters":"78","type":"44","typeVersion":1.2,"position":"79","id":"46","name":"10","webhookId":"47","credentials":"80"},{"main":"81"},{"main":"74"},{"parameters":"82","type":"83","typeVersion":2.7,"position":"84","id":"85","name":"21","credentials":"86"},{"main":"87"},{"main":"88"},"workflow","message","sendMessage","1","forceReply",{"force_reply":false},{},{"id":"89","name":"90"},[],[],"success",{"main":"91"},["92"],[],{"main":"93"},["94"],[],"error",{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759792500,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"95","additionalFields":"96"},[-224,-80],{"telegramApi":"97"},["98"],{"resource":"99","operation":"100","schema":"101","table":"102","returnAll":false,"limit":50,"where":"103","combineConditions":"104","sort":"105","options":"106"},"n8n-nodes-base.postgres",[-512,112],"3c35274e-a775-413c-9f2d-b3981e7964d5",{"postgres":"107"},["108"],["109"],"SXr9kdhP2pbmSSl5","Telegram account",["108"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["110"],{"previousNode":"20","previousNodeOutput":0,"previousNodeRun":0},{"force_reply":false},{},{"id":"89","name":"90"},["111"],"database","select",{"__rl":true,"mode":"112","value":"113"},{"__rl":true,"value":"114","mode":"115"},{},"AND",{},{"connectionTimeout":30},{"id":"116","name":"117"},["118"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["119"],{"json":"120","pairedItem":"121"},"list","public","items","name","aYolIV9R7XB2uz9G","Postgres account",{"json":"122","pairedItem":"123"},{"json":"120","pairedItem":"124"},{"id":"125","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"9"]	1da84623-df08-4630-a0a2-550f80e2a846
27	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"triggerNotice":"","operation":"page","defineForm":"fields","formFields":{},"limitWaitTime":false,"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"resource":"database","operation":"upsert","schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id","code"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert or update rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"74db2ddf02074d5663a405dbd9469a0559fe1e8fb1f192a1aa00987c58d822ad",{"nodeName":"17","mode":"18"},["19","10","17","20","21","22"],{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759832230,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"When clicking ‘Execute workflow’":"34","Insert rows in a table":"35","Send a text message":"36"},{},"Send a text message",{},["37","38"],{},{},{},{"version":1,"establishedAt":1785759831099,"source":"39","triggerNode":"40","redaction":"41","credentials":"42"},"Insert or update rows in a table","inclusive","When clicking ‘Execute workflow’","Insert rows in a table","Select rows from a table","Form","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"43","type":"44","typeVersion":1.2,"position":"45","id":"46","name":"10","webhookId":"47","credentials":"48"},["49"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["50"],["51"],["52"],{"node":"53","data":"54","source":"55"},{"node":"56","data":"57","source":"58"},"manual",{"name":"10","type":"44"},{"version":2,"production":false,"manual":false,"source":"59"},"U2FsdGVkX18V1mAHiXkpH69AYWBrF1JmLRDr94HSlDNFM5fVKcbMSsmEYRoTPFu2Bv+/XeRZuK4AOE4wVHLd+jsMyLs6v6jToTm5tC5eQ6YOEFDKT91YZdhTiCRpLJ6UIZtJgGILsO16bAFe5CVsDOzgQ3etUz7GHWyyeQ/uCNblpUNTeki6kCvpEbLVNIxIM9T/6uzCJJm1Gtc+YO4d4zCK1dTyMaAjkAUK1okkLc82SWb0wNPxjEr5jlxw27zKuSRbtMJGknp49genkvx91Po3u0rCCW+zDaO46aqieo5Ahq7iNIEaVMc6n+sPwbyKvdWCYQQmXCGHKl4sugjToF5KeXVfTAn6mkPCRRsiep+M0uB65hVLEMOWgTJuUEIvLWgLzJ0+LIjaD9LPCyOHnmz0mizK9+V0UA03zeGzWxub++281fMKixxw8LiZIq1zxNoL5czwCmXmukytpSyXVT45WXKm3kno9pmRMtR7xABfZ/dGuRZ9RNimb/lefe11Wv/CcXBuezbNVOjgLHPX4Q==",{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"64","additionalFields":"65"},"n8n-nodes-base.telegram",[-224,-80],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"66"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785759395627,"executionIndex":0,"source":"67","hints":"68","executionTime":1,"executionStatus":"69","data":"70"},{"startTime":1785759395630,"executionIndex":1,"source":"71","hints":"72","executionTime":102,"executionStatus":"69","data":"73"},{"startTime":1785759831117,"executionIndex":2,"source":"74","hints":"75","executionTime":1118,"executionStatus":"76","error":"77"},{"parameters":"78","type":"44","typeVersion":1.2,"position":"79","id":"46","name":"10","webhookId":"47","credentials":"80"},{"main":"81"},{"main":"74"},{"parameters":"82","type":"83","typeVersion":2.7,"position":"84","id":"85","name":"21","credentials":"86"},{"main":"87"},{"main":"88"},"workflow","message","sendMessage","1","forceReply",{"force_reply":false},{},{"id":"89","name":"90"},[],[],"success",{"main":"91"},["92"],[],{"main":"93"},["94"],[],"error",{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759832230,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"95","additionalFields":"96"},[-224,-80],{"telegramApi":"97"},["98"],{"resource":"99","operation":"100","schema":"101","table":"102","returnAll":false,"limit":50,"where":"103","combineConditions":"104","sort":"105","options":"106"},"n8n-nodes-base.postgres",[-512,112],"3c35274e-a775-413c-9f2d-b3981e7964d5",{"postgres":"107"},["108"],["109"],"SXr9kdhP2pbmSSl5","Telegram account",["108"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["110"],{"previousNode":"20","previousNodeOutput":0,"previousNodeRun":0},{"force_reply":false},{},{"id":"89","name":"90"},["111"],"database","select",{"__rl":true,"mode":"112","value":"113"},{"__rl":true,"value":"114","mode":"115"},{},"AND",{},{"connectionTimeout":30},{"id":"116","name":"117"},["118"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["119"],{"json":"120","pairedItem":"121"},"list","public","items","name","aYolIV9R7XB2uz9G","Postgres account",{"json":"122","pairedItem":"123"},{"json":"120","pairedItem":"124"},{"id":"125","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"9"]	f87d2c1b-aa6b-47ab-b3c7-f801cfc239d4
28	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"triggerNotice":"","operation":"page","defineForm":"fields","formFields":{},"limitWaitTime":false,"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{"code":0,"id":0},"matchingColumns":["id","code"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert rows in a table1","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"0e56dc6b50c8df34aab30bf95c40a30d8cb1242b19c14d6f026d9337f3a3b331",{"nodeName":"17","mode":"18"},["19","10","17","20","21","22"],{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759845526,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"When clicking ‘Execute workflow’":"34","Insert rows in a table":"35","Send a text message":"36"},{},"Send a text message",{},["37","38"],{},{},{},{"version":1,"establishedAt":1785759844378,"source":"39","triggerNode":"40","redaction":"41","credentials":"42"},"Insert rows in a table1","inclusive","When clicking ‘Execute workflow’","Insert rows in a table","Select rows from a table","Form","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"43","type":"44","typeVersion":1.2,"position":"45","id":"46","name":"10","webhookId":"47","credentials":"48"},["49"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["50"],["51"],["52"],{"node":"53","data":"54","source":"55"},{"node":"56","data":"57","source":"58"},"manual",{"name":"10","type":"44"},{"version":2,"production":false,"manual":false,"source":"59"},"U2FsdGVkX19UrQqgNQh20QfmRgJPe+EM40lu5k0JSdnb1kRnVgIwoMy501g0kXlZUIXmFaC5PaEwYqDvuqF3AQSTlP60shKJ6/Gm5mWOkwTT7+9ykEDRQtLDpTMZdZSAg0f65bc7rzovFoSAw2nVKtqsv0uJSKnTMJZPxHF8ShBm1XMZIRKXQ93g/0rqk9dhNcWSRstWnQw4foFX6e/9OVAWTKIRyLuf7Qb71OvzcwBghCHw+p7lD4QJm3dpvAAnzLHJA8bY3RGXxQY7miNerILipFH3kg5PI+k8cgIrPrnE3VDtdwAFyi6ctW91sZiijCZhHfDEfEQZGyR6x7qTrFD1ICS+lZmJcM63yFIQtiiXWt3Oy/g8Gffs79LxqoIzVMORtE3DY0z/oNtbyQ9qp64Q86YZTcFxmkg9LxBb7aPraVyTZQLkKSKhEcEF6QnkAiVStzEBNB5rLn6ES5B1UrhVxeRI15Q1z6MRBMOmhIIZ7XaLgaRdNte2brMcCrOOllIHN88SkdrJmzu7W1rGUQ==",{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"64","additionalFields":"65"},"n8n-nodes-base.telegram",[-224,-80],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"66"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785759395627,"executionIndex":0,"source":"67","hints":"68","executionTime":1,"executionStatus":"69","data":"70"},{"startTime":1785759395630,"executionIndex":1,"source":"71","hints":"72","executionTime":102,"executionStatus":"69","data":"73"},{"startTime":1785759844418,"executionIndex":2,"source":"74","hints":"75","executionTime":1112,"executionStatus":"76","error":"77"},{"parameters":"78","type":"44","typeVersion":1.2,"position":"79","id":"46","name":"10","webhookId":"47","credentials":"80"},{"main":"81"},{"main":"74"},{"parameters":"82","type":"83","typeVersion":2.7,"position":"84","id":"85","name":"21","credentials":"86"},{"main":"87"},{"main":"88"},"workflow","message","sendMessage","1","forceReply",{"force_reply":false},{},{"id":"89","name":"90"},[],[],"success",{"main":"91"},["92"],[],{"main":"93"},["94"],[],"error",{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759845526,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"95","additionalFields":"96"},[-224,-80],{"telegramApi":"97"},["98"],{"resource":"99","operation":"100","schema":"101","table":"102","returnAll":false,"limit":50,"where":"103","combineConditions":"104","sort":"105","options":"106"},"n8n-nodes-base.postgres",[-512,112],"3c35274e-a775-413c-9f2d-b3981e7964d5",{"postgres":"107"},["108"],["109"],"SXr9kdhP2pbmSSl5","Telegram account",["108"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["110"],{"previousNode":"20","previousNodeOutput":0,"previousNodeRun":0},{"force_reply":false},{},{"id":"89","name":"90"},["111"],"database","select",{"__rl":true,"mode":"112","value":"113"},{"__rl":true,"value":"114","mode":"115"},{},"AND",{},{"connectionTimeout":30},{"id":"116","name":"117"},["118"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["119"],{"json":"120","pairedItem":"121"},"list","public","items","name","aYolIV9R7XB2uz9G","Postgres account",{"json":"122","pairedItem":"123"},{"json":"120","pairedItem":"124"},{"id":"125","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"9"]	c4ef70bf-36e3-4388-963f-85d640744b35
29	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"triggerNotice":"","operation":"page","defineForm":"fields","formFields":{},"limitWaitTime":false,"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id","code"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert rows in a table1","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"522f3be9ebb090e8ab89091e888c1123951e8689f2919f695470027af5009dc4",{"nodeName":"17","mode":"18"},["19","10","17","20","21","22"],{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759854065,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"When clicking ‘Execute workflow’":"34","Insert rows in a table":"35","Send a text message":"36"},{},"Send a text message",{},["37","38"],{},{},{},{"version":1,"establishedAt":1785759852938,"source":"39","triggerNode":"40","redaction":"41","credentials":"42"},"Insert rows in a table1","inclusive","When clicking ‘Execute workflow’","Insert rows in a table","Select rows from a table","Form","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"43","type":"44","typeVersion":1.2,"position":"45","id":"46","name":"10","webhookId":"47","credentials":"48"},["49"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["50"],["51"],["52"],{"node":"53","data":"54","source":"55"},{"node":"56","data":"57","source":"58"},"manual",{"name":"10","type":"44"},{"version":2,"production":false,"manual":false,"source":"59"},"U2FsdGVkX1+MS3P1XtttwDCJrDGsJUCDje+42ptB41BgA1hRhfVDN8df7pVmQqksJdWWcthx5jcQabXZbGR8oPaqvZaY2zTcR1jNLXyWrT18p7/Grya1l0WDfdFMrzCDNkVSfuo6jsnkQJsr/vvfAs2gacXlaKeo2mnXWPF5BxgL0GC3Ab0rkgtXWCd7CT+nFc3eVcu74Dg+OYhi+pzoVkTWGPrRtWHLV5yJoMAccS9JBjtqmWA8GUo4TVMU4ckr5zHzN/JTss34obJNJYklC6p2PmDLoQhQltLragTvOLRGkn4+nuXcJ6mewUJyTJ9m4t5zgacinwFNJi1HhywYVh8rx8T20MmElVgadV/ng6l4UVsZPWgUUBKD8m2Bhy6O62uu59OSx+mDmzRFgEy/lH44j6IfTodfxcM05g3KsgWx3l2NbmLchROM3DfNTx9g9JhURIoLqYySaJDSm+ZPipItmKm7cdX4CTJ+NZEW8+kAO14MTHhTZ0Rr33R8zFcMDxWWiVmxs2cQ5QK1mUaIsQ==",{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"64","additionalFields":"65"},"n8n-nodes-base.telegram",[-224,-80],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"66"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785759395627,"executionIndex":0,"source":"67","hints":"68","executionTime":1,"executionStatus":"69","data":"70"},{"startTime":1785759395630,"executionIndex":1,"source":"71","hints":"72","executionTime":102,"executionStatus":"69","data":"73"},{"startTime":1785759852960,"executionIndex":2,"source":"74","hints":"75","executionTime":1111,"executionStatus":"76","error":"77"},{"parameters":"78","type":"44","typeVersion":1.2,"position":"79","id":"46","name":"10","webhookId":"47","credentials":"80"},{"main":"81"},{"main":"74"},{"parameters":"82","type":"83","typeVersion":2.7,"position":"84","id":"85","name":"21","credentials":"86"},{"main":"87"},{"main":"88"},"workflow","message","sendMessage","1","forceReply",{"force_reply":false},{},{"id":"89","name":"90"},[],[],"success",{"main":"91"},["92"],[],{"main":"93"},["94"],[],"error",{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759854065,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"95","additionalFields":"96"},[-224,-80],{"telegramApi":"97"},["98"],{"resource":"99","operation":"100","schema":"101","table":"102","returnAll":false,"limit":50,"where":"103","combineConditions":"104","sort":"105","options":"106"},"n8n-nodes-base.postgres",[-512,112],"3c35274e-a775-413c-9f2d-b3981e7964d5",{"postgres":"107"},["108"],["109"],"SXr9kdhP2pbmSSl5","Telegram account",["108"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["110"],{"previousNode":"20","previousNodeOutput":0,"previousNodeRun":0},{"force_reply":false},{},{"id":"89","name":"90"},["111"],"database","select",{"__rl":true,"mode":"112","value":"113"},{"__rl":true,"value":"114","mode":"115"},{},"AND",{},{"connectionTimeout":30},{"id":"116","name":"117"},["118"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["119"],{"json":"120","pairedItem":"121"},"list","public","items","name","aYolIV9R7XB2uz9G","Postgres account",{"json":"122","pairedItem":"123"},{"json":"120","pairedItem":"124"},{"id":"125","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"9"]	6222743d-73a5-4e22-80a3-d5cb9a13b620
30	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"triggerNotice":"","operation":"page","defineForm":"fields","formFields":{},"limitWaitTime":false,"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"resource":"database","operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{"destinationNode":"5","runNodeFilter":"6"},{"error":"7","runData":"8","pinData":"9","lastNodeExecuted":"10"},{"contextData":"11","nodeExecutionStack":"12","metadata":"13","waitingExecution":"14","waitingExecutionSource":"15","runtimeData":"16"},"aec2a7456a051e273250e3420b92a5015e9de835daa7646a39884eb328232397",{"nodeName":"17","mode":"18"},["19","10","17","20","21","22"],{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759920581,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"When clicking ‘Execute workflow’":"34","Insert rows in a table":"35","Send a text message":"36"},{},"Send a text message",{},["37","38"],{},{},{},{"version":1,"establishedAt":1785759919478,"source":"39","triggerNode":"40","redaction":"41","credentials":"42"},"Execute a SQL query","inclusive","When clicking ‘Execute workflow’","Insert rows in a table","Select rows from a table","Form","warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"43","type":"44","typeVersion":1.2,"position":"45","id":"46","name":"10","webhookId":"47","credentials":"48"},["49"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["50"],["51"],["52"],{"node":"53","data":"54","source":"55"},{"node":"56","data":"57","source":"58"},"manual",{"name":"10","type":"44"},{"version":2,"production":false,"manual":false,"source":"59"},"U2FsdGVkX1+TXNIDTVRR5h0l2kOB6BIfUtpX2RI7KNXJMWWCnu4ZqBQsSOZixodtobpLuDWiPYGRAU8XRHiQZ87jIKmykhihdwfiGoqG/4OHYg9XLYFepTssPWSsa8HxIymDgL2Lz5CGjO5B3eyQBM77csG20/cRbjHZcTbf5d4j3pCDAV1w6p0gLeylqKgOrLul0WIWbxq3O1CK6vEwMx8b1NTzpLShmFIWTZmwtNcAz16cgbnBJYHlqMyigTgwnEN3FFpH+M7EWvBq8SWL5onKGLyi/rRAr0ORYKKE1STEX5gL43H9NN0/YxrxysxvR9khAVa1WoNs/i/XLAnzE4Qdv0YtCCTuijGqU62YXykOGCMWSp0TPNBzFhG3Th0pmlJsfB/dRTZa2xNvE6+9VX3HR3KOjdzyabewscuH2fI0c27K0EECAwgB5V8wUJRH+4bbjgBQo2mNCHDHy9CI36b8t50dHsMwN2jk4eW4XtO3nb7rnqTO4iRYukP86Hct4bQJrNy05FJEy/HNbpYe0w==",{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"64","additionalFields":"65"},"n8n-nodes-base.telegram",[-224,-80],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"66"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785759395627,"executionIndex":0,"source":"67","hints":"68","executionTime":1,"executionStatus":"69","data":"70"},{"startTime":1785759395630,"executionIndex":1,"source":"71","hints":"72","executionTime":102,"executionStatus":"69","data":"73"},{"startTime":1785759919519,"executionIndex":2,"source":"74","hints":"75","executionTime":1065,"executionStatus":"76","error":"77"},{"parameters":"78","type":"44","typeVersion":1.2,"position":"79","id":"46","name":"10","webhookId":"47","credentials":"80"},{"main":"81"},{"main":"74"},{"parameters":"82","type":"83","typeVersion":2.7,"position":"84","id":"85","name":"21","credentials":"86"},{"main":"87"},{"main":"88"},"workflow","message","sendMessage","1","forceReply",{"force_reply":false},{},{"id":"89","name":"90"},[],[],"success",{"main":"91"},["92"],[],{"main":"93"},["94"],[],"error",{"level":"23","shouldReport":true,"description":"24","tags":"25","timestamp":1785759920581,"context":"26","functionality":"27","name":"28","node":"29","messages":"30","httpCode":"31","message":"32","stack":"33"},{"resource":"60","operation":"61","chatId":"62","text":"62","replyMarkup":"63","forceReply":"95","additionalFields":"96"},[-224,-80],{"telegramApi":"97"},["98"],{"resource":"99","operation":"100","schema":"101","table":"102","returnAll":false,"limit":50,"where":"103","combineConditions":"104","sort":"105","options":"106"},"n8n-nodes-base.postgres",[-512,112],"3c35274e-a775-413c-9f2d-b3981e7964d5",{"postgres":"107"},["108"],["109"],"SXr9kdhP2pbmSSl5","Telegram account",["108"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["110"],{"previousNode":"20","previousNodeOutput":0,"previousNodeRun":0},{"force_reply":false},{},{"id":"89","name":"90"},["111"],"database","select",{"__rl":true,"mode":"112","value":"113"},{"__rl":true,"value":"114","mode":"115"},{},"AND",{},{"connectionTimeout":30},{"id":"116","name":"117"},["118"],{"previousNode":"19","previousNodeOutput":0,"previousNodeRun":0},["119"],{"json":"120","pairedItem":"121"},"list","public","items","name","aYolIV9R7XB2uz9G","Postgres account",{"json":"122","pairedItem":"123"},{"json":"120","pairedItem":"124"},{"id":"125","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"9"]	25c7b4d0-af06-4c12-9b58-f4824cf830bb
31	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"triggerNotice":"","operation":"page","defineForm":"fields","formFields":{},"limitWaitTime":false,"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"resource":"database","operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"email","operation":"send","fromEmail":"","toEmail":"","subject":"","emailFormat":"html","html":"","options":{}},"type":"n8n-nodes-base.emailSend","typeVersion":2.1,"position":[336,0],"id":"cfee0e17-b0a3-4448-bd35-7f2067e25f9c","name":"Send an Email","webhookId":"fd800d06-1674-4453-b44d-43f3da3b3a8f","credentials":{"smtp":{"id":"vUrbIYd7RrDZxipc","name":"SMTP account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Execute a SQL query":{"main":[[{"node":"Send an Email","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"457df2777ac86e5264eb725243e60fb481ed50a52018531798428d0913abc4ce",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785760362497,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Send an Email' node has issues:\\n- Parameter \\"From Email\\" is required.\\n- Parameter \\"To Email\\" is required.","WorkflowHasIssuesError: The 'Send an Email' node has issues:\\n- Parameter \\"From Email\\" is required.\\n- Parameter \\"To Email\\" is required.\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	5332d09d-7337-44d4-8330-d45c6753ae27
32	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"triggerNotice":"","operation":"page","defineForm":"fields","formFields":{},"limitWaitTime":false,"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"resource":"database","operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"email","operation":"send","fromEmail":"","toEmail":"","subject":"","emailFormat":"html","html":"","options":{}},"type":"n8n-nodes-base.emailSend","typeVersion":2.1,"position":[336,0],"id":"cfee0e17-b0a3-4448-bd35-7f2067e25f9c","name":"Send an Email","webhookId":"fd800d06-1674-4453-b44d-43f3da3b3a8f","credentials":{"smtp":{"id":"vUrbIYd7RrDZxipc","name":"SMTP account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Execute a SQL query":{"main":[[{"node":"Send an Email","type":"main","index":0}]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6"},{"contextData":"7","nodeExecutionStack":"8","metadata":"9","waitingExecution":"10","waitingExecutionSource":"11"},"24dfcfddcbb167cf746e52428fcd552383334dd56e2413688714a5cfdbeab743",{"level":"12","shouldReport":true,"tags":"13","timestamp":1785760367660,"context":"14","functionality":"15","name":"16","message":"17","stack":"18"},{},{},[],{},{},{},"warning",{},{},"regular","WorkflowHasIssuesError","The 'Send an Email' node has issues:\\n- Parameter \\"From Email\\" is required.\\n- Parameter \\"To Email\\" is required.","WorkflowHasIssuesError: The 'Send an Email' node has issues:\\n- Parameter \\"From Email\\" is required.\\n- Parameter \\"To Email\\" is required.\\n    at WorkflowExecute.checkForWorkflowIssues (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1501:10)\\n    at WorkflowExecute.processRunExecutionData (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1580:8)\\n    at WorkflowExecute.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:196:15)\\n    at ManualExecutionService.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\manual-execution.service.ts:172:27)\\n    at WorkflowRunner.runMainProcess (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:427:53)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at WorkflowRunner.run (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflow-runner.ts:287:4)\\n    at WorkflowExecutionService.executeManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflow-execution.service.ts:286:24)\\n    at WorkflowsController.runManually (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\workflows\\\\workflows.controller.ts:529:18)\\n    at handler (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\src\\\\controller.registry.ts:115:12)"]	5332d09d-7337-44d4-8330-d45c6753ae27
33	{"id":"LMGDOuu6Yj3J2GUB","name":"n8n","nodes":[{"parameters":{"notice":""},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"resource":"database","operation":"insert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"resource":"message","operation":"sendMessage","chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"resource":"database","operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"returnAll":false,"limit":50,"where":{},"combineConditions":"AND","sort":{},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"triggerNotice":"","operation":"page","defineForm":"fields","formFields":{},"limitWaitTime":false,"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"resource":"database","operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}],"connections":{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Execute a SQL query":{"main":[[]]}},"settings":{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false},"nodeGroups":[]}	[{"version":1,"startData":"1","resultData":"2","executionData":"3","resumeToken":"4"},{},{"error":"5","runData":"6","pinData":"7","lastNodeExecuted":"8"},{"contextData":"9","nodeExecutionStack":"10","metadata":"11","waitingExecution":"12","waitingExecutionSource":"13","runtimeData":"14"},"2ef5ff84b18d30caa53fe1595283f095966eccaa28732945deb0ac0e399fde1e",{"level":"15","shouldReport":true,"description":"16","tags":"17","timestamp":1785760375473,"context":"18","functionality":"19","name":"20","node":"21","messages":"22","httpCode":"23","message":"24","stack":"25"},{"When clicking ‘Execute workflow’":"26","Insert rows in a table":"27","Send a text message":"28"},{},"Send a text message",{},["29","30"],{},{},{},{"version":1,"establishedAt":1785760374176,"source":"31","triggerNode":"32","redaction":"33","credentials":"34"},"warning","Bad Request: chat not found",{},{},"regular","NodeApiError",{"parameters":"35","type":"36","typeVersion":1.2,"position":"37","id":"38","name":"8","webhookId":"39","credentials":"40"},["41"],"400","Bad request - please check your parameters","NodeApiError: Bad request - please check your parameters\\n    at ExecuteContext.apiRequest (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\GenericFunctions.ts:244:9)\\n    at processTicksAndRejections (node:internal/process/task_queues:104:5)\\n    at ExecuteContext.execute (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-nodes-base\\\\nodes\\\\Telegram\\\\Telegram.node.ts:2497:21)\\n    at WorkflowExecute.executeNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1082:8)\\n    at WorkflowExecute.runNode (C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1382:11)\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:1855:27\\n    at C:\\\\Users\\\\harys\\\\AppData\\\\Roaming\\\\npm\\\\node_modules\\\\n8n\\\\node_modules\\\\n8n-core\\\\src\\\\execution-engine\\\\workflow-execute.ts:2549:11",["42"],["43"],["44"],{"node":"45","data":"46","source":"47"},{"node":"48","data":"49","source":"50"},"manual",{"name":"51","type":"52"},{"version":2,"production":false,"manual":false,"source":"53"},"U2FsdGVkX1+vSWM7CJhSVhT2P9tdTgpSMQvuOev1C6Vt56vw7UO9piHHyR1EnZWIVt4mxFqDyJ9bzcNQBkH5JhEADo7pYnVC95p01GQsfQDsEch/DVnnaMOb/JE9kNhmvorC4fQB0SaTuvaVWgSKRDKQCK5p0WFE41tQbKdw/b/AJJejEFKYe0vHrosk4jwN2nSKOKncK8xWqF1hDqWfpHVbGQ2agmF0wrgTwH2St9O8w9//mJk7iy7ZMhzJXy8ShgRXfJ05d7B9G8T85G8YeZLrphObW5Yt3TccgHrckvrk1A4jmORq9xVBKpOPT3slkd/G1VZx8xMr1xYOBdVgcMUUO1nCJ8Q1gpwA1yP8hmzyuUsWZ29/uXemuk8siZplfJDuV1r/0/5GjbU8dhyrTPRyCqCF5Xj6sXiYpJjxTWMAY1bzEjzVsKQjCsqUENOAC1cyaJgDmmbemjxCovT+4LfHB6lZzrEBMzmqJyTO8PFUQSu1gpR0SpNEErGDyw6EoMpieW8XTWZFOPZ+WHyPwg==",{"resource":"54","operation":"55","chatId":"56","text":"56","replyMarkup":"57","forceReply":"58","additionalFields":"59"},"n8n-nodes-base.telegram",[-224,-80],"259646ba-a37a-4a86-a62f-92c32edb2481","25f9c399-a485-469b-8c8b-107947f0be22",{"telegramApi":"60"},"400 - {\\"ok\\":false,\\"error_code\\":400,\\"description\\":\\"Bad Request: chat not found\\"}",{"startTime":1785760374195,"executionIndex":0,"source":"61","hints":"62","executionTime":2,"executionStatus":"63","data":"64"},{"startTime":1785760374199,"executionIndex":1,"source":"65","hints":"66","executionTime":108,"executionStatus":"63","data":"67"},{"startTime":1785760374313,"executionIndex":2,"source":"68","hints":"69","executionTime":1165,"executionStatus":"70","error":"71"},{"parameters":"72","type":"36","typeVersion":1.2,"position":"73","id":"38","name":"8","webhookId":"39","credentials":"74"},{"main":"75"},{"main":"68"},{"parameters":"76","type":"77","typeVersion":2.7,"position":"78","id":"79","name":"80","credentials":"81"},{"main":"82"},{"main":"83"},"When clicking ‘Execute workflow’","n8n-nodes-base.manualTrigger","workflow","message","sendMessage","1","forceReply",{"force_reply":false},{},{"id":"84","name":"85"},[],[],"success",{"main":"86"},["87"],[],{"main":"88"},["89"],[],"error",{"level":"15","shouldReport":true,"description":"16","tags":"17","timestamp":1785760375473,"context":"18","functionality":"19","name":"20","node":"21","messages":"22","httpCode":"23","message":"24","stack":"25"},{"resource":"54","operation":"55","chatId":"56","text":"56","replyMarkup":"57","forceReply":"90","additionalFields":"91"},[-224,-80],{"telegramApi":"92"},["93"],{"resource":"94","operation":"95","schema":"96","table":"97","returnAll":false,"limit":50,"where":"98","combineConditions":"99","sort":"100","options":"101"},"n8n-nodes-base.postgres",[-512,112],"3c35274e-a775-413c-9f2d-b3981e7964d5","Select rows from a table",{"postgres":"102"},["103"],["104"],"SXr9kdhP2pbmSSl5","Telegram account",["103"],{"previousNode":"51","previousNodeOutput":0,"previousNodeRun":0},["105"],{"previousNode":"106","previousNodeOutput":0,"previousNodeRun":0},{"force_reply":false},{},{"id":"84","name":"85"},["107"],"database","select",{"__rl":true,"mode":"108","value":"109"},{"__rl":true,"value":"110","mode":"111"},{},"AND",{},{"connectionTimeout":30},{"id":"112","name":"113"},["114"],{"previousNode":"51","previousNodeOutput":0,"previousNodeRun":0},["115"],"Insert rows in a table",{"json":"116","pairedItem":"117"},"list","public","items","name","aYolIV9R7XB2uz9G","Postgres account",{"json":"118","pairedItem":"119"},{"json":"116","pairedItem":"120"},{"id":"121","code":null,"name":null},{"item":0},{},{"item":0},{"item":0},"10"]	f0ce407d-b0a1-4e1d-92fe-0adfb8996fa6
\.


--
-- Data for Name: execution_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.execution_entity (id, finished, mode, "retryOf", "retrySuccessId", "startedAt", "stoppedAt", "waitTill", status, "workflowId", "deletedAt", "createdAt", "storedAt", "tracingContext", "deduplicationKey", "jsonSizeBytes", "workflowVersionId", "binaryDataSizeBytes", "usedPrivateCredentials") FROM stdin;
1	f	manual	\N	\N	2026-08-03 18:58:34.862+07	2026-08-03 18:58:35.989+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 18:58:34.82+07	db	\N	\N	5119	f7587b4f-b56c-40e7-a058-72af7fcd292d	0	f
8	f	manual	\N	\N	2026-08-03 19:06:52.499+07	2026-08-03 19:06:52.588+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:06:52.434+07	db	\N	\N	3622	dfa4f148-53a4-458e-9443-fc023d4c12f5	0	f
20	f	manual	\N	\N	2026-08-03 19:14:23.397+07	2026-08-03 19:14:23.451+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:14:23.312+07	db	\N	\N	4228	14802506-f2f9-41b6-bb75-bb3cd06705e6	0	f
2	f	manual	\N	\N	2026-08-03 19:00:01.44+07	2026-08-03 19:00:02.143+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:00:01.431+07	db	\N	\N	5079	e1c87199-65be-4386-ba56-6731852c03a7	0	f
3	f	manual	\N	\N	2026-08-03 19:00:12.949+07	2026-08-03 19:00:16.795+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:00:12.936+07	db	\N	\N	5323	5768c14e-efc0-4d02-bff7-1b95e745acc6	0	f
14	t	manual	\N	\N	2026-08-03 19:12:44.983+07	2026-08-03 19:12:45.139+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:12:44.971+07	db	\N	\N	3289	b1c61506-057e-4560-b4fc-441b85ee6f70	0	f
4	f	manual	\N	\N	2026-08-03 19:01:38.272+07	2026-08-03 19:01:38.387+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:01:38.252+07	db	\N	\N	2945	42e0e936-da46-4444-be1f-a447dad7b7e0	0	f
21	f	manual	\N	\N	2026-08-03 19:14:44.524+07	2026-08-03 19:14:45.905+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:14:44.51+07	db	\N	\N	6851	1d17aef2-32be-41a4-994b-a91dd007fc2e	0	f
9	f	manual	\N	\N	2026-08-03 19:07:26.269+07	2026-08-03 19:07:26.291+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:07:26.261+07	db	\N	\N	3622	dfa4f148-53a4-458e-9443-fc023d4c12f5	0	f
5	f	manual	\N	\N	2026-08-03 19:05:46.756+07	2026-08-03 19:05:46.781+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:05:46.743+07	db	\N	\N	3660	61acc561-d139-4cf5-87ea-5e721bb7287f	0	f
24	t	manual	\N	\N	2026-08-03 19:16:16.45+07	2026-08-03 19:16:16.687+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:16:16.438+07	db	\N	\N	5186	3bf80a3f-03a4-4623-9cf8-577c2fc04ba1	0	f
22	f	manual	\N	\N	2026-08-03 19:15:09.436+07	2026-08-03 19:15:10.557+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:15:09.428+07	db	\N	\N	6947	0de289c3-316f-4ecc-a7d4-10f0ce924711	0	f
6	f	manual	\N	\N	2026-08-03 19:05:55.62+07	2026-08-03 19:05:55.647+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:05:55.607+07	db	\N	\N	3622	dfa4f148-53a4-458e-9443-fc023d4c12f5	0	f
7	f	manual	\N	\N	2026-08-03 19:05:58.068+07	2026-08-03 19:05:58.102+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:05:58.012+07	db	\N	\N	3622	dfa4f148-53a4-458e-9443-fc023d4c12f5	0	f
29	f	manual	\N	\N	2026-08-03 19:24:12.918+07	2026-08-03 19:24:14.078+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:24:12.894+07	db	\N	\N	9986	6222743d-73a5-4e22-80a3-d5cb9a13b620	0	f
10	f	manual	\N	\N	2026-08-03 19:07:47.661+07	2026-08-03 19:07:47.674+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:07:47.645+07	db	\N	\N	3513	86317178-537d-45b9-aeaf-924bbfacf25b	0	f
23	t	manual	\N	\N	2026-08-03 19:15:41.361+07	2026-08-03 19:15:41.709+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:15:41.337+07	db	\N	\N	3982	b9b16aa7-8765-4348-af12-78c63cdbb451	0	f
11	f	manual	\N	\N	2026-08-03 19:10:26.275+07	2026-08-03 19:10:26.503+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:10:26.255+07	db	\N	\N	7218	6f648c2c-478f-4d22-93aa-b88bc345efee	0	f
25	f	manual	\N	\N	2026-08-03 19:16:35.582+07	2026-08-03 19:16:36.821+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:16:35.566+07	db	\N	\N	8329	3bf80a3f-03a4-4623-9cf8-577c2fc04ba1	0	f
15	t	manual	\N	\N	2026-08-03 19:12:46.42+07	2026-08-03 19:12:46.463+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:12:46.414+07	db	\N	\N	3432	b0431185-9ba0-44eb-af73-ba35927e2be4	0	f
12	t	manual	\N	\N	2026-08-03 19:11:22.744+07	2026-08-03 19:11:22.844+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:11:22.737+07	db	\N	\N	3241	6f648c2c-478f-4d22-93aa-b88bc345efee	0	f
27	f	manual	\N	\N	2026-08-03 19:23:51.074+07	2026-08-03 19:23:52.243+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:23:51.065+07	db	\N	\N	10007	f87d2c1b-aa6b-47ab-b3c7-f801cfc239d4	0	f
19	t	manual	\N	\N	2026-08-03 19:13:38.715+07	2026-08-03 19:13:38.768+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:13:38.706+07	db	\N	\N	3343	b0431185-9ba0-44eb-af73-ba35927e2be4	0	f
13	f	manual	\N	\N	2026-08-03 19:11:25.796+07	2026-08-03 19:11:25.847+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:11:25.791+07	db	\N	\N	7245	b1c61506-057e-4560-b4fc-441b85ee6f70	0	f
26	f	manual	\N	\N	2026-08-03 19:23:11.28+07	2026-08-03 19:23:12.51+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:23:11.265+07	db	\N	\N	9342	1da84623-df08-4630-a0a2-550f80e2a846	0	f
16	t	manual	\N	\N	2026-08-03 19:12:47.617+07	2026-08-03 19:12:47.668+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:12:47.607+07	db	\N	\N	3432	b0431185-9ba0-44eb-af73-ba35927e2be4	0	f
31	f	manual	\N	\N	2026-08-03 19:32:42.465+07	2026-08-03 19:32:42.5+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:32:42.446+07	db	\N	\N	6313	5332d09d-7337-44d4-8330-d45c6753ae27	0	f
17	t	manual	\N	\N	2026-08-03 19:12:48.805+07	2026-08-03 19:12:48.848+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:12:48.797+07	db	\N	\N	3432	b0431185-9ba0-44eb-af73-ba35927e2be4	0	f
28	f	manual	\N	\N	2026-08-03 19:24:04.355+07	2026-08-03 19:24:05.537+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:24:04.346+07	db	\N	\N	10001	c4ef70bf-36e3-4388-963f-85d640744b35	0	f
18	t	manual	\N	\N	2026-08-03 19:13:30.564+07	2026-08-03 19:13:30.673+07	\N	success	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:13:30.558+07	db	\N	\N	3432	b0431185-9ba0-44eb-af73-ba35927e2be4	0	f
30	f	manual	\N	\N	2026-08-03 19:25:19.456+07	2026-08-03 19:25:20.588+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:25:19.441+07	db	\N	\N	9355	25c7b4d0-af06-4c12-9b58-f4824cf830bb	0	f
33	f	manual	\N	\N	2026-08-03 19:32:54.159+07	2026-08-03 19:32:55.486+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:32:54.149+07	db	\N	\N	9271	f0ce407d-b0a1-4e1d-92fe-0adfb8996fa6	0	f
32	f	manual	\N	\N	2026-08-03 19:32:47.605+07	2026-08-03 19:32:47.662+07	\N	error	LMGDOuu6Yj3J2GUB	\N	2026-08-03 19:32:47.582+07	db	\N	\N	6313	5332d09d-7337-44d4-8330-d45c6753ae27	0	f
\.


--
-- Data for Name: execution_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.execution_metadata (id, "executionId", key, value) FROM stdin;
\.


--
-- Data for Name: folder; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.folder (id, name, "parentFolderId", "projectId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: folder_tag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.folder_tag ("folderId", "tagId") FROM stdin;
\.


--
-- Data for Name: insights_by_period; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.insights_by_period (id, "metaId", type, value, "periodUnit", "periodStart") FROM stdin;
\.


--
-- Data for Name: insights_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.insights_metadata ("metaId", "workflowId", "projectId", "workflowName", "projectName") FROM stdin;
\.


--
-- Data for Name: insights_raw; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.insights_raw (id, "metaId", type, value, "timestamp") FROM stdin;
\.


--
-- Data for Name: installed_nodes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.installed_nodes (name, type, "latestVersion", package) FROM stdin;
\.


--
-- Data for Name: installed_packages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.installed_packages ("packageName", "installedVersion", "authorName", "authorEmail", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_checkpoints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_checkpoints (key, "runId", "threadId", "resourceId", state, "createdAt", "updatedAt", "expiredAt", "hostRunId") FROM stdin;
\.


--
-- Data for Name: instance_ai_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_events ("threadId", seq, "runId", type, payload, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_iteration_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_iteration_logs (id, "threadId", "taskKey", entry, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_mcp_registry_connections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_mcp_registry_connections (id, "credentialId", "serverSlug", "toolFilter", "userId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_messages (id, "threadId", content, role, type, "resourceId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_observation_cursors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_observation_cursors ("observationScopeId", "lastObservedMessageId", "lastObservedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_observation_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_observation_locks ("observationScopeId", "taskKind", "holderId", "heldUntil", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_observational_memory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_observational_memory (id, "lookupKey", scope, "threadId", "resourceId", "activeObservations", "originType", config, "generationCount", "lastObservedAt", "pendingMessageTokens", "totalTokensObserved", "observationTokenCount", "isObserving", "isReflecting", "observedMessageIds", "observedTimezone", "bufferedObservations", "bufferedObservationTokens", "bufferedMessageIds", "bufferedReflection", "bufferedReflectionTokens", "bufferedReflectionInputTokens", "reflectedObservationLineCount", "bufferedObservationChunks", "isBufferingObservation", "isBufferingReflection", "lastBufferedAtTokens", "lastBufferedAtTime", metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_observations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_observations (id, "observationScopeId", marker, text, "parentId", "tokenCount", status, "supersededBy", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_pending_confirmations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_pending_confirmations ("requestId", "threadId", "userId", kind, "runId", "toolCallId", "messageGroupId", "checkpointKey", "checkpointTaskId", "expiresAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_resources; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_resources (id, "workingMemory", metadata, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_run_snapshots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_run_snapshots ("threadId", "runId", "messageGroupId", "runIds", tree, "createdAt", "updatedAt", "langsmithRunId", "langsmithTraceId", "traceId", "spanId") FROM stdin;
\.


--
-- Data for Name: instance_ai_thread_grants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_thread_grants ("threadId", "userId", "grantKey", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_ai_threads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_threads (id, "resourceId", title, metadata, "createdAt", "updatedAt", "projectId") FROM stdin;
\.


--
-- Data for Name: instance_ai_workflow_snapshots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_ai_workflow_snapshots ("runId", "workflowName", "resourceId", status, snapshot, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: instance_version_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instance_version_history (id, major, minor, patch, "createdAt") FROM stdin;
1	2	32	7	2026-08-03 09:11:03.228+07
\.


--
-- Data for Name: invalid_auth_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invalid_auth_token (token, "expiresAt") FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items (id, code, name) FROM stdin;
1	\N	\N
2	\N	\N
3	\N	\N
4	\N	\N
5	\N	\N
6	\N	\N
7	\N	\N
8	\N	\N
9	\N	\N
10	\N	\N
\.


--
-- Data for Name: items2; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items2 (id, payload, created_at) FROM stdin;
\.


--
-- Data for Name: mcp_registry_server; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mcp_registry_server (slug, status, version, "registryUpdatedAt", data, "createdAt", "updatedAt") FROM stdin;
notion	active	1.0.1	2026-06-11 19:29:07.703	{"id":1,"name":"com.notion/mcp","title":"Notion","tagline":"Connect to the Notion MCP Server","description":"Official Notion MCP server","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:13.571Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":1,"type":"streamable-http","url":"https://mcp.notion.com/mcp"},{"id":2,"type":"sse","url":"https://mcp.notion.com/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idjb_Qg_E_jj_26d71d08b5.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idjb_Qg_E_jj_5fcfcab5f8.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
atlassian	active	1.1.1	2026-06-11 19:28:42.32	{"id":2,"name":"com.atlassian/atlassian-mcp-server","title":"Atlassian","tagline":"Connect to the Atlassian MCP Server","description":"Atlassian Rovo MCP Server","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:24.904Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":3,"type":"streamable-http","url":"https://mcp.atlassian.com/v1/mcp"},{"id":4,"type":"sse","url":"https://mcp.atlassian.com/v1/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_KV_Ejn_Mrk_716d407499.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_KV_Ejn_Mrk_1f404ecbfd.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
apify	active	0.10.6	2026-06-11 19:28:32.446	{"id":3,"name":"com.apify/apify-mcp-server","title":"Apify","tagline":"Connect to the Apify MCP Server","description":"Extract data from any website with thousands of scrapers, crawlers, and automations on Apify Store ⚡","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:36.524Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":5,"type":"streamable-http","url":"https://mcp.apify.com/"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_S_Uz5c4rz_d01d21b490.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id6k3_J_n_Mi_ceeccc3a3e.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
stripe	active	0.2.4	2026-06-11 19:29:33.086	{"id":4,"name":"com.stripe/mcp","title":"Stripe","tagline":"Connect to the Stripe MCP Server","description":"MCP server integrating with Stripe - tools for customers, products, payments, and more.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:47.930Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":6,"type":"streamable-http","url":"https://mcp.stripe.com"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Bn9_1_Njr_e4279db01b.jpeg","mimeType":"image/jpeg","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
monday-com	active	0.0.1	2026-06-11 19:29:02.947	{"id":5,"name":"com.monday/monday.com","title":"monday.com","tagline":"Connect to the monday.com MCP Server","description":"MCP server for monday.com integration.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:49:59.434Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":7,"type":"streamable-http","url":"https://mcp.monday.com/mcp"},{"id":8,"type":"sse","url":"https://mcp.monday.com/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idz_Vgm_C8_SV_4533eff3c2.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
git-lab	active	0.0.1	2026-06-11 19:28:56.391	{"id":6,"name":"com.gitlab/mcp","title":"GitLab","tagline":"Connect to the GitLab MCP Server","description":"Official GitLab MCP Server","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:10.745Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":9,"type":"streamable-http","url":"https://gitlab.com/api/v4/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idkt3_Cw41b_9f7043ad83.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_O_Daz_Q_Zbt_f76933a2e6.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
linear	active	1.0.0	2026-06-11 19:28:04.979	{"id":7,"name":"app.linear/linear","title":"Linear","tagline":"Connect to the Linear MCP Server","description":"MCP server for Linear project management and issue tracking","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:22.156Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":11,"type":"sse","url":"https://mcp.linear.app/sse"},{"id":10,"type":"streamable-http","url":"https://mcp.linear.app/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_P3_K9_Q_jj_6b6c66c6c7.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_P3_K9_Q_jj_7d409a8856.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
webflow	active	2.0.0	2026-06-11 19:29:37.869	{"id":8,"name":"com.webflow/mcp","title":"Webflow","tagline":"Connect to the Webflow MCP Server","description":"AI-powered design and management for Webflow Sites","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:33.630Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":12,"type":"streamable-http","url":"https://mcp.webflow.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idx_GYKE_Fj1_b568d3380a.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Zp72_NUI_5_080d2c331c.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
pay-pal	active	1.0.0	2026-06-11 19:29:23.307	{"id":9,"name":"com.paypal.mcp/mcp","title":"PayPal","tagline":"Connect to the PayPal MCP Server","description":"PayPal MCP server provides access to PayPal services and operations for AI assistants","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:45.127Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":13,"type":"streamable-http","url":"https://mcp.paypal.com/mcp"},{"id":14,"type":"sse","url":"https://mcp.paypal.com/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_R_Wy_Aj_C_Dz_324a3b0a2e.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
post-hog	active	0.2.5	2026-06-11 19:29:53.047	{"id":10,"name":"io.github.PostHog/mcp","title":"PostHog","tagline":"Connect to the PostHog MCP Server","description":"Official PostHog MCP Server for product analytics, feature flags, experiments, and more.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:50:56.421Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":16,"type":"streamable-http","url":"https://mcp.posthog.com/mcp"},{"id":15,"type":"sse","url":"https://mcp.posthog.com/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Yz0_Wt_S_Oc_8e4d0f0070.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
amplitude	active	1.0.0	2026-06-11 19:28:25.27	{"id":11,"name":"com.amplitude/mcp-server","title":"Amplitude","tagline":"Connect to the Amplitude MCP Server","description":"Search, access, and get insights on your Amplitude data","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:08.257Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":17,"type":"streamable-http","url":"https://mcp.amplitude.com/mcp"},{"id":18,"type":"streamable-http","url":"https://mcp.eu.amplitude.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_G_Fjvl8_Pa_bd331a64fc.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_G_Fjvl8_Pa_a15896d97c.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
postman	active	2.8.9	2026-06-11 19:29:28.445	{"id":12,"name":"com.postman/postman-mcp-server","title":"Postman","tagline":"Connect to the Postman MCP Server","description":"A basic MCP server to operate on the Postman API.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:20.254Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":19,"type":"streamable-http","url":"https://mcp.postman.com/mcp"},{"id":20,"type":"streamable-http","url":"https://mcp.postman.com/minimal"},{"id":21,"type":"streamable-http","url":"https://mcp.eu.postman.com/mcp"},{"id":22,"type":"streamable-http","url":"https://mcp.eu.postman.com/minimal"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idr_UU_WRCO_c111cb0dea.png","mimeType":"image/png","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
close	active	1.0.1	2026-06-11 19:28:50.223	{"id":13,"name":"com.close/close-mcp","title":"Close","tagline":"Connect to the Close MCP Server","description":"Close CRM to manage your sales pipeline. Learn more at https://close.com or https://mcp.close.com","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:32.979Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":23,"type":"streamable-http","url":"https://mcp.close.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idpghi9sa_C_14d2cba8bf.png","mimeType":"image/png","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
wix	active	1.0.2	2026-06-11 19:29:47.22	{"id":14,"name":"com.wix/mcp","title":"Wix","tagline":"Connect to the Wix MCP Server","description":"A Model Context Protocol server for Wix AI tools","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:44.311Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":24,"type":"sse","url":"https://mcp.wix.com/sse"},{"id":25,"type":"streamable-http","url":"https://mcp.wix.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Qa_F_Jx_Orc_31d963143f.jpeg","mimeType":"image/jpeg","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
prisma	active	1.0.0	2026-06-11 19:30:05.827	{"id":15,"name":"io.prisma/mcp","title":"Prisma","tagline":"Connect to the Prisma MCP Server","description":"MCP server for managing Prisma Postgres.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:51:55.545Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":26,"type":"sse","url":"https://mcp.prisma.io/sse"},{"id":27,"type":"streamable-http","url":"https://mcp.prisma.io/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idz_L_5t_H6_B_e6163aea2d.jpg","mimeType":"image/jpeg","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
sanity	active	2.19.0	2026-06-11 19:30:10.774	{"id":16,"name":"io.sanity.www/mcp","title":"Sanity","tagline":"Connect to the Sanity MCP Server","description":"Direct access to your Sanity projects (content, datasets, releases, schemas) and agent rules","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:52:07.029Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":28,"type":"streamable-http","url":"https://mcp.sanity.io"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Qr019q7c_e4c0ec82b7.png","mimeType":"image/png","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
axiom	active	1.0.0	2026-06-11 19:28:11.99	{"id":17,"name":"co.axiom/mcp","title":"Axiom","tagline":"Connect to the Axiom MCP Server","description":"List datasets, schemas, run APL queries, and use prompts for exploration, anomalies, and monitoring.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:52:18.335Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":30,"type":"sse","url":"https://mcp.axiom.co/sse"},{"id":29,"type":"streamable-http","url":"https://mcp.axiom.co/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Xjr_Dncs4_d8a390ab33.jpeg","mimeType":"image/jpeg","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
hugging-face	active	0.2.33	2026-06-11 19:28:18.177	{"id":18,"name":"co.huggingface/hf-mcp-server","title":"Hugging Face","tagline":"Connect to the Hugging Face MCP Server","description":"Connect to Hugging Face Hub and thousands of Gradio AI Applications","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-05-19T16:52:30.024Z","publishedAt":"2026-06-18T09:50:05.210Z","remotes":[{"id":32,"type":"streamable-http","url":"https://huggingface.co/mcp?login"},{"id":31,"type":"streamable-http","url":"https://huggingface.co/mcp"},{"id":33,"type":"streamable-http","url":"https://huggingface.co/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_S6h_Od6z2_c35cc34669.jpeg","mimeType":"image/jpeg","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
unstoppable-domains	active	1.0.0	2026-07-27 13:25:24.004	{"id":19,"name":"com.unstoppabledomains/mcp-server","title":"Unstoppable Domains","tagline":"Connect to the Unstoppable Domains MCP Server","description":"Domain search, registration, DNS, marketplace, and checkout with your AI agent.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:25:24.004Z","publishedAt":"2026-07-27T06:25:23.975Z","remotes":[{"id":34,"type":"streamable-http","url":"https://api.unstoppabledomains.com/mcp/v1/"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Go_L_Bex_7_98cca38628.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
you-com-web-access-ai	active	3.5.0	2026-07-27 13:25:36.296	{"id":20,"name":"io.github.youdotcom-oss/mcp","title":"You.com Web Access & AI","tagline":"Connect to the You.com Web Access & AI MCP Server","description":"Web search, AI agent, and content extraction via You.com APIs","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:25:36.296Z","publishedAt":"2026-07-27T06:25:36.279Z","remotes":[{"id":35,"type":"streamable-http","url":"https://api.you.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idale_Bp_Jx_J_b69ac7e4b6.png","mimeType":"image/png","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
tolstoy-library	active	1.0.0	2026-07-31 15:57:40.033	{"id":21,"name":"io.github.GoTolstoy/library","title":"Tolstoy Library","tagline":"Connect to the Tolstoy Library MCP Server","description":"Browse, search, rename, and favorite your Tolstoy media library from any AI client.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:25:48.599Z","publishedAt":"2026-07-31T08:57:39.981Z","remotes":[{"id":36,"type":"streamable-http","url":"https://apilb.gotolstoy.com/mcp/v1/library/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id1bfg_NL_0_W_a737f0b436.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idswp_Hz_VRG_41aaa8f2a7.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
smart-bear	active	0.32.0	2026-07-27 13:26:00.585	{"id":22,"name":"com.smartbear/smartbear-mcp","title":"SmartBear","tagline":"Connect to the SmartBear MCP Server","description":"MCP server for AI access to SmartBear tools, including BugSnag, Reflect, Swagger, PactFlow, QTM4J.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:26:00.585Z","publishedAt":"2026-07-27T06:26:00.567Z","remotes":[{"id":37,"type":"streamable-http","url":"https://bugsnag.mcp.smartbear.com/mcp"},{"id":38,"type":"streamable-http","url":"https://zephyr.mcp.smartbear.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idi_Kc_F1m_Nh_08a3260e96.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
egnyte-remote	active	1.0.0	2026-07-27 13:26:12.344	{"id":23,"name":"com.egnyte/mcp-server","title":"Egnyte Remote","tagline":"Connect to the Egnyte Remote MCP Server","description":"Egnyte's remote MCP server for secure AI access, search, upload and file management in your account.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:26:12.344Z","publishedAt":"2026-07-27T06:26:12.319Z","remotes":[{"id":39,"type":"streamable-http","url":"https://mcp-server.egnyte.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_y3xa_T_9_348146b508.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
airtable	active	0.1.0	2026-07-31 15:55:31.929	{"id":24,"name":"com.airtable/mcp","title":"Airtable","tagline":"Connect to the Airtable MCP Server","description":"Official Airtable MCP server — database and operations layer for agents.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:26:24.433Z","publishedAt":"2026-07-31T08:55:31.874Z","remotes":[{"id":40,"type":"streamable-http","url":"https://mcp.airtable.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_RW_Qzz_VRI_a8b8b106af.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/iddyj0wl13_cb19e5e7fa.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
alchemy	active	0.5.2	2026-07-27 13:26:35.615	{"id":25,"name":"com.alchemy/mcp","title":"Alchemy","tagline":"Connect to the Alchemy MCP Server","description":"Blockchain data across 100+ chains: token prices, NFTs, transfers, simulation, traces, Solana DAS","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:26:35.615Z","publishedAt":"2026-07-27T06:26:35.599Z","remotes":[{"id":41,"type":"streamable-http","url":"https://mcp.alchemy.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/apple_touch_icon_824c201a3f.png","mimeType":"image/png"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
guru-remote	active	1.0.2	2026-07-27 13:26:47.365	{"id":26,"name":"com.getguru/mcp-server","title":"Guru Remote","tagline":"Connect to the Guru Remote MCP Server","description":"Guru MCP Server - Connect AI tools to your Guru knowledge base","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:26:47.365Z","publishedAt":"2026-07-27T06:26:47.339Z","remotes":[{"id":42,"type":"streamable-http","url":"https://mcp.api.getguru.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_KOIM_9_MG_a2d2a74e04.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
avo	active	1.0.0	2026-07-27 13:26:59.555	{"id":27,"name":"io.github.avohq/avo","title":"Avo","tagline":"Connect to the Avo MCP Server","description":"Define, ship & query your analytics tracking from one source of truth, trusted by humans and agents.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:26:59.555Z","publishedAt":"2026-07-27T06:26:59.535Z","remotes":[{"id":43,"type":"streamable-http","url":"https://mcp.avo.app/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idr574_A_Kk_X_6db6ee0e4c.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
flux	active	1.0.0	2026-07-27 13:27:11.348	{"id":28,"name":"io.github.black-forest-labs/flux-mcp","title":"FLUX","tagline":"Connect to the FLUX MCP Server","description":"Official FLUX MCP server. Generate, edit, vary, and browse images from Black Forest Labs.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:27:11.348Z","publishedAt":"2026-07-27T06:27:11.334Z","remotes":[{"id":44,"type":"streamable-http","url":"https://mcp.bfl.ai"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Lu4p_X9l_F_2d4acf82df.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
bitrix-24	active	1.0.0	2026-07-27 13:27:23.396	{"id":29,"name":"io.github.bitrix24/bitrix24","title":"Bitrix24","tagline":"Connect to the Bitrix24 MCP Server","description":"MCP server enabling AI agents to manage Bitrix24 features via standardized protocol","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:27:23.396Z","publishedAt":"2026-07-27T06:27:23.360Z","remotes":[{"id":45,"type":"streamable-http","url":"https://mcp.bitrix24.com/mcp/"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Fs_Tz_WJ_4_X_2dd0bbcd84.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
c-data-connect-ai	active	1.0.0	2026-07-27 13:27:35.15	{"id":30,"name":"com.cdata/cdata-connect-ai","title":"CData Connect AI","tagline":"Connect to the CData Connect AI MCP Server","description":"Cloud-hosted MCP server for secure AI access to enterprise data sources via CData Connect AI.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:27:35.150Z","publishedAt":"2026-07-27T06:27:35.130Z","remotes":[{"id":46,"type":"streamable-http","url":"https://mcp.cloud.cdata.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_XN_Pnsge_I_18a9c34852.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
crypto-quant	active	0.1.1	2026-07-27 13:27:46.962	{"id":31,"name":"com.cryptoquant/mcp-server","title":"CryptoQuant","tagline":"Connect to the CryptoQuant MCP Server","description":"Query cryptocurrency on-chain data, OHLCV prices, market data, and Research & QuickTake insights.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:27:46.962Z","publishedAt":"2026-07-27T06:27:46.944Z","remotes":[{"id":47,"type":"streamable-http","url":"https://mcp.cryptoquant.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_V_Lc_E486p_f1a6e16cf8.png","mimeType":"image/png","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
cypress-cloud	active	1.0.0	2026-07-27 13:27:58.817	{"id":32,"name":"io.cypress.mcp/cypress-cloud","title":"Cypress Cloud","tagline":"Connect to the Cypress Cloud MCP Server","description":"Direct access to Cypress tests results and accessibility reports in your AI workflow.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:27:58.817Z","publishedAt":"2026-07-27T06:27:58.799Z","remotes":[{"id":48,"type":"streamable-http","url":"https://mcp.cypress.io/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idv3zwm_Si_Y_97b8f8b3d4.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
exa	active	3.1.3	2026-07-27 13:28:10.635	{"id":33,"name":"ai.exa/exa","title":"Exa","tagline":"Connect to the Exa MCP Server","description":"Fast, intelligent web search and web crawling.\\n\\nNew mcp tool: Exa-code is a context tool for coding ","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:28:10.635Z","publishedAt":"2026-07-27T06:28:10.618Z","remotes":[{"id":49,"type":"streamable-http","url":"https://mcp.exa.ai/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idek_S6b5_Vc_846a9be831.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
fibery	active	1.0.0	2026-07-27 13:28:22.675	{"id":34,"name":"io.github.Fibery-inc/mcp","title":"Fibery","tagline":"Connect to the Fibery MCP Server","description":"Connect AI Assistant to Fibery — operating system for orgs run by nerds.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:28:22.675Z","publishedAt":"2026-07-27T06:28:22.659Z","remotes":[{"id":50,"type":"streamable-http","url":"https://mcp.fibery.io/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idc_Az9_Jna3_3655f33477.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
grafana	active	v0.17.2	2026-07-31 15:56:04.253	{"id":35,"name":"io.github.grafana/mcp-grafana","title":"Grafana","tagline":"Connect to the Grafana MCP Server","description":"An MCP server giving access to Grafana dashboards, data and more.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:28:34.695Z","publishedAt":"2026-07-31T08:56:03.609Z","remotes":[{"id":51,"type":"streamable-http","url":"https://mcp.grafana.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Voh_Wbum_D_22ee5e3d3d.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_KI_2_Ge8_Tx_8fa7637298.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
hackle	active	1.0.0	2026-07-27 13:28:46.707	{"id":36,"name":"io.github.hackle-io/hackle-mcp","title":"Hackle","tagline":"Connect to the Hackle MCP Server","description":"Remote MCP server for the Hackle Admin API: experiments, feature flags, remote config, messaging.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:28:46.707Z","publishedAt":"2026-07-27T06:28:46.687Z","remotes":[{"id":52,"type":"streamable-http","url":"https://mcp.hackle.io/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idb_Cgt3_EZ_5_6022811256.png","mimeType":"image/png","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
himalayas-remote-jobs	active	1.0.2	2026-07-27 13:28:57.931	{"id":37,"name":"app.himalayas/mcp","title":"Himalayas Remote Jobs","tagline":"Connect to the Himalayas Remote Jobs MCP Server","description":"Search and post remote jobs, browse companies, check salaries, and find talent on Himalayas.app","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:28:57.931Z","publishedAt":"2026-07-27T06:28:57.821Z","remotes":[{"id":53,"type":"streamable-http","url":"https://mcp.himalayas.app/mcp"},{"id":54,"type":"sse","url":"https://mcp.himalayas.app/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/icon_80aa4c0cf9.png","mimeType":"image/png"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
honeycomb	active	1.0.0	2026-07-31 15:56:17.715	{"id":38,"name":"io.honeycomb/mcp","title":"Honeycomb","tagline":"Connect to the Honeycomb MCP Server","description":"Query Honeycomb observability data: traces, events, metrics, SLOs, triggers, and boards.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:29:09.821Z","publishedAt":"2026-07-31T08:56:17.624Z","remotes":[{"id":55,"type":"streamable-http","url":"https://mcp.honeycomb.io/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idc_Eu_Mai3_Y_51bd126c09.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Zffh_QN_Fl_bfda41d0f1.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
jotform	active	1.0.0	2026-07-31 15:56:30.157	{"id":39,"name":"com.jotform/mcp","title":"Jotform","tagline":"Connect to the Jotform MCP Server","description":"Jotform MCP","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:29:22.378Z","publishedAt":"2026-07-31T08:56:30.074Z","remotes":[{"id":56,"type":"streamable-http","url":"https://mcp.jotform.com/"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idcaz_TK_Ep1_099d00aa95.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Rg_Fx_ND_Ty_d7d836bfa5.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
jumpcloud	active	0.0.38	2026-07-27 13:29:34.445	{"id":40,"name":"com.jumpcloud/jumpcloud-genai","title":"Jumpcloud","tagline":"Connect to the Jumpcloud MCP Server","description":"An MCP server that provides an API to LLMs to manage their JumpCloud resources.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:29:34.445Z","publishedAt":"2026-07-27T06:29:34.429Z","remotes":[{"id":57,"type":"streamable-http","url":"https://mcp.jumpcloud.com/v1"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Q_Wjip_S_Dg_57592c9ce8.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
kajabi	active	1.0.0	2026-07-27 13:29:46.253	{"id":41,"name":"com.kajabi/kajabi","title":"Kajabi","tagline":"Connect to the Kajabi MCP Server","description":"Manage Kajabi from any MCP client — products, pages, contacts, offers, emails, analytics.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:29:46.253Z","publishedAt":"2026-07-27T06:29:46.233Z","remotes":[{"id":58,"type":"streamable-http","url":"https://mcp.kajabi.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_BPULB_Tw_A_b4460963bc.svg","mimeType":"image/svg+xml","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
lucid	active	1.0.0	2026-07-27 13:29:57.456	{"id":42,"name":"app.lucid.mcp/lucid","title":"Lucid","tagline":"Connect to the Lucid MCP Server","description":"Lucid’s connector creates diagrams, searches, edits, shares, and retrieves docs to summarize.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:29:57.456Z","publishedAt":"2026-07-27T06:29:57.441Z","remotes":[{"id":59,"type":"streamable-http","url":"https://mcp.lucid.app/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/cab2c5c2_21ed_4272_8606_4ce6e117da17_b893d525b7.png","mimeType":"image/png"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
mapbox	active	0.12.7	2026-07-27 13:30:09.602	{"id":43,"name":"io.github.mapbox/mcp-server","title":"Mapbox","tagline":"Connect to the Mapbox MCP Server","description":"Geospatial intelligence with Mapbox APIs like geocoding, POI search, directions, isochrones, etc.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:30:09.602Z","publishedAt":"2026-07-27T06:30:09.586Z","remotes":[{"id":60,"type":"streamable-http","url":"https://mcp.mapbox.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Ks_p_3_Ey_088e4b1f1c.png","mimeType":"image/png","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
mux	active	12.8.0	2026-07-27 13:30:21.396	{"id":44,"name":"com.mux/mcp","title":"Mux","tagline":"Connect to the Mux MCP Server","description":"The official MCP Server for the Mux API","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:30:21.396Z","publishedAt":"2026-07-27T06:30:21.382Z","remotes":[{"id":61,"type":"streamable-http","url":"https://mcp.mux.com"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idd_VMK_Dr_E_9ee0d1c0fd.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
new-relic	active	0.1.0	2026-07-27 13:30:33.181	{"id":45,"name":"com.newrelic/mcp-server","title":"New Relic","tagline":"Connect to the New Relic MCP Server","description":"Access New Relic observability data through MCP - query metrics, logs, traces, entities, and more","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:30:33.181Z","publishedAt":"2026-07-27T06:30:33.165Z","remotes":[{"id":62,"type":"streamable-http","url":"https://mcp.newrelic.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idj_OU_5_Ls_Vn_b153d861d2.svg","mimeType":"image/svg+xml","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
onlyoffice	active	3.2.0	2026-07-27 13:30:45.489	{"id":46,"name":"io.github.ONLYOFFICE/docspace","title":"Onlyoffice","tagline":"Connect to the Onlyoffice MCP Server","description":"A room-based collaborative platform","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:30:45.489Z","publishedAt":"2026-07-27T06:30:45.477Z","remotes":[{"id":63,"type":"sse","url":"https://mcp.onlyoffice.com/sse"},{"id":64,"type":"streamable-http","url":"https://mcp.onlyoffice.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idc_J_Gf_Mm1x_3abc6daf5a.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
open-video	active	1.1.0	2026-07-27 13:30:57.197	{"id":47,"name":"video.open/open-video","title":"Open Video","tagline":"Connect to the Open Video MCP Server","description":"AI-powered video publishing, channel management, and monetization via open.video","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:30:57.197Z","publishedAt":"2026-07-27T06:30:57.182Z","remotes":[{"id":65,"type":"streamable-http","url":"https://mcp.open.video/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_C4_Z_Er2jl_efcb489bf4.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
open-agenda	active	1.3.2	2026-07-27 13:31:08.655	{"id":48,"name":"com.openagenda/mcp","title":"OpenAgenda","tagline":"Connect to the OpenAgenda MCP Server","description":"Search, analyze and manage events on OpenAgenda.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:31:08.655Z","publishedAt":"2026-07-27T06:31:08.639Z","remotes":[{"id":66,"type":"streamable-http","url":"https://mcp.openagenda.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/openagenda_icon_512_white_abac3fef40.png","mimeType":"image/png"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/openagenda_icon_white_463b7b7aad.svg","mimeType":"image/svg+xml"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
quicknode	active	1.0.0	2026-07-31 15:56:55.454	{"id":49,"name":"io.github.quicknode/mcp","title":"Quicknode","tagline":"Connect to the Quicknode MCP Server","description":"Manage your blockchain infrastructure across 80+ chains with your agents.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:31:22.594Z","publishedAt":"2026-07-31T08:56:55.393Z","remotes":[{"id":67,"type":"streamable-http","url":"https://mcp.quicknode.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Gkd_Tc_T_Q_6cd067aa96.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Eo_Rfmv8_I_b2228a7aa7.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
railway	active	1.0.0	2026-07-31 15:57:13.759	{"id":50,"name":"com.railway/mcp","title":"Railway","tagline":"Connect to the Railway MCP Server","description":"Develop, manage, and debug Railway projects, services, and deployments from within agents.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:31:34.656Z","publishedAt":"2026-07-31T08:57:13.686Z","remotes":[{"id":68,"type":"streamable-http","url":"https://mcp.railway.com/"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_N_Pa1_W_g_1b0b09d3c0.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Nf_YM_Ddf_P_d0762ab2e7.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
roboflow-official	active	1.0.3	2026-07-27 13:31:46.505	{"id":51,"name":"com.roboflow/roboflow-mcp","title":"Roboflow (Official)","tagline":"Connect to the Roboflow (Official) MCP Server","description":"Roboflow computer vision for AI agents: datasets, annotation, versioning, workflows, inference.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:31:46.505Z","publishedAt":"2026-07-27T06:31:46.487Z","remotes":[{"id":69,"type":"streamable-http","url":"https://mcp.roboflow.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/icon_5a61ee5b18.png","mimeType":"image/png"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
serpstat	active	1.1.5	2026-07-27 13:31:58.494	{"id":52,"name":"com.serpstat/mcp","title":"Serpstat","tagline":"Connect to the Serpstat MCP Server","description":"Automate your daily SEO tasks and get results in a few seconds with Serpstat SEO Tools MCP","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:31:58.494Z","publishedAt":"2026-07-27T06:31:58.473Z","remotes":[{"id":70,"type":"streamable-http","url":"https://mcp.serpstat.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/favicon_32x32_9deb9e3426.png","mimeType":"image/png"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/favicon_16x16_978f8c1d24.png","mimeType":"image/png"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/apple_touch_icon_60x60_0e141e6ab3.png","mimeType":"image/png"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/apple_touch_icon_120x120_989cf97cef.png","mimeType":"image/png"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/mstile_144x144_86f983426c.png","mimeType":"image/png"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/apple_touch_icon_180x180_d5650b553b.png","mimeType":"image/png"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
tenderly	active	1.0.1	2026-07-31 15:57:28.375	{"id":53,"name":"co.tenderly/tenderly-mcp","title":"Tenderly","tagline":"Connect to the Tenderly MCP Server","description":"Tenderly MCP server for blockchain dev — simulate, debug, and test on 100+ networks.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:32:10.706Z","publishedAt":"2026-07-31T08:57:28.309Z","remotes":[{"id":71,"type":"streamable-http","url":"https://mcp.tenderly.co/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Np_P91btg_2999d326fa.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idg5pc_CT_Me_199bebd567.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
user-guiding	active	1.0.0	2026-07-27 13:32:22.58	{"id":54,"name":"io.github.userguiding/mcp","title":"UserGuiding","tagline":"Connect to the UserGuiding MCP Server","description":"Manage users, track events, companies, and knowledge base articles in UserGuiding.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:32:22.580Z","publishedAt":"2026-07-27T06:32:22.566Z","remotes":[{"id":72,"type":"streamable-http","url":"https://mcp.userguiding.com/mcp/"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Gqzc_El_EH_ac5ec7c6bf.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
wordlift	active	1.0.7	2026-07-27 13:32:34.408	{"id":55,"name":"io.wordlift/mcp-server","title":"Wordlift","tagline":"Connect to the Wordlift MCP Server","description":"Knowledge Graph, GraphQL, GS1 Digital Link and SEO tools for semantic content optimization.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:32:34.408Z","publishedAt":"2026-07-27T06:32:34.385Z","remotes":[{"id":73,"type":"sse","url":"https://mcp.wordlift.io/sse"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Y8_Nf90og_3c8f9dbd0a.png","mimeType":"image/png","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
zigpoll	active	2.0.0	2026-07-27 13:32:46.428	{"id":56,"name":"com.zigpoll/zigpoll-mcp","title":"Zigpoll","tagline":"Connect to the Zigpoll MCP Server","description":"Analyze Zigpoll survey responses, track trends, and get AI-powered insights.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:32:46.428Z","publishedAt":"2026-07-27T06:32:46.415Z","remotes":[{"id":74,"type":"streamable-http","url":"https://mcp.zigpoll.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_b4l_E3_VQ_6438fbc3e9.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
ivisa	active	0.0.3	2026-07-27 13:32:58.532	{"id":57,"name":"com.ivisa.www/mcp","title":"Ivisa","tagline":"Connect to the Ivisa MCP Server","description":"Check visa requirements and travel documents for international travel destinations.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:32:58.532Z","publishedAt":"2026-07-27T06:32:58.503Z","remotes":[{"id":75,"type":"streamable-http","url":"https://www.ivisa.com/mcp"},{"id":76,"type":"sse","url":"https://www.ivisa.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Go_Qi_Xix_P_239207701b.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
veed-ai-video-generator	active	1.0.0	2026-07-27 13:33:09.725	{"id":58,"name":"io.veed/fabric-mcp","title":"VEED AI Video Generator","tagline":"Connect to the VEED AI Video Generator MCP Server","description":"Generate AI talking-head videos with custom characters and voices.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:33:09.725Z","publishedAt":"2026-07-27T06:33:09.706Z","remotes":[{"id":77,"type":"streamable-http","url":"https://www.veed.io/api/v1/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/favicon_prod_d15545bdfc.svg","mimeType":"image/svg+xml"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/favicon_32x32_f264fbd0f8.png","mimeType":"image/png"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
fingerprint	active	0.1.35	2026-07-27 13:33:21.382	{"id":59,"name":"io.github.fingerprintjs/fingerprint-mcp-server","title":"Fingerprint","tagline":"Connect to the Fingerprint MCP Server","description":"Device intelligence for AI agents: Fingerprint events, smart signals, and API key management.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:33:21.382Z","publishedAt":"2026-07-27T06:33:21.372Z","remotes":[{"id":78,"type":"streamable-http","url":"https://mcp.fpjs.io/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id7_Fxo_YI_61_3ef3687cce.png","mimeType":"image/png","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
altmetric	active	1.1.0	2026-07-27 13:33:32.848	{"id":60,"name":"com.altmetric.mcp/altmetric-mcp","title":"Altmetric","tagline":"Connect to the Altmetric MCP Server","description":"MCP server for Altmetric APIs - track research attention across news, policy, social media, and more","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:33:32.848Z","publishedAt":"2026-07-27T06:33:32.831Z","remotes":[{"id":79,"type":"streamable-http","url":"https://mcp.altmetric.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/icon_50fcccdb0a.svg","mimeType":"image/svg+xml"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
brandfetch	active	1.0.1	2026-07-31 15:55:50.736	{"id":61,"name":"io.brandfetch/brandfetch","title":"Brandfetch","tagline":"Connect to the Brandfetch MCP Server","description":"Search brands and retrieve design assets, company data, other brand context from Brandfetch's API","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:33:44.412Z","publishedAt":"2026-07-31T08:55:50.665Z","remotes":[{"id":80,"type":"streamable-http","url":"https://mcp.brandfetch.io/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_X_Gq6_S_Iu2_39f64c1e3e.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idd_CQ_52_AR_5_a0d0556d83.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
cello	active	1.0.1	2026-07-27 13:33:55.459	{"id":62,"name":"so.cello/mcp","title":"Cello","tagline":"Connect to the Cello MCP Server","description":"Cello MCP server to launch and manage your Referral and Partner program","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:33:55.459Z","publishedAt":"2026-07-27T06:33:55.441Z","remotes":[{"id":81,"type":"streamable-http","url":"https://mcp.cello.so/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/icon_48x48_f037a7c241.png","mimeType":"image/png"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
composio	active	1.0.5	2026-07-27 13:34:06.747	{"id":63,"name":"io.github.ComposioHQ/composio","title":"Composio","tagline":"Connect to the Composio MCP Server","description":"Connect AI agents to 1000+ apps with managed authentication and tool-calling.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:34:06.747Z","publishedAt":"2026-07-27T06:34:06.652Z","remotes":[{"id":82,"type":"streamable-http","url":"https://connect.composio.dev/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/Logomark_Black_fe5c6c91c6.svg","mimeType":"image/svg+xml","theme":"light"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/Logomark_White_b349b06097.svg","mimeType":"image/svg+xml","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
gtmetrix	active	1.1.0	2026-07-27 13:34:18.943	{"id":64,"name":"com.gtmetrix/gtmetrix","title":"Gtmetrix","tagline":"Connect to the Gtmetrix MCP Server","description":"Analyze web performance and get optimization insights from GTmetrix, directly in your AI workflow.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:34:18.943Z","publishedAt":"2026-07-27T06:34:18.929Z","remotes":[{"id":83,"type":"streamable-http","url":"https://gtmetrix.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_S5_Ofsvh_D_030852542c.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
lusha	active	1.0.0	2026-07-31 15:56:43.789	{"id":65,"name":"com.lusha.mcp/mcp","title":"Lusha","tagline":"Connect to the Lusha MCP Server","description":"Lusha MCP server for authorized business profile, usage, and buying-signal insights.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:34:30.787Z","publishedAt":"2026-07-31T08:56:43.704Z","remotes":[{"id":84,"type":"streamable-http","url":"https://mcp.lusha.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Oqhne_W4l_160b2c6387.svg","mimeType":"image/svg+xml","theme":"dark"},{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_Hn_Bv_Pm_MF_b3cab3545f.svg","mimeType":"image/svg+xml","theme":"light"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
opus-clip	active	0.1.2	2026-07-27 13:34:42.641	{"id":66,"name":"io.github.opus-pro/opusclip","title":"OpusClip","tagline":"Connect to the OpusClip MCP Server","description":"Turn long videos into AI-curated short clips: caption, reframe, thumbnail, schedule, and publish.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:34:42.641Z","publishedAt":"2026-07-27T06:34:42.627Z","remotes":[{"id":85,"type":"streamable-http","url":"https://mcp.opus.pro/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id16btw_Mn_34285031cd.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
rackspace-spot	active	0.3.2	2026-07-27 13:34:54.483	{"id":67,"name":"io.github.rackspace-spot/spot-mcp","title":"Rackspace Spot","tagline":"Connect to the Rackspace Spot MCP Server","description":"Manage Rackspace Spot Kubernetes Cloudspaces, node pools, and VMs from your AI assistant.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:34:54.483Z","publishedAt":"2026-07-27T06:34:54.469Z","remotes":[{"id":86,"type":"streamable-http","url":"https://mcp.spot.rackspace.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/id_R_Am_XHO_Xj_c7492988ea.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
send-pulse	active	1.0.0	2026-07-27 13:35:06.234	{"id":68,"name":"com.sendpulse.mcp/mcp-server","title":"SendPulse","tagline":"Connect to the SendPulse MCP Server","description":"Empower AI agents with SendPulse email, CRM, chatbot, SMTP, and course automation","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:35:06.234Z","publishedAt":"2026-07-27T06:35:06.215Z","remotes":[{"id":87,"type":"streamable-http","url":"https://mcp.sendpulse.com/mcp"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idv4t5t_Kt_Q_bad208ede1.jpeg","mimeType":"image/jpeg","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
snitcher	active	1.1.0	2026-07-27 13:35:18.252	{"id":69,"name":"com.snitcher/snitcher","title":"Snitcher","tagline":"Connect to the Snitcher MCP Server","description":"Identify companies visiting your website: organisations, contacts, segments, tags, CRM sync.","websiteUrl":null,"authType":"oauth2","isOfficial":true,"isPublished":true,"origin":"registry","createdAt":"2026-07-27T06:35:18.252Z","publishedAt":"2026-07-27T06:35:18.236Z","remotes":[{"id":88,"type":"streamable-http","url":"https://app.snitcher.com/mcp/snitcher"}],"tools":[],"tags":{"data":[]},"extendsCredential":null,"icons":[{"src":"https://n8niostorageaccount.blob.core.windows.net/n8nio-strapi-blobs-prod/assets/idgwm_NEV_1_f421fc6c44.svg","mimeType":"image/svg+xml","theme":"dark"}]}	2026-08-03 11:54:45.021+07	2026-08-03 11:54:45.021+07
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migrations (id, "timestamp", name) FROM stdin;
1	1587669153312	InitialMigration1587669153312
2	1589476000887	WebhookModel1589476000887
3	1594828256133	CreateIndexStoppedAt1594828256133
4	1607431743768	MakeStoppedAtNullable1607431743768
5	1611144599516	AddWebhookId1611144599516
6	1617270242566	CreateTagEntity1617270242566
7	1620824779533	UniqueWorkflowNames1620824779533
8	1626176912946	AddwaitTill1626176912946
9	1630419189837	UpdateWorkflowCredentials1630419189837
10	1644422880309	AddExecutionEntityIndexes1644422880309
11	1646834195327	IncreaseTypeVarcharLimit1646834195327
12	1646992772331	CreateUserManagement1646992772331
13	1648740597343	LowerCaseUserEmail1648740597343
14	1652254514002	CommunityNodes1652254514002
15	1652367743993	AddUserSettings1652367743993
16	1652905585850	AddAPIKeyColumn1652905585850
17	1654090467022	IntroducePinData1654090467022
18	1658932090381	AddNodeIds1658932090381
19	1659902242948	AddJsonKeyPinData1659902242948
20	1660062385367	CreateCredentialsUserRole1660062385367
21	1663755770893	CreateWorkflowsEditorRole1663755770893
22	1664196174001	WorkflowStatistics1664196174001
23	1665484192212	CreateCredentialUsageTable1665484192212
24	1665754637025	RemoveCredentialUsageTable1665754637025
25	1669739707126	AddWorkflowVersionIdColumn1669739707126
26	1669823906995	AddTriggerCountColumn1669823906995
27	1671535397530	MessageEventBusDestinations1671535397530
28	1671726148421	RemoveWorkflowDataLoadedFlag1671726148421
29	1673268682475	DeleteExecutionsWithWorkflows1673268682475
30	1674138566000	AddStatusToExecutions1674138566000
31	1674509946020	CreateLdapEntities1674509946020
32	1675940580449	PurgeInvalidWorkflowConnections1675940580449
33	1676996103000	MigrateExecutionStatus1676996103000
34	1677236854063	UpdateRunningExecutionStatus1677236854063
35	1677501636754	CreateVariables1677501636754
36	1679416281778	CreateExecutionMetadataTable1679416281778
37	1681134145996	AddUserActivatedProperty1681134145996
38	1681134145997	RemoveSkipOwnerSetup1681134145997
39	1690000000000	MigrateIntegerKeysToString1690000000000
40	1690000000020	SeparateExecutionData1690000000020
41	1690000000030	RemoveResetPasswordColumns1690000000030
42	1690000000030	AddMfaColumns1690000000030
43	1690787606731	AddMissingPrimaryKeyOnExecutionData1690787606731
44	1691088862123	CreateWorkflowNameIndex1691088862123
45	1692967111175	CreateWorkflowHistoryTable1692967111175
46	1693491613982	ExecutionSoftDelete1693491613982
47	1693554410387	DisallowOrphanExecutions1693554410387
48	1694091729095	MigrateToTimestampTz1694091729095
49	1695128658538	AddWorkflowMetadata1695128658538
50	1695829275184	ModifyWorkflowHistoryNodesAndConnections1695829275184
51	1700571993961	AddGlobalAdminRole1700571993961
52	1705429061930	DropRoleMapping1705429061930
53	1711018413374	RemoveFailedExecutionStatus1711018413374
54	1711390882123	MoveSshKeysToDatabase1711390882123
55	1712044305787	RemoveNodesAccess1712044305787
56	1714133768519	CreateProject1714133768519
57	1714133768521	MakeExecutionStatusNonNullable1714133768521
58	1717498465931	AddActivatedAtUserSetting1717498465931
59	1720101653148	AddConstraintToExecutionMetadata1720101653148
60	1721377157740	FixExecutionMetadataSequence1721377157740
61	1723627610222	CreateInvalidAuthTokenTable1723627610222
62	1723796243146	RefactorExecutionIndices1723796243146
63	1724753530828	CreateAnnotationTables1724753530828
64	1724951148974	AddApiKeysTable1724951148974
65	1726606152711	CreateProcessedDataTable1726606152711
66	1727427440136	SeparateExecutionCreationFromStart1727427440136
67	1728659839644	AddMissingPrimaryKeyOnAnnotationTagMapping1728659839644
68	1729607673464	UpdateProcessedDataValueColumnToText1729607673464
69	1729607673469	AddProjectIcons1729607673469
70	1730386903556	CreateTestDefinitionTable1730386903556
71	1731404028106	AddDescriptionToTestDefinition1731404028106
72	1731582748663	MigrateTestDefinitionKeyToString1731582748663
73	1732271325258	CreateTestMetricTable1732271325258
74	1732549866705	CreateTestRun1732549866705
75	1733133775640	AddMockedNodesColumnToTestDefinition1733133775640
76	1734479635324	AddManagedColumnToCredentialsTable1734479635324
77	1736172058779	AddStatsColumnsToTestRun1736172058779
78	1736947513045	CreateTestCaseExecutionTable1736947513045
79	1737715421462	AddErrorColumnsToTestRuns1737715421462
80	1738709609940	CreateFolderTable1738709609940
81	1739549398681	CreateAnalyticsTables1739549398681
82	1740445074052	UpdateParentFolderIdColumn1740445074052
83	1741167584277	RenameAnalyticsToInsights1741167584277
84	1742918400000	AddScopesColumnToApiKeys1742918400000
85	1745322634000	ClearEvaluation1745322634000
86	1745587087521	AddWorkflowStatisticsRootCount1745587087521
87	1745934666076	AddWorkflowArchivedColumn1745934666076
88	1745934666077	DropRoleTable1745934666077
89	1747824239000	AddProjectDescriptionColumn1747824239000
90	1750252139166	AddLastActiveAtColumnToUser1750252139166
91	1750252139166	AddScopeTables1750252139166
92	1750252139167	AddRolesTables1750252139167
93	1750252139168	LinkRoleToUserTable1750252139168
94	1750252139170	RemoveOldRoleColumn1750252139170
95	1752669793000	AddInputsOutputsToTestCaseExecution1752669793000
96	1753953244168	LinkRoleToProjectRelationTable1753953244168
97	1754475614601	CreateDataStoreTables1754475614601
98	1754475614602	ReplaceDataStoreTablesWithDataTables1754475614602
99	1756906557570	AddTimestampsToRoleAndRoleIndexes1756906557570
100	1758731786132	AddAudienceColumnToApiKeys1758731786132
101	1758794506893	AddProjectIdToVariableTable1758794506893
102	1759399811000	ChangeValueTypesForInsights1759399811000
103	1760019379982	CreateChatHubTables1760019379982
104	1760020000000	CreateChatHubAgentTable1760020000000
105	1760020838000	UniqueRoleNames1760020838000
106	1760116750277	CreateOAuthEntities1760116750277
107	1760314000000	CreateWorkflowDependencyTable1760314000000
108	1760965142113	DropUnusedChatHubColumns1760965142113
109	1761047826451	AddWorkflowVersionColumn1761047826451
110	1761655473000	ChangeDependencyInfoToJson1761655473000
111	1761773155024	AddAttachmentsToChatHubMessages1761773155024
112	1761830340990	AddToolsColumnToChatHubTables1761830340990
113	1762177736257	AddWorkflowDescriptionColumn1762177736257
114	1762763704614	BackfillMissingWorkflowHistoryRecords1762763704614
115	1762771264000	ChangeDefaultForIdInUserTable1762771264000
116	1762771954619	AddIsGlobalColumnToCredentialsTable1762771954619
117	1762847206508	AddWorkflowHistoryAutoSaveFields1762847206508
118	1763047800000	AddActiveVersionIdColumn1763047800000
119	1763048000000	ActivateExecuteWorkflowTriggerWorkflows1763048000000
120	1763572724000	ChangeOAuthStateColumnToUnboundedVarchar1763572724000
121	1763716655000	CreateBinaryDataTable1763716655000
122	1764167920585	CreateWorkflowPublishHistoryTable1764167920585
123	1764276827837	AddCreatorIdToProjectTable1764276827837
124	1764682447000	CreateDynamicCredentialResolverTable1764682447000
125	1764689388394	AddDynamicCredentialEntryTable1764689388394
126	1765448186933	BackfillMissingWorkflowHistoryRecords1765448186933
127	1765459448000	AddResolvableFieldsToCredentials1765459448000
128	1765788427674	AddIconToAgentTable1765788427674
129	1765804780000	ConvertAgentIdToUuid1765804780000
130	1765886667897	AddAgentIdForeignKeys1765886667897
131	1765892199653	AddWorkflowVersionIdToExecutionData1765892199653
132	1766064542000	AddWorkflowPublishScopeToProjectRoles1766064542000
133	1766068346315	AddChatMessageIndices1766068346315
134	1766500000000	ExpandInsightsWorkflowIdLength1766500000000
135	1767018516000	ChangeWorkflowStatisticsFKToNoAction1767018516000
136	1768402473068	ExpandModelColumnLength1768402473068
137	1768557000000	AddStoredAtToExecutionEntity1768557000000
138	1768901721000	AddDynamicCredentialUserEntryTable1768901721000
139	1769000000000	AddPublishedVersionIdToWorkflowDependency1769000000000
140	1769433700000	CreateSecretsProviderConnectionTables1769433700000
141	1769698710000	CreateWorkflowPublishedVersionTable1769698710000
142	1769784356000	ExpandSubjectIDColumnLength1769784356000
143	1769900001000	AddWorkflowUnpublishScopeToCustomRoles1769900001000
144	1770000000000	CreateChatHubToolsTable1770000000000
145	1770000000000	ExpandProviderIdColumnLength1770000000000
146	1770220686000	CreateWorkflowBuilderSessionTable1770220686000
147	1771417407753	AddScalingFieldsToTestRun1771417407753
148	1771500000000	MigrateExternalSecretsToEntityStorage1771500000000
149	1771500000001	AddUnshareScopeToCustomRoles1771500000001
150	1771500000002	AddFilesColumnToChatHubAgents1771500000002
151	1772000000000	AddSuggestedPromptsToAgentTable1772000000000
152	1772619247761	AddRoleColumnToProjectSecretsProviderAccess1772619247761
153	1772619247762	ChangeWorkflowPublishedVersionFKsToRestrict1772619247762
154	1772700000000	AddTypeToChatHubSessions1772700000000
155	1772800000000	CreateRoleMappingRuleTable1772800000000
156	1773000000000	CreateCredentialDependencyTable1773000000000
157	1774280963551	AddRestoreFieldsToWorkflowBuilderSession1774280963551
158	1774854660000	CreateInstanceVersionHistoryTable1774854660000
159	1775000000000	CreateInstanceAiTables1775000000000
160	1775116241000	CreateTokenExchangeJtiTable1775116241000
161	1775740765000	ChangeWorkflowPublishHistoryVersionIdToSetNull1775740765000
162	1776000000000	CreateTrustedKeyTables1776000000000
163	1776150756000	CreateFavoritesTable1776150756000
164	1777000000000	CreateDeploymentKeyTable1777000000000
165	1777023444000	AddJweKeyIndexesToDeploymentKey1777023444000
166	1777045000000	AddTracingContextToExecution1777045000000
167	1777100000000	AddLangsmithIdsToInstanceAiRunSnapshots1777100000000
168	1777281990043	CreateAiBuilderTemporaryWorkflowTable1777281990043
169	1777420800000	ExpandVariablesValueColumnToText1777420800000
170	1777996709110	AddRunIndexToTestCaseExecution1777996709110
171	1778000000000	AddExecutionDeduplicationKey1778000000000
172	1778100000000	CreateEvaluationConfig1778100000000
173	1778100001000	AddWorkflowVersionToTestRun1778100001000
174	1778100002000	AddEvaluationConfigColumnsToTestRun1778100002000
175	1778496086558	CreateEvaluationCollection1778496086558
176	1783000000000	CreateAgentTables1783000000000
177	1783000000001	CreateAgentExecutionTables1783000000001
178	1784000000000	CreateAgentObservationTables1784000000000
179	1784000000001	ReplaceAgentObservationTables1784000000001
180	1784000000002	DropAgentExecutionWorkingMemory1784000000002
181	1784000000003	LimitWorkflowVersionTriggerToContent1784000000003
182	1784000000004	AddInsightsRawTimestampIdIndex1784000000004
183	1784000000005	CreateMcpRegistryServerTable1784000000005
184	1784000000006	AddNodeGroupsColumnToWorkflowAndHistory1784000000006
185	1784000000007	CreateInstanceAiCheckpointTable1784000000007
186	1784000000008	ResetInstanceAiNativePersistence1784000000008
187	1784000000009	CreateAgentMemoryEntryTables1784000000009
188	1784000000010	RefactorAgentObservationScope1784000000010
189	1784000000011	CreateAgentHistoryTable1784000000011
190	1784000000012	CreateInstanceAiObservationTables1784000000012
191	1784000000013	SplitRedactionScopeInCustomRoles1784000000013
192	1784000000014	PersistInstanceAiPendingConfirmations1784000000014
193	1784000000015	AddSourceWorkflowIdToWorkflow1784000000015
194	1784000000016	UseSlugAsPrimaryKeyInMcpRegistryServer1784000000016
195	1784000000017	AddLastUsedAtToApiKey1784000000017
196	1784000000018	CreateAgentFilesTable1784000000018
197	1784000000019	AddCustomTelemetryTagsToProject1784000000019
198	1784000000021	CreateAgentTaskDefinitionTable1784000000021
199	1784000000022	AddSubAgentLinkageToAgentExecutionThreads1784000000022
200	1784000000023	CreateInstanceAiMcpRegistryConnectionTable1784000000023
201	1784000000024	AddResourceToOAuthAuthorizationCodes1784000000024
202	1784000000025	MigrateRedactionEnforcementToFloor1784000000025
203	1784000000026	AddScopeColumnToOAuthTables1784000000026
204	1784000000027	CreateWorkflowPublicationOutboxTable1784000000027
205	1784000000028	AddProjectIdToInstanceAiThread1784000000028
206	1784000000029	AddJsonSizeBytesAndWorkflowVersionIdToExecutionEntity1784000000029
207	1784000000030	CreateAgentChatSubscriptions1784000000030
208	1784000000031	AddExecutionEntityWorkflowStatusIndex1784000000031
209	1784000000033	AddBinaryDataSizeBytesToExecutionEntity1784000000033
210	1784000000034	AllowAzureStoredAt1784000000034
211	1784000000035	AddUniqueAgentFileNames1784000000035
212	1784000000036	CreateInstanceAiThreadGrantTable1784000000036
213	1784000000037	DropAgentDescriptionFromAgents1784000000037
214	1784000000038	SetChatHubEnabledFromUsage1784000000038
215	1784000000039	DropAgentExecutionFallbackColumns1784000000039
216	1784000000040	CreateWorkflowPublicationTriggerStatusTable1784000000040
217	1784000000041	AddUsedPrivateCredentialsToExecutionEntity1784000000041
218	1784000000042	CreateSchedulerTables1784000000042
219	1784000000043	CreateWorkflowStatisticsDeltaTable1784000000043
220	1784000000044	AddPartialIndexForGlobalCredentials1784000000044
221	1784000000045	AddRecurringCronScheduleKind1784000000045
222	1784000000046	CreateInstanceAiEventsTable1784000000046
223	1784000000047	BackfillPreScopingOAuthGrantScopes1784000000047
224	1784000000048	AddTriggerKindToWorkflowPublicationTriggerStatus1784000000048
225	1784000000049	AddScheduledTaskDispatchedAt1784000000049
226	1784000000050	AddHostRunIdToInstanceAiCheckpoints1784000000050
227	1784000000051	BackfillInstanceAiEventLog1784000000051
\.


--
-- Data for Name: oauth_access_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oauth_access_tokens (token, "clientId", "userId") FROM stdin;
\.


--
-- Data for Name: oauth_authorization_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oauth_authorization_codes (code, "clientId", "userId", "redirectUri", "codeChallenge", "codeChallengeMethod", "expiresAt", state, used, "createdAt", "updatedAt", resource, scope) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oauth_clients (id, name, "redirectUris", "grantTypes", "clientSecret", "clientSecretExpiresAt", "tokenEndpointAuthMethod", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: oauth_refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oauth_refresh_tokens (token, "clientId", "userId", "expiresAt", "createdAt", "updatedAt", scope) FROM stdin;
\.


--
-- Data for Name: oauth_user_consents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oauth_user_consents (id, "userId", "clientId", "grantedAt", scope) FROM stdin;
\.


--
-- Data for Name: processed_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.processed_data ("workflowId", context, "createdAt", "updatedAt", value) FROM stdin;
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project (id, name, type, "createdAt", "updatedAt", icon, description, "creatorId", "customTelemetryTags") FROM stdin;
vWagCZseTzZf36H9	harys rifai <harysrifai@gmail.com>	personal	2026-08-03 09:10:57.876+07	2026-08-03 11:55:50.468+07	\N	\N	edead8de-7465-41ce-922a-fd7c1d6b255d	[]
\.


--
-- Data for Name: project_relation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_relation ("projectId", "userId", role, "createdAt", "updatedAt") FROM stdin;
vWagCZseTzZf36H9	edead8de-7465-41ce-922a-fd7c1d6b255d	project:personalOwner	2026-08-03 09:10:57.876+07	2026-08-03 09:10:57.876+07
\.


--
-- Data for Name: project_secrets_provider_access; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_secrets_provider_access ("secretsProviderConnectionId", "projectId", "createdAt", "updatedAt", role) FROM stdin;
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role (slug, "displayName", description, "roleType", "systemRole", "createdAt", "updatedAt") FROM stdin;
global:chatUser	Chat User	Can only use workflows through the chat interface, not build them	global	t	2026-08-03 09:11:00.692+07	2026-08-03 09:11:00.692+07
global:owner	Owner	Owner	global	t	2026-08-03 09:10:58.539+07	2026-08-03 09:11:00.716+07
global:admin	Admin	Full control of the instance, including all workflows and credentials	global	t	2026-08-03 09:10:58.539+07	2026-08-03 09:11:00.716+07
global:member	Member	Can create and use their own workflows and credentials	global	t	2026-08-03 09:10:58.539+07	2026-08-03 09:11:00.716+07
project:admin	Project Admin	Full control of settings, members, workflows, credentials and executions	project	t	2026-08-03 09:10:58.539+07	2026-08-03 09:11:00.739+07
project:personalOwner	Project Owner	Project Owner	project	t	2026-08-03 09:10:58.539+07	2026-08-03 09:11:00.739+07
project:editor	Project Editor	Create, edit, and delete workflows, credentials, and executions	project	t	2026-08-03 09:10:58.539+07	2026-08-03 09:11:00.739+07
project:viewer	Project Viewer	Read-only access to workflows, credentials, and executions	project	t	2026-08-03 09:10:58.539+07	2026-08-03 09:11:00.739+07
project:chatUser	Project Chat User	Chat-only access to chatting with workflows that have n8n Chat enabled	project	t	2026-08-03 09:10:58.539+07	2026-08-03 09:11:00.739+07
credential:owner	Credential Owner	Credential Owner	credential	t	2026-08-03 09:11:00.692+07	2026-08-03 09:11:00.692+07
credential:user	Credential User	Credential User	credential	t	2026-08-03 09:11:00.692+07	2026-08-03 09:11:00.692+07
workflow:owner	Workflow Owner	Workflow Owner	workflow	t	2026-08-03 09:11:00.692+07	2026-08-03 09:11:00.692+07
workflow:editor	Workflow Editor	Workflow Editor	workflow	t	2026-08-03 09:11:00.692+07	2026-08-03 09:11:00.692+07
secretsProviderConnection:owner	Secrets Provider Connection Owner	Full control of secrets provider connection settings and secrets	secretsProviderConnection	t	2026-08-03 09:11:00.692+07	2026-08-03 09:11:00.692+07
secretsProviderConnection:user	Secrets Provider Connection User	Read-only access to use secrets from the connection	secretsProviderConnection	t	2026-08-03 09:11:00.692+07	2026-08-03 09:11:00.692+07
\.


--
-- Data for Name: role_mapping_rule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_mapping_rule (id, expression, role, type, "order", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: role_mapping_rule_project; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_mapping_rule_project ("roleMappingRuleId", "projectId") FROM stdin;
\.


--
-- Data for Name: role_scope; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_scope ("roleSlug", "scopeSlug") FROM stdin;
global:owner	workflow:unpublish
global:owner	workflow:unshare
global:owner	credential:unshare
global:owner	agent:create
global:owner	agent:read
global:owner	agent:update
global:owner	agent:delete
global:owner	agent:list
global:owner	agent:execute
global:owner	agent:publish
global:owner	agent:unpublish
global:owner	agent:manage
global:owner	aiAssistant:manage
global:owner	annotationTag:create
global:owner	annotationTag:read
global:owner	annotationTag:update
global:owner	annotationTag:delete
global:owner	annotationTag:list
global:owner	auditLogs:manage
global:owner	banner:dismiss
global:owner	community:register
global:owner	communityPackage:install
global:owner	communityPackage:uninstall
global:owner	communityPackage:update
global:owner	communityPackage:list
global:owner	credential:share
global:owner	credential:shareGlobally
global:owner	credential:move
global:owner	credential:connect
global:owner	credential:createEndUser
global:owner	credential:create
global:owner	credential:read
global:owner	credential:update
global:owner	credential:delete
global:owner	credential:list
global:owner	externalSecretsProvider:sync
global:owner	externalSecretsProvider:create
global:owner	externalSecretsProvider:read
global:owner	externalSecretsProvider:update
global:owner	externalSecretsProvider:delete
global:owner	externalSecretsProvider:list
global:owner	externalSecret:list
global:owner	eventBusDestination:test
global:owner	eventBusDestination:create
global:owner	eventBusDestination:read
global:owner	eventBusDestination:update
global:owner	eventBusDestination:delete
global:owner	eventBusDestination:list
global:owner	ldap:sync
global:owner	ldap:manage
global:owner	license:manage
global:owner	logStreaming:manage
global:owner	orchestration:read
global:owner	project:create
global:owner	project:read
global:owner	project:update
global:owner	project:delete
global:owner	project:list
global:owner	project:export
global:owner	saml:manage
global:owner	securityAudit:generate
global:owner	securitySettings:manage
global:owner	sourceControl:pull
global:owner	sourceControl:push
global:owner	sourceControl:manage
global:owner	tag:create
global:owner	tag:read
global:owner	tag:update
global:owner	tag:delete
global:owner	tag:list
global:owner	user:resetPassword
global:owner	user:changeRole
global:owner	user:enforceMfa
global:owner	user:generateInviteLink
global:owner	user:create
global:owner	user:read
global:owner	user:update
global:owner	user:delete
global:owner	user:list
global:owner	variable:create
global:owner	variable:read
global:owner	variable:update
global:owner	variable:delete
global:owner	variable:list
global:owner	projectVariable:create
global:owner	projectVariable:read
global:owner	projectVariable:update
global:owner	projectVariable:delete
global:owner	projectVariable:list
global:owner	workersView:manage
global:owner	workflow:share
global:owner	workflow:execute
global:owner	workflow:execute-chat
global:owner	workflow:export
global:owner	workflow:import
global:owner	workflow:move
global:owner	workflow:create
global:owner	workflow:read
global:owner	workflow:update
global:owner	workflow:delete
global:owner	workflow:list
global:owner	folder:create
global:owner	folder:read
global:owner	folder:update
global:owner	folder:delete
global:owner	folder:list
global:owner	folder:move
global:owner	insights:list
global:owner	insights:read
global:owner	oidc:manage
global:owner	provisioning:manage
global:owner	dataTable:create
global:owner	dataTable:read
global:owner	dataTable:update
global:owner	dataTable:delete
global:owner	dataTable:list
global:owner	dataTable:readRow
global:owner	dataTable:writeRow
global:owner	dataTable:readColumn
global:owner	dataTable:writeColumn
global:owner	dataTable:listProject
global:owner	execution:reveal
global:owner	role:manage
global:owner	role:read
global:owner	mcp:manage
global:owner	mcp:oauth
global:owner	mcpApiKey:create
global:owner	mcpApiKey:rotate
global:owner	chatHub:manage
global:owner	chatHub:message
global:owner	chatHubAgent:create
global:owner	chatHubAgent:read
global:owner	chatHubAgent:update
global:owner	chatHubAgent:delete
global:owner	chatHubAgent:list
global:owner	breakingChanges:list
global:owner	apiKey:manage
global:owner	apiKey:list
global:owner	apiKey:create
global:owner	apiKey:delete
global:owner	apiKey:update
global:owner	encryptionKey:manage
global:owner	credentialResolver:create
global:owner	credentialResolver:read
global:owner	credentialResolver:update
global:owner	credentialResolver:delete
global:owner	credentialResolver:list
global:owner	instanceAi:message
global:owner	instanceAi:manage
global:owner	instanceAi:gateway
global:owner	instanceAi:eval
global:owner	roleMappingRule:create
global:owner	roleMappingRule:read
global:owner	roleMappingRule:update
global:owner	roleMappingRule:delete
global:owner	roleMappingRule:list
global:owner	otel:manage
global:owner	workflow:publish
global:owner	workflow:enableRedaction
global:owner	workflow:disableRedaction
global:admin	workflow:unpublish
global:admin	workflow:unshare
global:admin	credential:unshare
global:admin	agent:create
global:admin	agent:read
global:admin	agent:update
global:admin	agent:delete
global:admin	agent:list
global:admin	agent:execute
global:admin	agent:publish
global:admin	agent:unpublish
global:admin	agent:manage
global:admin	aiAssistant:manage
global:admin	annotationTag:create
global:admin	annotationTag:read
global:admin	annotationTag:update
global:admin	annotationTag:delete
global:admin	annotationTag:list
global:admin	auditLogs:manage
global:admin	banner:dismiss
global:admin	community:register
global:admin	communityPackage:install
global:admin	communityPackage:uninstall
global:admin	communityPackage:update
global:admin	communityPackage:list
global:admin	credential:share
global:admin	credential:shareGlobally
global:admin	credential:move
global:admin	credential:connect
global:admin	credential:createEndUser
global:admin	credential:create
global:admin	credential:read
global:admin	credential:update
global:admin	credential:delete
global:admin	credential:list
global:admin	externalSecretsProvider:sync
global:admin	externalSecretsProvider:create
global:admin	externalSecretsProvider:read
global:admin	externalSecretsProvider:update
global:admin	externalSecretsProvider:delete
global:admin	externalSecretsProvider:list
global:admin	externalSecret:list
global:admin	eventBusDestination:test
global:admin	eventBusDestination:create
global:admin	eventBusDestination:read
global:admin	eventBusDestination:update
global:admin	eventBusDestination:delete
global:admin	eventBusDestination:list
global:admin	ldap:sync
global:admin	ldap:manage
global:admin	license:manage
global:admin	logStreaming:manage
global:admin	orchestration:read
global:admin	project:create
global:admin	project:read
global:admin	project:update
global:admin	project:delete
global:admin	project:list
global:admin	project:export
global:admin	saml:manage
global:admin	securityAudit:generate
global:admin	securitySettings:manage
global:admin	sourceControl:pull
global:admin	sourceControl:push
global:admin	sourceControl:manage
global:admin	tag:create
global:admin	tag:read
global:admin	tag:update
global:admin	tag:delete
global:admin	tag:list
global:admin	user:resetPassword
global:admin	user:changeRole
global:admin	user:enforceMfa
global:admin	user:generateInviteLink
global:admin	user:create
global:admin	user:read
global:admin	user:update
global:admin	user:delete
global:admin	user:list
global:admin	variable:create
global:admin	variable:read
global:admin	variable:update
global:admin	variable:delete
global:admin	variable:list
global:admin	projectVariable:create
global:admin	projectVariable:read
global:admin	projectVariable:update
global:admin	projectVariable:delete
global:admin	projectVariable:list
global:admin	workersView:manage
global:admin	workflow:share
global:admin	workflow:execute
global:admin	workflow:execute-chat
global:admin	workflow:export
global:admin	workflow:import
global:admin	workflow:move
global:admin	workflow:create
global:admin	workflow:read
global:admin	workflow:update
global:admin	workflow:delete
global:admin	workflow:list
global:admin	folder:create
global:admin	folder:read
global:admin	folder:update
global:admin	folder:delete
global:admin	folder:list
global:admin	folder:move
global:admin	insights:list
global:admin	insights:read
global:admin	oidc:manage
global:admin	provisioning:manage
global:admin	dataTable:create
global:admin	dataTable:read
global:admin	dataTable:update
global:admin	dataTable:delete
global:admin	dataTable:list
global:admin	dataTable:readRow
global:admin	dataTable:writeRow
global:admin	dataTable:readColumn
global:admin	dataTable:writeColumn
global:admin	dataTable:listProject
global:admin	execution:reveal
global:admin	role:manage
global:admin	role:read
global:admin	mcp:manage
global:admin	mcp:oauth
global:admin	mcpApiKey:create
global:admin	mcpApiKey:rotate
global:admin	chatHub:manage
global:admin	chatHub:message
global:admin	chatHubAgent:create
global:admin	chatHubAgent:read
global:admin	chatHubAgent:update
global:admin	chatHubAgent:delete
global:admin	chatHubAgent:list
global:admin	breakingChanges:list
global:admin	apiKey:manage
global:admin	apiKey:list
global:admin	apiKey:create
global:admin	apiKey:delete
global:admin	apiKey:update
global:admin	encryptionKey:manage
global:admin	credentialResolver:create
global:admin	credentialResolver:read
global:admin	credentialResolver:update
global:admin	credentialResolver:delete
global:admin	credentialResolver:list
global:admin	instanceAi:message
global:admin	instanceAi:manage
global:admin	instanceAi:gateway
global:admin	instanceAi:eval
global:admin	roleMappingRule:create
global:admin	roleMappingRule:read
global:admin	roleMappingRule:update
global:admin	roleMappingRule:delete
global:admin	roleMappingRule:list
global:admin	otel:manage
global:admin	workflow:publish
global:admin	workflow:enableRedaction
global:admin	workflow:disableRedaction
global:member	annotationTag:create
global:member	annotationTag:read
global:member	annotationTag:update
global:member	annotationTag:delete
global:member	annotationTag:list
global:member	eventBusDestination:test
global:member	eventBusDestination:list
global:member	tag:create
global:member	tag:read
global:member	tag:update
global:member	tag:list
global:member	user:list
global:member	variable:read
global:member	variable:list
global:member	dataTable:list
global:member	mcp:oauth
global:member	mcpApiKey:create
global:member	mcpApiKey:rotate
global:member	chatHub:message
global:member	chatHubAgent:create
global:member	chatHubAgent:read
global:member	chatHubAgent:update
global:member	chatHubAgent:delete
global:member	chatHubAgent:list
global:member	apiKey:list
global:member	apiKey:create
global:member	apiKey:delete
global:member	apiKey:update
global:member	credentialResolver:list
global:member	instanceAi:message
global:member	instanceAi:gateway
global:chatUser	chatHub:message
global:chatUser	chatHubAgent:create
global:chatUser	chatHubAgent:read
global:chatUser	chatHubAgent:update
global:chatUser	chatHubAgent:delete
global:chatUser	chatHubAgent:list
project:admin	workflow:unpublish
project:admin	credential:unshare
project:admin	agent:create
project:admin	agent:read
project:admin	agent:update
project:admin	agent:delete
project:admin	agent:list
project:admin	agent:execute
project:admin	agent:publish
project:admin	agent:unpublish
project:admin	credential:share
project:admin	credential:move
project:admin	credential:connect
project:admin	credential:createEndUser
project:admin	credential:create
project:admin	credential:read
project:admin	credential:update
project:admin	credential:delete
project:admin	credential:list
project:admin	project:read
project:admin	project:update
project:admin	project:delete
project:admin	project:list
project:admin	project:export
project:admin	sourceControl:push
project:admin	projectVariable:create
project:admin	projectVariable:read
project:admin	projectVariable:update
project:admin	projectVariable:delete
project:admin	projectVariable:list
project:admin	workflow:execute
project:admin	workflow:execute-chat
project:admin	workflow:export
project:admin	workflow:import
project:admin	workflow:move
project:admin	workflow:create
project:admin	workflow:read
project:admin	workflow:update
project:admin	workflow:delete
project:admin	workflow:list
project:admin	folder:create
project:admin	folder:read
project:admin	folder:update
project:admin	folder:delete
project:admin	folder:list
project:admin	folder:move
project:admin	dataTable:create
project:admin	dataTable:read
project:admin	dataTable:update
project:admin	dataTable:delete
project:admin	dataTable:readRow
project:admin	dataTable:writeRow
project:admin	dataTable:readColumn
project:admin	dataTable:writeColumn
project:admin	dataTable:listProject
project:admin	execution:reveal
project:admin	workflow:publish
project:admin	workflow:enableRedaction
project:admin	workflow:disableRedaction
project:personalOwner	workflow:unpublish
project:personalOwner	workflow:unshare
project:personalOwner	credential:unshare
project:personalOwner	agent:create
project:personalOwner	agent:read
project:personalOwner	agent:update
project:personalOwner	agent:delete
project:personalOwner	agent:list
project:personalOwner	agent:execute
project:personalOwner	agent:publish
project:personalOwner	agent:unpublish
project:personalOwner	credential:share
project:personalOwner	credential:move
project:personalOwner	credential:connect
project:personalOwner	credential:createEndUser
project:personalOwner	credential:create
project:personalOwner	credential:read
project:personalOwner	credential:update
project:personalOwner	credential:delete
project:personalOwner	credential:list
project:personalOwner	project:read
project:personalOwner	project:list
project:personalOwner	project:export
project:personalOwner	workflow:share
project:personalOwner	workflow:execute
project:personalOwner	workflow:execute-chat
project:personalOwner	workflow:export
project:personalOwner	workflow:import
project:personalOwner	workflow:move
project:personalOwner	workflow:create
project:personalOwner	workflow:read
project:personalOwner	workflow:update
project:personalOwner	workflow:delete
project:personalOwner	workflow:list
project:personalOwner	folder:create
project:personalOwner	folder:read
project:personalOwner	folder:update
project:personalOwner	folder:delete
project:personalOwner	folder:list
project:personalOwner	folder:move
project:personalOwner	dataTable:create
project:personalOwner	dataTable:read
project:personalOwner	dataTable:update
project:personalOwner	dataTable:delete
project:personalOwner	dataTable:readRow
project:personalOwner	dataTable:writeRow
project:personalOwner	dataTable:readColumn
project:personalOwner	dataTable:writeColumn
project:personalOwner	dataTable:listProject
project:personalOwner	execution:reveal
project:personalOwner	workflow:publish
project:personalOwner	workflow:enableRedaction
project:personalOwner	workflow:disableRedaction
project:editor	workflow:unpublish
project:editor	agent:create
project:editor	agent:read
project:editor	agent:update
project:editor	agent:delete
project:editor	agent:list
project:editor	agent:execute
project:editor	agent:publish
project:editor	agent:unpublish
project:editor	credential:connect
project:editor	credential:create
project:editor	credential:read
project:editor	credential:update
project:editor	credential:delete
project:editor	credential:list
project:editor	project:read
project:editor	project:list
project:editor	project:export
project:editor	projectVariable:create
project:editor	projectVariable:read
project:editor	projectVariable:update
project:editor	projectVariable:delete
project:editor	projectVariable:list
project:editor	workflow:execute
project:editor	workflow:execute-chat
project:editor	workflow:export
project:editor	workflow:import
project:editor	workflow:create
project:editor	workflow:read
project:editor	workflow:update
project:editor	workflow:delete
project:editor	workflow:list
project:editor	folder:create
project:editor	folder:read
project:editor	folder:update
project:editor	folder:delete
project:editor	folder:list
project:editor	dataTable:create
project:editor	dataTable:read
project:editor	dataTable:update
project:editor	dataTable:delete
project:editor	dataTable:readRow
project:editor	dataTable:writeRow
project:editor	dataTable:readColumn
project:editor	dataTable:writeColumn
project:editor	dataTable:listProject
project:editor	workflow:publish
project:viewer	agent:read
project:viewer	agent:list
project:viewer	agent:execute
project:viewer	credential:read
project:viewer	credential:list
project:viewer	project:read
project:viewer	project:list
project:viewer	project:export
project:viewer	projectVariable:read
project:viewer	projectVariable:list
project:viewer	workflow:execute-chat
project:viewer	workflow:export
project:viewer	workflow:read
project:viewer	workflow:list
project:viewer	folder:read
project:viewer	folder:list
project:viewer	dataTable:read
project:viewer	dataTable:readRow
project:viewer	dataTable:readColumn
project:viewer	dataTable:listProject
project:chatUser	agent:execute
project:chatUser	workflow:execute-chat
credential:owner	credential:unshare
credential:owner	credential:share
credential:owner	credential:move
credential:owner	credential:connect
credential:owner	credential:read
credential:owner	credential:update
credential:owner	credential:delete
credential:user	credential:connect
credential:user	credential:read
workflow:owner	workflow:unpublish
workflow:owner	workflow:unshare
workflow:owner	workflow:share
workflow:owner	workflow:execute
workflow:owner	workflow:execute-chat
workflow:owner	workflow:export
workflow:owner	workflow:move
workflow:owner	workflow:read
workflow:owner	workflow:update
workflow:owner	workflow:delete
workflow:owner	execution:reveal
workflow:owner	workflow:publish
workflow:owner	workflow:enableRedaction
workflow:owner	workflow:disableRedaction
workflow:editor	workflow:unpublish
workflow:editor	workflow:execute
workflow:editor	workflow:execute-chat
workflow:editor	workflow:export
workflow:editor	workflow:read
workflow:editor	workflow:update
workflow:editor	workflow:publish
secretsProviderConnection:owner	externalSecretsProvider:sync
secretsProviderConnection:owner	externalSecretsProvider:read
secretsProviderConnection:owner	externalSecretsProvider:update
secretsProviderConnection:owner	externalSecretsProvider:delete
secretsProviderConnection:owner	externalSecretsProvider:list
secretsProviderConnection:owner	externalSecret:list
secretsProviderConnection:user	externalSecretsProvider:read
secretsProviderConnection:user	externalSecretsProvider:list
secretsProviderConnection:user	externalSecret:list
\.


--
-- Data for Name: scheduled_job; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scheduled_job (id, name, "workflowId", "nodeId", "taskType", payload, kind, "cronExpression", timezone, "intervalSeconds", "fireAt", enabled, "nextRunAt", "lastFiredAt", "maxAttempts", "createdAt", "updatedAt", "recurrenceUnit", "recurrenceSize") FROM stdin;
\.


--
-- Data for Name: scheduled_task; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scheduled_task (id, "jobId", "taskType", payload, "scheduledFor", "runAt", status, attempts, "maxAttempts", "claimedBy", "leaseExpiresAt", "leaseEpoch", "startedAt", "finishedAt", "errorMessage", "createdAt", "dispatchedAt") FROM stdin;
\.


--
-- Data for Name: scope; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scope (slug, "displayName", description) FROM stdin;
workflow:unpublish	Unpublish Workflow	Allows unpublishing workflows.
workflow:unshare	Unshare Workflow	Allows removing workflow shares.
credential:unshare	Unshare Credential	Allows removing credential shares.
agent:create	Create Agent	Allows creating new agents in a project.
agent:read	Read Agent	Allows reading agent configuration and history.
agent:update	Update Agent	Allows updating, building, publishing, and managing integrations of agents.
agent:delete	Delete Agent	Allows deleting agents.
agent:list	List Agents	Allows listing agents in a project.
agent:execute	Execute Agent	Allows running agents in chat.
agent:publish	Publish Agent	Allows publishing agents.
agent:unpublish	Unpublish Agent	Allows unpublishing agents.
agent:manage	agent:manage	\N
aiAssistant:manage	Manage AI Usage	Allows managing AI Usage settings.
annotationTag:create	Create Annotation Tag	Allows creating new annotation tags.
annotationTag:read	annotationTag:read	\N
annotationTag:update	annotationTag:update	\N
annotationTag:delete	annotationTag:delete	\N
annotationTag:list	annotationTag:list	\N
auditLogs:manage	auditLogs:manage	\N
banner:dismiss	banner:dismiss	\N
community:register	community:register	\N
communityPackage:install	communityPackage:install	\N
communityPackage:uninstall	communityPackage:uninstall	\N
communityPackage:update	communityPackage:update	\N
communityPackage:list	communityPackage:list	\N
communityPackage:manage	communityPackage:manage	\N
credential:share	credential:share	\N
credential:shareGlobally	credential:shareGlobally	\N
credential:move	credential:move	\N
credential:connect	Connect End-User Credential	Allows connecting an own account to an end-user credential.
credential:createEndUser	Manage End-User Credential	Allows creating, deleting, and changing the type of end-user credentials, which resolve to each user's own connection.
credential:create	credential:create	\N
credential:read	credential:read	\N
credential:update	credential:update	\N
credential:delete	credential:delete	\N
credential:list	credential:list	\N
externalSecretsProvider:sync	externalSecretsProvider:sync	\N
externalSecretsProvider:create	externalSecretsProvider:create	\N
externalSecretsProvider:read	externalSecretsProvider:read	\N
externalSecretsProvider:update	externalSecretsProvider:update	\N
externalSecretsProvider:delete	externalSecretsProvider:delete	\N
externalSecretsProvider:list	externalSecretsProvider:list	\N
externalSecret:list	externalSecret:list	\N
eventBusDestination:test	eventBusDestination:test	\N
eventBusDestination:create	eventBusDestination:create	\N
eventBusDestination:read	eventBusDestination:read	\N
eventBusDestination:update	eventBusDestination:update	\N
eventBusDestination:delete	eventBusDestination:delete	\N
eventBusDestination:list	eventBusDestination:list	\N
ldap:sync	ldap:sync	\N
ldap:manage	ldap:manage	\N
license:manage	license:manage	\N
logStreaming:manage	logStreaming:manage	\N
orchestration:read	orchestration:read	\N
orchestration:list	orchestration:list	\N
project:create	project:create	\N
project:read	project:read	\N
project:update	project:update	\N
project:delete	project:delete	\N
project:list	project:list	\N
project:export	Export Project	Allows including projects in a portable package export.
saml:manage	saml:manage	\N
securityAudit:generate	securityAudit:generate	\N
securitySettings:manage	securitySettings:manage	\N
sourceControl:pull	sourceControl:pull	\N
sourceControl:push	sourceControl:push	\N
sourceControl:manage	sourceControl:manage	\N
tag:create	tag:create	\N
tag:read	tag:read	\N
tag:update	tag:update	\N
tag:delete	tag:delete	\N
tag:list	tag:list	\N
user:resetPassword	user:resetPassword	\N
user:changeRole	user:changeRole	\N
user:enforceMfa	user:enforceMfa	\N
user:generateInviteLink	user:generateInviteLink	\N
user:create	user:create	\N
user:read	user:read	\N
user:update	user:update	\N
user:delete	user:delete	\N
user:list	user:list	\N
variable:create	variable:create	\N
variable:read	variable:read	\N
variable:update	variable:update	\N
variable:delete	variable:delete	\N
variable:list	variable:list	\N
projectVariable:create	projectVariable:create	\N
projectVariable:read	projectVariable:read	\N
projectVariable:update	projectVariable:update	\N
projectVariable:delete	projectVariable:delete	\N
projectVariable:list	projectVariable:list	\N
workersView:manage	workersView:manage	\N
workflow:share	workflow:share	\N
workflow:execute	workflow:execute	\N
workflow:execute-chat	Execute Workflow in Chat	Allows executing workflows in chat.
workflow:export	Export Workflow	Allows including workflows in a portable package export.
workflow:import	Import Workflow	Allows importing workflows from a portable package into the project.
workflow:move	workflow:move	\N
workflow:activate	workflow:activate	\N
workflow:deactivate	workflow:deactivate	\N
workflow:create	workflow:create	\N
workflow:read	workflow:read	\N
workflow:update	workflow:update	\N
workflow:delete	workflow:delete	\N
workflow:list	workflow:list	\N
folder:create	folder:create	\N
folder:read	folder:read	\N
folder:update	folder:update	\N
folder:delete	folder:delete	\N
folder:list	folder:list	\N
folder:move	folder:move	\N
insights:list	insights:list	\N
insights:read	Read Insights	Allows reading insights data.
oidc:manage	oidc:manage	\N
provisioning:manage	provisioning:manage	\N
dataTable:create	dataTable:create	\N
dataTable:read	dataTable:read	\N
dataTable:update	dataTable:update	\N
dataTable:delete	dataTable:delete	\N
dataTable:list	dataTable:list	\N
dataTable:readRow	dataTable:readRow	\N
dataTable:writeRow	dataTable:writeRow	\N
dataTable:readColumn	dataTable:readColumn	\N
dataTable:writeColumn	dataTable:writeColumn	\N
dataTable:listProject	dataTable:listProject	\N
execution:delete	execution:delete	\N
execution:read	execution:read	\N
execution:retry	execution:retry	\N
execution:list	execution:list	\N
execution:get	execution:get	\N
execution:reveal	execution:reveal	\N
testRun:read	Read Test Run	Allows reading evaluation test runs and their per-case results.
testRun:list	List Test Runs	Allows listing evaluation test runs for a workflow.
workflowTags:update	workflowTags:update	\N
workflowTags:list	workflowTags:list	\N
role:manage	role:manage	\N
role:read	role:read	\N
role:manageProject	Manage project roles	Allows creating, editing, and deleting project role definitions.
mcp:manage	mcp:manage	\N
mcp:oauth	mcp:oauth	\N
mcpApiKey:create	mcpApiKey:create	\N
mcpApiKey:rotate	mcpApiKey:rotate	\N
chatHub:manage	chatHub:manage	\N
chatHub:message	chatHub:message	\N
chatHubAgent:create	chatHubAgent:create	\N
chatHubAgent:read	chatHubAgent:read	\N
chatHubAgent:update	chatHubAgent:update	\N
chatHubAgent:delete	chatHubAgent:delete	\N
chatHubAgent:list	chatHubAgent:list	\N
breakingChanges:list	breakingChanges:list	\N
apiKey:manage	apiKey:manage	\N
apiKey:list	apiKey:list	\N
apiKey:create	apiKey:create	\N
apiKey:delete	apiKey:delete	\N
apiKey:update	apiKey:update	\N
encryptionKey:manage	Manage Encryption Keys	Allows listing and rotating instance encryption keys.
credentialResolver:create	credentialResolver:create	\N
credentialResolver:read	credentialResolver:read	\N
credentialResolver:update	credentialResolver:update	\N
credentialResolver:delete	credentialResolver:delete	\N
credentialResolver:list	credentialResolver:list	\N
instanceAi:message	instanceAi:message	\N
instanceAi:manage	instanceAi:manage	\N
instanceAi:gateway	instanceAi:gateway	\N
instanceAi:eval	instanceAi:eval	\N
roleMappingRule:create	roleMappingRule:create	\N
roleMappingRule:read	roleMappingRule:read	\N
roleMappingRule:update	roleMappingRule:update	\N
roleMappingRule:delete	roleMappingRule:delete	\N
roleMappingRule:list	roleMappingRule:list	\N
otel:manage	otel:manage	\N
workflow:publish	Publish Workflow	Allows publishing workflows.
workflow:enableRedaction	workflow:enableRedaction	\N
workflow:disableRedaction	workflow:disableRedaction	\N
\.


--
-- Data for Name: secrets_provider_connection; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.secrets_provider_connection (id, "providerKey", type, "encryptedSettings", "isEnabled", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settings (key, value, "loadOnStartup") FROM stdin;
ui.banners.dismissed	["V1"]	t
features.ldap	{"loginEnabled":false,"loginLabel":"","connectionUrl":"","allowUnauthorizedCerts":false,"connectionSecurity":"none","connectionPort":389,"baseDn":"","bindingAdminDn":"","bindingAdminPassword":"","firstNameAttribute":"","lastNameAttribute":"","emailAttribute":"","loginIdAttribute":"","ldapIdAttribute":"","userFilter":"","synchronizationEnabled":false,"synchronizationInterval":60,"searchPageSize":0,"searchTimeout":60,"enforceEmailUniqueness":true}	t
chat.access.enabled	false	t
userManagement.isInstanceOwnerSetUp	true	t
license.cert	eyJsaWNlbnNlS2V5IjoiLS0tLS1CRUdJTiBMSUNFTlNFIEtFWS0tLS0tXG52elNsNnhSODRQZDAvcll4b2UzNzZQK3NVSldhSU95MXRCa2dOaDNJTDlSZXpVMDFiQ2FXN3JtNzF0V3RzeDVTXG5qNnNDOFhxOXVSR3g5NkgyUUwrYVQ2QlVzTmlOaFg3c1ZpSnVEdzlLTDJocklScElReWwxVDNkeSthVCtOdnB6XG5tOVh3bW9hVTU4c0RLTExyN1oxdTJsL3RabkR3cmFqYzNuYWJXMmozYWtXL2ZBYTJYQ1M3NkhxNFprRHVlekpnXG5TWitpUnBSb3NxTkFjZWkwNXlIYy8vR096R25WUnMxQ3lhSU5WRW9KMVN4cnlrdDg5RWxSK1FpbzZ2WjhDYU8yXG4yNkpUZjBWemRqNXJNdnBIRG9oT050Z0hhUWxleEhhSjlQTlZBN3FhcjJyL0VoVTI4RCt1bVFqTUJlMjR5UXJKXG5jRHhWZEs1ejYvbmI4ZHg4akNzUzJBPT18fFUyRnNkR1ZrWDErVW9rQXFVK05EcVRTOXpDRUpXcnk5SGNkaWxhXG5YR0dhdTZ5NlhwZHpERnZRdkp6aGs5eVJkcCswSzgrQm9PTUFzY3ZZQ2xrRW41NjlQc0RsdWYwM0NqUjU0aFZiXG42QlpGbFBYMnlnRVpaM0dVMEhjUUVzTThiSnhtMUt0SCtZVE4xeVd1UGRFN1FPWmpmOTdpbUo1dWpRVlFpSWdqXG5IUzQ4OVUxU3BROGxKYXlGOGJzcTNnK1lJbld0VjYrOEFWaDVkaUxVSVFSK2NhWGNhTkNmVFRMaDgvZTNmcG5NXG5nNUU1YjJzcHJuK3JiZkZlcWU5NVVVdFVRaGpxMVVVcnBUYXpVN0NWcDZBb3c5cHZDaWNHVVJ5c21nLzExdHFJXG5NajhDS25GUG1uWUVxY1Jqd1ZlMXVoeGxlRmhpbWQ4ZUZ1amg5eVFsTmsxS2J3OThiblM0N3NEK2ZPZG1kcjFDXG5PTkJvaDg4OGJGMVU1dEdSQ2NCNWptSXlYS0lZQlJxQjdDYnMvQkVwTmRYSVJrM1dUS21JV3ltZHFocmhVaTBGXG55YmNOSGJBd0ZobW9jb1FBV0lyTDFmMG5DT080UnR1WDhHdWlRV0VZcS8zVFNMRm1wZmFUd2hGZ2xxUFc3Q0REXG5jZFhGVUxuaXFKdTBOUkxSbGRoMzI4dEdQZ0FJMS9MeG1PNFE0K1JhWFBxRFpmcm1lWjdKakNEWm1RWTVMYjRpXG41OXI5OGt2Q210bVpNM0ljb0k5TzhleUJybStKeVpJcjVwalZIM3d3WTFuWFYxc1RSVmlBM0t6K3VkZ2c4Vy8wXG5lYXI3emQwVHNrQ1RzeTYwMlg5S292ZnAvK0IxWDc5RGdHemtOLzEwTVRqZjgxM3RMN2s4OEhtWnM1TGIyeTc2XG5ITThoRkdKNW9NTEtWRDcrZWk1b241VjFRVUR1NEIrUWlkUjArKzlTQ1RzSUNZZUlvVytsM2hLUXNjTFI2WlhpXG5nT1FxTGF5MDFsTjJJbFE4ajh6a2ZTOVVhQUtOVGRoVGpzQi90VmxudDlEWXpCV1FDbTk2S2hXMVpHN3FEU29pXG50eW1BVmtiZURoUXp1SERuQWVjMWVSaGR3UmxaNlV5eklmMWRLbTI3Q2tBMnhYcVNMek43NytTa05iclY1aDRUXG4rNW9Jc2kxZ25xdnRlQ3phQjcyeHdDSnZ2TWlrMnQ0V1pSWUhlTTVybWE5VUV4SWFSZjk0MFRqYXpRUUFXTUlVXG5IM3FQRnJoaXM5alBEYXp4cFdsOUlCL0h4V3N1WHM4cWxHVmZmdTZXN29UTW16YUN1M3V0ZTVuSFZpNzBOaU9IXG5yNkxUZzlhb1poTWpsM21CZjZITDZMVWF1S2ZBaC96UXZ0NUtpTHZxQWdheXFIWWRVUjVDb1NJQTExT3BHMnI5XG5ETmtYb2lUQUI0Q1ZrUE4rbmZVdjM3aXhPNExGaHF2VFhRenBnRFJGSkIvVTdQSitTS0tscmtkQ3NBOHh6WmJVXG5Zb3ZMVkhzUlVVdEtlMGExSU1GMERpZWlwT2hJU3NQcGxURCtyYjVOV0FXc2crK2VRWTgwOEhkbHZtVW9wNVpjXG4ybzFYOUk1aGMvNldKR3QzOStpK2tzSUQ4c0txSm40NzlnWWNXZkVDcDVvZHM1N2J6RW5weEJ6SFRKT1ZZbndzXG5uQk5iOVJtVGM1L3dEd3diSmdoWFBPQlhGT0ZSU3BQOGN0ZEx4SmkxSDJPUjhIN2h0RWtDOGVQbzNBNDBjR1lXXG4vRmsrcEt6MURnYlJGcTEzdVgya3pDMGdqT3VHRFpyN1l6VnhJYU4vSFVER0dpd1ZEM0lLRUd5K3VDd2Y4U2VZXG5iNHZ4Ky8yL0R2eGVnbURpcGtmak4yWkI3bFg5MlNtNjZTZzRETEtqOUNKN0M3QXNQWkg3VEx4bEI4L3hyNjhhXG43SEFRYXlhbVY3SVpoL1N3WVNaS1RjclIvT3crTUhYalhFQlpQUDdDLzlGa2VUSjZoZVFiRUZMOHdXR0gxeEVnXG5saDFGWWF3N1lUaEkvdXFKdWtXMm5kK2NleDhFWExhd3cxclUrSU1aTWQzTDB0ZklwcnowbzF4R3ovVEJSWEVlXG5BR1daWHBBaDJLTkxLZTZOam5jN0ltTi92Y0xYQVZiRWhUMzJSbWZMRjRGZzZmZmxzczREM055WmdMNWY2ZklRXG5mTjdFU3ZkVUdpOExNMmEwL0NCYkpydWZsNmhiR2hvMjk5QktOSjdnM3dxbldsQkhEWldkMGliTXFEdXpoajlkXG4yRjdudFMzeFVEWVZOWWxRQnRNVnhGcFAybU5udWMxT3g4MEw5aFErek5SWlZQc05YbkhGQkRhTit5L0srR1IwXG5jUTN3YVo5OEpLSUpVWVY0R3dwSXMxVCt4aXl2RHZoeExaeUlIZkkvWHFkZlZnaG04eEpiWXNRaWdMY1YvdExmXG5QbUxxSWljQXY5aDNuM2N3UEF2VmVySnpnbkpXalVyNGZGRU9kZzN1K28xaHloWjlUUEpIc3dvQXphN3UwTFl1XG5LNUZyenhoUVB6bEJ2N082RmdyaHVla2hDNEc3K0pFakJvdmhmUjVxelIxWEw5VkZZNFZsbkJ4TTdPQnkrNUp0XG5MK2UrRFBGNU5scDE0ZEh2aTNqZWtyK1RMTFZNbnU1b2RMNzJubjdYcjFFMUNkRlZWMmdJK0s1MzJYdm5PVStVXG4wQ254eXowVGlqMi9SQS9MSHBMS2J5TWgvS1MrTzZDSXVZVVFRZ0pVUmFJQjJUckEwL0dFUXdicmlyczJDOVY1XG5CaWU2YWdIWGpDa1pWc2NQT2ZFYmJqTlNJbTNmdXZoYXFyVTRkWUx3MHEvMWJQNS9hZVU0MkZuTjZhaVY1WW1EXG42b0svL09RSTBIQWhYU21WeUQyUjVDVDY2L3pEUFVadHBRaC9uQ09zNDAwa3ZIRDY3aXFsS1VpVkYwMmhYc2syXG5XMEF4WXNPZnh2Z3lFVzBZUkVoN1owMUd3dnlTcVFueXBZV1k5Z1N1UE1lRklGWSt4MzlJNVBwbFdxaS9QK2pPXG5zSmE3YWQwRGVRYU1GaEdkM0hZSi82WGNmVitTU3cxNForYWJJa1ZXb0tNUXVoSEE9PXx8cmRvVFRhMUYwMlVaXG50c2dKRGExOUgwQzBTR0g5U0VPbWZEcVpZWFdCYXZaSlVJRytvZ2ROb1JhRGFvWjBISXpkdlZVRlE3MFNCaTd3XG5jbDlyK1R4bWlNN2ZMRjA2RmtuR2NLb2JMS2dkQUwxSkdFd0hXQVllajlNOTA5bjBDdWJYQTZpNTdWNVhYbmNJXG4rTms3SGcxYUZXTGdWbjk4U0REeWpYYzAzRXVxMVFuY04ydG55ZEtCM1RjTXBSdjJaYk5PQmpxaFJXNnd4cXBUXG5xeFJNUHp0UnErTjQvQ2VTdHROZGNLUTRWQ3VOQXk4WGFsU0tNaks0MTExMjdQOEw5dzg0SHNDTEFpaDZYY1R4XG5aRm5KaEdNT2VTMHhzYTdRb2VqSHRWbEVZZytZeTY3Zi9zS0ppYmltZU1MU0ZILy9LcDI5a0FPUGVkODFtRGhZXG5nVDcyclgyN0h3PT1cbi0tLS0tRU5EIExJQ0VOU0UgS0VZLS0tLS0iLCJ4NTA5IjoiLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tXG5NSUlFRERDQ0FmUUNDUUNxZzJvRFQ4MHh3akFOQmdrcWhraUc5dzBCQVFVRkFEQklNUXN3Q1FZRFZRUUdFd0pFXG5SVEVQTUEwR0ExVUVDQXdHUW1WeWJHbHVNUTh3RFFZRFZRUUhEQVpDWlhKc2FXNHhGekFWQmdOVkJBTU1EbXhwXG5ZMlZ1YzJVdWJqaHVMbWx2TUI0WERUSXlNRFl5TkRBME1UQTBNRm9YRFRJek1EWXlOREEwTVRBME1Gb3dTREVMXG5NQWtHQTFVRUJoTUNSRVV4RHpBTkJnTlZCQWdNQmtKbGNteHBiakVQTUEwR0ExVUVCd3dHUW1WeWJHbHVNUmN3XG5GUVlEVlFRRERBNXNhV05sYm5ObExtNDRiaTVwYnpDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDXG5BUW9DZ2dFQkFNQk0wNVhCNDRnNXhmbUNMd2RwVVR3QVQ4K0NCa3lMS0ZzZXprRDVLLzZXaGFYL1hyc2QvUWQwXG4yMEo3d2w1V2RIVTRjVkJtRlJqVndWemtsQ0syeVlKaThtang4c1hzR3E5UTFsYlVlTUtmVjlkc2dmdWhubEFTXG50blFaZ2x1Z09uRjJGZ1JoWGIvakswdHhUb2FvK2JORTZyNGdJRXpwa3RITEJUWXZ2aXVKbXJlZjdXYlBSdDRJXG5uZDlEN2xoeWJlYnloVjdrdXpqUUEvcFBLSFRGczhNVEhaOGhZVXhSeXJwbTMrTVl6UUQrYmpBMlUxRkljdGFVXG53UVhZV2FON3QydVR3Q3Q5ekFLc21ZL1dlT2J2bDNUWk41T05MQXp5V0dDdWxtNWN3S1IzeGJsQlp6WG5CNmdzXG5Pbk4yT0FkU3RjelRWQ3ljbThwY0ZVcnl0S1NLa0dFQ0F3RUFBVEFOQmdrcWhraUc5dzBCQVFVRkFBT0NBZ0VBXG5sSjAxd2NuMXZqWFhDSHVvaTdSMERKMWxseDErZGFmcXlFcVBBMjdKdStMWG1WVkdYUW9yUzFiOHhqVXFVa2NaXG5UQndiV0ZPNXo1ZFptTnZuYnlqYXptKzZvT2cwUE1hWXhoNlRGd3NJMlBPYmM3YkZ2MmVheXdQdC8xQ3BuYzQwXG5xVU1oZnZSeC9HQ1pQQ1d6My8yUlBKV1g5alFEU0hYQ1hxOEJXK0kvM2N1TERaeVkzZkVZQkIwcDNEdlZtYWQ2XG42V0hRYVVyaU4wL0xxeVNPcC9MWmdsbC90MDI5Z1dWdDA1WmliR29LK2NWaFpFY3NMY1VJaHJqMnVGR0ZkM0ltXG5KTGcxSktKN2pLU0JVUU9kSU1EdnNGVUY3WWRNdk11ckNZQTJzT05OOENaK0k1eFFWMUtTOWV2R0hNNWZtd2dTXG5PUEZ2UHp0RENpMC8xdVc5dE9nSHBvcnVvZGFjdCtFWk5rQVRYQ3ZaaXUydy9xdEtSSkY0VTRJVEVtNWFXMGt3XG42enVDOHh5SWt0N3ZoZHM0OFV1UlNHSDlqSnJBZW1sRWl6dEdJTGhHRHF6UUdZYmxoVVFGR01iQmI3amhlTHlDXG5MSjFXT0c2MkYxc3B4Q0tCekVXNXg2cFIxelQxbWhFZ2Q0TWtMYTZ6UFRwYWNyZDk1QWd4YUdLRUxhMVJXU0ZwXG5NdmRoR2s0TnY3aG5iOHIrQnVNUkM2aWVkUE1DelhxL001MGNOOEFnOGJ3K0oxYUZvKzBFSzJoV0phN2tpRStzXG45R3ZGalNkekNGbFVQaEtra1Vaa1NvNWFPdGNRcTdKdTZrV0JoTG9GWUtncHJscDFRVkIwc0daQTZvNkR0cWphXG5HNy9SazZ2YmFZOHdzTllLMnpCWFRUOG5laDVab1JaL1BKTFV0RUV0YzdZPVxuLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLSJ9	f
\.


--
-- Data for Name: shared_credentials; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shared_credentials ("credentialsId", "projectId", role, "createdAt", "updatedAt") FROM stdin;
NaMyFYvBO9XCMEhG	vWagCZseTzZf36H9	credential:owner	2026-08-03 12:10:06.102+07	2026-08-03 12:10:06.102+07
SXr9kdhP2pbmSSl5	vWagCZseTzZf36H9	credential:owner	2026-08-03 18:58:15.55+07	2026-08-03 18:58:15.55+07
aYolIV9R7XB2uz9G	vWagCZseTzZf36H9	credential:owner	2026-08-03 19:02:29.198+07	2026-08-03 19:02:29.198+07
vUrbIYd7RrDZxipc	vWagCZseTzZf36H9	credential:owner	2026-08-03 19:27:49.558+07	2026-08-03 19:27:49.558+07
\.


--
-- Data for Name: shared_workflow; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shared_workflow ("workflowId", "projectId", role, "createdAt", "updatedAt") FROM stdin;
LMGDOuu6Yj3J2GUB	vWagCZseTzZf36H9	workflow:owner	2026-08-03 11:59:00.013+07	2026-08-03 11:59:00.013+07
\.


--
-- Data for Name: tag_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tag_entity (name, "createdAt", "updatedAt", id) FROM stdin;
home	2026-08-03 11:59:06.157+07	2026-08-03 11:59:06.157+07	QvY44fMVDy7Oo8iV
\.


--
-- Data for Name: test_case_execution; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_case_execution (id, "testRunId", "executionId", status, "runAt", "completedAt", "errorCode", "errorDetails", metrics, "createdAt", "updatedAt", inputs, outputs, "runIndex") FROM stdin;
\.


--
-- Data for Name: test_run; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.test_run (id, "workflowId", status, "errorCode", "errorDetails", "runAt", "completedAt", metrics, "createdAt", "updatedAt", "runningInstanceId", "cancelRequested", "workflowVersionId", "evaluationConfigId", "evaluationConfigSnapshot", "collectionId") FROM stdin;
\.


--
-- Data for Name: token_exchange_jti; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.token_exchange_jti (jti, "expiresAt", "createdAt") FROM stdin;
\.


--
-- Data for Name: trusted_key; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trusted_key ("sourceId", kid, data, "createdAt") FROM stdin;
\.


--
-- Data for Name: trusted_key_source; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trusted_key_source (id, type, config, status, "lastError", "lastRefreshedAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."user" (id, email, "firstName", "lastName", password, "personalizationAnswers", "createdAt", "updatedAt", settings, disabled, "mfaEnabled", "mfaSecret", "mfaRecoveryCodes", "lastActiveAt", "roleSlug") FROM stdin;
edead8de-7465-41ce-922a-fd7c1d6b255d	harysrifai@gmail.com	harys	rifai	$2a$10$IDbSMWmfPI6W7sMoK7cYfOni1MtbQavpLvgCqIGTjpe.DD6Wdx4Ui	{"version":"v4","personalization_survey_submitted_at":"2026-08-03T04:56:05.989Z","personalization_survey_n8n_version":"2.32.7","companySize":"<20","companyType":"saas","role":"business-owner","reportedSource":"youtube"}	2026-08-03 09:10:57.309+07	2026-08-03 11:56:06.029+07	{"userActivated": false}	f	f	\N	\N	2026-08-03	global:owner
\.


--
-- Data for Name: user_api_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_api_keys (id, "userId", label, "apiKey", "createdAt", "updatedAt", scopes, audience, "lastUsedAt") FROM stdin;
5qndyKujBzwbKgZI	edead8de-7465-41ce-922a-fd7c1d6b255d	n8n_local	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlZGVhZDhkZS03NDY1LTQxY2UtOTIyYS1mZDdjMWQ2YjI1NWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiYjZmNTcwMWQtNjZhYS00NDA1LTgwM2ItZmU3Zjk3YzE2NjViIiwiaWF0IjoxNzg1NzMzMDQyfQ.dAq2KgJlHFLA0oAc1WZbTG-JclPD-exB8KB3iExKgjA	2026-08-03 11:57:22.3+07	2026-08-03 12:28:11.941+07	["communityPackage:install","communityPackage:uninstall","communityPackage:update","communityPackage:list","credential:move","credential:create","credential:read","credential:update","credential:delete","credential:list","eventBusDestination:test","eventBusDestination:create","eventBusDestination:read","eventBusDestination:update","eventBusDestination:delete","eventBusDestination:list","project:create","project:update","project:delete","project:list","project:export","saml:manage","securityAudit:generate","securitySettings:manage","sourceControl:pull","tag:create","tag:read","tag:update","tag:delete","tag:list","user:changeRole","user:create","user:read","user:delete","user:list","variable:create","variable:update","variable:delete","variable:list","workflow:export","workflow:import","workflow:move","workflow:create","workflow:read","workflow:update","workflow:delete","workflow:list","folder:create","folder:read","folder:update","folder:delete","folder:list","insights:read","dataTable:create","dataTable:read","dataTable:update","dataTable:delete","dataTable:list","workflowTags:update","workflowTags:list","executionTags:update","executionTags:list","workflow:activate","workflow:deactivate","execution:delete","execution:read","execution:retry","execution:stop","execution:list","testRun:read","testRun:list","testRun:create","testRun:cancel","dataTableRow:create","dataTableRow:read","dataTableRow:update","dataTableRow:delete","dataTableRow:upsert","dataTableColumn:create","dataTableColumn:read","dataTableColumn:update","dataTableColumn:delete"]	public-api	\N
wxrWfxVPJP1NAXNr	edead8de-7465-41ce-922a-fd7c1d6b255d	home	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlZGVhZDhkZS03NDY1LTQxY2UtOTIyYS1mZDdjMWQ2YjI1NWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwianRpIjoiNjM1NDc4ZDItOGJkNi00YmUxLWI5YmEtMmFiODk1MWUyODRiIiwiaWF0IjoxNzg1NzM0OTEwfQ.4uStSp8chw2G5d8vcE1wQhdEtmogbkxRMi1oB5lrhxI	2026-08-03 12:28:30.946+07	2026-08-03 12:28:30.946+07	["communityPackage:install","communityPackage:uninstall","communityPackage:update","communityPackage:list","credential:move","credential:create","credential:read","credential:update","credential:delete","credential:list","eventBusDestination:test","eventBusDestination:create","eventBusDestination:read","eventBusDestination:update","eventBusDestination:delete","eventBusDestination:list","project:create","project:update","project:delete","project:list","project:export","saml:manage","securityAudit:generate","securitySettings:manage","sourceControl:pull","tag:create","tag:read","tag:update","tag:delete","tag:list","user:changeRole","user:create","user:read","user:delete","user:list","variable:create","variable:update","variable:delete","variable:list","workflow:export","workflow:import","workflow:move","workflow:create","workflow:read","workflow:update","workflow:delete","workflow:list","folder:create","folder:read","folder:update","folder:delete","folder:list","insights:read","dataTable:create","dataTable:read","dataTable:update","dataTable:delete","dataTable:list","workflowTags:update","workflowTags:list","executionTags:update","executionTags:list","workflow:activate","workflow:deactivate","execution:delete","execution:read","execution:retry","execution:stop","execution:list","testRun:read","testRun:list","testRun:create","testRun:cancel","dataTableRow:create","dataTableRow:read","dataTableRow:update","dataTableRow:delete","dataTableRow:upsert","dataTableColumn:create","dataTableColumn:read","dataTableColumn:update","dataTableColumn:delete"]	public-api	\N
\.


--
-- Data for Name: user_favorites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_favorites (id, "userId", "resourceId", "resourceType") FROM stdin;
\.


--
-- Data for Name: variables; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.variables (key, type, value, id, "projectId") FROM stdin;
\.


--
-- Data for Name: webhook_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.webhook_entity ("webhookPath", method, node, "webhookId", "pathLength", "workflowId") FROM stdin;
\.


--
-- Data for Name: workflow_builder_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_builder_session (id, "workflowId", "userId", messages, "previousSummary", "createdAt", "updatedAt", "activeVersionCardId", "resumeAfterRestoreMessageId") FROM stdin;
\.


--
-- Data for Name: workflow_dependency; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_dependency (id, "workflowId", "workflowVersionId", "dependencyType", "dependencyKey", "dependencyInfo", "indexVersionId", "createdAt", "publishedVersionId") FROM stdin;
373	LMGDOuu6Yj3J2GUB	63	nodeType	n8n-nodes-base.manualTrigger	{"nodeId":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","nodeVersion":1}	1	2026-08-03 19:57:02.422+07	\N
374	LMGDOuu6Yj3J2GUB	63	nodeType	n8n-nodes-base.postgres	{"nodeId":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","nodeVersion":2.7}	1	2026-08-03 19:57:02.422+07	\N
375	LMGDOuu6Yj3J2GUB	63	credentialId	aYolIV9R7XB2uz9G	{"nodeId":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","nodeVersion":2.7}	1	2026-08-03 19:57:02.422+07	\N
376	LMGDOuu6Yj3J2GUB	63	nodeType	n8n-nodes-base.telegram	{"nodeId":"259646ba-a37a-4a86-a62f-92c32edb2481","nodeVersion":1.2}	1	2026-08-03 19:57:02.422+07	\N
377	LMGDOuu6Yj3J2GUB	63	credentialId	SXr9kdhP2pbmSSl5	{"nodeId":"259646ba-a37a-4a86-a62f-92c32edb2481","nodeVersion":1.2}	1	2026-08-03 19:57:02.422+07	\N
378	LMGDOuu6Yj3J2GUB	63	nodeType	n8n-nodes-base.postgres	{"nodeId":"3c35274e-a775-413c-9f2d-b3981e7964d5","nodeVersion":2.7}	1	2026-08-03 19:57:02.422+07	\N
379	LMGDOuu6Yj3J2GUB	63	credentialId	aYolIV9R7XB2uz9G	{"nodeId":"3c35274e-a775-413c-9f2d-b3981e7964d5","nodeVersion":2.7}	1	2026-08-03 19:57:02.422+07	\N
380	LMGDOuu6Yj3J2GUB	63	nodeType	n8n-nodes-base.form	{"nodeId":"bfbd7164-9701-4310-bef9-3a9d138fd1db","nodeVersion":2.5}	1	2026-08-03 19:57:02.422+07	\N
381	LMGDOuu6Yj3J2GUB	63	nodeType	n8n-nodes-base.postgres	{"nodeId":"024d6658-52ca-407b-9324-5442c2e5dfd5","nodeVersion":2.7}	1	2026-08-03 19:57:02.422+07	\N
382	LMGDOuu6Yj3J2GUB	63	credentialId	aYolIV9R7XB2uz9G	{"nodeId":"024d6658-52ca-407b-9324-5442c2e5dfd5","nodeVersion":2.7}	1	2026-08-03 19:57:02.422+07	\N
\.


--
-- Data for Name: workflow_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_entity (name, active, nodes, connections, "createdAt", "updatedAt", settings, "staticData", "pinData", "versionId", "triggerCount", id, meta, "parentFolderId", "isArchived", "versionCounter", description, "activeVersionId", "nodeGroups", "sourceWorkflowId") FROM stdin;
n8n	f	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Execute a SQL query":{"main":[[]]}}	2026-08-03 11:59:00.013+07	2026-08-03 19:57:02.364+07	{"executionOrder":"v1","binaryMode":"separate","availableInMCP":false}	\N	{}	cbdcdab4-901c-4209-8d40-7640f8bdac25	0	LMGDOuu6Yj3J2GUB	{"templateCredsSetupCompleted":true}	\N	f	63	\N	\N	[]	\N
\.


--
-- Data for Name: workflow_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_history ("versionId", "workflowId", authors, "createdAt", "updatedAt", nodes, connections, name, autosaved, description, "nodeGroups") FROM stdin;
7fe56eb9-8ce4-408e-841d-21b930ab3150	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 11:59:16.552+07	2026-08-03 11:59:16.552+07	[{"parameters":{},"type":"n8n-nodes-base.executeWorkflowTrigger","typeVersion":1.2,"position":[0,0],"id":"b86b71cd-3ea7-4929-a806-83f523eeb5a4","name":"When Executed by Another Workflow"}]	{}	\N	t	\N	[]
276e06a0-881b-4455-b8c0-ad33851b7f91	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 11:59:35.571+07	2026-08-03 11:59:35.571+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger"}]	{}	\N	t	\N	[]
c6a37d52-989b-4ad4-92df-b95726aae0d1	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 12:10:07.704+07	2026-08-03 12:10:07.704+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}}]	{}	\N	t	\N	[]
1b6ca3e9-d2b9-4a8e-b600-65fc829506f7	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 18:57:46.718+07	2026-08-03 18:57:46.718+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24"}]	{}	\N	t	\N	[]
0db662e9-852d-4502-a9fc-0d77b44c5823	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 18:58:17.235+07	2026-08-03 18:58:17.235+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
c210f969-636e-479a-830a-4d09affe1759	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 18:58:29.994+07	2026-08-03 18:58:29.994+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"chatId":"@JourneyDevBot","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
f7587b4f-b56c-40e7-a058-72af7fcd292d	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 18:58:33.53+07	2026-08-03 18:58:33.53+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"chatId":"@JourneyDevBot","text":"Hi","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
0a3c1bf7-ebe0-4850-a859-b873bb5919b1	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 18:59:33.429+07	2026-08-03 18:59:33.429+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"chatId":"JourneyDevBot","text":"Hi","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
356ceefd-4fe2-4058-8adb-68a8bde9f6e6	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 18:59:41.972+07	2026-08-03 18:59:41.972+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"chatId":"JourneyDevBot","text":"Hi","replyMarkup":"forceReply","forceReply":{},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
b8e8a5ac-f036-4ada-886d-3e87f1bfa4aa	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 18:59:51.438+07	2026-08-03 18:59:51.438+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"resource":"chat","chatId":"JourneyDevBot"},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Get a chat","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
574c3ece-32c7-4042-838a-1218ee9758a8	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 18:59:56.543+07	2026-08-03 18:59:56.543+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"chatId":"JourneyDevBot","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
67dad390-a3de-4ddc-ac0d-246fd4848ec0	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:01:10.331+07	2026-08-03 19:01:10.331+07	[{"parameters":{"chatId":"JourneyDevBot","text":"HI all","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-416,-96],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","alwaysOutputData":true,"executeOnce":true,"retryOnFail":true,"notesInFlow":true,"credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
082da4ee-6bb6-402f-9ea6-0aa069b3cf53	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:02:30.865+07	2026-08-03 19:02:30.865+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"mode":"list","value":""}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
5768c14e-efc0-4d02-bff7-1b95e745acc6	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:00:12.642+07	2026-08-03 19:00:12.642+07	[{"parameters":{"pollTimes":{"item":[{"mode":"everyMinute"}]},"authentication":"serviceAccount","filters":{}},"type":"n8n-nodes-base.gmailTrigger","typeVersion":1.4,"position":[0,0],"id":"58fb0188-8805-4f0c-9971-61b62eb3b086","name":"Gmail Trigger","credentials":{"googleApi":{"id":"NaMyFYvBO9XCMEhG","name":"Google Service Account account"}}},{"parameters":{"chatId":"JourneyDevBot","text":"HI all","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[144,144],"id":"556410cb-9d28-4bc4-bf2e-5db3fdc6f27f","name":"Send a text message","webhookId":"ca51bb74-2f84-4703-b48a-74c3da97dc24","alwaysOutputData":true,"executeOnce":true,"retryOnFail":true,"notesInFlow":true,"credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{}	\N	t	\N	[]
42e0e936-da46-4444-be1f-a447dad7b7e0	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:01:30.624+07	2026-08-03 19:01:30.624+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"mode":"list","value":""}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table"}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
583eb4a8-90d7-42f1-812c-8d0211b5c985	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:05:14.948+07	2026-08-03 19:05:14.948+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"mode":"name","value":""}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
772a4b6a-4562-4057-9503-0d17c11a90e4	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:05:20.12+07	2026-08-03 19:05:20.12+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
dd05d289-04ee-4820-a701-d0b291b320f5	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:05:30.752+07	2026-08-03 19:05:30.752+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{"payload":"Hi"},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
61acc561-d139-4cf5-87ea-5e721bb7287f	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:05:42.455+07	2026-08-03 19:05:42.455+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{"payload":"Hi"},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
dfa4f148-53a4-458e-9443-fc023d4c12f5	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:05:54.863+07	2026-08-03 19:05:54.863+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items2","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"payload","displayName":"payload","required":true,"defaultMatch":false,"display":true,"type":"object","canBeUsedToMatch":true},{"id":"created_at","displayName":"created_at","required":false,"defaultMatch":false,"display":true,"type":"dateTime","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
86317178-537d-45b9-aeaf-924bbfacf25b	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:07:45.434+07	2026-08-03 19:07:45.434+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":[],"schema":[{"id":"code","displayName":"code","required":true,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true},{"id":"name","displayName":"name","required":true,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
6f648c2c-478f-4d22-93aa-b88bc345efee	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:10:24.341+07	2026-08-03 19:10:24.341+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":[],"schema":[{"id":"code","displayName":"code","required":true,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true},{"id":"name","displayName":"name","required":true,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
b1c61506-057e-4560-b4fc-441b85ee6f70	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:11:24.699+07	2026-08-03 19:11:24.699+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":[],"schema":[{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
14802506-f2f9-41b6-bb75-bb3cd06705e6	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:14:16.16+07	2026-08-03 19:14:16.16+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-208,-96],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}}	\N	t	\N	[]
1d17aef2-32be-41a4-994b-a91dd007fc2e	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:14:44.397+07	2026-08-03 19:14:44.397+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-208,-96],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}}	\N	f	\N	[]
b6a6562a-4278-4786-a058-ecbd9029bf4c	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:14:54.791+07	2026-08-03 19:14:54.791+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[0,0],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-416,-96],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-208,-96],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}}	\N	t	\N	[]
4d59db3e-91de-495a-b1f5-e5697d912b13	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:16:02.362+07	2026-08-03 19:16:02.362+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Insert rows in a table1","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Insert rows in a table1","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Insert rows in a table1":{"main":[[{"node":"Send a text message","type":"main","index":0}]]}}	\N	t	\N	[]
2883ba9c-e496-41bc-8a1e-a14828e64050	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:22:13.981+07	2026-08-03 19:22:13.981+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert rows in a table1","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]}}	\N	t	\N	[]
9eac7220-929f-4dfd-b2b2-7e586f879829	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:22:34.283+07	2026-08-03 19:22:34.283+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","query":"update ","options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]}}	\N	t	\N	[]
1da84623-df08-4630-a0a2-550f80e2a846	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:23:10.945+07	2026-08-03 19:23:10.945+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES ($1, $2);","options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]}}	\N	t	\N	[]
6fc01df3-7c60-4e93-91cc-b9dcf3483926	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:22:25.757+07	2026-08-03 19:22:25.757+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]}}	\N	t	\N	[]
86302d0a-f152-47e3-b39e-9a24245ba269	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:22:39.902+07	2026-08-03 19:22:39.902+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]}}	\N	t	\N	[]
9a4d130a-39c7-4bda-b7a4-5916c1775520	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:23:30.169+07	2026-08-03 19:23:30.169+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"upsert","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"mode":"list","value":""}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert or update rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
7322de81-e6e4-46fa-824f-54c8d3a55252	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:23:35.184+07	2026-08-03 19:23:35.184+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"upsert","schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"mode":"list","value":""}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert or update rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
fe5eb943-969a-4e2b-845c-281427391314	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:23:41.927+07	2026-08-03 19:23:41.927+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"upsert","schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert or update rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
f87d2c1b-aa6b-47ab-b3c7-f801cfc239d4	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:23:50.536+07	2026-08-03 19:23:50.536+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"upsert","schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id","code"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert or update rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert or update rows in a table","type":"main","index":0}]]}}	\N	t	\N	[]
c4ef70bf-36e3-4388-963f-85d640744b35	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:24:01.045+07	2026-08-03 19:24:01.045+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{"code":0,"id":0},"matchingColumns":["id","code"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert rows in a table1","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]}}	\N	t	\N	[]
8c532152-fc88-44ae-aa70-d75792d1fbcd	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:24:09.874+07	2026-08-03 19:24:09.874+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{"id":0},"matchingColumns":["id","code"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert rows in a table1","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]}}	\N	t	\N	[]
6222743d-73a5-4e22-80a3-d5cb9a13b620	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:24:12.498+07	2026-08-03 19:24:12.498+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"schema":{"__rl":true,"value":"public","mode":"list","cachedResultName":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"defineBelow","value":{},"matchingColumns":["id","code"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Insert rows in a table1","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]},"Form":{"main":[[{"node":"Insert rows in a table1","type":"main","index":0}]]}}	\N	t	\N	[]
913f79ea-a4d3-43f4-a961-48178c2b010e	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:24:24.069+07	2026-08-03 19:24:24.069+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]}}	\N	t	\N	[]
2dfffb5e-453c-434e-bf01-d0be106e6cbf	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:26:10.666+07	2026-08-03 19:26:10.666+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.emailSend","typeVersion":2.1,"position":[624,208],"id":"cfee0e17-b0a3-4448-bd35-7f2067e25f9c","name":"Send an Email","webhookId":"fd800d06-1674-4453-b44d-43f3da3b3a8f"}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]}}	\N	t	\N	[]
5332d09d-7337-44d4-8330-d45c6753ae27	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:32:37.516+07	2026-08-03 19:32:37.516+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.emailSend","typeVersion":2.1,"position":[336,0],"id":"cfee0e17-b0a3-4448-bd35-7f2067e25f9c","name":"Send an Email","webhookId":"fd800d06-1674-4453-b44d-43f3da3b3a8f","credentials":{"smtp":{"id":"vUrbIYd7RrDZxipc","name":"SMTP account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Execute a SQL query":{"main":[[{"node":"Send an Email","type":"main","index":0}]]}}	\N	t	\N	[]
f0ce407d-b0a1-4e1d-92fe-0adfb8996fa6	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:32:54.049+07	2026-08-03 19:32:54.049+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Execute a SQL query":{"main":[[]]}}	\N	f	\N	[]
65b2f7c2-8b52-4dc6-93ca-5fa286ff73b2	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:57:00.273+07	2026-08-03 19:57:00.273+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"operation":"completion","options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Execute a SQL query":{"main":[[]]}}	\N	t	\N	[]
cbdcdab4-901c-4209-8d40-7640f8bdac25	LMGDOuu6Yj3J2GUB	harys rifai	2026-08-03 19:57:02.367+07	2026-08-03 19:57:02.367+07	[{"parameters":{},"type":"n8n-nodes-base.manualTrigger","typeVersion":1,"position":[-752,-80],"id":"23b1d01e-abc6-4a30-8634-f6c3208bde2e","name":"When clicking ‘Execute workflow’"},{"parameters":{"schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"columns":{"mappingMode":"autoMapInputData","value":{},"matchingColumns":["id"],"schema":[{"id":"id","displayName":"id","required":false,"defaultMatch":true,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"code","displayName":"code","required":false,"defaultMatch":false,"display":true,"type":"number","canBeUsedToMatch":true,"removed":false},{"id":"name","displayName":"name","required":false,"defaultMatch":false,"display":true,"type":"string","canBeUsedToMatch":true,"removed":false}],"attemptToConvertTypes":false,"convertFieldsToString":false},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,-80],"id":"5e4ecc83-c3a8-44df-a88e-84c428cb745c","name":"Insert rows in a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"chatId":"1","text":"1","replyMarkup":"forceReply","forceReply":{"force_reply":false},"additionalFields":{}},"type":"n8n-nodes-base.telegram","typeVersion":1.2,"position":[-224,-80],"id":"259646ba-a37a-4a86-a62f-92c32edb2481","name":"Send a text message","webhookId":"25f9c399-a485-469b-8c8b-107947f0be22","credentials":{"telegramApi":{"id":"SXr9kdhP2pbmSSl5","name":"Telegram account"}}},{"parameters":{"operation":"select","schema":{"__rl":true,"mode":"list","value":"public"},"table":{"__rl":true,"value":"items","mode":"name"},"options":{"connectionTimeout":30}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[-512,112],"id":"3c35274e-a775-413c-9f2d-b3981e7964d5","name":"Select rows from a table","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}},{"parameters":{"options":{}},"type":"n8n-nodes-base.form","typeVersion":2.5,"position":[-240,176],"id":"bfbd7164-9701-4310-bef9-3a9d138fd1db","name":"Form","webhookId":"438ffa93-f337-4557-8959-ae4b833f5fd9"},{"parameters":{"operation":"executeQuery","query":"INSERT INTO items (code, name)\\nVALUES (\\n  {{$json.code}},\\n  '{{$json.name}}'\\n);","options":{}},"type":"n8n-nodes-base.postgres","typeVersion":2.7,"position":[96,0],"id":"024d6658-52ca-407b-9324-5442c2e5dfd5","name":"Execute a SQL query","credentials":{"postgres":{"id":"aYolIV9R7XB2uz9G","name":"Postgres account"}}}]	{"When clicking ‘Execute workflow’":{"main":[[{"node":"Insert rows in a table","type":"main","index":0},{"node":"Select rows from a table","type":"main","index":0}]]},"Insert rows in a table":{"main":[[{"node":"Send a text message","type":"main","index":0}]]},"Select rows from a table":{"main":[[{"node":"Send a text message","type":"main","index":0},{"node":"Form","type":"main","index":0}]]},"Send a text message":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Form":{"main":[[{"node":"Execute a SQL query","type":"main","index":0}]]},"Execute a SQL query":{"main":[[]]}}	\N	t	\N	[]
\.


--
-- Data for Name: workflow_publication_outbox; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_publication_outbox (id, "workflowId", "publishedVersionId", status, "errorMessage", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: workflow_publication_trigger_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_publication_trigger_status ("workflowId", "nodeId", "versionId", status, "errorMessage", "createdAt", "updatedAt", "triggerKind") FROM stdin;
\.


--
-- Data for Name: workflow_publish_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_publish_history (id, "workflowId", "versionId", event, "userId", "createdAt") FROM stdin;
\.


--
-- Data for Name: workflow_published_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_published_version ("workflowId", "publishedVersionId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: workflow_statistics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_statistics (count, "latestEvent", name, "workflowId", "rootCount", id, "workflowName") FROM stdin;
9	2026-08-03 19:16:16.712+07	manual_success	LMGDOuu6Yj3J2GUB	0	12	n8n
24	2026-08-03 19:32:55.559+07	manual_error	LMGDOuu6Yj3J2GUB	0	1	n8n
\.


--
-- Data for Name: workflow_statistics_delta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_statistics_delta (id, "workflowId", name, "rootCountDelta", "createdAt", "workflowName") FROM stdin;
\.


--
-- Data for Name: workflows_tags; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflows_tags ("workflowId", "tagId") FROM stdin;
LMGDOuu6Yj3J2GUB	QvY44fMVDy7Oo8iV
\.


--
-- Name: auth_provider_sync_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_provider_sync_history_id_seq', 1, false);


--
-- Name: credential_dependency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.credential_dependency_id_seq', 1, false);


--
-- Name: data_table_user_VBZ0QdgF869s7cES_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."data_table_user_VBZ0QdgF869s7cES_id_seq"', 1, false);


--
-- Name: email_tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_tasks_id_seq', 1, false);


--
-- Name: execution_annotations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.execution_annotations_id_seq', 1, false);


--
-- Name: execution_entity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.execution_entity_id_seq', 33, true);


--
-- Name: execution_metadata_temp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.execution_metadata_temp_id_seq', 1, false);


--
-- Name: insights_by_period_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.insights_by_period_id_seq', 1, false);


--
-- Name: insights_metadata_metaId_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."insights_metadata_metaId_seq"', 1, false);


--
-- Name: insights_raw_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.insights_raw_id_seq', 1, false);


--
-- Name: instance_version_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.instance_version_history_id_seq', 1, true);


--
-- Name: items2_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.items2_id_seq', 1, false);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.items_id_seq', 10, true);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.migrations_id_seq', 227, true);


--
-- Name: oauth_user_consents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.oauth_user_consents_id_seq', 1, false);


--
-- Name: scheduled_job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scheduled_job_id_seq', 1, false);


--
-- Name: scheduled_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scheduled_task_id_seq', 1, false);


--
-- Name: secrets_provider_connection_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.secrets_provider_connection_id_seq', 1, false);


--
-- Name: user_favorites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_favorites_id_seq', 1, false);


--
-- Name: workflow_dependency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_dependency_id_seq', 382, true);


--
-- Name: workflow_publication_outbox_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_publication_outbox_id_seq', 1, false);


--
-- Name: workflow_publish_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_publish_history_id_seq', 1, false);


--
-- Name: workflow_statistics_delta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_statistics_delta_id_seq', 33, true);


--
-- Name: workflow_statistics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.workflow_statistics_id_seq', 30, true);


--
-- Name: test_run PK_011c050f566e9db509a0fadb9b9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "PK_011c050f566e9db509a0fadb9b9" PRIMARY KEY (id);


--
-- Name: project_secrets_provider_access PK_0402b7fcec5415246656f102f83; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_secrets_provider_access
    ADD CONSTRAINT "PK_0402b7fcec5415246656f102f83" PRIMARY KEY ("secretsProviderConnectionId", "projectId");


--
-- Name: installed_packages PK_08cc9197c39b028c1e9beca225940576fd1a5804; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.installed_packages
    ADD CONSTRAINT "PK_08cc9197c39b028c1e9beca225940576fd1a5804" PRIMARY KEY ("packageName");


--
-- Name: instance_ai_run_snapshots PK_0a5fc9690a84950ebf1416fb146; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_run_snapshots
    ADD CONSTRAINT "PK_0a5fc9690a84950ebf1416fb146" PRIMARY KEY ("threadId", "runId");


--
-- Name: instance_ai_events PK_12489cd6197feeac2089acc7ef6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_events
    ADD CONSTRAINT "PK_12489cd6197feeac2089acc7ef6" PRIMARY KEY ("threadId", seq);


--
-- Name: mcp_registry_server PK_12fd89a1fb8489513b0a91f5d31; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mcp_registry_server
    ADD CONSTRAINT "PK_12fd89a1fb8489513b0a91f5d31" PRIMARY KEY (slug);


--
-- Name: workflow_publication_trigger_status PK_14aa18b83513fb92d7523909e02; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_publication_trigger_status
    ADD CONSTRAINT "PK_14aa18b83513fb92d7523909e02" PRIMARY KEY ("workflowId", "nodeId");


--
-- Name: instance_ai_messages PK_156c6f287225e9befe0181bb02b; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_messages
    ADD CONSTRAINT "PK_156c6f287225e9befe0181bb02b" PRIMARY KEY (id);


--
-- Name: agent_task_definition PK_1756c11c637903e97629a7a784a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_task_definition
    ADD CONSTRAINT "PK_1756c11c637903e97629a7a784a" PRIMARY KEY (id);


--
-- Name: execution_metadata PK_17a0b6284f8d626aae88e1c16e4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_metadata
    ADD CONSTRAINT "PK_17a0b6284f8d626aae88e1c16e4" PRIMARY KEY (id);


--
-- Name: role_mapping_rule_project PK_198c5b5aea509d139274efcaf9a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_mapping_rule_project
    ADD CONSTRAINT "PK_198c5b5aea509d139274efcaf9a" PRIMARY KEY ("roleMappingRuleId", "projectId");


--
-- Name: project_relation PK_1caaa312a5d7184a003be0f0cb6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "PK_1caaa312a5d7184a003be0f0cb6" PRIMARY KEY ("projectId", "userId");


--
-- Name: chat_hub_sessions PK_1eafef1273c70e4464fec703412; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "PK_1eafef1273c70e4464fec703412" PRIMARY KEY (id);


--
-- Name: agent_task_snapshot PK_2142a8bcda2360c3c5e34f82640; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_task_snapshot
    ADD CONSTRAINT "PK_2142a8bcda2360c3c5e34f82640" PRIMARY KEY ("versionId", "taskId");


--
-- Name: instance_ai_iteration_logs PK_21c2b214b44bc6c34a6d3551c90; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_iteration_logs
    ADD CONSTRAINT "PK_21c2b214b44bc6c34a6d3551c90" PRIMARY KEY (id);


--
-- Name: agent_execution_threads PK_22373dbf6ba6929d8ac50093309; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_execution_threads
    ADD CONSTRAINT "PK_22373dbf6ba6929d8ac50093309" PRIMARY KEY (id);


--
-- Name: instance_ai_pending_confirmations PK_25c38179c8d45095b168adfff80; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_pending_confirmations
    ADD CONSTRAINT "PK_25c38179c8d45095b168adfff80" PRIMARY KEY ("requestId");


--
-- Name: agents_memory_entry_sources PK_278f05e98e74baaaa93f52b4bab; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "PK_278f05e98e74baaaa93f52b4bab" PRIMARY KEY (id);


--
-- Name: folder_tag PK_27e4e00852f6b06a925a4d83a3e; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "PK_27e4e00852f6b06a925a4d83a3e" PRIMARY KEY ("folderId", "tagId");


--
-- Name: instance_ai_threads PK_35575100e45cdedeb89ae0643e9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_threads
    ADD CONSTRAINT "PK_35575100e45cdedeb89ae0643e9" PRIMARY KEY (id);


--
-- Name: role PK_35c9b140caaf6da09cfabb0d675; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT "PK_35c9b140caaf6da09cfabb0d675" PRIMARY KEY (slug);


--
-- Name: secrets_provider_connection PK_4350ae85e76f9ba7df1370acb5d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.secrets_provider_connection
    ADD CONSTRAINT "PK_4350ae85e76f9ba7df1370acb5d" PRIMARY KEY (id);


--
-- Name: instance_ai_resources PK_45b5b0b6f715dae4292b86603d8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_resources
    ADD CONSTRAINT "PK_45b5b0b6f715dae4292b86603d8" PRIMARY KEY (id);


--
-- Name: agents_threads PK_4a3feb0a13ffe315c009cce64e5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_threads
    ADD CONSTRAINT "PK_4a3feb0a13ffe315c009cce64e5" PRIMARY KEY (id);


--
-- Name: project PK_4d68b1358bb5b766d3e78f32f57; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT "PK_4d68b1358bb5b766d3e78f32f57" PRIMARY KEY (id);


--
-- Name: instance_ai_observations PK_4d9b514cdf0f0b577650caf2ac2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observations
    ADD CONSTRAINT "PK_4d9b514cdf0f0b577650caf2ac2" PRIMARY KEY (id);


--
-- Name: agent_checkpoints PK_50a27cbafa6806c9b162304b5fd; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_checkpoints
    ADD CONSTRAINT "PK_50a27cbafa6806c9b162304b5fd" PRIMARY KEY ("runId");


--
-- Name: dynamic_credential_entry PK_5135ffcabecad4727ff6b9b803d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_credential_entry
    ADD CONSTRAINT "PK_5135ffcabecad4727ff6b9b803d" PRIMARY KEY (credential_id, subject_id, resolver_id);


--
-- Name: workflow_dependency PK_52325e34cd7a2f0f67b0f3cad65; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_dependency
    ADD CONSTRAINT "PK_52325e34cd7a2f0f67b0f3cad65" PRIMARY KEY (id);


--
-- Name: instance_ai_checkpoints PK_5315a45f0846d1f9d128c18a2ed; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_checkpoints
    ADD CONSTRAINT "PK_5315a45f0846d1f9d128c18a2ed" PRIMARY KEY (key);


--
-- Name: instance_ai_thread_grants PK_56107d26ebeabf780c5cf311d66; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_thread_grants
    ADD CONSTRAINT "PK_56107d26ebeabf780c5cf311d66" PRIMARY KEY ("threadId", "userId", "grantKey");


--
-- Name: invalid_auth_token PK_5779069b7235b256d91f7af1a15; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invalid_auth_token
    ADD CONSTRAINT "PK_5779069b7235b256d91f7af1a15" PRIMARY KEY (token);


--
-- Name: evaluation_config PK_59c14dccf8989df94070c2dcfda; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluation_config
    ADD CONSTRAINT "PK_59c14dccf8989df94070c2dcfda" PRIMARY KEY (id);


--
-- Name: instance_ai_observation_cursors PK_5b6319b2e9a37c1064a72428f9a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observation_cursors
    ADD CONSTRAINT "PK_5b6319b2e9a37c1064a72428f9a" PRIMARY KEY ("observationScopeId");


--
-- Name: shared_workflow PK_5ba87620386b847201c9531c58f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "PK_5ba87620386b847201c9531c58f" PRIMARY KEY ("workflowId", "projectId");


--
-- Name: workflow_published_version PK_5c76fb7ee939fe2530374d3f75a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_published_version
    ADD CONSTRAINT "PK_5c76fb7ee939fe2530374d3f75a" PRIMARY KEY ("workflowId");


--
-- Name: folder PK_6278a41a706740c94c02e288df8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "PK_6278a41a706740c94c02e288df8" PRIMARY KEY (id);


--
-- Name: agent_history PK_65ffcfe7a8e112fb826311fb092; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_history
    ADD CONSTRAINT "PK_65ffcfe7a8e112fb826311fb092" PRIMARY KEY ("versionId");


--
-- Name: data_table_column PK_673cb121ee4a8a5e27850c72c51; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "PK_673cb121ee4a8a5e27850c72c51" PRIMARY KEY (id);


--
-- Name: agent_files PK_692920e59217af7d124cd95106f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_files
    ADD CONSTRAINT "PK_692920e59217af7d124cd95106f" PRIMARY KEY (id);


--
-- Name: chat_hub_tools PK_696d26426c704fba79b2c195ef5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_tools
    ADD CONSTRAINT "PK_696d26426c704fba79b2c195ef5" PRIMARY KEY (id);


--
-- Name: annotation_tag_entity PK_69dfa041592c30bbc0d4b84aa00; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.annotation_tag_entity
    ADD CONSTRAINT "PK_69dfa041592c30bbc0d4b84aa00" PRIMARY KEY (id);


--
-- Name: user_favorites PK_6c472a19a7423cfbbf6b7c75939; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT "PK_6c472a19a7423cfbbf6b7c75939" PRIMARY KEY (id);


--
-- Name: instance_ai_observational_memory PK_7192dd00cddba039bf1d3e6a098; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observational_memory
    ADD CONSTRAINT "PK_7192dd00cddba039bf1d3e6a098" PRIMARY KEY (id);


--
-- Name: oauth_refresh_tokens PK_74abaed0b30711b6532598b0392; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT "PK_74abaed0b30711b6532598b0392" PRIMARY KEY (token);


--
-- Name: dynamic_credential_user_entry PK_74f548e633abc66dc27c8f0ca77; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_credential_user_entry
    ADD CONSTRAINT "PK_74f548e633abc66dc27c8f0ca77" PRIMARY KEY ("credentialId", "userId", "resolverId");


--
-- Name: agent_chat_subscriptions PK_76598cf91038bee1f3ac94c94bc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_chat_subscriptions
    ADD CONSTRAINT "PK_76598cf91038bee1f3ac94c94bc" PRIMARY KEY ("agentId", "integrationType", "credentialId", "threadId");


--
-- Name: chat_hub_messages PK_7704a5add6baed43eef835f0bfb; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "PK_7704a5add6baed43eef835f0bfb" PRIMARY KEY (id);


--
-- Name: execution_annotations PK_7afcf93ffa20c4252869a7c6a23; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_annotations
    ADD CONSTRAINT "PK_7afcf93ffa20c4252869a7c6a23" PRIMARY KEY (id);


--
-- Name: agents_observation_locks PK_7e2e315162ac3d80587e15ac2c3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observation_locks
    ADD CONSTRAINT "PK_7e2e315162ac3d80587e15ac2c3" PRIMARY KEY ("agentId", "observationScopeId", "taskKind");


--
-- Name: credential_dependency PK_80212729ed0ffa0709417ab28f4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credential_dependency
    ADD CONSTRAINT "PK_80212729ed0ffa0709417ab28f4" PRIMARY KEY (id);


--
-- Name: agents_messages PK_81020dc608dfb0af1ede386d907; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_messages
    ADD CONSTRAINT "PK_81020dc608dfb0af1ede386d907" PRIMARY KEY (id);


--
-- Name: data_table_user_VBZ0QdgF869s7cES PK_84f4118ea3bcf37269499922b57; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."data_table_user_VBZ0QdgF869s7cES"
    ADD CONSTRAINT "PK_84f4118ea3bcf37269499922b57" PRIMARY KEY (id);


--
-- Name: ai_builder_temporary_workflow PK_85a87a1ba0f61999fe11dc56325; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_builder_temporary_workflow
    ADD CONSTRAINT "PK_85a87a1ba0f61999fe11dc56325" PRIMARY KEY ("workflowId");


--
-- Name: oauth_user_consents PK_85b9ada746802c8993103470f05; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_user_consents
    ADD CONSTRAINT "PK_85b9ada746802c8993103470f05" PRIMARY KEY (id);


--
-- Name: instance_version_history PK_874f58cb616935bf49d9dbd67e9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_version_history
    ADD CONSTRAINT "PK_874f58cb616935bf49d9dbd67e9" PRIMARY KEY (id);


--
-- Name: chat_hub_session_tools PK_87aea76ff4c274c4a5ac838ebe3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_session_tools
    ADD CONSTRAINT "PK_87aea76ff4c274c4a5ac838ebe3" PRIMARY KEY ("sessionId", "toolId");


--
-- Name: scheduled_job PK_893185383f029ca8d57bb781fa8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_job
    ADD CONSTRAINT "PK_893185383f029ca8d57bb781fa8" PRIMARY KEY (id);


--
-- Name: migrations PK_8c82d7f526340ab734260ea46be; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT "PK_8c82d7f526340ab734260ea46be" PRIMARY KEY (id);


--
-- Name: installed_nodes PK_8ebd28194e4f792f96b5933423fc439df97d9689; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.installed_nodes
    ADD CONSTRAINT "PK_8ebd28194e4f792f96b5933423fc439df97d9689" PRIMARY KEY (name);


--
-- Name: shared_credentials PK_8ef3a59796a228913f251779cff; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "PK_8ef3a59796a228913f251779cff" PRIMARY KEY ("credentialsId", "projectId");


--
-- Name: test_case_execution PK_90c121f77a78a6580e94b794bce; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "PK_90c121f77a78a6580e94b794bce" PRIMARY KEY (id);


--
-- Name: instance_ai_workflow_snapshots PK_93f2696eb321dfe1d7defe7073f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_workflow_snapshots
    ADD CONSTRAINT "PK_93f2696eb321dfe1d7defe7073f" PRIMARY KEY ("runId", "workflowName");


--
-- Name: deployment_key PK_94bb7aeb5def5a0284a5fe9f9a0; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.deployment_key
    ADD CONSTRAINT "PK_94bb7aeb5def5a0284a5fe9f9a0" PRIMARY KEY (id);


--
-- Name: user_api_keys PK_978fa5caa3468f463dac9d92e69; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_api_keys
    ADD CONSTRAINT "PK_978fa5caa3468f463dac9d92e69" PRIMARY KEY (id);


--
-- Name: execution_annotation_tags PK_979ec03d31294cca484be65d11f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "PK_979ec03d31294cca484be65d11f" PRIMARY KEY ("annotationId", "tagId");


--
-- Name: trusted_key_source PK_99e8908ce2c2cdccce487db7fc6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trusted_key_source
    ADD CONSTRAINT "PK_99e8908ce2c2cdccce487db7fc6" PRIMARY KEY (id);


--
-- Name: agents_observations PK_9ad319654d12c2649f7caf27135; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "PK_9ad319654d12c2649f7caf27135" PRIMARY KEY (id);


--
-- Name: agents PK_9c653f28ae19c5884d5baf6a1d9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT "PK_9c653f28ae19c5884d5baf6a1d9" PRIMARY KEY (id);


--
-- Name: agents_memory_entry_locks PK_a8e0f570d04a174292bea104ae6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_locks
    ADD CONSTRAINT "PK_a8e0f570d04a174292bea104ae6" PRIMARY KEY ("agentId", "resourceId");


--
-- Name: webhook_entity PK_b21ace2e13596ccd87dc9bf4ea6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.webhook_entity
    ADD CONSTRAINT "PK_b21ace2e13596ccd87dc9bf4ea6" PRIMARY KEY ("webhookPath", method);


--
-- Name: agents_memory_entry_cursors PK_b31a1d5c009a27f4cc5ef8f102a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_cursors
    ADD CONSTRAINT "PK_b31a1d5c009a27f4cc5ef8f102a" PRIMARY KEY ("agentId", "observationScopeId");


--
-- Name: workflow_publication_outbox PK_b3e2eeee36a4bd044d56468d311; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_publication_outbox
    ADD CONSTRAINT "PK_b3e2eeee36a4bd044d56468d311" PRIMARY KEY (id);


--
-- Name: insights_by_period PK_b606942249b90cc39b0265f0575; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insights_by_period
    ADD CONSTRAINT "PK_b606942249b90cc39b0265f0575" PRIMARY KEY (id);


--
-- Name: workflow_history PK_b6572dd6173e4cd06fe79937b58; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_history
    ADD CONSTRAINT "PK_b6572dd6173e4cd06fe79937b58" PRIMARY KEY ("versionId");


--
-- Name: dynamic_credential_resolver PK_b76cfb088dcdaf5275e9980bb64; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_credential_resolver
    ADD CONSTRAINT "PK_b76cfb088dcdaf5275e9980bb64" PRIMARY KEY (id);


--
-- Name: agent_execution PK_ba438acc8532addc12d1ef17049; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_execution
    ADD CONSTRAINT "PK_ba438acc8532addc12d1ef17049" PRIMARY KEY (id);


--
-- Name: agents_memory_entries PK_bfbc45dc88f66fae4e4b4a15fec; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entries
    ADD CONSTRAINT "PK_bfbc45dc88f66fae4e4b4a15fec" PRIMARY KEY (id);


--
-- Name: scope PK_bfc45df0481abd7f355d6187da1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scope
    ADD CONSTRAINT "PK_bfc45df0481abd7f355d6187da1" PRIMARY KEY (slug);


--
-- Name: oauth_clients PK_c4759172d3431bae6f04e678e0d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT "PK_c4759172d3431bae6f04e678e0d" PRIMARY KEY (id);


--
-- Name: workflow_publish_history PK_c788f7caf88e91e365c97d6d04a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_publish_history
    ADD CONSTRAINT "PK_c788f7caf88e91e365c97d6d04a" PRIMARY KEY (id);


--
-- Name: processed_data PK_ca04b9d8dc72de268fe07a65773; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processed_data
    ADD CONSTRAINT "PK_ca04b9d8dc72de268fe07a65773" PRIMARY KEY ("workflowId", context);


--
-- Name: chat_hub_agent_tools PK_cc8806fdea48297a7d497035d72; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_agent_tools
    ADD CONSTRAINT "PK_cc8806fdea48297a7d497035d72" PRIMARY KEY ("agentId", "toolId");


--
-- Name: scheduled_task PK_d690af24e57e30594c1948af1e6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_task
    ADD CONSTRAINT "PK_d690af24e57e30594c1948af1e6" PRIMARY KEY (id);


--
-- Name: role_mapping_rule PK_d772c8ec1a89b52d31c882bc560; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_mapping_rule
    ADD CONSTRAINT "PK_d772c8ec1a89b52d31c882bc560" PRIMARY KEY (id);


--
-- Name: token_exchange_jti PK_d8e8a6f737d530fdd2dd716e89c; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.token_exchange_jti
    ADD CONSTRAINT "PK_d8e8a6f737d530fdd2dd716e89c" PRIMARY KEY (jti);


--
-- Name: settings PK_dc0fe14e6d9943f268e7b119f69ab8bd; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT "PK_dc0fe14e6d9943f268e7b119f69ab8bd" PRIMARY KEY (key);


--
-- Name: trusted_key PK_dc7d93798f3dbb6959f974c97e1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trusted_key
    ADD CONSTRAINT "PK_dc7d93798f3dbb6959f974c97e1" PRIMARY KEY ("sourceId", kid);


--
-- Name: oauth_access_tokens PK_dcd71f96a5d5f4bf79e67d322bf; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT "PK_dcd71f96a5d5f4bf79e67d322bf" PRIMARY KEY (token);


--
-- Name: data_table PK_e226d0001b9e6097cbfe70617cb; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "PK_e226d0001b9e6097cbfe70617cb" PRIMARY KEY (id);


--
-- Name: instance_ai_mcp_registry_connections PK_e34e4d15d78eabbe8217e33ef03; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_mcp_registry_connections
    ADD CONSTRAINT "PK_e34e4d15d78eabbe8217e33ef03" PRIMARY KEY (id);


--
-- Name: workflow_builder_session PK_e69ef0d385986e273423b0e8695; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_builder_session
    ADD CONSTRAINT "PK_e69ef0d385986e273423b0e8695" PRIMARY KEY (id);


--
-- Name: evaluation_collection PK_e720b6efc1e45b878ebb0b2ca30; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluation_collection
    ADD CONSTRAINT "PK_e720b6efc1e45b878ebb0b2ca30" PRIMARY KEY (id);


--
-- Name: user PK_ea8f538c94b6e352418254ed6474a81f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "PK_ea8f538c94b6e352418254ed6474a81f" PRIMARY KEY (id);


--
-- Name: agents_observation_cursors PK_eb777ac57ab872d38f8ebd19317; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observation_cursors
    ADD CONSTRAINT "PK_eb777ac57ab872d38f8ebd19317" PRIMARY KEY ("agentId", "observationScopeId");


--
-- Name: insights_raw PK_ec15125755151e3a7e00e00014f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insights_raw
    ADD CONSTRAINT "PK_ec15125755151e3a7e00e00014f" PRIMARY KEY (id);


--
-- Name: chat_hub_agents PK_f39a3b36bbdf0e2979ddb21cf78; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_agents
    ADD CONSTRAINT "PK_f39a3b36bbdf0e2979ddb21cf78" PRIMARY KEY (id);


--
-- Name: insights_metadata PK_f448a94c35218b6208ce20cf5a1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "PK_f448a94c35218b6208ce20cf5a1" PRIMARY KEY ("metaId");


--
-- Name: agent_task_run_lock PK_f593adaf7230e964d3c25deda64; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_task_run_lock
    ADD CONSTRAINT "PK_f593adaf7230e964d3c25deda64" PRIMARY KEY ("agentId", "taskId");


--
-- Name: agents_resources PK_fa6b20b2d31a9991529dbf8ef7d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_resources
    ADD CONSTRAINT "PK_fa6b20b2d31a9991529dbf8ef7d" PRIMARY KEY (id);


--
-- Name: oauth_authorization_codes PK_fb91ab932cfbd694061501cc20f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT "PK_fb91ab932cfbd694061501cc20f" PRIMARY KEY (code);


--
-- Name: binary_data PK_fc3691585b39408bb0551122af6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.binary_data
    ADD CONSTRAINT "PK_fc3691585b39408bb0551122af6" PRIMARY KEY ("fileId");


--
-- Name: instance_ai_observation_locks PK_fc491dd378b9448655c3c683f85; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observation_locks
    ADD CONSTRAINT "PK_fc491dd378b9448655c3c683f85" PRIMARY KEY ("observationScopeId", "taskKind");


--
-- Name: role_scope PK_role_scope; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "PK_role_scope" PRIMARY KEY ("roleSlug", "scopeSlug");


--
-- Name: oauth_user_consents UQ_083721d99ce8db4033e2958ebb4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_user_consents
    ADD CONSTRAINT "UQ_083721d99ce8db4033e2958ebb4" UNIQUE ("userId", "clientId");


--
-- Name: evaluation_config UQ_3c3c99a712e971835c52292e44c; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluation_config
    ADD CONSTRAINT "UQ_3c3c99a712e971835c52292e44c" UNIQUE ("workflowId", name);


--
-- Name: data_table_column UQ_8082ec4890f892f0bc77473a123; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "UQ_8082ec4890f892f0bc77473a123" UNIQUE ("dataTableId", name);


--
-- Name: data_table UQ_b23096ef747281ac944d28e8b0d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "UQ_b23096ef747281ac944d28e8b0d" UNIQUE ("projectId", name);


--
-- Name: role_mapping_rule UQ_b33ac896ad3099fc8de36fdc1c4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_mapping_rule
    ADD CONSTRAINT "UQ_b33ac896ad3099fc8de36fdc1c4" UNIQUE (type, "order");


--
-- Name: user_favorites UQ_cf6ae658ead9ffc124723413c65; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT "UQ_cf6ae658ead9ffc124723413c65" UNIQUE ("userId", "resourceId", "resourceType");


--
-- Name: user UQ_e12875dfb3b1d92d7d7c5377e2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "UQ_e12875dfb3b1d92d7d7c5377e2" UNIQUE (email);


--
-- Name: workflow_builder_session UQ_ec2aa73632932d485a1d5192ce1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_builder_session
    ADD CONSTRAINT "UQ_ec2aa73632932d485a1d5192ce1" UNIQUE ("workflowId", "userId");


--
-- Name: auth_identity auth_identity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_identity
    ADD CONSTRAINT auth_identity_pkey PRIMARY KEY ("providerId", "providerType");


--
-- Name: auth_provider_sync_history auth_provider_sync_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_provider_sync_history
    ADD CONSTRAINT auth_provider_sync_history_pkey PRIMARY KEY (id);


--
-- Name: credentials_entity credentials_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credentials_entity
    ADD CONSTRAINT credentials_entity_pkey PRIMARY KEY (id);


--
-- Name: email_tasks email_tasks_email_message_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_tasks
    ADD CONSTRAINT email_tasks_email_message_id_key UNIQUE (email_message_id);


--
-- Name: email_tasks email_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_tasks
    ADD CONSTRAINT email_tasks_pkey PRIMARY KEY (id);


--
-- Name: event_destinations event_destinations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_destinations
    ADD CONSTRAINT event_destinations_pkey PRIMARY KEY (id);


--
-- Name: execution_data execution_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_data
    ADD CONSTRAINT execution_data_pkey PRIMARY KEY ("executionId");


--
-- Name: items2 items2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items2
    ADD CONSTRAINT items2_pkey PRIMARY KEY (id);


--
-- Name: items items_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_code_key UNIQUE (code);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: execution_entity pk_e3e63bbf986767844bbe1166d4e; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_entity
    ADD CONSTRAINT pk_e3e63bbf986767844bbe1166d4e PRIMARY KEY (id);


--
-- Name: workflows_tags pk_workflows_tags; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT pk_workflows_tags PRIMARY KEY ("workflowId", "tagId");


--
-- Name: tag_entity tag_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tag_entity
    ADD CONSTRAINT tag_entity_pkey PRIMARY KEY (id);


--
-- Name: variables variables_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_pkey PRIMARY KEY (id);


--
-- Name: workflow_entity workflow_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_entity
    ADD CONSTRAINT workflow_entity_pkey PRIMARY KEY (id);


--
-- Name: workflow_statistics_delta workflow_statistics_delta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_statistics_delta
    ADD CONSTRAINT workflow_statistics_delta_pkey PRIMARY KEY (id);


--
-- Name: workflow_statistics workflow_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_statistics
    ADD CONSTRAINT workflow_statistics_pkey PRIMARY KEY (id);


--
-- Name: IDX_02751202c9a2ad75f2d8e14f5e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_02751202c9a2ad75f2d8e14f5e" ON public.instance_ai_iteration_logs USING btree ("threadId", "taskKey", "createdAt");


--
-- Name: IDX_0468a9dc35597314e641d4722a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_0468a9dc35597314e641d4722a" ON public.agent_execution_threads USING btree ("agentId");


--
-- Name: IDX_069e791e428391a5569e7a96b2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_069e791e428391a5569e7a96b2" ON public.agents_memory_entry_cursors USING btree ("observationScopeId");


--
-- Name: IDX_070b5de842ece9ccdda0d9738b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_070b5de842ece9ccdda0d9738b" ON public.workflow_publish_history USING btree ("workflowId", "versionId");


--
-- Name: IDX_07cb1e4a302629c5fa5d74d2bb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_07cb1e4a302629c5fa5d74d2bb" ON public.agents_observations USING btree ("agentId", "observationScopeId", status);


--
-- Name: IDX_0babdf6e3b897a86fe4678355e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_0babdf6e3b897a86fe4678355e" ON public.instance_ai_pending_confirmations USING btree ("checkpointKey");


--
-- Name: IDX_0d5db648188d338df7fb2a8064; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_0d5db648188d338df7fb2a8064" ON public.instance_ai_observations USING btree ("observationScopeId", status, "createdAt", id);


--
-- Name: IDX_0e2f8bf92a7a9c88b89670f701; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_0e2f8bf92a7a9c88b89670f701" ON public.agent_execution_threads USING btree ("projectId");


--
-- Name: IDX_0edf1226b77ddc525eae493807; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_0edf1226b77ddc525eae493807" ON public.agents_memory_entries USING btree ("supersededBy");


--
-- Name: IDX_127ee1078ffa952bb37b511efa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_127ee1078ffa952bb37b511efa" ON public.agents_observations USING btree ("supersededBy");


--
-- Name: IDX_1443a75e59adbfb796071d6639; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_1443a75e59adbfb796071d6639" ON public.agents_memory_entries USING btree ("resourceId");


--
-- Name: IDX_14f68deffaf858465715995508; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_14f68deffaf858465715995508" ON public.folder USING btree ("projectId", id);


--
-- Name: IDX_16db3adb7b19df1ee55ff06b27; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_16db3adb7b19df1ee55ff06b27" ON public.instance_ai_mcp_registry_connections USING btree ("userId", "serverSlug", "credentialId");


--
-- Name: IDX_1d11050a381548c42c32cc25c4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_1d11050a381548c42c32cc25c4" ON public.user_favorites USING btree ("resourceType", "resourceId");


--
-- Name: IDX_1d8ab99d5861c9388d2dc1cf73; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_1d8ab99d5861c9388d2dc1cf73" ON public.insights_metadata USING btree ("workflowId");


--
-- Name: IDX_1dd5c393ad0517be3c31a7af83; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_1dd5c393ad0517be3c31a7af83" ON public.user_favorites USING btree ("userId");


--
-- Name: IDX_1e31657f5fe46816c34be7c1b4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_1e31657f5fe46816c34be7c1b4" ON public.workflow_history USING btree ("workflowId");


--
-- Name: IDX_1eeb64cb9d66a927988de759e6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_1eeb64cb9d66a927988de759e6" ON public.instance_ai_messages USING btree ("threadId");


--
-- Name: IDX_1ef35bac35d20bdae979d917a3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_1ef35bac35d20bdae979d917a3" ON public.user_api_keys USING btree ("apiKey");


--
-- Name: IDX_2b23f3f24a70bebb990203b011; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_2b23f3f24a70bebb990203b011" ON public.instance_ai_checkpoints USING btree ("threadId");


--
-- Name: IDX_32cdd799675715fb1d2a8683e9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_32cdd799675715fb1d2a8683e9" ON public.instance_ai_events USING btree ("threadId", "runId");


--
-- Name: IDX_35a78869286c65d9330d02b88f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_35a78869286c65d9330d02b88f" ON public.role_mapping_rule_project USING btree ("projectId");


--
-- Name: IDX_39b07732e819fb561d74c38763; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_39b07732e819fb561d74c38763" ON public.ai_builder_temporary_workflow USING btree ("threadId");


--
-- Name: IDX_401b94abf83d1ac7a841f31330; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_401b94abf83d1ac7a841f31330" ON public.instance_ai_thread_grants USING btree ("userId");


--
-- Name: IDX_451d387a182fa8dd8002dfc3a7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_451d387a182fa8dd8002dfc3a7" ON public.agents_memory_entry_sources USING btree ("threadId");


--
-- Name: IDX_45dafc48fe2ce95eac30fc8ffd; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_45dafc48fe2ce95eac30fc8ffd" ON public.agent_files USING btree ("agentId", "createdAt");


--
-- Name: IDX_4c72ebdb265d1775bf61147af0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_4c72ebdb265d1775bf61147af0" ON public.chat_hub_tools USING btree ("ownerId", name);


--
-- Name: IDX_4cfd8a70ebb0a5b0cf047dca3c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_4cfd8a70ebb0a5b0cf047dca3c" ON public.agents_observations USING btree ("observationScopeId");


--
-- Name: IDX_501e2d1701a10e24fb69ab5fc5; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_501e2d1701a10e24fb69ab5fc5" ON public.agents_observations USING btree ("parentId");


--
-- Name: IDX_54fa1b94f34a409beafae567a4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_54fa1b94f34a409beafae567a4" ON public.agents_threads USING btree ("resourceId");


--
-- Name: IDX_56900edc3cfd16612e2ef2c6a8; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_56900edc3cfd16612e2ef2c6a8" ON public.binary_data USING btree ("sourceType", "sourceId");


--
-- Name: IDX_5e31c210f896d539964bf99fe3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_5e31c210f896d539964bf99fe3" ON public.agent_checkpoints USING btree ("agentId");


--
-- Name: IDX_5ec8e8c8d3539f3696cf73b43b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_5ec8e8c8d3539f3696cf73b43b" ON public.credential_dependency USING btree ("credentialId");


--
-- Name: IDX_5f0643f6717905a05164090dde; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_5f0643f6717905a05164090dde" ON public.project_relation USING btree ("userId");


--
-- Name: IDX_60b6a84299eeb3f671dfec7693; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_60b6a84299eeb3f671dfec7693" ON public.insights_by_period USING btree ("periodStart", type, "periodUnit", "metaId");


--
-- Name: IDX_61448d56d61802b5dfde5cdb00; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_61448d56d61802b5dfde5cdb00" ON public.project_relation USING btree ("projectId");


--
-- Name: IDX_62476b94b56d9dc7ed9ed75d3d; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_62476b94b56d9dc7ed9ed75d3d" ON public.dynamic_credential_entry USING btree (subject_id);


--
-- Name: IDX_63d3c3a68b9cebf05f967f0b1c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_63d3c3a68b9cebf05f967f0b1c" ON public.agent_execution USING btree ("threadId", "createdAt");


--
-- Name: IDX_63d7bbae72c767cf162d459fcc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_63d7bbae72c767cf162d459fcc" ON public.user_api_keys USING btree ("userId", label);


--
-- Name: IDX_6b55089892e447c2f82e5ec60e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_6b55089892e447c2f82e5ec60e" ON public.agents_observation_locks USING btree ("observationScopeId");


--
-- Name: IDX_6edec973a6450990977bb854c3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_6edec973a6450990977bb854c3" ON public.dynamic_credential_user_entry USING btree ("resolverId");


--
-- Name: IDX_768189b506cc26c4fe878b87cb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_768189b506cc26c4fe878b87cb" ON public.instance_ai_checkpoints USING btree ("runId");


--
-- Name: IDX_76e212c6867fbaa06bf0decd6f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_76e212c6867fbaa06bf0decd6f" ON public.instance_ai_messages USING btree ("resourceId");


--
-- Name: IDX_87aa187d27ea67eafd16490515; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_87aa187d27ea67eafd16490515" ON public.agents_observation_cursors USING btree ("observationScopeId");


--
-- Name: IDX_87cd5a8da20304b089ea2f83fe; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_87cd5a8da20304b089ea2f83fe" ON public.agent_history USING btree ("agentId");


--
-- Name: IDX_8e4b4774db42f1e6dda3452b2a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_8e4b4774db42f1e6dda3452b2a" ON public.test_case_execution USING btree ("testRunId");


--
-- Name: IDX_91ee85fa9619dd6776725e117b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_91ee85fa9619dd6776725e117b" ON public.credential_dependency USING btree ("dependencyType", "dependencyId");


--
-- Name: IDX_92f13cb6bc694227e069447f7b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_92f13cb6bc694227e069447f7b" ON public.instance_ai_observational_memory USING btree ("lookupKey");


--
-- Name: IDX_9594c0983cfee1c8ff49b05848; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_9594c0983cfee1c8ff49b05848" ON public.agents_memory_entry_locks USING btree ("resourceId");


--
-- Name: IDX_97f863fa83c4786f1956508496; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_97f863fa83c4786f1956508496" ON public.execution_annotations USING btree ("executionId");


--
-- Name: IDX_9c9ee9df586e60bb723234e499; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_9c9ee9df586e60bb723234e499" ON public.dynamic_credential_resolver USING btree (type);


--
-- Name: IDX_UniqueRoleDisplayName; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_UniqueRoleDisplayName" ON public.role USING btree ("displayName");


--
-- Name: IDX_a03e04e94bea8439dd166d4b52; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_a03e04e94bea8439dd166d4b52" ON public.agents_memory_entries USING btree ("agentId", "resourceId", "contentHash");


--
-- Name: IDX_a30d560207c4071d98aa03c179; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_a30d560207c4071d98aa03c179" ON public.agents USING btree ("projectId");


--
-- Name: IDX_a353ac251315ef0af6ad3c9f0a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_a353ac251315ef0af6ad3c9f0a" ON public.agents_memory_entry_sources USING btree ("memoryEntryId", "observationId", "evidenceHash");


--
-- Name: IDX_a3697779b366e131b2bbdae297; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_a3697779b366e131b2bbdae297" ON public.execution_annotation_tags USING btree ("tagId");


--
-- Name: IDX_a36dc616fabc3f736bb82410a2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_a36dc616fabc3f736bb82410a2" ON public.dynamic_credential_user_entry USING btree ("userId");


--
-- Name: IDX_a371ee6b8e0ebb5635f8baa46d; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_a371ee6b8e0ebb5635f8baa46d" ON public.instance_ai_workflow_snapshots USING btree ("workflowName", status);


--
-- Name: IDX_a48ce930c3bc7604894b8f0eaa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_a48ce930c3bc7604894b8f0eaa" ON public.evaluation_collection USING btree ("workflowId");


--
-- Name: IDX_a4ff2d9b9628ea988fa9e7d0bf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_a4ff2d9b9628ea988fa9e7d0bf" ON public.workflow_dependency USING btree ("workflowId");


--
-- Name: IDX_a680ac96aae02dc887bbaac512; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_a680ac96aae02dc887bbaac512" ON public.instance_ai_observational_memory USING btree (scope, "threadId", "resourceId");


--
-- Name: IDX_a80e0ee839a2f10ba4b86e1999; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_a80e0ee839a2f10ba4b86e1999" ON public.instance_ai_observations USING btree ("supersededBy");


--
-- Name: IDX_ae51b54c4bb430cf92f48b623f; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_ae51b54c4bb430cf92f48b623f" ON public.annotation_tag_entity USING btree (name);


--
-- Name: IDX_aff2807b31eccbafe59d0474f0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_aff2807b31eccbafe59d0474f0" ON public.agents_memory_entries USING btree ("agentId", "resourceId", status, "createdAt", id);


--
-- Name: IDX_agent_execution_threads_taskVersionId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_agent_execution_threads_taskVersionId" ON public.agent_execution_threads USING btree ("taskVersionId");


--
-- Name: IDX_agent_files_agentId_binaryDataId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_agent_files_agentId_binaryDataId" ON public.agent_files USING btree ("agentId", "binaryDataId");


--
-- Name: IDX_agent_files_agentId_fileName; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_agent_files_agentId_fileName" ON public.agent_files USING btree ("agentId", "fileName");


--
-- Name: IDX_agents_messages_threadId_createdAt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_agents_messages_threadId_createdAt" ON public.agents_messages USING btree ("threadId", "createdAt");


--
-- Name: IDX_agents_projectId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_agents_projectId" ON public.agents USING btree ("projectId");


--
-- Name: IDX_ba67ee8dc311830a2eea89b6e9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_ba67ee8dc311830a2eea89b6e9" ON public.instance_ai_pending_confirmations USING btree ("threadId");


--
-- Name: IDX_bb66e404c35996b0d694617750; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_bb66e404c35996b0d694617750" ON public.role_mapping_rule USING btree (role);


--
-- Name: IDX_be9d0eca0b19fb93d4eb74b327; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_be9d0eca0b19fb93d4eb74b327" ON public.instance_ai_checkpoints USING btree ("resourceId");


--
-- Name: IDX_c1519757391996eb06064f0e7c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_c1519757391996eb06064f0e7c" ON public.execution_annotation_tags USING btree ("annotationId");


--
-- Name: IDX_cb7c15d22fd068a0806aa57fc0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_cb7c15d22fd068a0806aa57fc0" ON public.agents_memory_entry_sources USING btree ("observationId");


--
-- Name: IDX_cec8eea3bf49551482ccb4933e; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_cec8eea3bf49551482ccb4933e" ON public.execution_metadata USING btree ("executionId", key);


--
-- Name: IDX_chat_hub_messages_sessionId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_chat_hub_messages_sessionId" ON public.chat_hub_messages USING btree ("sessionId");


--
-- Name: IDX_chat_hub_sessions_owner_lastmsg_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_chat_hub_sessions_owner_lastmsg_id" ON public.chat_hub_sessions USING btree ("ownerId", "lastMessageAt" DESC, id);


--
-- Name: IDX_credential_dependency_credentialId_dependencyType_dependenc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_credential_dependency_credentialId_dependencyType_dependenc" ON public.credential_dependency USING btree ("credentialId", "dependencyType", "dependencyId");


--
-- Name: IDX_credentials_entity_is_global; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_credentials_entity_is_global" ON public.credentials_entity USING btree (id) WHERE ("isGlobal" = true);


--
-- Name: IDX_d3a2bc880e7a8626802e5474ad; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_d3a2bc880e7a8626802e5474ad" ON public.instance_ai_run_snapshots USING btree ("threadId", "createdAt");


--
-- Name: IDX_d61a12235d268a49af6a3c09c1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_d61a12235d268a49af6a3c09c1" ON public.dynamic_credential_entry USING btree (resolver_id);


--
-- Name: IDX_d634a0c93fd7de68a87eab951b; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_d634a0c93fd7de68a87eab951b" ON public.evaluation_collection USING btree ("evaluationConfigId");


--
-- Name: IDX_d6870d3b6e4c185d33926f423c; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_d6870d3b6e4c185d33926f423c" ON public.test_run USING btree ("workflowId");


--
-- Name: IDX_d7a4aba7440449865e2b924377; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_d7a4aba7440449865e2b924377" ON public.instance_ai_pending_confirmations USING btree ("expiresAt");


--
-- Name: IDX_d926c16c2ad9728cb9a81790c0; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_d926c16c2ad9728cb9a81790c0" ON public.instance_ai_run_snapshots USING btree ("threadId", "messageGroupId");


--
-- Name: IDX_daef2195a4a846eb70eed15e03; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_daef2195a4a846eb70eed15e03" ON public.instance_ai_observations USING btree ("parentId");


--
-- Name: IDX_deployment_key_data_encryption_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_deployment_key_data_encryption_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'data_encryption'::text));


--
-- Name: IDX_deployment_key_instance_id_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_deployment_key_instance_id_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'instance.id'::text));


--
-- Name: IDX_deployment_key_jwe_private_key_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_deployment_key_jwe_private_key_active" ON public.deployment_key USING btree (type, algorithm) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'jwe.private-key'::text));


--
-- Name: IDX_deployment_key_signing_binary_data_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_deployment_key_signing_binary_data_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'signing.binary_data'::text));


--
-- Name: IDX_deployment_key_signing_hmac_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_deployment_key_signing_hmac_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'signing.hmac'::text));


--
-- Name: IDX_deployment_key_signing_jwt_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_deployment_key_signing_jwt_active" ON public.deployment_key USING btree (type) WHERE (((status)::text = 'active'::text) AND ((type)::text = 'signing.jwt'::text));


--
-- Name: IDX_df5fd25c8bbfd2b042602600d8; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_df5fd25c8bbfd2b042602600d8" ON public.instance_ai_pending_confirmations USING btree ("userId");


--
-- Name: IDX_e48a201071ab85d9d09119d640; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_e48a201071ab85d9d09119d640" ON public.workflow_dependency USING btree ("dependencyKey");


--
-- Name: IDX_e7fe1cfda990c14a445937d0b9; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_e7fe1cfda990c14a445937d0b9" ON public.workflow_dependency USING btree ("dependencyType");


--
-- Name: IDX_execution_entity_deduplicationKey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_execution_entity_deduplicationKey" ON public.execution_entity USING btree ("deduplicationKey") WHERE ("deduplicationKey" IS NOT NULL);


--
-- Name: IDX_execution_entity_deletedAt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_execution_entity_deletedAt" ON public.execution_entity USING btree ("deletedAt");


--
-- Name: IDX_execution_entity_workflowId_status_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_execution_entity_workflowId_status_id" ON public.execution_entity USING btree ("workflowId", status, id) WHERE ("deletedAt" IS NULL);


--
-- Name: IDX_f36dea4d38fe92e0e8f44d5a56; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_f36dea4d38fe92e0e8f44d5a56" ON public.instance_ai_threads USING btree ("resourceId");


--
-- Name: IDX_f45d0535a2ed59b6c2dd6da98a; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_f45d0535a2ed59b6c2dd6da98a" ON public.agent_task_definition USING btree ("agentId");


--
-- Name: IDX_f9573af4ed653f13b0ba1f7b12; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_f9573af4ed653f13b0ba1f7b12" ON public.agents_memory_entry_sources USING btree ("agentId", "threadId");


--
-- Name: IDX_fc7bf858660bfafd19181e8e35; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_fc7bf858660bfafd19181e8e35" ON public.agents_messages USING btree ("threadId", "createdAt");


--
-- Name: IDX_fd7542bb123074760285dc1bbf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_fd7542bb123074760285dc1bbf" ON public.evaluation_config USING btree ("workflowId");


--
-- Name: IDX_insights_raw_timestamp_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_insights_raw_timestamp_id" ON public.insights_raw USING btree ("timestamp", id);


--
-- Name: IDX_instance_ai_threads_projectId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_instance_ai_threads_projectId" ON public.instance_ai_threads USING btree ("projectId");


--
-- Name: IDX_role_scope_scopeSlug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_role_scope_scopeSlug" ON public.role_scope USING btree ("scopeSlug");


--
-- Name: IDX_scheduled_job_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_scheduled_job_name" ON public.scheduled_job USING btree (name);


--
-- Name: IDX_scheduled_job_nextRunAt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_scheduled_job_nextRunAt" ON public.scheduled_job USING btree ("nextRunAt") WHERE ((enabled = true) AND ("nextRunAt" IS NOT NULL));


--
-- Name: IDX_scheduled_job_workflowId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_scheduled_job_workflowId" ON public.scheduled_job USING btree ("workflowId") WHERE ("workflowId" IS NOT NULL);


--
-- Name: IDX_scheduled_task_finishedAt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_scheduled_task_finishedAt" ON public.scheduled_task USING btree ("finishedAt") WHERE ("finishedAt" IS NOT NULL);


--
-- Name: IDX_scheduled_task_jobId_scheduledFor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_scheduled_task_jobId_scheduledFor" ON public.scheduled_task USING btree ("jobId", "scheduledFor");


--
-- Name: IDX_scheduled_task_leaseExpiresAt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_scheduled_task_leaseExpiresAt" ON public.scheduled_task USING btree ("leaseExpiresAt") WHERE ((status)::text = 'running'::text);


--
-- Name: IDX_scheduled_task_runAt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_scheduled_task_runAt" ON public.scheduled_task USING btree ("runAt") WHERE ((status)::text = 'pending'::text);


--
-- Name: IDX_secrets_provider_connection_providerKey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_secrets_provider_connection_providerKey" ON public.secrets_provider_connection USING btree ("providerKey");


--
-- Name: IDX_shared_workflow_projectId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_shared_workflow_projectId" ON public.shared_workflow USING btree ("projectId");


--
-- Name: IDX_test_run_collectionId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_test_run_collectionId" ON public.test_run USING btree ("collectionId");


--
-- Name: IDX_test_run_evaluationConfigId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_test_run_evaluationConfigId" ON public.test_run USING btree ("evaluationConfigId");


--
-- Name: IDX_workflow_dependency_publishedVersionId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_workflow_dependency_publishedVersionId" ON public.workflow_dependency USING btree ("publishedVersionId");


--
-- Name: IDX_workflow_entity_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_workflow_entity_name" ON public.workflow_entity USING btree (name);


--
-- Name: IDX_workflow_entity_sourceWorkflowId; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_workflow_entity_sourceWorkflowId" ON public.workflow_entity USING btree ("sourceWorkflowId") WHERE ("sourceWorkflowId" IS NOT NULL);


--
-- Name: IDX_workflow_publication_outbox_active_workflow_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_workflow_publication_outbox_active_workflow_status" ON public.workflow_publication_outbox USING btree ("workflowId", status) WHERE ((status)::text = ANY ((ARRAY['pending'::character varying, 'in_progress'::character varying])::text[]));


--
-- Name: IDX_workflow_statistics_workflow_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "IDX_workflow_statistics_workflow_name" ON public.workflow_statistics USING btree ("workflowId", name);


--
-- Name: idx_07fde106c0b471d8cc80a64fc8; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_07fde106c0b471d8cc80a64fc8 ON public.credentials_entity USING btree (type);


--
-- Name: idx_16f4436789e804e3e1c9eeb240; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_16f4436789e804e3e1c9eeb240 ON public.webhook_entity USING btree ("webhookId", method, "pathLength");


--
-- Name: idx_812eb05f7451ca757fb98444ce; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_812eb05f7451ca757fb98444ce ON public.tag_entity USING btree (name);


--
-- Name: idx_execution_entity_stopped_at_status_deleted_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_execution_entity_stopped_at_status_deleted_at ON public.execution_entity USING btree ("stoppedAt", status, "deletedAt") WHERE (("stoppedAt" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_execution_entity_wait_till_status_deleted_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_execution_entity_wait_till_status_deleted_at ON public.execution_entity USING btree ("waitTill", status, "deletedAt") WHERE (("waitTill" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_execution_entity_workflow_id_started_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_execution_entity_workflow_id_started_at ON public.execution_entity USING btree ("workflowId", "startedAt") WHERE (("startedAt" IS NOT NULL) AND ("deletedAt" IS NULL));


--
-- Name: idx_workflows_tags_workflow_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_workflows_tags_workflow_id ON public.workflows_tags USING btree ("workflowId");


--
-- Name: pk_credentials_entity_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX pk_credentials_entity_id ON public.credentials_entity USING btree (id);


--
-- Name: pk_tag_entity_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX pk_tag_entity_id ON public.tag_entity USING btree (id);


--
-- Name: pk_workflow_entity_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX pk_workflow_entity_id ON public.workflow_entity USING btree (id);


--
-- Name: project_relation_role_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX project_relation_role_idx ON public.project_relation USING btree (role);


--
-- Name: project_relation_role_project_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX project_relation_role_project_idx ON public.project_relation USING btree ("projectId", role);


--
-- Name: user_role_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_role_idx ON public."user" USING btree ("roleSlug");


--
-- Name: variables_global_key_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX variables_global_key_unique ON public.variables USING btree (key) WHERE ("projectId" IS NULL);


--
-- Name: variables_project_key_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX variables_project_key_unique ON public.variables USING btree ("projectId", key) WHERE ("projectId" IS NOT NULL);


--
-- Name: workflow_entity workflow_version_increment; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER workflow_version_increment BEFORE UPDATE ON public.workflow_entity FOR EACH ROW EXECUTE FUNCTION public.increment_workflow_version();


--
-- Name: workflow_builder_session FK_00290cdeee4d4d7db84709be936; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_builder_session
    ADD CONSTRAINT "FK_00290cdeee4d4d7db84709be936" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agent_execution_threads FK_0468a9dc35597314e641d4722aa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_execution_threads
    ADD CONSTRAINT "FK_0468a9dc35597314e641d4722aa" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_cursors FK_069e791e428391a5569e7a96b20; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_cursors
    ADD CONSTRAINT "FK_069e791e428391a5569e7a96b20" FOREIGN KEY ("observationScopeId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: processed_data FK_06a69a7032c97a763c2c7599464; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processed_data
    ADD CONSTRAINT "FK_06a69a7032c97a763c2c7599464" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: workflow_entity FK_08d6c67b7f722b0039d9d5ed620; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_entity
    ADD CONSTRAINT "FK_08d6c67b7f722b0039d9d5ed620" FOREIGN KEY ("activeVersionId") REFERENCES public.workflow_history("versionId") ON DELETE RESTRICT;


--
-- Name: agents_observation_locks FK_093e44ae20f2518e97d83a95433; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observation_locks
    ADD CONSTRAINT "FK_093e44ae20f2518e97d83a95433" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agents_messages FK_0a8057a61afabd2999608ffd0d9; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_messages
    ADD CONSTRAINT "FK_0a8057a61afabd2999608ffd0d9" FOREIGN KEY ("threadId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: instance_ai_pending_confirmations FK_0babdf6e3b897a86fe4678355eb; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_pending_confirmations
    ADD CONSTRAINT "FK_0babdf6e3b897a86fe4678355eb" FOREIGN KEY ("checkpointKey") REFERENCES public.instance_ai_checkpoints(key) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_locks FK_0ccf6d9ea6f44fa1c264fc2f795; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_locks
    ADD CONSTRAINT "FK_0ccf6d9ea6f44fa1c264fc2f795" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agent_execution_threads FK_0e2f8bf92a7a9c88b89670f701c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_execution_threads
    ADD CONSTRAINT "FK_0e2f8bf92a7a9c88b89670f701c" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entries FK_0edf1226b77ddc525eae4938079; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entries
    ADD CONSTRAINT "FK_0edf1226b77ddc525eae4938079" FOREIGN KEY ("supersededBy") REFERENCES public.agents_memory_entries(id);


--
-- Name: instance_ai_observation_locks FK_103e2e5f454860b28ea05a82c74; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observation_locks
    ADD CONSTRAINT "FK_103e2e5f454860b28ea05a82c74" FOREIGN KEY ("observationScopeId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: agents_observations FK_127ee1078ffa952bb37b511efad; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "FK_127ee1078ffa952bb37b511efad" FOREIGN KEY ("supersededBy") REFERENCES public.agents_observations(id);


--
-- Name: agents_memory_entries FK_1443a75e59adbfb796071d66393; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entries
    ADD CONSTRAINT "FK_1443a75e59adbfb796071d66393" FOREIGN KEY ("resourceId") REFERENCES public.agents_resources(id) ON DELETE CASCADE;


--
-- Name: project_secrets_provider_access FK_18e5c27d2524b1638b292904e48; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_secrets_provider_access
    ADD CONSTRAINT "FK_18e5c27d2524b1638b292904e48" FOREIGN KEY ("secretsProviderConnectionId") REFERENCES public.secrets_provider_connection(id) ON DELETE CASCADE;


--
-- Name: agent_task_snapshot FK_1acedce6690392ef1611cca8b88; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_task_snapshot
    ADD CONSTRAINT "FK_1acedce6690392ef1611cca8b88" FOREIGN KEY ("versionId") REFERENCES public.agent_history("versionId") ON DELETE CASCADE;


--
-- Name: instance_ai_mcp_registry_connections FK_1d25707354d2012da256eb2ec0a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_mcp_registry_connections
    ADD CONSTRAINT "FK_1d25707354d2012da256eb2ec0a" FOREIGN KEY ("serverSlug") REFERENCES public.mcp_registry_server(slug) ON DELETE CASCADE;


--
-- Name: insights_metadata FK_1d8ab99d5861c9388d2dc1cf733; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "FK_1d8ab99d5861c9388d2dc1cf733" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: user_favorites FK_1dd5c393ad0517be3c31a7af836; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT "FK_1dd5c393ad0517be3c31a7af836" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: workflow_history FK_1e31657f5fe46816c34be7c1b4b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_history
    ADD CONSTRAINT "FK_1e31657f5fe46816c34be7c1b4b" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_mcp_registry_connections FK_1e826120e7e53ebc4681f026de8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_mcp_registry_connections
    ADD CONSTRAINT "FK_1e826120e7e53ebc4681f026de8" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_messages FK_1eeb64cb9d66a927988de759e6e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_messages
    ADD CONSTRAINT "FK_1eeb64cb9d66a927988de759e6e" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_1f4998c8a7dec9e00a9ab15550e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_1f4998c8a7dec9e00a9ab15550e" FOREIGN KEY ("revisionOfMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: oauth_user_consents FK_21e6c3c2d78a097478fae6aaefa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_user_consents
    ADD CONSTRAINT "FK_21e6c3c2d78a097478fae6aaefa" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: insights_metadata FK_2375a1eda085adb16b24615b69c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insights_metadata
    ADD CONSTRAINT "FK_2375a1eda085adb16b24615b69c" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE SET NULL;


--
-- Name: chat_hub_messages FK_25c9736e7f769f3a005eef4b372; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_25c9736e7f769f3a005eef4b372" FOREIGN KEY ("retryOfMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entries FK_28e981fb675e9b44ce02f0ec1dd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entries
    ADD CONSTRAINT "FK_28e981fb675e9b44ce02f0ec1dd" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: instance_ai_checkpoints FK_2b23f3f24a70bebb990203b011e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_checkpoints
    ADD CONSTRAINT "FK_2b23f3f24a70bebb990203b011e" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: chat_hub_agent_tools FK_2b53d796b3dbae91b1a9553c048; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_agent_tools
    ADD CONSTRAINT "FK_2b53d796b3dbae91b1a9553c048" FOREIGN KEY ("agentId") REFERENCES public.chat_hub_agents(id) ON DELETE CASCADE;


--
-- Name: instance_ai_run_snapshots FK_2f63fa21d09d7918f347ddbdf70; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_run_snapshots
    ADD CONSTRAINT "FK_2f63fa21d09d7918f347ddbdf70" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: execution_metadata FK_31d0b4c93fb85ced26f6005cda3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_metadata
    ADD CONSTRAINT "FK_31d0b4c93fb85ced26f6005cda3" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_observational_memory FK_34018c303885cd37093458e6409; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observational_memory
    ADD CONSTRAINT "FK_34018c303885cd37093458e6409" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE SET NULL;


--
-- Name: instance_ai_events FK_35909c5576a4a6c1d6a6fb71caa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_events
    ADD CONSTRAINT "FK_35909c5576a4a6c1d6a6fb71caa" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: role_mapping_rule_project FK_35a78869286c65d9330d02b88f5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_mapping_rule_project
    ADD CONSTRAINT "FK_35a78869286c65d9330d02b88f5" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: ai_builder_temporary_workflow FK_39b07732e819fb561d74c38763f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_builder_temporary_workflow
    ADD CONSTRAINT "FK_39b07732e819fb561d74c38763f" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: instance_ai_thread_grants FK_401b94abf83d1ac7a841f31330e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_thread_grants
    ADD CONSTRAINT "FK_401b94abf83d1ac7a841f31330e" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: shared_credentials FK_416f66fc846c7c442970c094ccf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "FK_416f66fc846c7c442970c094ccf" FOREIGN KEY ("credentialsId") REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: variables FK_42f6c766f9f9d2edcc15bdd6e9b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT "FK_42f6c766f9f9d2edcc15bdd6e9b" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: chat_hub_agent_tools FK_43e70f04c53344f82483d0570f6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_agent_tools
    ADD CONSTRAINT "FK_43e70f04c53344f82483d0570f6" FOREIGN KEY ("toolId") REFERENCES public.chat_hub_tools(id) ON DELETE CASCADE;


--
-- Name: chat_hub_agents FK_441ba2caba11e077ce3fbfa2cd8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_agents
    ADD CONSTRAINT "FK_441ba2caba11e077ce3fbfa2cd8" FOREIGN KEY ("ownerId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_sources FK_451d387a182fa8dd8002dfc3a77; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "FK_451d387a182fa8dd8002dfc3a77" FOREIGN KEY ("threadId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_sources FK_4706f6223313959b7437a2b48df; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "FK_4706f6223313959b7437a2b48df" FOREIGN KEY ("memoryEntryId") REFERENCES public.agents_memory_entries(id) ON DELETE CASCADE;


--
-- Name: agents_observations FK_4cfd8a70ebb0a5b0cf047dca3cf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "FK_4cfd8a70ebb0a5b0cf047dca3cf" FOREIGN KEY ("observationScopeId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: agents_observations FK_501e2d1701a10e24fb69ab5fc5f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "FK_501e2d1701a10e24fb69ab5fc5f" FOREIGN KEY ("parentId") REFERENCES public.agents_observations(id);


--
-- Name: instance_ai_observation_cursors FK_5b6319b2e9a37c1064a72428f9a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observation_cursors
    ADD CONSTRAINT "FK_5b6319b2e9a37c1064a72428f9a" FOREIGN KEY ("observationScopeId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: workflow_published_version FK_5c76fb7ee939fe2530374d3f75a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_published_version
    ADD CONSTRAINT "FK_5c76fb7ee939fe2530374d3f75a" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE RESTRICT;


--
-- Name: agent_checkpoints FK_5e31c210f896d539964bf99fe32; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_checkpoints
    ADD CONSTRAINT "FK_5e31c210f896d539964bf99fe32" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: credential_dependency FK_5ec8e8c8d3539f3696cf73b43bf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credential_dependency
    ADD CONSTRAINT "FK_5ec8e8c8d3539f3696cf73b43bf" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_5f0643f6717905a05164090dde7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_5f0643f6717905a05164090dde7" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_61448d56d61802b5dfde5cdb002; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_61448d56d61802b5dfde5cdb002" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: insights_by_period FK_6414cfed98daabbfdd61a1cfbc0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insights_by_period
    ADD CONSTRAINT "FK_6414cfed98daabbfdd61a1cfbc0" FOREIGN KEY ("metaId") REFERENCES public.insights_metadata("metaId") ON DELETE CASCADE;


--
-- Name: oauth_authorization_codes FK_64d965bd072ea24fb6da55468cd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT "FK_64d965bd072ea24fb6da55468cd" FOREIGN KEY ("clientId") REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: agents_observation_cursors FK_64e92819f4b413661ed6e2c3c3d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observation_cursors
    ADD CONSTRAINT "FK_64e92819f4b413661ed6e2c3c3d" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: chat_hub_session_tools FK_6596a328affd8d4967ffb303eee; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_session_tools
    ADD CONSTRAINT "FK_6596a328affd8d4967ffb303eee" FOREIGN KEY ("toolId") REFERENCES public.chat_hub_tools(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_6afb260449dd7a9b85355d4e0c9; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_6afb260449dd7a9b85355d4e0c9" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE SET NULL;


--
-- Name: agents_observation_locks FK_6b55089892e447c2f82e5ec60ed; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observation_locks
    ADD CONSTRAINT "FK_6b55089892e447c2f82e5ec60ed" FOREIGN KEY ("observationScopeId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: insights_raw FK_6e2e33741adef2a7c5d66befa4e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insights_raw
    ADD CONSTRAINT "FK_6e2e33741adef2a7c5d66befa4e" FOREIGN KEY ("metaId") REFERENCES public.insights_metadata("metaId") ON DELETE CASCADE;


--
-- Name: workflow_publish_history FK_6eab5bd9eedabe9c54bd879fc40; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_publish_history
    ADD CONSTRAINT "FK_6eab5bd9eedabe9c54bd879fc40" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: dynamic_credential_user_entry FK_6edec973a6450990977bb854c38; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_credential_user_entry
    ADD CONSTRAINT "FK_6edec973a6450990977bb854c38" FOREIGN KEY ("resolverId") REFERENCES public.dynamic_credential_resolver(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens FK_7234a36d8e49a1fa85095328845; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT "FK_7234a36d8e49a1fa85095328845" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: installed_nodes FK_73f857fc5dce682cef8a99c11dbddbc969618951; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.installed_nodes
    ADD CONSTRAINT "FK_73f857fc5dce682cef8a99c11dbddbc969618951" FOREIGN KEY (package) REFERENCES public.installed_packages("packageName") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agents_memory_entry_cursors FK_746780fd115e5e4352457a3c617; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_cursors
    ADD CONSTRAINT "FK_746780fd115e5e4352457a3c617" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens FK_78b26968132b7e5e45b75876481; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT "FK_78b26968132b7e5e45b75876481" FOREIGN KEY ("clientId") REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: workflow_builder_session FK_7983c618db48f47bf5a4cc1e1e4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_builder_session
    ADD CONSTRAINT "FK_7983c618db48f47bf5a4cc1e1e4" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: chat_hub_sessions FK_7bc13b4c7e6afbfaf9be326c189; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_7bc13b4c7e6afbfaf9be326c189" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE SET NULL;


--
-- Name: folder FK_804ea52f6729e3940498bd54d78; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "FK_804ea52f6729e3940498bd54d78" FOREIGN KEY ("parentFolderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: shared_credentials FK_812c2852270da1247756e77f5a4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shared_credentials
    ADD CONSTRAINT "FK_812c2852270da1247756e77f5a4" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: ai_builder_temporary_workflow FK_85a87a1ba0f61999fe11dc56325; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_builder_temporary_workflow
    ADD CONSTRAINT "FK_85a87a1ba0f61999fe11dc56325" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: agent_history FK_8771675f44c58fb40e0feb9ee35; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_history
    ADD CONSTRAINT "FK_8771675f44c58fb40e0feb9ee35" FOREIGN KEY ("publishedById") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: agents_observation_cursors FK_87aa187d27ea67eafd164905154; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observation_cursors
    ADD CONSTRAINT "FK_87aa187d27ea67eafd164905154" FOREIGN KEY ("observationScopeId") REFERENCES public.agents_threads(id) ON DELETE CASCADE;


--
-- Name: agent_history FK_87cd5a8da20304b089ea2f83fec; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_history
    ADD CONSTRAINT "FK_87cd5a8da20304b089ea2f83fec" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: instance_ai_mcp_registry_connections FK_8b42c08a531d76410980c639a5b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_mcp_registry_connections
    ADD CONSTRAINT "FK_8b42c08a531d76410980c639a5b" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: instance_ai_iteration_logs FK_8bfcc6c51fd3d69b1eae8aebd49; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_iteration_logs
    ADD CONSTRAINT "FK_8bfcc6c51fd3d69b1eae8aebd49" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: trusted_key FK_8c2938d746943dd8f608d23c891; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trusted_key
    ADD CONSTRAINT "FK_8c2938d746943dd8f608d23c891" FOREIGN KEY ("sourceId") REFERENCES public.trusted_key_source(id) ON DELETE CASCADE;


--
-- Name: test_case_execution FK_8e4b4774db42f1e6dda3452b2af; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "FK_8e4b4774db42f1e6dda3452b2af" FOREIGN KEY ("testRunId") REFERENCES public.test_run(id) ON DELETE CASCADE;


--
-- Name: instance_ai_thread_grants FK_908202dbc0a9b52f669c11d730c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_thread_grants
    ADD CONSTRAINT "FK_908202dbc0a9b52f669c11d730c" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: data_table_column FK_930b6e8faaf88294cef23484160; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_table_column
    ADD CONSTRAINT "FK_930b6e8faaf88294cef23484160" FOREIGN KEY ("dataTableId") REFERENCES public.data_table(id) ON DELETE CASCADE;


--
-- Name: agents FK_940597dfe9753375309ce6aeea0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT "FK_940597dfe9753375309ce6aeea0" FOREIGN KEY ("activeVersionId") REFERENCES public.agent_history("versionId") ON DELETE SET NULL;


--
-- Name: dynamic_credential_user_entry FK_945ba70b342a066d1306b12ccd2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_credential_user_entry
    ADD CONSTRAINT "FK_945ba70b342a066d1306b12ccd2" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: folder_tag FK_94a60854e06f2897b2e0d39edba; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "FK_94a60854e06f2897b2e0d39edba" FOREIGN KEY ("folderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_locks FK_9594c0983cfee1c8ff49b05848b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_locks
    ADD CONSTRAINT "FK_9594c0983cfee1c8ff49b05848b" FOREIGN KEY ("resourceId") REFERENCES public.agents_resources(id) ON DELETE CASCADE;


--
-- Name: execution_annotations FK_97f863fa83c4786f19565084960; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_annotations
    ADD CONSTRAINT "FK_97f863fa83c4786f19565084960" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: chat_hub_agents FK_9c61ad497dcbae499c96a6a78ba; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_agents
    ADD CONSTRAINT "FK_9c61ad497dcbae499c96a6a78ba" FOREIGN KEY ("credentialId") REFERENCES public.credentials_entity(id) ON DELETE SET NULL;


--
-- Name: chat_hub_sessions FK_9f9293d9f552496c40e0d1a8f80; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_9f9293d9f552496c40e0d1a8f80" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: agents FK_a30d560207c4071d98aa03c179c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT "FK_a30d560207c4071d98aa03c179c" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: execution_annotation_tags FK_a3697779b366e131b2bbdae2976; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "FK_a3697779b366e131b2bbdae2976" FOREIGN KEY ("tagId") REFERENCES public.annotation_tag_entity(id) ON DELETE CASCADE;


--
-- Name: dynamic_credential_user_entry FK_a36dc616fabc3f736bb82410a22; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_credential_user_entry
    ADD CONSTRAINT "FK_a36dc616fabc3f736bb82410a22" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: shared_workflow FK_a45ea5f27bcfdc21af9b4188560; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "FK_a45ea5f27bcfdc21af9b4188560" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: evaluation_collection FK_a48ce930c3bc7604894b8f0eaad; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluation_collection
    ADD CONSTRAINT "FK_a48ce930c3bc7604894b8f0eaad" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: workflow_dependency FK_a4ff2d9b9628ea988fa9e7d0bf8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_dependency
    ADD CONSTRAINT "FK_a4ff2d9b9628ea988fa9e7d0bf8" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: oauth_user_consents FK_a651acea2f6c97f8c4514935486; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_user_consents
    ADD CONSTRAINT "FK_a651acea2f6c97f8c4514935486" FOREIGN KEY ("clientId") REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_refresh_tokens FK_a699f3ed9fd0c1b19bc2608ac53; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT "FK_a699f3ed9fd0c1b19bc2608ac53" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: dynamic_credential_entry FK_a6d1dd080958304a47a02952aab; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_credential_entry
    ADD CONSTRAINT "FK_a6d1dd080958304a47a02952aab" FOREIGN KEY (credential_id) REFERENCES public.credentials_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_observations FK_a80e0ee839a2f10ba4b86e19998; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observations
    ADD CONSTRAINT "FK_a80e0ee839a2f10ba4b86e19998" FOREIGN KEY ("supersededBy") REFERENCES public.instance_ai_observations(id);


--
-- Name: folder FK_a8260b0b36939c6247f385b8221; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder
    ADD CONSTRAINT "FK_a8260b0b36939c6247f385b8221" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: oauth_authorization_codes FK_aa8d3560484944c19bdf79ffa16; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT "FK_aa8d3560484944c19bdf79ffa16" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agent_files FK_aca4514cb500494b64356c2e164; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_files
    ADD CONSTRAINT "FK_aca4514cb500494b64356c2e164" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_acf8926098f063cdbbad8497fd1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_acf8926098f063cdbbad8497fd1" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE SET NULL;


--
-- Name: agent_execution FK_add2432fb6034cc18b6af299dce; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_execution
    ADD CONSTRAINT "FK_add2432fb6034cc18b6af299dce" FOREIGN KEY ("threadId") REFERENCES public.agent_execution_threads(id) ON DELETE CASCADE;


--
-- Name: oauth_refresh_tokens FK_b388696ce4d8be7ffbe8d3e4b69; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT "FK_b388696ce4d8be7ffbe8d3e4b69" FOREIGN KEY ("clientId") REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: workflow_publish_history FK_b4cfbc7556d07f36ca177f5e473; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_publish_history
    ADD CONSTRAINT "FK_b4cfbc7556d07f36ca177f5e473" FOREIGN KEY ("versionId") REFERENCES public.workflow_history("versionId") ON DELETE SET NULL;


--
-- Name: agent_task_run_lock FK_b57a2862ae869aab24e54cefd48; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_task_run_lock
    ADD CONSTRAINT "FK_b57a2862ae869aab24e54cefd48" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: workflow_publication_trigger_status FK_b7b496d8d1a21158c65f475cd88; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_publication_trigger_status
    ADD CONSTRAINT "FK_b7b496d8d1a21158c65f475cd88" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: chat_hub_tools FK_b8030b47af9213f1fd15450fb7f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_tools
    ADD CONSTRAINT "FK_b8030b47af9213f1fd15450fb7f" FOREIGN KEY ("ownerId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: instance_ai_pending_confirmations FK_ba67ee8dc311830a2eea89b6e96; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_pending_confirmations
    ADD CONSTRAINT "FK_ba67ee8dc311830a2eea89b6e96" FOREIGN KEY ("threadId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: role_mapping_rule FK_bb66e404c35996b0d6946177501; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_mapping_rule
    ADD CONSTRAINT "FK_bb66e404c35996b0d6946177501" FOREIGN KEY (role) REFERENCES public.role(slug) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: project_secrets_provider_access FK_bd264b81209355b543878deedb1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_secrets_provider_access
    ADD CONSTRAINT "FK_bd264b81209355b543878deedb1" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: workflow_publish_history FK_c01316f8c2d7101ec4fa9809267; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_publish_history
    ADD CONSTRAINT "FK_c01316f8c2d7101ec4fa9809267" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: execution_annotation_tags FK_c1519757391996eb06064f0e7c8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_annotation_tags
    ADD CONSTRAINT "FK_c1519757391996eb06064f0e7c8" FOREIGN KEY ("annotationId") REFERENCES public.execution_annotations(id) ON DELETE CASCADE;


--
-- Name: data_table FK_c2a794257dee48af7c9abf681de; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_table
    ADD CONSTRAINT "FK_c2a794257dee48af7c9abf681de" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: agents_memory_entry_sources FK_c38e8a57a36b880e39a52ada2e8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "FK_c38e8a57a36b880e39a52ada2e8" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: project_relation FK_c6b99592dc96b0d836d7a21db91; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_relation
    ADD CONSTRAINT "FK_c6b99592dc96b0d836d7a21db91" FOREIGN KEY (role) REFERENCES public.role(slug);


--
-- Name: agents_memory_entry_sources FK_cb7c15d22fd068a0806aa57fc03; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_memory_entry_sources
    ADD CONSTRAINT "FK_cb7c15d22fd068a0806aa57fc03" FOREIGN KEY ("observationId") REFERENCES public.agents_observations(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_chat_hub_messages_agentId; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_chat_hub_messages_agentId" FOREIGN KEY ("agentId") REFERENCES public.chat_hub_agents(id) ON DELETE SET NULL;


--
-- Name: chat_hub_sessions FK_chat_hub_sessions_agentId; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_chat_hub_sessions_agentId" FOREIGN KEY ("agentId") REFERENCES public.chat_hub_agents(id) ON DELETE SET NULL;


--
-- Name: agents_observations FK_d206432be97b7ed88d187479b1b; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_observations
    ADD CONSTRAINT "FK_d206432be97b7ed88d187479b1b" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: instance_ai_observations FK_d54fc84a6c8ac91b5e0db0378a4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observations
    ADD CONSTRAINT "FK_d54fc84a6c8ac91b5e0db0378a4" FOREIGN KEY ("observationScopeId") REFERENCES public.instance_ai_threads(id) ON DELETE CASCADE;


--
-- Name: dynamic_credential_entry FK_d61a12235d268a49af6a3c09c13; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dynamic_credential_entry
    ADD CONSTRAINT "FK_d61a12235d268a49af6a3c09c13" FOREIGN KEY (resolver_id) REFERENCES public.dynamic_credential_resolver(id) ON DELETE CASCADE;


--
-- Name: evaluation_collection FK_d634a0c93fd7de68a87eab951b2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluation_collection
    ADD CONSTRAINT "FK_d634a0c93fd7de68a87eab951b2" FOREIGN KEY ("evaluationConfigId") REFERENCES public.evaluation_config(id) ON DELETE CASCADE;


--
-- Name: test_run FK_d6870d3b6e4c185d33926f423c8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "FK_d6870d3b6e4c185d33926f423c8" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: shared_workflow FK_daa206a04983d47d0a9c34649ce; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shared_workflow
    ADD CONSTRAINT "FK_daa206a04983d47d0a9c34649ce" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_observations FK_daef2195a4a846eb70eed15e039; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_observations
    ADD CONSTRAINT "FK_daef2195a4a846eb70eed15e039" FOREIGN KEY ("parentId") REFERENCES public.instance_ai_observations(id);


--
-- Name: folder_tag FK_dc88164176283de80af47621746; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folder_tag
    ADD CONSTRAINT "FK_dc88164176283de80af47621746" FOREIGN KEY ("tagId") REFERENCES public.tag_entity(id) ON DELETE CASCADE;


--
-- Name: role_mapping_rule_project FK_dd7ce4dfa09e95b36a626bd9de3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_mapping_rule_project
    ADD CONSTRAINT "FK_dd7ce4dfa09e95b36a626bd9de3" FOREIGN KEY ("roleMappingRuleId") REFERENCES public.role_mapping_rule(id) ON DELETE CASCADE;


--
-- Name: workflow_published_version FK_df3428a541b802d6a63ac56e330; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_published_version
    ADD CONSTRAINT "FK_df3428a541b802d6a63ac56e330" FOREIGN KEY ("publishedVersionId") REFERENCES public.workflow_history("versionId") ON DELETE RESTRICT;


--
-- Name: instance_ai_pending_confirmations FK_df5fd25c8bbfd2b042602600d8e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_pending_confirmations
    ADD CONSTRAINT "FK_df5fd25c8bbfd2b042602600d8e" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_api_keys FK_e131705cbbc8fb589889b02d457; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_api_keys
    ADD CONSTRAINT "FK_e131705cbbc8fb589889b02d457" FOREIGN KEY ("userId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_hub_messages FK_e22538eb50a71a17954cd7e076c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_e22538eb50a71a17954cd7e076c" FOREIGN KEY ("sessionId") REFERENCES public.chat_hub_sessions(id) ON DELETE CASCADE;


--
-- Name: test_case_execution FK_e48965fac35d0f5b9e7f51d8c44; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_case_execution
    ADD CONSTRAINT "FK_e48965fac35d0f5b9e7f51d8c44" FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE SET NULL;


--
-- Name: chat_hub_messages FK_e5d1fa722c5a8d38ac204746662; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_messages
    ADD CONSTRAINT "FK_e5d1fa722c5a8d38ac204746662" FOREIGN KEY ("previousMessageId") REFERENCES public.chat_hub_messages(id) ON DELETE CASCADE;


--
-- Name: chat_hub_session_tools FK_e649bf1295f4ed8d4299ed290f9; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_session_tools
    ADD CONSTRAINT "FK_e649bf1295f4ed8d4299ed290f9" FOREIGN KEY ("sessionId") REFERENCES public.chat_hub_sessions(id) ON DELETE CASCADE;


--
-- Name: agent_chat_subscriptions FK_e79153bd179c011e779d5016796; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_chat_subscriptions
    ADD CONSTRAINT "FK_e79153bd179c011e779d5016796" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: chat_hub_sessions FK_e9ecf8ede7d989fcd18790fe36a; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_hub_sessions
    ADD CONSTRAINT "FK_e9ecf8ede7d989fcd18790fe36a" FOREIGN KEY ("ownerId") REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user FK_eaea92ee7bfb9c1b6cd01505d56; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT "FK_eaea92ee7bfb9c1b6cd01505d56" FOREIGN KEY ("roleSlug") REFERENCES public.role(slug);


--
-- Name: workflow_publication_trigger_status FK_ef1994db9d0ac1b6a5c89b5f729; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_publication_trigger_status
    ADD CONSTRAINT "FK_ef1994db9d0ac1b6a5c89b5f729" FOREIGN KEY ("versionId") REFERENCES public.workflow_history("versionId") ON DELETE CASCADE;


--
-- Name: agent_execution_threads FK_f00b52d74fe11838e1fe086deea; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_execution_threads
    ADD CONSTRAINT "FK_f00b52d74fe11838e1fe086deea" FOREIGN KEY ("taskVersionId") REFERENCES public.agent_history("versionId") ON DELETE SET NULL;


--
-- Name: evaluation_collection FK_f4561f38b5a22a4f090d5cd3eae; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluation_collection
    ADD CONSTRAINT "FK_f4561f38b5a22a4f090d5cd3eae" FOREIGN KEY ("createdById") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: agent_task_definition FK_f45d0535a2ed59b6c2dd6da98a0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_task_definition
    ADD CONSTRAINT "FK_f45d0535a2ed59b6c2dd6da98a0" FOREIGN KEY ("agentId") REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: evaluation_config FK_fd7542bb123074760285dc1bbf3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.evaluation_config
    ADD CONSTRAINT "FK_fd7542bb123074760285dc1bbf3" FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: instance_ai_threads FK_instance_ai_threads_projectId; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instance_ai_threads
    ADD CONSTRAINT "FK_instance_ai_threads_projectId" FOREIGN KEY ("projectId") REFERENCES public.project(id) ON DELETE CASCADE;


--
-- Name: role_scope FK_role; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "FK_role" FOREIGN KEY ("roleSlug") REFERENCES public.role(slug) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: scheduled_job FK_scheduled_job_workflowId; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_job
    ADD CONSTRAINT "FK_scheduled_job_workflowId" FOREIGN KEY ("workflowId") REFERENCES public.workflow_published_version("workflowId") ON DELETE CASCADE;


--
-- Name: scheduled_task FK_scheduled_task_jobId; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_task
    ADD CONSTRAINT "FK_scheduled_task_jobId" FOREIGN KEY ("jobId") REFERENCES public.scheduled_job(id) ON DELETE CASCADE;


--
-- Name: role_scope FK_scope; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_scope
    ADD CONSTRAINT "FK_scope" FOREIGN KEY ("scopeSlug") REFERENCES public.scope(slug) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: test_run FK_test_run_collection_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "FK_test_run_collection_id" FOREIGN KEY ("collectionId") REFERENCES public.evaluation_collection(id) ON DELETE SET NULL;


--
-- Name: test_run FK_test_run_evaluation_config_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.test_run
    ADD CONSTRAINT "FK_test_run_evaluation_config_id" FOREIGN KEY ("evaluationConfigId") REFERENCES public.evaluation_config(id) ON DELETE SET NULL;


--
-- Name: auth_identity auth_identity_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_identity
    ADD CONSTRAINT "auth_identity_userId_fkey" FOREIGN KEY ("userId") REFERENCES public."user"(id);


--
-- Name: credentials_entity credentials_entity_resolverId_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credentials_entity
    ADD CONSTRAINT "credentials_entity_resolverId_foreign" FOREIGN KEY ("resolverId") REFERENCES public.dynamic_credential_resolver(id) ON DELETE SET NULL;


--
-- Name: execution_data execution_data_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_data
    ADD CONSTRAINT execution_data_fk FOREIGN KEY ("executionId") REFERENCES public.execution_entity(id) ON DELETE CASCADE;


--
-- Name: execution_entity fk_execution_entity_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.execution_entity
    ADD CONSTRAINT fk_execution_entity_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: webhook_entity fk_webhook_entity_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.webhook_entity
    ADD CONSTRAINT fk_webhook_entity_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: workflow_entity fk_workflow_parent_folder; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_entity
    ADD CONSTRAINT fk_workflow_parent_folder FOREIGN KEY ("parentFolderId") REFERENCES public.folder(id) ON DELETE CASCADE;


--
-- Name: workflows_tags fk_workflows_tags_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT fk_workflows_tags_tag_id FOREIGN KEY ("tagId") REFERENCES public.tag_entity(id) ON DELETE CASCADE;


--
-- Name: workflows_tags fk_workflows_tags_workflow_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflows_tags
    ADD CONSTRAINT fk_workflows_tags_workflow_id FOREIGN KEY ("workflowId") REFERENCES public.workflow_entity(id) ON DELETE CASCADE;


--
-- Name: project projects_creatorId_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT "projects_creatorId_foreign" FOREIGN KEY ("creatorId") REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict V6TrDheoqkmpLN8HlxcaDsvMUWU1zgTdqNoVWJQLqfgsIhkhTbNhkkSgcFVrQjR

