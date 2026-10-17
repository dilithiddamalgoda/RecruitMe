import from datetime { datetime }
import from hr.domain { User, ApplicantProfile, AgentProfile, Company, Job, Application, Interview, AgentAvailability, ApplicationFor, ApplicantSubmitted, ApplicationScheduledAs, InterviewConductedBy, AgentHasSlot, JobAssignedTo, UserHasAgentProfile, UserHasCompany, CompanyPosts }
import from hr.Authorization { require_role }
import from hr.Audit { log_status_change, record_audit }
import from hr.Notifications { notify }
import from shared.Errors { AppError, make_error }

def _parse_time(value: str) -> datetime | None {
    try { return datetime.fromisoformat(value); } except ValueError { return None; }
}

def _times_overlap(a_start: datetime, a_end: datetime, b_start: datetime, b_end: datetime) -> bool {
    return a_start < b_end and b_start < a_end;
}

def _actor_agent() -> AgentProfile | None {
    users = [root -->][?:User];
    if len(users) == 0 { return None; }
    for agent in [root -->][?:AgentProfile] {
        for linked in [users[0] ->:UserHasAgentProfile:->] { if jid(linked) == jid(agent) { return agent; } }
    }
    return None;
}

walker:pub add_availability {
    has start: str;
    has end: str;
    has timezone: str = "UTC";

    can add_slot with Root entry {
        denial = require_role(["agent"]);
        if denial is not None { report denial; disengage; }
        start_dt = _parse_time(self.start);
        end_dt = _parse_time(self.end);
        if start_dt is None or end_dt is None or end_dt <= start_dt { report make_error("INVALID_SLOT", "Use a valid start and end time with end after start."); disengage; }
        agent = _actor_agent();
        if agent is None { report make_error("PROFILE_NOT_FOUND", "Agent profile was not found."); disengage; }
        for slot in [agent ->:AgentHasSlot:->] {
            existing_start = _parse_time(slot.start);
            existing_end = _parse_time(slot.end);
            if existing_start is not None and existing_end is not None and _times_overlap(start_dt, end_dt, existing_start, existing_end) { report make_error("SLOT_OVERLAP", "Availability slots cannot overlap."); disengage; }
        }
        created = agent ++> AgentAvailability(start=self.start, end=self.end, timezone=self.timezone, is_booked=False);
        report created;
    }
}

walker:pub get_my_availability {
    can list_slots with Root entry {
        denial = require_role(["agent"]);
        if denial is not None { report denial; disengage; }
        agent = _actor_agent();
        if agent is None { report make_error("PROFILE_NOT_FOUND", "Agent profile was not found."); disengage; }
        report [agent ->:AgentHasSlot:->];
    }
}

