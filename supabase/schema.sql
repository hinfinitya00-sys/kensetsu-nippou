-- ============================================================
-- 建設業 工事日報システム — Supabase スキーマ
-- Supabase SQL Editor で実行してください
-- ============================================================

-- 拡張機能（uuid 自動生成）
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ────────────────────────────────────────────────────────────
-- 1. companies — 契約企業管理
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS companies (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text        NOT NULL,
  email        text        UNIQUE NOT NULL,
  plan         text        NOT NULL DEFAULT 'basic',  -- basic / pro / enterprise
  status       text        NOT NULL DEFAULT 'active', -- active / suspended / cancelled
  api_key_hash text        UNIQUE NOT NULL,           -- SHA-256(会社APIキー)
  created_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz                            -- NULL = 無期限
);

-- インデックス
CREATE INDEX IF NOT EXISTS idx_companies_api_key_hash ON companies (api_key_hash);
CREATE INDEX IF NOT EXISTS idx_companies_status       ON companies (status);

-- RLS（Row Level Security）— サービスロールキーのみアクセス可
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────
-- 2. usage_logs — API利用ログ
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS usage_logs (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  uuid        REFERENCES companies (id) ON DELETE SET NULL,
  action      text        NOT NULL DEFAULT 'generate_report',
  tokens_used integer     NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX IF NOT EXISTS idx_usage_logs_company_id ON usage_logs (company_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_created_at ON usage_logs (created_at DESC);

-- RLS
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────
-- 3. survey_responses — Google Forms の代替アンケート回答保存
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS survey_responses (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  q1_answer        text,       -- 一番大変な書類作業（自由記述）
  q2_company_size  text,       -- 会社規模（1-5人 / 6-20人 / 21-50人 / 51人以上）
  q3_prefecture    text,       -- 都道府県
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────
-- サンプルデータ（テスト用 — 本番では削除してください）
-- API キー "TEST-API-KEY-12345" の SHA-256 ハッシュ
-- ────────────────────────────────────────────────────────────
-- INSERT INTO companies (name, email, plan, status, api_key_hash, expires_at)
-- VALUES (
--   'テスト建設株式会社',
--   'test@example.com',
--   'basic',
--   'active',
--   encode(digest('TEST-API-KEY-12345', 'sha256'), 'hex'),
--   now() + interval '1 year'
-- );
