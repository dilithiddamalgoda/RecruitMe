import from datetime { datetime }
import from hr.domain { User, ApplicantProfile, AgentProfile, Company, Job, CompanyEmploys, CompanyPosts, JobAssignedTo, ApplicantFollows, UserHasCompany, UserHasAgentProfile }
import from hr.Authorization { require_role }
import from hr.Audit { log_status_change }
import from hr.Notifications { notify_job_followers }
import from shared.Errors { AppError, make_error }
import from hr.RecruitmentIntegration { shared_companies, shared_jobs, publish_company, publish_job }

walker:pub create_company {
    has name: str;
    has description: str = "";
    has address: str = "";

    can create with Root entry {
        denial = require_role(["company_admin"]);
        if denial is not None { report denial; disengage; }
        if len(self.name.strip()) == 0 { report make_error("INVALID_COMPANY", "Company name is required.", "name"); disengage; }
        user = [root -->][?:User][0];
        company = root.shared ++> Company(name=self.name, description=self.description, address=self.address, status="pending");
        _ = publish_company(company);
        user +>:UserHasCompany:+> company;
        report company;
    }
}

walker:pub verify_company {
    has company_id: str;

    can verify with Root entry {
        denial = require_role(["admin", "system"]);
        if denial is not None { report denial; disengage; }
        for company in shared_companies() {
            if jid(company) == self.company_id {
                old_status = company.status;
                company.verified = True;
                company.status = "verified";
                _ = log_status_change("system", "Company", self.company_id, old_status, company.status, "Company verification");
                report company;
                disengage;
            }
        }
        report make_error("COMPANY_NOT_FOUND", "Company was not found.");
    }
}

walker:pub add_agent_to_company {
    has company_id: str;
    has agent_id: str;

    can attach with Root entry {
        denial = require_role(["company_admin"]);
        if denial is not None { report denial; disengage; }
        company: Company | None = None;
        for candidate in shared_companies() { if jid(candidate) == self.company_id { company = candidate; } }
        if company is None { report make_error("COMPANY_NOT_FOUND", "Company was not found."); disengage; }
        company_node = company as Company;
        actor = [root -->][?:User][0];
        member_of_company = False;
        for owned in [actor ->:UserHasCompany:->] { if jid(owned) == self.company_id { member_of_company = True; } }
        if not member_of_company { report make_error("FORBIDDEN", "You can manage only your own company."); disengage; }
        for agent in [root -->][?:AgentProfile] {
            if jid(agent) == self.agent_id {
                duplicate = False;
                for linked in [company_node ->:CompanyEmploys:->] { if jid(linked) == self.agent_id { duplicate = True; } }
                if not duplicate { company_node +>:CompanyEmploys:+> agent; }
                report {"ok": True, "company_id": self.company_id, "agent_id": self.agent_id};
                disengage;
            }
        }
        report make_error("AGENT_NOT_FOUND", "Agent was not found.");
    }
}

