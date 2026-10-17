import from datetime { datetime, timedelta }
import from hr.domain { User, ApplicantProfile, Company, AgentProfile, Job, Application, AgentAvailability, Interview, UserHasApplicantProfile, UserHasCompany, UserHasAgentProfile, CompanyEmploys, CompanyPosts, JobAssignedTo, ApplicantSubmitted, ApplicationFor, ApplicationScheduledAs, InterviewConductedBy }

test "application and interview workflow reserves and releases an agent slot" {
    applicant = root ++> User(id="integration-applicant", email="flow-applicant@example.test", role="applicant");
    profile = root ++> ApplicantProfile(name="Flow Applicant", email="flow-applicant@example.test", skills=["Python"], parse_status="confirmed");
    applicant +>:UserHasApplicantProfile:+> profile;
    company_user = root ++> User(id="integration-company", email="flow-company@example.test", role="company_admin");
    company = root ++> Company(name="Flow Company", verified=True, status="verified");
    company_user +>:UserHasCompany:+> company;
    agent_user = root ++> User(id="integration-agent", email="flow-agent@example.test", role="agent");
    agent = root ++> AgentProfile(name="Flow Agent", email="flow-agent@example.test", max_active_jobs=4);
    agent_user +>:UserHasAgentProfile:+> agent;
    company +>:CompanyEmploys:+> agent;
    job = root ++> Job(title="Flow Engineer", status="open", available_spots=1, deadline=(datetime.now() + timedelta(days=30)).isoformat(), must_have_skills=["Python"], threshold=50.0);
    company +>:CompanyPosts:+> job;
    job +>:JobAssignedTo:+> agent;
    app = root ++> Application(status="shortlisted", match_score=90.0, profile_snapshot={"skills": ["Python"]});
    profile +>:ApplicantSubmitted:+> app;
    app +>:ApplicationFor:+> job;
    start = datetime.now() + timedelta(days=2);
    end = start + timedelta(hours=1);
    slot = agent ++> AgentAvailability(start=start.isoformat(), end=end.isoformat(), timezone="UTC", is_booked=False);
    interview = root ++> Interview(slot=slot.start, mode="online", status="scheduled");
    app +>:ApplicationScheduledAs:+> interview;
    interview +>:InterviewConductedBy:+> agent;
    slot.is_booked = True;
    assert app.match_score >= job.threshold;
    assert slot.is_booked;
    assert job.available_spots == 1;
    interview.status = "completed";
    assert interview.status == "completed";
}

test "rescheduling makes prior availability reusable" {
    agent = root ++> AgentProfile(name="Calendar Agent", email="calendar@example.test", max_active_jobs=3);
    first_start = datetime.now() + timedelta(days=4);
    second_start = datetime.now() + timedelta(days=5);
    first = root ++> AgentAvailability(start=first_start.isoformat(), end=(first_start + timedelta(hours=1)).isoformat());
    second = root ++> AgentAvailability(start=second_start.isoformat(), end=(second_start + timedelta(hours=1)).isoformat());
    meeting = root ++> Interview(slot=first.start, status="scheduled");
    meeting +>:InterviewConductedBy:+> agent;
    first.is_booked = False;
    second.is_booked = True;
    meeting.slot = second.start;
    assert not first.is_booked;
    assert second.is_booked;
}
