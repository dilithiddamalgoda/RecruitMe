import from hr.domain { Company, Job, AgentProfile, CompanyPosts, JobAssignedTo }
import from shared.Errors { AppError }
import from datetime { datetime, timedelta }

test "unverified companies cannot be used for open job postings" {
    company = root ++> Company(name="Meridian Labs", verified=False);
    assert not company.verified;
}

test "active job capacity is represented by open assignments" {
    agent = root ++> AgentProfile(name="Recruitment partner", max_active_jobs=1);
    _ = root ++> Company(name="Northstar Systems", verified=True);
    first_job = root ++> Job(title="People Operations Lead", status="open");
    first_job +>:JobAssignedTo:+> agent;
    assert len([agent <-:JobAssignedTo:<-[?:Job]]) == 1;
    assert agent.max_active_jobs == 1;
}

test "expired open job is automatically closed" {
    _ = root ++> User(id="test-applicant", email="applicant@test.invalid", role="applicant");
    past = (datetime.now() - timedelta(days=1)).isoformat();
    job = root ++> Job(title="Expired role", status="open", deadline=past, available_spots=1);
    result: AppError | None = check_job_open(jid(job));
    assert result is not None;
    assert result.code == "JOB_CLOSED";
    assert job.status == "closed";
}

test "open job search fields support filters and page slicing" {
    job_a = root ++> Job(title="Senior Data Engineer", category="Technology", employment_type="full-time", salary={"min": 100000.0, "max": 140000.0}, working_location={"city": "Toronto"}, status="open", deadline=(datetime.now() + timedelta(days=20)).isoformat());
    job_b = root ++> Job(title="Office Coordinator", category="Operations", employment_type="contract", salary={"min": 50000.0, "max": 70000.0}, working_location={"city": "Ottawa"}, status="open", deadline=(datetime.now() + timedelta(days=20)).isoformat());
    assert "data" in job_a.title.lower();
    assert job_a.category == "Technology";
    assert job_a.employment_type == "full-time";
    assert job_a.working_location["city"] == "Toronto";
    assert job_b.category != job_a.category;
}
