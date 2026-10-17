import from .frontend { app as ClientApp }
import from hr.Auth { register, login }
import from hr.CompanyJobs { create_company, verify_company, add_agent_to_company, create_job, assign_agent_to_job, close_job, auto_close_jobs, check_job_open, search_jobs, get_job_by_id, get_job_by_slug, follow_company, unfollow_company }
import from hr.Notifications { notify, notify_job_followers }

# Auth endpoints are registered from this entry module for REST callers.
def:pub app() -> JsxElement {
    return <ClientApp />;
}
