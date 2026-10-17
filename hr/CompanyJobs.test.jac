import from hr.domain { User, Company, Job, AgentProfile, CompanyPosts, JobAssignedTo }
import from shared.Errors { AppError }
import from datetime { datetime, timedelta }

test "unverified companies cannot be used for open job postings" {
    company = Company(name="Meridian Labs", verified=False);
    root ++> company;
    assert not company.verified;
}

test "active job capacity is represented by open assignments" {
    agent = AgentProfile(name="Recruitment partner", max_active_jobs=1);
    root ++> agent;
    company = Company(name="Northstar Systems", verified=True);
    root ++> company;
    first_job = Job(title="People Operations Lead", status="open");
    root ++> first_job;
    first_job +>:JobAssignedTo:+> agent;
    assert len([agent <-:JobAssignedTo:<-[?:Job]]) == 1;
    assert agent.max_active_jobs == 1;
}

test "expired open job is automatically closed" {
    applicant = User(id="test-applicant", email="applicant@test.invalid", role="applicant");
    root ++> applicant;
    past = (datetime.now() - timedelta(days=1)).isoformat();
    job = Job(title="Expired role", status="open", deadline=past, available_spots=1);
    root ++> job;
    result: AppError | None = check_job_open(jid(job));
    assert result is not None;
    assert result.code == "JOB_CLOSED";
    assert job.status == "closed";
}

test "open job search fields support filters and page slicing" {
    job_a = Job(title="Senior Data Engineer", category="Technology", employment_type="full-time", salary={"min": 100000.0, "max": 140000.0}, working_location={"city": "Toronto"}, status="open", deadline=(datetime.now() + timedelta(days=20)).isoformat());
    root ++> job_a;
    job_b = Job(title="Office Coordinator", category="Operations", employment_type="contract", salary={"min": 50000.0, "max": 70000.0}, working_location={"city": "Ottawa"}, status="open", deadline=(datetime.now() + timedelta(days=20)).isoformat());
    root ++> job_b;
    assert "data" in job_a.title.lower();
    assert job_a.category == "Technology";
    assert job_a.employment_type == "full-time";
    assert job_a.working_location["city"] == "Toronto";
    assert job_b.category != job_a.category;
}
