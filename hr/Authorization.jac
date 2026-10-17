import os;
import from shared.Errors { AppError, make_error }
import from hr.domain { User }

def:pub current_app_user() -> User | None {
    users = [root -->][?:User];
    identity = os.environ.get("JAC_USER_EMAIL", os.environ.get("USER_EMAIL", ""));
    if len(identity) > 0 {
        for user in users { if user.email.lower() == identity.lower() { return user; } }
    }
    if len(users) == 1 { return users[0]; }
    return None;
}

def:pub bootstrap_role(email: str, requested_role: str) -> str {
    admin_email = os.environ.get("ADMIN_EMAIL", "").lower();
    if len(admin_email) > 0 and email.lower() == admin_email { return "admin"; }
    if requested_role in ["applicant", "agent", "company_admin"] { return requested_role; }
    return "applicant";
}

def:pub has_role(role: str) -> bool {
    user = current_app_user();
    return user is not None and user.role == role;
}

def:pub require_role(roles: list[str]) -> AppError | None {
    user = current_app_user();
    if user is None { return make_error("FORBIDDEN", "An authenticated application profile is required."); }
    if user.role not in roles { return make_error("FORBIDDEN", "Your account role cannot perform this action."); }
    return None;
}
