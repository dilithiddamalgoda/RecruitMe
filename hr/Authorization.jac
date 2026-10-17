import from hr.domain { User }
import from shared.Errors { AppError, make_error }

def:pub has_role(role: str) -> bool {
    users = [root -->][?:User];
    return len(users) > 0 and users[0].role == role;
}

def:pub require_role(roles: list[str]) -> AppError | None {
    users = [root -->][?:User];
    if len(users) == 0 {
        return make_error("FORBIDDEN", "An account profile is required.");
    }
    if users[0].role not in roles {
        return make_error("FORBIDDEN", "Your account role cannot perform this action.");
    }
    return None;
}
