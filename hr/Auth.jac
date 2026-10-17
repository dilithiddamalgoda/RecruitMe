import from hr.domain { User, ApplicantProfile, AgentProfile, Company, UserHasApplicantProfile, UserHasAgentProfile, UserHasCompany }
import from shared.Errors { AppError, make_error }
import from shared.Validation { validate_registration }
import from hr.Authorization { require_role }
import from hr.Audit { log_status_change, record_audit }

walker:pub register {
    has email: str;
    has password_hash: str;
    has role: str;
    has name: str = "";

    can create with Root entry {
        validation = validate_registration(self.email, self.password_hash, self.role);
        if validation is not None {
            report validation;
            disengage;
        }
        users = [root -->][?:User];
        for existing in users {
            if existing.email == self.email {
                report make_error("EMAIL_EXISTS", "An account with this email already exists.", "email");
                disengage;
            }
        }
        account = root ++> User(id="", email=self.email, password_hash=self.password_hash, role=self.role);
        account.id = jid(account);
        if self.role == "applicant" {
            account +>:UserHasApplicantProfile:+> ApplicantProfile(name=self.name, email=self.email);
        } elif self.role == "agent" {
            account +>:UserHasAgentProfile:+> AgentProfile(name=self.name, email=self.email);
        } else {
            account +>:UserHasCompany:+> Company(name=self.name);
        }
        _ = log_status_change(account.id, "User", account.id, "", "registered", "Account registration");
        report {"ok": True, "user_id": account.id, "role": account.role};
    }
}

walker:pub login {
    has email: str;
    has password_hash: str;

    can authenticate with Root entry {
        for account in [root -->][?:User] {
            if account.email == self.email and account.password_hash == self.password_hash {
                _ = record_audit(account.id, "User", account.id, "Successful login");
                report {"ok": True, "user_id": account.id, "role": account.role};
                disengage;
            }
        }
        report make_error("INVALID_CREDENTIALS", "Email or password is incorrect.");
    }
}