walker:pub schedule_interview {
    has application_id: str;
    has slot_id: str;
    has mode: str = "online";
    has override_reason: str = "";

    can schedule with Root entry {
        denial = require_role(["agent", "company_admin"]);
        if denial is not None { report denial; disengage; }
        if self.mode not in ["online", "onsite"] { report make_error("INVALID_MODE", "Interview mode must be online or onsite."); disengage; }
        current_app: Application | None = None;
        for app in [root -->][?:Application] { if jid(app) == self.application_id { current_app = app; } }
        if current_app is None { report make_error("APPLICATION_NOT_FOUND", "Application was not found."); disengage; }
        app_node = current_app as Application;
        current_job: Job | None = None;
        for job in [root -->][?:Job] { for app_job in [app_node ->:ApplicationFor:->] { if jid(job) == jid(app_job) { current_job = job; } } }
        if current_job is None { report make_error("JOB_NOT_FOUND", "Application job was not found."); disengage; }
        job_node = current_job as Job;
        job_owner = False;
        user = [root -->][?:User][0];
        if user.role == "company_admin" {
            for company in [root -->][?:Company] {
                owns = False;
                for linked in [user ->:UserHasCompany:->] { if jid(linked) == jid(company) { owns = True; } }
                if owns { for posted in [company ->:CompanyPosts:->] { if jid(posted) == jid(job_node) { job_owner = True; } } }
            }
        }
        actor_agent = _actor_agent();
        assigned = False;
        if actor_agent is not None { for assigned_agent in [job_node ->:JobAssignedTo:->] { if jid(assigned_agent) == jid(actor_agent as AgentProfile) { assigned = True; } } }
        if user.role == "company_admin" and not job_owner { report make_error("FORBIDDEN", "Company can schedule interviews only for its own jobs."); disengage; }
        if user.role == "agent" and not assigned { report make_error("FORBIDDEN", "Agent must be assigned to the job."); disengage; }
        if app_node.match_score < job_node.threshold {
            if self.override_reason.strip() == "" { report make_error("THRESHOLD_REQUIRED", "A reasoned agent override is required below the suitability threshold."); disengage; }
            if user.role != "agent" { report make_error("FORBIDDEN", "Only the assigned agent can override the suitability threshold."); disengage; }
            _ = record_audit(user.id, "SuitabilityOverride", self.application_id, self.override_reason);
        }
        slot: AgentAvailability | None = None;
        for candidate in [root -->][?:AgentAvailability] { if jid(candidate) == self.slot_id { slot = candidate; } }
        if slot is None { report make_error("SLOT_NOT_FOUND", "Availability slot was not found."); disengage; }
        slot_node = slot as AgentAvailability;
        if slot_node.is_booked { report make_error("SLOT_BOOKED", "This availability slot is already booked."); disengage; }
        slot_start = _parse_time(slot_node.start);
        slot_end = _parse_time(slot_node.end);
        if slot_start is None or slot_end is None { report make_error("INVALID_SLOT", "Availability slot has invalid timestamps."); disengage; }
        if datetime.now(slot_start.tzinfo) >= slot_start { report make_error("SLOT_PAST", "Choose a future availability slot."); disengage; }
        for booked in [root -->][?:Interview] {
            if booked.status == "scheduled" {
                booked_start = _parse_time(booked.slot);
                if booked_start is not None and booked_start == slot_start { report make_error("SLOT_BOOKED", "An interview already occupies this slot."); disengage; }
            }
        }
        old_status = app_node.status;
        app_node.status = "interview_scheduled";
        slot_node.is_booked = True;
        interviewer = actor_agent;
        if interviewer is None { report make_error("PROFILE_NOT_FOUND", "Agent profile was not found."); disengage; }
        interview = Interview(slot=slot_node.start, mode=self.mode, status="scheduled");
        app_node +>:ApplicationScheduledAs:+> interview;
        interview +>:InterviewConductedBy:+> (interviewer as AgentProfile);
        _ = log_status_change(user.id, "Application", self.application_id, old_status, "interview_scheduled", "Interview scheduled");
        for applicant in [root -->][?:ApplicantProfile] {
            for linked_app in [applicant ->:ApplicantSubmitted:->] { if jid(linked_app) == self.application_id {
                for account in [root -->][?:User] { if account.email == applicant.email { _ = notify(account, "interview_scheduled", "An interview has been scheduled for " + job_node.title + " at " + slot_node.start); } }
            } }
        }
        report interview;
    }
}

walker:pub reschedule_interview {
    has interview_id: str;
    has slot_id: str;
    has reason: str = "Interview rescheduled";

    can move with Root entry {
        denial = require_role(["agent"]);
        if denial is not None { report denial; disengage; }
        interview: Interview | None = None;
        for candidate in [root -->][?:Interview] { if jid(candidate) == self.interview_id { interview = candidate; } }
        if interview is None { report make_error("INTERVIEW_NOT_FOUND", "Interview was not found."); disengage; }
        interview_node = interview as Interview;
        if interview_node.status != "scheduled" { report make_error("INVALID_TRANSITION", "Only scheduled interviews can be rescheduled."); disengage; }
        actor_agent = _actor_agent();
        if actor_agent is None { report make_error("PROFILE_NOT_FOUND", "Agent profile was not found."); disengage; }
        agent_node = actor_agent as AgentProfile;
        allowed = False;
        for conductor in [interview_node ->:InterviewConductedBy:->] { if jid(conductor) == jid(agent_node) { allowed = True; } }
        if not allowed { report make_error("FORBIDDEN", "Only the conducting agent can reschedule this interview."); disengage; }
        new_slot: AgentAvailability | None = None;
        for candidate in [agent_node ->:AgentHasSlot:->] { if jid(candidate) == self.slot_id { new_slot = candidate; } }
        if new_slot is None { report make_error("SLOT_NOT_FOUND", "Availability slot was not found."); disengage; }
        new_slot_node = new_slot as AgentAvailability;
        if new_slot_node.is_booked { report make_error("SLOT_BOOKED", "This availability slot is already booked."); disengage; }
        start_dt = _parse_time(new_slot_node.start);
        if start_dt is None or datetime.now(start_dt.tzinfo) >= start_dt { report make_error("SLOT_PAST", "Choose a future availability slot."); disengage; }
        prior = interview_node.slot;
        for old_slot in [agent_node ->:AgentHasSlot:->] { if old_slot.start == prior { old_slot.is_booked = False; } }
        new_slot_node.is_booked = True;
        interview_node.slot = new_slot_node.start;
        _ = record_audit([root -->][?:User][0].id, "Interview", self.interview_id, self.reason);
        _ = _notify_interview_users(interview_node, "interview_rescheduled", "Your interview has been rescheduled to " + new_slot_node.start);
        report interview_node;
    }
}

