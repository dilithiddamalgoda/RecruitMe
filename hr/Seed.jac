import from datetime { datetime, timedelta }
import from hr.domain { User, ApplicantProfile, AgentProfile, Company, Job, Application, Interview, AgentAvailability, UserHasApplicantProfile, UserHasAgentProfile, UserHasCompany, CompanyEmploys, CompanyPosts, JobAssignedTo, ApplicantSubmitted, ApplicationFor, ApplicationScheduledAs, InterviewConductedBy, AgentHasSlot }
import from hr.Authorization { require_role }
import from hr.RecruitmentIntegration { shared_directory, publish_company, publish_job }
import from shared.Errors { AppError, make_error }

walker:pub seed_demo_data {
    can seed with Root entry {
        denial = require_role(["admin", "system"]);
        if denial is not None { report denial; disengage; }
        users = [root -->][?:User];
        if len(users) == 0 { report make_error("FORBIDDEN", "Authenticated administrator profile is required."); disengage; }
        seeded_before = False;
        for existing in [root -->][?:User] { if existing.id == "demo-admin" { seeded_before = True; } }
        if seeded_before { report {"ok": True, "seeded": False, "message": "Demo data already exists."}; disengage; }
        _ = root ++> User(id="demo-admin", email="admin@havenhire.test", role="admin");
        company_admin1 = User(id="demo-company-1", email="talent@northstar.test", role="company_admin");
        root ++> company_admin1;
        company_admin2 = User(id="demo-company-2", email="people@harbor.test", role="company_admin");
        root ++> company_admin2;
        directory = shared_directory();
        company1 = Company(name="Northstar Systems", description="Product engineering and data teams", address="Toronto", verified=True, status="verified");
        directory ++> company1;
        company2 = Company(name="Harbor Health", description="Community health technology", address="Vancouver", verified=False, status="pending");
        directory ++> company2;
        _ = publish_company(company1);
        _ = publish_company(company2);
        company_admin1 +>:UserHasCompany:+> company1;
        company_admin2 +>:UserHasCompany:+> company2;
        agents: list[AgentProfile] = [];
        for (index, name) in enumerate(["Ari Patel", "Morgan Chen", "Riley Brooks"]) {
            email = "agent" + str(index + 1) + "@havenhire.test";
            user = User(id="demo-agent-" + str(index + 1), email=email, role="agent");
            root ++> user;
            agent = AgentProfile(name=name, email=email, specialization="Technology", max_active_jobs=4);
            root ++> agent;
            user +>:UserHasAgentProfile:+> agent;
            company1 +>:CompanyEmploys:+> agent;
            agents.append(agent);
        }
        profiles: list[ApplicantProfile] = [];
        for (index, name) in enumerate(["Sam Rivera", "Taylor Quinn", "Alex Kim", "Jamie Ellis", "Casey Morgan"]) {
            email = "applicant" + str(index + 1) + "@havenhire.test";
            user = User(id="demo-applicant-" + str(index + 1), email=email, role="applicant");
            root ++> user;
            status = "confirmed" if index != 4 else "pending";
            profile = ApplicantProfile(name=name, email=email, location="Toronto", summary="Experienced recruiter and talent partner", skills=["Python", "Recruiting", "Data analysis"], education=[{"qualification": "Bachelor degree", "institution": "University of Toronto", "year": 2021}], experience=[{"job_title": "Talent Partner", "company": "Previous employer", "duration": "3 years", "responsibilities": ["Hiring", "Candidate sourcing"]}], parse_status=status);
            root ++> profile;
            user +>:UserHasApplicantProfile:+> profile;
            profiles.append(profile);
        }
        jobs: list[Job] = [];
        for (index, title) in enumerate(["Senior Data Engineer", "People Operations Lead", "Technical Recruiter", "Recruiting Coordinator", "Analytics Engineer", "Campus Talent Partner"]) {
            state = "open" if index < 3 else ("closed" if index == 3 else "open");
            deadline = (datetime.now() + timedelta(days=30)).isoformat();
            if index == 5 { deadline = (datetime.now() - timedelta(days=1)).isoformat(); }
            spots = 2 if index < 2 else (1 if index == 2 else 0);
            job = Job(title=title, description="Build excellent teams and deliver thoughtful hiring outcomes.", category="Technology" if index % 2 == 0 else "People", role=title, available_spots=spots, required_skills=["Python", "Recruiting"], must_have_skills=["Python"], nice_to_have_skills=["Data analysis"], min_experience_years=2.0, education_requirement="Bachelor degree", threshold=55.0, deadline=deadline, status=state);
            directory ++> job;
            _ = publish_job(job);
            if index < 4 { company1 +>:CompanyPosts:+> job; } else { company2 +>:CompanyPosts:+> job; }
            if index < 3 { job +>:JobAssignedTo:+> agents[index]; }
            jobs.append(job);
        }
        for index in [0, 1, 2, 3] {
            profile = profiles[index];
            job = jobs[index % 3];
            app = Application(status="shortlisted", match_score=76.5, matched_skills=["Python"], missing_skills=[], profile_snapshot={"skills": profile.skills, "education": profile.education, "experience": profile.experience, "certifications": profile.certifications}, ai_verdict={"requirements": [{"requirement": "Python", "type": "must_have", "verdict": "met", "evidence": "Listed in skills"}], "experience_years_estimate": 3.0, "summary": "Relevant experience; suitability is advisory."}, ai_status="done", applied_at=datetime.now().isoformat(), evaluated_at=datetime.now().isoformat());
            root ++> app;
            profile +>:ApplicantSubmitted:+> app;
            app +>:ApplicationFor:+> job;
        }
        for agent in agents {
            for index in [0, 1] {
                start = datetime.now() + timedelta(days=index + 1);
                end = start + timedelta(hours=1);
                slot = AgentAvailability(start=start.isoformat(), end=end.isoformat(), timezone="UTC", is_booked=False);
                agent ++> slot;
            }
        }
        report {"ok": True, "seeded": True, "companies": 2, "agents": 3, "applicants": 5, "jobs": 6, "applications": 4};
    }
}
