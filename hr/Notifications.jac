import from datetime { datetime }
import from hr.domain { Notification, User, ApplicantProfile, ApplicantFollows, Company }
import from shared.Errors { AppError, make_error }

def:pub notify(user: User, kind: str, message: str) -> Notification {
    return user ++> Notification(type=kind, message=message, read=False);
}

def:pub notify_job_followers(company_id: str, job_title: str) -> int {
    sent = 0;
    for applicant in [root -->][?:ApplicantProfile] {
        for company in [applicant ->:ApplicantFollows:->] {
            if jid(company) == company_id {
                for user in [root -->][?:User] {
                    if user.email == applicant.email {
                        _ = notify(user, "new_job", "New job posted: " + job_title);
                        sent += 1;
                    }
                }
            }
        }
    }
    return sent;
}
