-- ==============================================================================
-- AZ EXPERT PAVILION: ENTERPRISE CONSTRUCTION ERP DATABASE SCHEMA
-- PostgreSQL / Supabase Cloud Database Architecture
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. PROJECTS TABLE
CREATE TABLE IF NOT EXISTS public.projects (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    client VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'Active',
    budget NUMERIC(15, 2) DEFAULT 25000000.00,
    units_count INTEGER DEFAULT 174,
    contractor VARCHAR(255) DEFAULT 'Main Contractor JV',
    start_date DATE,
    completion_date DATE,
    phases JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. APPROVALS WORKFLOW TABLE (GOVERNANCE QUEUE)
CREATE TABLE IF NOT EXISTS public.approvals (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) REFERENCES public.projects(id) ON DELETE CASCADE,
    project_name VARCHAR(255),
    title VARCHAR(255) NOT NULL,
    type VARCHAR(100) NOT NULL, -- 'Payment Claim', 'Scope Variation', 'Daily Site Progress', 'Snag Sign-off'
    submitted_by VARCHAR(255) NOT NULL,
    details TEXT,
    amount NUMERIC(15, 2),
    status VARCHAR(50) DEFAULT 'Pending', -- 'Pending', 'Approved', 'Rejected'
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    decided_by VARCHAR(255),
    decided_at TIMESTAMPTZ
);

-- 4. ERP STUDIO DESIGNS & BESPOKE CLIENT CONFIGURATIONS
CREATE TABLE IF NOT EXISTS public.project_designs (
    project_id VARCHAR(64) PRIMARY KEY REFERENCES public.projects(id) ON DELETE CASCADE,
    project_name VARCHAR(255),
    client_org VARCHAR(255),
    tagline VARCHAR(255),
    theme_color VARCHAR(50) DEFAULT '#6366f1',
    modules JSONB DEFAULT '[]'::jsonb,
    custom_sections JSONB DEFAULT '[]'::jsonb,
    module_data JSONB DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. SITE DAILY LOGS (FIELD DIARY & TELEMETRY)
CREATE TABLE IF NOT EXISTS public.site_logs (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) REFERENCES public.projects(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    manpower INTEGER DEFAULT 0,
    weather VARCHAR(100),
    equipment INTEGER DEFAULT 0,
    incidents INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. QA/QC SNAGGING & PUNCH LIST DEFECTS
CREATE TABLE IF NOT EXISTS public.qa_snags (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) REFERENCES public.projects(id) ON DELETE CASCADE,
    location VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    trade VARCHAR(255),
    severity VARCHAR(50) DEFAULT 'Medium', -- 'Low', 'Medium', 'High'
    status VARCHAR(50) DEFAULT 'Open', -- 'Open', 'Pending Verification', 'Rectified'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. CDE TECHNICAL RFIS & TRANSMITTALS
CREATE TABLE IF NOT EXISTS public.rfis (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) REFERENCES public.projects(id) ON DELETE CASCADE,
    rfi_no VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    discipline VARCHAR(100),
    raised_by VARCHAR(255),
    due_date VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Pending Consultant',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. COMPATIBILITY CLUSTER TABLE (app_state)
-- Preserves resilient JSON key-value store used by the current application layer
CREATE TABLE IF NOT EXISTS public.app_state (
    id INTEGER PRIMARY KEY,
    data JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. SEED DEFAULT RECORD IF NOT PRESENT
INSERT INTO public.app_state (id, data)
VALUES 
  (0, '{"projects": [{"id": "proj-1", "name": "Pavilion Expo 2026", "client": "Expo Authority", "status": "Active"}]}'::jsonb),
  (2, '{"approvals": []}'::jsonb),
  (3, '{"designs": {}}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 10. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qa_snags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_state ENABLE ROW LEVEL SECURITY;

-- Allow authenticated reads and service_role full privileges
CREATE POLICY "Public Read Access on Projects" ON public.projects FOR SELECT USING (true);
CREATE POLICY "Service Role Full Access on Projects" ON public.projects USING (auth.role() = 'service_role');

CREATE POLICY "Public Read Access on App State" ON public.app_state FOR SELECT USING (true);
CREATE POLICY "Service Role Full Access on App State" ON public.app_state USING (auth.role() = 'service_role');
