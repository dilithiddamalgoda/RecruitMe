import from datetime { datetime }
import from hr.domain { Notification, User, ApplicantProfile, ApplicantFollows, Company, UserHasNotification }
import from hr.Authorization { require_role }
import from shared.Errors { AppError, make_error }

def:pub notify(user: User, kind: str, message: str) -> Notification {
    notification = user ++> Notification(type=kind, message=message, read=False);
    user +>:UserHasNotification:+> notification;
    return notification;
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

walker:pub get_my_notifications {
    can list_notifications with Root entry {
        denial = require_role(["applicant", "agent", "company_admin"]);
        if denial is not None { report denial; disengage; }
        users = [root -->][?:User];
        if len(users) == 0 { report make_error("USER_NOT_FOUND", "User was not found."); disengage; }
        report [users[0] ->:UserHasNotification:->];
    }
}

walker:pub mark_read {
    has notification_id: str;
    can read with Root entry {
        denial = require_role(["applicant", "agent", "company_admin"]);
        if denial is not None { report denial; disengage; }
        users = [root -->][?:User];
        if len(users) == 0 { report make_error("USER_NOT_FOUND", "User was not found."); disengage; }
        for notification in [users[0] ->:UserHasNotification:->] {
            if jid(notification) == self.notification_id {
                notification.read = True;
                report notification;
                disengage;
            }
        }
        report make_error("NOTIFICATION_NOT_FOUND", "Notification was not found.");
    }
}
