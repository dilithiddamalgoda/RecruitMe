sv import from hr.ApplicantProfiles { get_my_profile, update_profile, confirm_profile, delete_my_data, import_linkedin_pdf }
sv import from hr.Notifications { get_my_notifications, mark_read }
sv import from hr.CompanyJobs { follow_company, unfollow_company }
cl import from .RecruitmentShell { HavenhireLayout }
cl import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
cl import from .ui.button { Button }
cl import from .ui.input { Input }
cl import from .ui.textarea { Textarea }
cl import from .ui.badge { Badge }
cl import from .ui.empty { Empty, EmptyHeader, EmptyTitle, EmptyDescription }

cl def:pub ApplicantDashboardPage() -> JsxPage {
    has profile: any = None;
    has notifications: list[any] = [];
    has name: str = "";
    has email: str = "";
    has phone: str = "";
    has location: str = "";
    has summary: str = "";
    has skills: str = "";
    has loading: bool = True;
    has message: str = "";
    has file_name: str = "";
    has chosen_file: any = None;
    has uploading: bool = False;
    def on_name(e: ChangeEvent) { name = e.target.value; }
    def on_email(e: ChangeEvent) { email = e.target.value; }
    def on_phone(e: ChangeEvent) { phone = e.target.value; }
    def on_location(e: ChangeEvent) { location = e.target.value; }
    def on_summary(e: ChangeEvent) { summary = e.target.value; }
    def on_skills(e: ChangeEvent) { skills = e.target.value; }
    def on_file(e: ChangeEvent) {
        picked: any = e.target.files;
        if picked and len(picked) > 0 { chosen_file = picked[0]; file_name = str(picked[0].name); }
        else { chosen_file = None; file_name = ""; }
    }
    async def load_dashboard {
        loading = True;
        try {
            profile_result = root spawn get_my_profile();
            if profile_result.reports and len(profile_result.reports) > 0 {
                first: any = profile_result.reports[0];
                if first["code"] { profile = None; message = str(first["message"]); }
                else {
                    profile = first;
                    name = str(profile.name); email = str(profile.email); phone = str(profile.phone); location = str(profile.location); summary = str(profile.summary);
                    skills = ", ".join(profile.skills);
                }
            }
            notification_result = root spawn get_my_notifications();
            if notification_result.reports and len(notification_result.reports) > 0 { notifications = notification_result.reports[0] as list[any]; }
        } except Exception { message = "Sign in as an applicant to manage your profile."; }
        loading = False;
    }
    async def save_profile {
        try {
            update_result = root spawn update_profile(name=name, email=email, phone=phone, location=location, summary=summary, skills=[item.strip() for item in skills.split(",") if item.strip()], education=profile.education, experience=profile.experience, certifications=profile.certifications);
            if update_result.reports and len(update_result.reports) > 0 { profile = update_result.reports[0]; message = "Profile saved. Confirm it before applying."; }
        } except Exception { message = "Profile could not be saved. Check required fields and sign-in."; }
    }
    async def confirm_profile_now { try { result = root spawn confirm_profile(); if result.reports and len(result.reports) > 0 { profile = result.reports[0]; message = "Profile confirmed. You can apply to open jobs."; } } except Exception { message = "Confirm your profile after reviewing your details."; } }
    async def delete_data { try { result = root spawn delete_my_data(); profile = None; message = "Your profile data and resume were deleted."; } except Exception { message = "Your data could not be deleted right now."; } }
    async def read_notification(notification_id: str) { _ = root spawn mark_read(notification_id=notification_id); await load_dashboard(); }
    async def upload_resume {
        if not chosen_file { message = "Choose a PDF file first."; return; }
        uploading = True;
        message = "";
        form: any = new(FormData);
        form.append("file", chosen_file);
        token: any = localStorage.getItem("jac_token");
        headers: dict = {};
        if token { headers["Authorization"] = "Bearer " + str(token); }
        response: any = None;
        payload: any = None;
        outcome: any = None;
        try {
            response = await fetch("/walker/import_linkedin_pdf", {"method": "POST", "headers": headers, "body": form});
            if response.status == 401 { message = "Your session expired. Sign in again to import a PDF."; }
            elif not response.ok { message = "The PDF could not be uploaded (" + str(response.status) + "). Try again."; }
            else {
                payload = await response.json();
                outcome = payload["data"]["reports"][0] if payload["data"] and payload["data"]["reports"] and len(payload["data"]["reports"]) > 0 else None;
                if outcome is None { message = "The import returned no result. Enter your details manually."; }
                elif outcome["code"] { message = str(outcome["message"]); }
                else {
                    profile = outcome;
                    name = str(outcome["name"]); email = str(outcome["email"]); phone = str(outcome["phone"]); location = str(outcome["location"]); summary = str(outcome["summary"]);
                    skills = ", ".join(outcome["skills"]);
                    message = "PDF imported. Review the details below, then confirm your profile.";
                }
            }
        } except Exception { message = "The PDF could not be uploaded. Check your connection and try again."; }
        uploading = False;
    }
    async can with entry { await load_dashboard(); }
    status_label = "Confirmed" if profile and profile["parse_status"] == "confirmed" else ("Needs review" if profile and profile["parse_status"] == "parsed" else "Incomplete");
    return <HavenhireLayout title="Applicant workspace" subtitle="Keep your profile current and stay on top of application updates.">
        {if loading { <Card className="p-6 text-sm text-muted-foreground">{"Loading your profile and notifications…"}</Card> }}
        {if message { <p className="rounded-lg border bg-card px-4 py-3 text-sm">{message}</p> }}
        <div className="grid gap-5 lg:grid-cols-[1.15fr_0.85fr]">
            <Card className="shadow-sm"><CardHeader><div className="flex flex-wrap items-start justify-between gap-3"><div><CardTitle>{"Your profile"}</CardTitle><CardDescription>{"Review every detail before confirming your application profile."}</CardDescription></div><Badge variant="outline">{status_label}</Badge></div></CardHeader><CardContent className="flex flex-col gap-4">
                {if not profile { <Empty><EmptyHeader><EmptyTitle>{"Start with your profile"}</EmptyTitle><EmptyDescription>{"Enter your details manually or import a text-based LinkedIn PDF."}</EmptyDescription></EmptyHeader></Empty> }}
                <div className="grid gap-3 sm:grid-cols-2"><label className="flex flex-col gap-1 text-sm font-medium">{"Full name"}<Input value={name} onChange={on_name} placeholder="Your name" /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Email"}<Input value={email} onChange={on_email} placeholder="you@example.com" /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Phone"}<Input value={phone} onChange={on_phone} placeholder="Phone number" /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Location"}<Input value={location} onChange={on_location} placeholder="City, region" /></label></div>
                <label className="flex flex-col gap-1 text-sm font-medium">{"Summary"}<Textarea value={summary} onChange={on_summary} placeholder="A short professional introduction" /></label>
                <label className="flex flex-col gap-1 text-sm font-medium">{"Skills, separated by commas"}<Input value={skills} onChange={on_skills} placeholder="Recruiting, sourcing, analytics" /></label>
                <div className="flex flex-wrap gap-2"><Button onClick={save_profile}>{"Save profile"}</Button><Button variant="outline" onClick={confirm_profile_now}>{"Confirm reviewed profile"}</Button></div>
                <div className="rounded-xl border border-dashed p-4"><h3 className="font-medium">{"Import a LinkedIn PDF"}</h3><p className="mt-1 text-sm text-muted-foreground">{"Text-based PDFs only, up to 5 MB and 10 pages. Review the parsed details before confirming."}</p><div className="mt-3 flex flex-wrap gap-2"><Input type="file" accept="application/pdf,.pdf" onChange={on_file} className="max-w-sm" /><Button variant="outline" disabled={uploading} onClick={upload_resume}>{"Importing…" if uploading else "Import PDF"}</Button></div>{if file_name { <p className="mt-2 text-xs text-muted-foreground">{file_name}</p> }}</div>
                <Button variant="destructive" onClick={delete_data} className="self-start">{"Delete my data"}</Button>
            </CardContent></Card>
            <div className="flex flex-col gap-5">
                <Card className="shadow-sm"><CardHeader><CardTitle>{"Applications and interviews"}</CardTitle><CardDescription>{"Your submitted applications and scheduled interviews appear here."}</CardDescription></CardHeader><CardContent><p className="text-sm text-muted-foreground">{"No applications to display yet. Browse open roles when your profile is confirmed."}</p><a href="/jobs" className="mt-3 inline-flex text-sm font-medium text-primary">{"Browse open jobs"}</a></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>{"Notifications"}</CardTitle><CardDescription>{"Updates about your applications and interviews."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">{if len(notifications) == 0 { <p className="text-sm text-muted-foreground">{"You’re all caught up."}</p> }}{for notification in notifications { <div key={str(notification["_jac_id"])} className="flex items-start justify-between gap-3 rounded-lg border p-3"><div><p className="text-sm font-medium">{str(notification["type"])}</p><p className="text-sm text-muted-foreground">{str(notification["message"])}</p></div>{if not notification["read"] { <Button size="sm" variant="outline" onClick={lambda { read_notification(str(notification["_jac_id"])); }}>{"Mark read"}</Button> }}</div> }}</CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>{"Followed companies"}</CardTitle><CardDescription>{"Job alerts from companies you follow."}</CardDescription></CardHeader><CardContent><p className="text-sm text-muted-foreground">{"Follow a company from its job page to receive new-role notifications."}</p></CardContent></Card>
            </div>
        </div>
    </HavenhireLayout>;
}