walker:pub create_job {
    has company_id: str;
    has title: str;
    has available_spots: int;
    has salary_min: float;
    has salary_max: float;
    has deadline: str;
    has description: str = "";
    has category: str = "";
    has role: str = "";
    has currency: str = "USD";
    has salary_period: str = "year";
    has location_type: str = "onsite";
    has city: str = "";
    has employment_type: str = "full-time";
    has experience_level: str = "";
    has must_have_skills: list[str] = [];
    has nice_to_have_skills: list[str] = [];

    can create with Root entry {
        denial = require_role(["company_admin"]);
        if denial is not None { report denial; disengage; }
        if self.salary_min > self.salary_max { report make_error("INVALID_SALARY", "Minimum salary must not exceed maximum salary.", "salary"); disengage; }
        if self.available_spots <= 0 { report make_error("INVALID_SPOTS", "Available spots must be greater than zero.", "available_spots"); disengage; }
        if len(self.title.strip()) == 0 { report make_error("INVALID_TITLE", "Job title is required.", "title"); disengage; }
        if len(self.must_have_skills) == 0 and len(self.nice_to_have_skills) == 0 { report make_error("INVALID_SKILLS", "Provide at least one must-have or nice-to-have skill.", "must_have_skills"); disengage; }
        try { deadline_dt = datetime.fromisoformat(self.deadline); } except ValueError { report make_error("INVALID_DEADLINE", "Deadline must be an ISO 8601 datetime.", "deadline"); disengage; }
        now = datetime.now(deadline_dt.tzinfo);
        if deadline_dt <= now { report make_error("INVALID_DEADLINE", "Deadline must be in the future.", "deadline"); disengage; }
        company: Company | None = None;
        for candidate in shared_companies() { if jid(candidate) == self.company_id { company = candidate; } }
        if company is None { report make_error("COMPANY_NOT_FOUND", "Company was not found."); disengage; }
        company_node = company as Company;
        if not company_node.verified { report make_error("COMPANY_UNVERIFIED", "Only verified companies may post jobs."); disengage; }
        actor = [root -->][?:User][0];
        owns_company = False;
        for owned in [actor ->:UserHasCompany:->] { if jid(owned) == self.company_id { owns_company = True; } }
        if not owns_company { report make_error("FORBIDDEN", "You can post jobs only for your company."); disengage; }
        directory = shared_directory();
        job = directory ++> Job(title=self.title, description=self.description, category=self.category, role=self.role, available_spots=self.available_spots, salary={"min": self.salary_min, "max": self.salary_max, "currency": self.currency, "period": self.salary_period}, working_location={"type": self.location_type, "city": self.city}, employment_type=self.employment_type, experience_level=self.experience_level, must_have_skills=self.must_have_skills, nice_to_have_skills=self.nice_to_have_skills, required_skills=self.must_have_skills + self.nice_to_have_skills, deadline=self.deadline, status="open");
        _ = publish_job(job);
        company_node +>:CompanyPosts:+> job;
        _ = log_status_change(actor.id, "Job", jid(job), "draft", "open", "Job posted");
        _ = notify_job_followers(self.company_id, self.title);
        report job;
    }
}

walker:pub assign_agent_to_job {
    has job_id: str;
    has agent_id: str;

    can assign with Root entry {
        denial = require_role(["company_admin"]);
        if denial is not None { report denial; disengage; }
        job: Job | None = None;
        for candidate in shared_jobs() { if jid(candidate) == self.job_id { job = candidate; } }
        if job is None { report make_error("JOB_NOT_FOUND", "Job was not found."); disengage; }
        state = check_job_open(jid(job));
        if state is not None { report state; disengage; }
        companies = shared_companies();
        owner_found = False;
        for company in companies {
            posted = False;
            for posted_job in [company ->:CompanyPosts:->] { if jid(posted_job) == self.job_id { posted = True; } }
            if posted {
                actor = [root -->][?:User][0];
                for owned in [actor ->:UserHasCompany:->] { if jid(owned) == jid(company) { owner_found = True; } }
            }
        }
        if not owner_found { report make_error("FORBIDDEN", "You can assign agents only to your company's jobs."); disengage; }
        agent: AgentProfile | None = None;
        for candidate in [root -->][?:AgentProfile] { if jid(candidate) == self.agent_id { agent = candidate; } }
        if agent is None { report make_error("AGENT_NOT_FOUND", "Agent was not found."); disengage; }
        belongs = False;
        for company in companies {
            posted = False;
            for posted_job in [company ->:CompanyPosts:->] { if jid(posted_job) == self.job_id { posted = True; } }
            if posted { for member in [company ->:CompanyEmploys:->] { if jid(member) == self.agent_id { belongs = True; } } }
        }
        if not belongs { report make_error("AGENT_COMPANY_MISMATCH", "Agent must belong to the job's company."); disengage; }
        active_count = 0;
        for assigned_job in [agent <-:JobAssignedTo:<-] { if assigned_job.status == "open" { active_count += 1; } }
        agent_node = agent as AgentProfile;
        job_node = job as Job;
        if active_count >= agent_node.max_active_jobs { report make_error("MAX_ACTIVE_JOBS", "Agent has reached their active job limit."); disengage; }
        already_assigned = False;
        for assigned in [job_node ->:JobAssignedTo:->] { if jid(assigned) == self.agent_id { already_assigned = True; } }
        if not already_assigned { job_node +>:JobAssignedTo:+> agent_node; }
        report {"ok": True, "job_id": self.job_id, "agent_id": self.agent_id};
    }
}

