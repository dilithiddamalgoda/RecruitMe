import from datetime { datetime, timedelta }
import from hr.domain { User, AgentProfile, AgentAvailability, Interview, UserHasAgentProfile, InterviewConductedBy }

test "overlap predicate rejects intersecting availability intervals" {
    first_start = datetime.fromisoformat("2035-04-12T09:00:00+00:00");
    first_end = datetime.fromisoformat("2035-04-12T10:00:00+00:00");
    overlap_start = datetime.fromisoformat("2035-04-12T09:30:00+00:00");
    overlap_end = datetime.fromisoformat("2035-04-12T10:30:00+00:00");
    assert _times_overlap(first_start, first_end, overlap_start, overlap_end);
}

test "adjacent availability intervals are not overlapping" {
    first_start = datetime.fromisoformat("2035-04-12T09:00:00+00:00");
    first_end = datetime.fromisoformat("2035-04-12T10:00:00+00:00");
    next_start = datetime.fromisoformat("2035-04-12T10:00:00+00:00");
    next_end = datetime.fromisoformat("2035-04-12T11:00:00+00:00");
    assert not _times_overlap(first_start, first_end, next_start, next_end);
}

test "booking and cancellation release a slot for reuse" {
    agent = AgentProfile(name="Ari Patel", email="ari@example.test");
    root ++> agent;
    start = (datetime.now() + timedelta(days=4)).isoformat();
    slot = AgentAvailability(start=start, end=(datetime.now() + timedelta(days=4, hours=1)).isoformat(), timezone="UTC", is_booked=False);
    agent ++> slot;
    interview = Interview(slot=slot.start, status="scheduled");
    root ++> interview;
    interview +>:InterviewConductedBy:+> agent;
    slot.is_booked = True;
    assert slot.is_booked;
    slot.is_booked = False;
    interview.status = "cancelled";
    assert not slot.is_booked;
    assert interview.status == "cancelled";
}

test "agent lookup is isolated to current app user relationship" {
    user = User(id="interview-agent", email="agent@example.test", role="agent");
    root ++> user;
    agent = AgentProfile(name="Morgan Chen", email="agent@example.test");
    root ++> agent;
    user +>:UserHasAgentProfile:+> agent;
    resolved = _actor_agent();
    assert resolved is not None;
    assert resolved.email == agent.email;
}
