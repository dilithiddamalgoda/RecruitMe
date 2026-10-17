import from hr.Authorization { has_role, require_role }
import from shared.Validation { validate_registration }
import from shared.Errors { AppError }

test "role check rejects accounts without a user profile" {
    assert not has_role("applicant");
    denial = require_role(["company_admin"]);
    assert denial is not None;
    assert denial.code == "FORBIDDEN";
}

test "registration validation rejects invalid input" {
    invalid_email: AppError | None = validate_registration("bad", "long-enough-password", "applicant");
    assert invalid_email is not None;
    assert invalid_email.code == "INVALID_EMAIL";
    invalid_password: AppError | None = validate_registration("person@example.com", "short", "applicant");
    assert invalid_password is not None;
    assert invalid_password.code == "INVALID_PASSWORD";
    invalid_role: AppError | None = validate_registration("person@example.com", "long-enough-password", "root");
    assert invalid_role is not None;
    assert invalid_role.code == "INVALID_ROLE";
}