walker:pub close_job {
    has job_id: str;
    has reason: str = "Closed by company administrator";

    can close with Root entry {
        denial = require_role(["company_admin"]);
        if denial is not None { report denial; disengage; }
        actor = [root -->][?:User][0];
        for company in shared_companies() {
            for job in [company ->:CompanyPosts:->] {
                if jid(job) == self.job_id {
                    owns = False;
                    for owned in [actor ->:UserHasCompany:->] { if jid(owned) == jid(company) { owns = True; } }
                    if not owns { report make_error("FORBIDDEN", "You can close only your company's jobs."); disengage; }
                    if job.status != "closed" {
                        old_status = job.status;
                        job.status = "closed";
                        _ = log_status_change(actor.id, "Job", self.job_id, old_status, "closed", self.reason);
                    }
                    report job;
                    disengage;
                }
            }
        }
        report make_error("JOB_NOT_FOUND", "Job was not found.");
    }
}

def:pub check_job_open(job_id: str) -> AppError | None {
    denial = require_role(["applicant", "agent", "company_admin", "admin", "system"]);
    if denial is not None { return denial; }
    for job in shared_jobs() {
        if jid(job) == job_id {
            if job.status != "open" { return make_error("JOB_CLOSED", "This job is not open."); }
            try { deadline_dt = datetime.fromisoformat(job.deadline); } except ValueError { return make_error("INVALID_DEADLINE", "Job deadline is invalid.", "deadline"); }
            now = datetime.now(deadline_dt.tzinfo);
            if job.available_spots <= 0 or deadline_dt <= now {
                old_status = job.status;
                job.status = "closed";
                users = [root -->][?:User];
                actor_id = users[0].id if len(users) > 0 else "system";
                _ = log_status_change(actor_id, "Job", job_id, old_status, "closed", "Automatic close: no spots or deadline passed");
                return make_error("JOB_CLOSED", "This job has closed.");
            }
            return None;
        }
    }
    return make_error("JOB_NOT_FOUND", "Job was not found.");
}

walker:pub auto_close_jobs {
    can close_expired with Root entry {
        denial = require_role(["admin", "system"]);
        if denial is not None { report denial; disengage; }
        closed: list[str] = [];
        for job in shared_jobs() {
            if job.status == "open" {
                try { deadline_dt = datetime.fromisoformat(job.deadline); } except ValueError { skip; }
                now = datetime.now(deadline_dt.tzinfo);
                if job.available_spots <= 0 or deadline_dt <= now {
                    old_status = job.status;
                    job.status = "closed";
                    actor = [root -->][?:User][0];
                    _ = log_status_change(actor.id, "Job", jid(job), old_status, "closed", "Automatic close: no spots or deadline passed");
                    closed.append(jid(job));
                }
            }
        }
        report {"ok": True, "closed_job_ids": closed};
    }
}

