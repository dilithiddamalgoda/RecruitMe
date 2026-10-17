import os;
import bcrypt;
import from datetime { datetime }
import from shared.Errors { AppError, make_error }
import from shared.Validation { validate_registration }
import from hr.Authorization { current_app_user, bootstrap_role }
import from hr.Audit { log_status_change, record_audit }
import from hr.domain { User, ApplicantProfile, AgentProfile, Company, UserHasApplicantProfile, UserHasAgentProfile, UserHasCompany }
import from hr.RecruitmentIntegration { publish_company }

walker:pub register {
    has email: str;
    has password: str;
    has role: str;
    has name: str = "";

    can create with Root entry {
        validation = validate_registration(self.email, self.password, self.role);
        if validation is not None { report validation; disengage; }
        users = [root -->][?:User];
        for existing in users {
            if existing.email.lower() == self.email.lower() { report make_error("EMAIL_EXISTS", "An account with this email already exists.", "email"); disengage; }
        }
        resolved_role = bootstrap_role(self.email, self.role);
        encoded = bcrypt.hashpw(self.password.encode(), bcrypt.gensalt());
        account = root ++> User(id="", email=self.email.lower(), credential_hash=encoded.decode(), role=resolved_role);
        account.id = jid(account);
        report {"ok": True, "user_id": account.id, "role": account.role};
    }
}

walker:pub login {
    has email: str;
    has password: str;

    can authenticate with Root entry {
        for account in [root -->][?:User] {
            try {
                matched = bcrypt.checkpw(self.password.encode(), account.credential_hash.encode());
                if account.email.lower() == self.email.lower() and matched {
                    _ = record_audit(account.id, "User", account.id, "Successful login");
                    report {"ok": True, "user_id": account.id, "role": account.role};
                    disengage;
                }
            } except Exception { }
        }
        report make_error("INVALID_CREDENTIALS", "Email or password is incorrect.");
    }
}

walker:pub ensure_my_profile {
    has name: str = "";
    has email: str = "";
    has role: str = "applicant";

    can bootstrap_profile with Root entry {
        # Anonymous callers run on the shared guest graph, never create accounts there.
        if jid(root) == jid(root.shared) { report make_error("UNAUTHENTICATED", "Sign in before creating an application profile."); disengage; }
        user = current_app_user();
        if user is None {
            validation = validate_registration(self.email, "placeholder-password", self.role);
            if validation is not None { report validation; disengage; }
            account = User(id="", email=self.email.lower(), credential_hash="", role=bootstrap_role(self.email, self.role));
            _ = root ++> account;
            account.id = jid(account);
            user = account;
        }
        found = False;
        if user.role == "applicant" {
            for profile in [root -->][?:ApplicantProfile] { if profile.email.lower() == user.email.lower() { found = True; } }
            if not found {
                profile = ApplicantProfile(name=self.name, email=user.email, parse_status="pending");
                _ = root ++> profile;
                user +>:UserHasApplicantProfile:+> profile;
            }
        } elif user.role == "agent" {
            for profile in [root -->][?:AgentProfile] { if profile.email.lower() == user.email.lower() { found = True; } }
            if not found {
                agent = AgentProfile(name=self.name, email=user.email);
                _ = root ++> agent;
                user +>:UserHasAgentProfile:+> agent;
            }
        } elif user.role == "company_admin" {
            for owned in [user ->:UserHasCompany:->] { found = True; }
            if not found {
                company = Company(name=self.name, status="pending", verified=False);
                _ = root.shared ++> company;
                _ = publish_company(company);
                user +>:UserHasCompany:+> company;
            }
        }
        report {"ok": True, "role": user.role};
    }
}