walker:pub cancel_interview {
    has interview_id: str;
    has reason: str = "Interview cancelled";

    can cancel with Root entry {
        denial = require_role(["agent", "company_admin"]);
        if denial is not None { report denial; disengage; }
        interview: Interview | None = None;
        for candidate in [root -->][?:Interview] { if jid(candidate) == self.interview_id { interview = candidate; } }
        if interview is None { report make_error("INTERVIEW_NOT_FOUND", "Interview was not found."); disengage; }
        interview_node = interview as Interview;
        if interview_node.status != "scheduled" { report make_error("INVALID_TRANSITION", "Only scheduled interviews can be cancelled."); disengage; }
        authorized = False;
        user = [root -->][?:User][0];
        for interviewer in [interview_node ->:InterviewConductedBy:->] {
            agent = _actor_agent();
            if agent is not None and jid(interviewer) == jid(agent as AgentProfile) { authorized = True; }
        }
        if user.role == "company_admin" { authorized = True; }
        if not authorized { report make_error("FORBIDDEN", "You cannot cancel this interview."); disengage; }
        prior = interview_node.slot;
        for slot in [root -->][?:AgentAvailability] { if slot.start == prior { slot.is_booked = False; } }
        interview_node.status = "cancelled";
        _ = record_audit(user.id, "Interview", self.interview_id, self.reason);
        _ = _notify_interview_users(interview_node, "interview_cancelled", "Your interview has been cancelled.");
        report interview_node;
    }
}

walker:pub complete_interview {
    has interview_id: str;
    has notes: str = "";

    can complete with Root entry {
        denial = require_role(["agent"]);
        if denial is not None { report denial; disengage; }
        interview: Interview | None = None;
        for candidate in [root -->][?:Interview] { if jid(candidate) == self.interview_id { interview = candidate; } }
        if interview is None { report make_error("INTERVIEW_NOT_FOUND", "Interview was not found."); disengage; }
        interview_node = interview as Interview;
        if interview_node.status != "scheduled" { report make_error("INVALID_TRANSITION", "Only scheduled interviews can be completed."); disengage; }
        agent = _actor_agent();
        if agent is None { report make_error("PROFILE_NOT_FOUND", "Agent profile was not found."); disengage; }
        authorized = False;
        for interviewer in [interview_node ->:InterviewConductedBy:->] { if jid(interviewer) == jid(agent as AgentProfile) { authorized = True; } }
        if not authorized { report make_error("FORBIDDEN", "Only the conducting agent can complete this interview."); disengage; }
        interview_node.status = "completed";
        interview_node.notes = self.notes;
        user = [root -->][?:User][0];
        _ = record_audit(user.id, "Interview", self.interview_id, "Interview completed");
        _ = _notify_interview_users(interview_node, "interview_completed", "Your interview has been completed.");
        report interview_node;
    }
}

def _notify_interview_users(interview: Interview, kind: str, message: str) -> int {
    sent = 0;
    applications = [root -->][?:Application];
    for app in applications {
        linked = False;
        for scheduled in [app ->:ApplicationScheduledAs:->] { if jid(scheduled) == jid(interview) { linked = True; } }
        if linked {
            for profile in [root -->][?:ApplicantProfile] {
                for owned_app in [profile ->:ApplicantSubmitted:->] { if jid(owned_app) == jid(app) { for account in [root -->][?:User] { if account.email == profile.email { _ = notify(account, kind, message); sent += 1; } } } }
            }
            for agent in [root -->][?:AgentProfile] {
                for conductor in [interview ->:InterviewConductedBy:->] { if jid(conductor) == jid(agent) { for account in [root -->][?:User] { if account.email == agent.email { _ = notify(account, kind, message); sent += 1; } } } }
            }
        }
    }
    return sent;
}
