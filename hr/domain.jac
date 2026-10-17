node SharedDirectory {
    has namespace: str = "recruitme-global";
}

node User {
    has id: str = "";
    has email: str = "";
    has credential_hash: str = "";
    has role: str = "applicant";
}


node ApplicantProfile {
    has name: str = "";
    has email: str = "";
    has phone: str = "";
    has location: str = "";
    has summary: str = "";
    has skills: list[str] = [];
    has education: list[dict] = [];
    has experience: list[dict] = [];
    has certifications: list[str] = [];
    has resume_file: str = "";
    has resume_hash: str = "";
    has source: str = "manual";
    has parse_status: str = "pending";
}

node AgentProfile {
    has name: str = "";
    has email: str = "";
    has phone: str = "";
    has location: str = "";
    has summary: str = "";
    has skills: list[str] = [];
    has specialization: str = "";
    has max_active_jobs: int = 0;
}

node Company {
    has name: str = "";
    has description: str = "";
    has address: str = "";
    has verified: bool = False;
    has status: str = "pending";
}

node Job {
    has title: str = "";
    has description: str = "";
    has category: str = "";
    has role: str = "";
    has available_spots: int = 0;
    has salary: dict = {};
    has working_location: dict = {};
    has employment_type: str = "";
    has experience_level: str = "";
    has required_skills: list[str] = [];
    has must_have_skills: list[str] = [];
    has nice_to_have_skills: list[str] = [];
    has min_experience_years: float = 0.0;
    has education_requirement: str = "";
    has threshold: float = 0.0;
    has deadline: str = "";
    has status: str = "draft";
}

node Application {
    has status: str = "applied";
    has match_score: float = 0.0;
    has matched_skills: list[str] = [];
    has missing_skills: list[str] = [];
    has profile_snapshot: dict = {};
    has ai_verdict: dict = {};
    has ai_status: str = "pending";
    has applied_at: str = "";
    has evaluated_at: str = "";
}

node AgentAvailability {
    has start: str = "";
    has end: str = "";
    has timezone: str = "UTC";
    has is_booked: bool = False;
}

node Interview {
    has slot: str = "";
    has mode: str = "online";
    has status: str = "scheduled";
    has notes: str = "";
}

node Notification {
    has type: str = "";
    has message: str = "";
    has read: bool = False;
}

node AIEvaluationLog {
    has application_id: str = "";
    has model: str = "";
    has input_hash: str = "";
    has output_json: dict = {};
    has latency_ms: int = 0;
    has created_at: str = "";
}

node AuditLog {
    has actor_id: str = "";
    has entity: str = "";
    has entity_id: str = "";
    has from_status: str = "";
    has to_status: str = "";
    has reason: str = "";
    has created_at: str = "";
}

edge DirectoryHasCompany: SharedDirectory --> Company {}
edge DirectoryHasJob: SharedDirectory --> Job {}
edge CompanyEmploys: Company --> AgentProfile {}
edge CompanyPosts: Company --> Job {}
edge JobAssignedTo: Job --> AgentProfile {}
edge ApplicantFollows: ApplicantProfile --> Company {}
edge ApplicantSubmitted: ApplicantProfile --> Application {}
edge ApplicationFor: Application --> Job {}
edge ApplicationScheduledAs: Application --> Interview {}
edge InterviewConductedBy: Interview --> AgentProfile {}
edge AgentHasSlot: AgentProfile --> AgentAvailability {}
edge UserHasApplicantProfile: User --> ApplicantProfile {}
edge UserHasAgentProfile: User --> AgentProfile {}
edge UserHasCompany: User --> Company {}
edge UserHasNotification: User --> Notification {}
edge UserHasAuditLog: User --> AuditLog {}
edge ApplicationHasEvaluationLog: Application --> AIEvaluationLog {}
