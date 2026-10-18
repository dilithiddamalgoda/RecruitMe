import os;
import from hr.domain { User, ApplicantProfile, AgentProfile, Company, UserHasApplicantProfile, UserHasAgentProfile, UserHasCompany }
import from hr.Authorization { current_app_user, require_role }
import from hr.Audit { record_audit }
import from hr.RecruitmentIntegration { publish_company, shared_companies }
import from shared.Errors { make_error }

walker:priv ensure_my_profile {
    has name: str = "";
    has role: str = "applicant";

    can initialize with Root entry {
        user: User | None = current_app_user();
        if user is None { report make_error("UNAUTHENTICATED", "Sign in before initializing your profile."); disengage; }
        resolved_role = user.role if user.role in ["admin", "system"] else role_value(self.role);
        user.role = resolved_role;
        found = False;
        if resolved_role == "applicant" {
            for profile in [root -->][?:ApplicantProfile] { if profile.email.lower() == user.email.lower() { found = True; } }
            if not found { user +>:UserHasApplicantProfile:+> ApplicantProfile(name=self.name, email=user.email, parse_status="pending"); }
        } elif resolved_role == "agent" {
            for profile in [root -->][?:AgentProfile] { if profile.email.lower() == user.email.lower() { found = True; } }
            if not found { user +>:UserHasAgentProfile:+> AgentProfile(name=self.name, email=user.email); }
        } elif resolved_role == "company_admin" {
            for company in shared_companies() { for owner in [user ->:UserHasCompany:->] { if jid(company) == jid(owner) { found = True; } } }
            if not found {
                company = root.shared ++> Company(name=self.name, status="pending", verified=False);
                _ = publish_company(company);
                user +>:UserHasCompany:+> company;
            }
        }
        _ = record_audit(user.id, "User", user.id, "Role profile initialized: " + resolved_role);
        report {"ok": True, "user_id": user.id, "role": resolved_role};
    }
}

def role_value(requested: str) -> str {
    return requested if requested in ["applicant", "agent", "company_admin"] else "applicant";
}

walker:priv bootstrap_admin {
    can bootstrap with Root entry {
        user = current_app_user();
        if user is None { report make_error("UNAUTHENTICATED", "Sign in with the configured administrator account."); disengage; }
        expected = os.environ.get("ADMIN_EMAIL", "").lower();
        if len(expected) == 0 or user.email.lower() != expected { report make_error("FORBIDDEN", "This account is not the configured bootstrap administrator."); disengage; }
        user.role = "admin";
        _ = record_audit(user.id, "User", user.id, "Bootstrapped initial administrator role");
        report {"ok": True, "role": "admin"};
    }
}
