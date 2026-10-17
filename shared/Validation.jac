import from shared.Errors { AppError, make_error }

def:pub validate_registration(email: str, password: str, role: str) -> AppError | None {
    if len(email.strip()) < 3 or "@" not in email {
        return make_error("INVALID_EMAIL", "Enter a valid email address.", "email");
    }
    if len(password) < 8 {
        return make_error("INVALID_PASSWORD", "Password must contain at least 8 characters.", "password");
    }
    if role not in ["applicant", "agent", "company_admin"] {
        return make_error("INVALID_ROLE", "Choose a supported account role.", "role");
    }
    return None;
}
