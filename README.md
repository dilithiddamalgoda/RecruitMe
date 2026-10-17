# Havenhire Recruitment

Graph-native HR recruitment system built with Jac and Object-Spatial Programming (OSP). The backend models candidates, companies, jobs, applications, interviews, and availability as connected graph nodes.

## Install and run

```bash
jac install
jac start --dev main.jac
```

Set environment variables in the JacHammer Settings panel before starting/restarting the preview:

- `OPENAI_API_KEY` — powers structured applicant suitability evaluations (optional; rule-based fallback is used if unavailable).
- `LLM_MODEL` — optional model name; defaults to `gpt-4o-mini`.
- `RESUME_ENCRYPTION_KEY` — Fernet key used by encrypted resume import from the preceding profile workflow. Generate with Python `Fernet.generate_key()` and keep it private.
- `RESUME_STORAGE_DIR` — optional private server path for encrypted resume documents.

For local Jac use, export the same variables before running `jac start --dev main.jac`.

## Demo data

Sign in with an account assigned the `admin` or `system` application role, then call `POST /walker/seed_demo_data`. Seeding is idempotent. It creates demo graph nodes for one admin, two companies (one unverified), three agents, five applicants (one profile unconfirmed), six jobs (open, closed, and expired), sample applications/verdicts, and agent availability. Demo credentials are not generated; use authenticated accounts and assign roles through the platform's admin controls before seeding.

## Public walker endpoints

All endpoints use `POST /walker/<name>` with JSON request bodies. Authenticated routes require a Scale JWT.

### Accounts and applicant profiles
- `register`, `login`
- `import_linkedin_pdf`, `update_profile`, `confirm_profile`, `get_my_profile`, `delete_my_data`

### Jobs and companies
- `create_company`, `verify_company`, `add_agent_to_company`, `create_job`, `assign_agent_to_job`, `close_job`, `auto_close_jobs`
- `search_jobs`, `get_job_by_id`, `get_job_by_slug`, `follow_company`, `unfollow_company`

### Applications and suitability
- `apply_to_job`, `evaluate_application`, `check_suitability`, `update_application_status`, `withdraw_application`

### Interviews and notifications
- `add_availability`, `get_my_availability`, `schedule_interview`, `reschedule_interview`, `cancel_interview`, `complete_interview`
- `get_my_notifications`, `mark_read`

## Tests

```bash
jac test hr/RecruitmentIntegration.jac -v
jac test hr/Interviews.jac -v
jac test hr/Applications.jac -v
```

All AI suitability is advisory. Match scores are computed in code, never accepted from the model, and must not automatically reject or hire an applicant.
