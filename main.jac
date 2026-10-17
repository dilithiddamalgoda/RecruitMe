import from hr.Auth { register, login }
import from hr.CompanyJobs { create_company, verify_company, add_agent_to_company, create_job, assign_agent_to_job, close_job, auto_close_jobs, check_job_open, search_jobs, get_job_by_id, get_job_by_slug, follow_company, unfollow_company }
import from hr.Notifications { notify, notify_job_followers, get_my_notifications, mark_read }
import from hr.ApplicantProfiles { import_linkedin_pdf, update_profile, confirm_profile, get_my_profile, delete_my_data }
import from hr.Applications { apply_to_job, evaluate_application, check_suitability, update_application_status, withdraw_application }
import from hr.Interviews { add_availability, get_my_availability, schedule_interview, reschedule_interview, cancel_interview, complete_interview }
import from hr.Seed { seed_demo_data }
import from hr.RecruitmentIntegration { shared_directory, shared_companies, shared_jobs, publish_company, publish_job }

cl {
    import ".styles.global.css";
    import from "@jac/runtime" { Router, Routes, Route, Navigate }
    import from .components.AuthPage { AuthPage }
    import from .components.JobSearchPage { JobSearchPage }
    import from .components.JobDetailsPage { JobDetailsPage }
    import from .components.ApplicantDashboardPage { ApplicantDashboardPage }
    import from .components.AgentDashboardPage { AgentDashboardPage }
    import from .components.CompanyDashboardPage { CompanyDashboardPage }

    def:pub app() -> JsxElement {
        return <Router><Routes>
            <Route path="/" element={<Navigate to="/jobs" replace={True} />} />
            <Route path="/auth" element={<AuthPage />} />
            <Route path="/jobs" element={<JobSearchPage />} />
            <Route path="/jobs/:slug" element={<JobDetailsPage />} />
            <Route path="/applicant" element={<ApplicantDashboardPage />} />
            <Route path="/agent" element={<AgentDashboardPage />} />
            <Route path="/company" element={<CompanyDashboardPage />} />
            <Route path="*" element={<Navigate to="/jobs" replace={True} />} />
        </Routes></Router>;
    }
}