walker:pub search_jobs {
    has keyword: str = "";
    has category: str = "";
    has location: str = "";
    has salary_min: float = 0.0;
    has salary_max: float = 0.0;
    has employment_type: str = "";
    has page: int = 1;
    has page_size: int = 20;

    can search with Root entry {
        denial = require_role(["applicant"]);
        if denial is not None { report denial; disengage; }
        if self.page < 1 or self.page_size < 1 or self.page_size > 100 { report make_error("INVALID_PAGINATION", "Page must be positive and page size must be between 1 and 100."); disengage; }
        found: list[Job] = [];
        for job in shared_jobs() {
            if job.status == "open" {
                state = check_job_open(jid(job));
                if state is None {
                    matches = True;
                    if len(self.keyword) > 0 and self.keyword.lower() not in (job.title + " " + job.description + " " + job.role).lower() { matches = False; }
                    if len(self.category) > 0 and job.category.lower() != self.category.lower() { matches = False; }
                    city = job.working_location["city"] as str;
                    if len(self.location) > 0 and city.lower() not in self.location.lower() and self.location.lower() not in city.lower() { matches = False; }
                    low = job.salary["min"] as float;
                    high = job.salary["max"] as float;
                    if self.salary_min > 0.0 and high < self.salary_min { matches = False; }
                    if self.salary_max > 0.0 and low > self.salary_max { matches = False; }
                    if len(self.employment_type) > 0 and job.employment_type.lower() != self.employment_type.lower() { matches = False; }
                    if matches { found.append(job); }
                }
            }
        }
        start = (self.page - 1) * self.page_size;
        rows: list[Job] = [];
        index = 0;
        for job in found {
            if index >= start and index < start + self.page_size { rows.append(job); }
            index += 1;
        }
        report {"items": rows, "total": len(found), "page": self.page, "page_size": self.page_size};
    }
}

walker:pub get_job_by_id {
    has job_id: str;
    can find with Root entry {
        denial = require_role(["applicant", "agent", "company_admin"]);
        if denial is not None { report denial; disengage; }
        for job in shared_jobs() { if jid(job) == self.job_id { report job; disengage; } }
        report make_error("JOB_NOT_FOUND", "Job was not found.");
    }
}

walker:pub get_job_by_slug {
    has slug: str;
    can find with Root entry {
        denial = require_role(["applicant", "agent", "company_admin"]);
        if denial is not None { report denial; disengage; }
        for job in shared_jobs() {
            candidate = job.title.lower().replace(" ", "-");
            if candidate == self.slug or jid(job) == self.slug { report {"id": jid(job), "title": job.title, "description": job.description, "category": job.category, "role": job.role, "available_spots": job.available_spots, "salary": job.salary, "working_location": job.working_location, "employment_type": job.employment_type, "experience_level": job.experience_level, "required_skills": job.required_skills, "must_have_skills": job.must_have_skills, "nice_to_have_skills": job.nice_to_have_skills, "min_experience_years": job.min_experience_years, "education_requirement": job.education_requirement, "threshold": job.threshold, "deadline": job.deadline, "status": job.status}; disengage; }
        }
        report make_error("JOB_NOT_FOUND", "Job was not found.");
    }
}

walker:pub follow_company {
    has company_id: str;
    can follow with Root entry {
        denial = require_role(["applicant"]);
        if denial is not None { report denial; disengage; }
        profiles = [root -->][?:ApplicantProfile];
        if len(profiles) == 0 { report make_error("PROFILE_NOT_FOUND", "Applicant profile was not found."); disengage; }
        company: Company | None = None;
        for candidate in shared_companies() { if jid(candidate) == self.company_id { company = candidate; } }
        if company is None { report make_error("COMPANY_NOT_FOUND", "Company was not found."); disengage; }
        company_node = company as Company;
        already = False;
        for followed in [profiles[0] ->:ApplicantFollows:->] { if jid(followed) == self.company_id { already = True; } }
        if not already { profiles[0] +>:ApplicantFollows:+> company_node; }
        report {"ok": True, "company_id": self.company_id, "following": True};
    }
}

walker:pub unfollow_company {
    has company_id: str;
    can unfollow with Root entry {
        denial = require_role(["applicant"]);
        if denial is not None { report denial; disengage; }
        profiles = [root -->][?:ApplicantProfile];
        if len(profiles) == 0 { report make_error("PROFILE_NOT_FOUND", "Applicant profile was not found."); disengage; }
        company: Company | None = None;
        for candidate in shared_companies() { if jid(candidate) == self.company_id { company = candidate; } }
        if company is None { report make_error("COMPANY_NOT_FOUND", "Company was not found."); disengage; }
        edges = [edge profiles[0] ->:ApplicantFollows:-> company];
        for link in edges { del link; }
        report {"ok": True, "company_id": self.company_id, "following": False};
    }
}
