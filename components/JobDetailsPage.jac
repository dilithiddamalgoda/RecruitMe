import from "@jac/runtime" { useParams, Link }
import from "@jac/runtime" { jid }
sv import from hr.CompanyJobs { Job, get_job_by_slug }
sv import from hr.Applications { apply_to_job }
cl import from .RecruitmentShell { HavenhireLayout }
cl import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
cl import from .ui.button { Button }
cl import from .ui.badge { Badge }
cl import from .ui.empty { Empty, EmptyHeader, EmptyTitle, EmptyDescription }

cl def:pub JobDetailsPage() -> JsxPage {
    has job: any = None;
    has application_result: any = None;
    has loading: bool = True;
    has message: str = "";
    params = useParams();
    slug_value = params["slug"];
    slug: str = str(slug_value) if slug_value else "";
    async def load_job {
        loading = True;
        try {
            result = root spawn get_job_by_slug(slug=slug);
            if result.reports and len(result.reports) > 0 { job = result.reports[0]; }
            else { message = "This job could not be found."; }
        } except Exception { message = "Sign in to view this job."; }
        loading = False;
    }
    async def apply_now {
        if job { try { result = root spawn apply_to_job(job_id=jid(job as Job)); if result.reports and len(result.reports) > 0 { application_result = result.reports[0]; } } except Exception { message = "Sign in as an applicant with a confirmed profile to apply."; } }
    }
    async can with entry { await load_job(); }
    return <HavenhireLayout title={"Job details"} subtitle={"Review the role and decide whether it fits your next step."}>
        {if loading { <Card className="p-6 text-sm text-muted-foreground">{"Loading job details…"}</Card> }}
        {if not loading and not job { <Empty className="rounded-xl border bg-card py-12"><EmptyHeader><EmptyTitle>{"Job not found"}</EmptyTitle><EmptyDescription>{"This role may have closed or the link may be incorrect."}</EmptyDescription></EmptyHeader><Link to="/jobs" className="mx-auto mt-4 inline-flex text-sm font-medium text-primary">{"Back to jobs"}</Link></Empty> }}
        {if job {
            <div className="grid gap-6 lg:grid-cols-[1fr_20rem]">
                <Card className="shadow-sm"><CardHeader><div className="flex flex-wrap items-start justify-between gap-3"><div><CardTitle className="text-2xl">{str(job["title"])}</CardTitle><CardDescription>{str(job["category"]) + " · " + str(job["working_location"]["city"]) + " · " + str(job["employment_type"])}</CardDescription></div><Badge variant="secondary">{str(job["status"])}</Badge></div></CardHeader><CardContent className="flex flex-col gap-6"><div><h2 className="font-semibold">{"About the role"}</h2><p className="mt-2 whitespace-pre-wrap text-sm leading-relaxed text-muted-foreground">{str(job["description"])}</p></div><div><h2 className="font-semibold">{"What you’ll bring"}</h2><div className="mt-2 flex flex-wrap gap-2">{for skill in (job["must_have_skills"] as list[str]) { <Badge key={skill} variant="outline">{skill}</Badge> }}{for skill in (job["nice_to_have_skills"] as list[str]) { <Badge key={skill} variant="secondary">{skill}</Badge> }}</div></div><div className="grid gap-3 rounded-xl bg-muted/50 p-4 text-sm sm:grid-cols-3"><div><span className="block text-xs text-muted-foreground">{"Experience"}</span>{str(job["min_experience_years"]) + "+ years"}</div><div><span className="block text-xs text-muted-foreground">{"Openings"}</span>{str(job["available_spots"])}</div><div><span className="block text-xs text-muted-foreground">{"Apply by"}</span>{str(job["deadline"])}</div></div></CardContent></Card>
                <div className="flex flex-col gap-4"><Card className="shadow-sm"><CardHeader><CardTitle>{"Ready to apply?"}</CardTitle><CardDescription>{"Your suitability result is advisory and never makes the hiring decision."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><Button disabled={str(job["status"]) != "open"} onClick={apply_now}>{"Apply to this role"}</Button><Link to="/jobs" className="text-center text-sm text-muted-foreground">{"Return to search"}</Link></CardContent></Card>
                    {if application_result { <Card className="shadow-sm"><CardHeader><CardTitle>{"Your suitability overview"}</CardTitle><CardDescription>{"Use the evidence to decide whether to continue."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><p className="text-3xl font-semibold tabular-nums">{str(application_result["match_score"]) + "%"}</p><p className="text-sm text-muted-foreground">{str(application_result["ai_verdict"]["summary"])}</p><div><p className="text-xs font-semibold">{"Requirement evidence"}</p>{for row in (application_result["ai_verdict"]["requirements"] as list[dict]) { <div key={row["requirement"]} className="mt-2 rounded-lg border p-3"><div className="flex justify-between gap-2 text-sm"><span>{str(row["requirement"])}</span><Badge variant="outline">{str(row["verdict"])}</Badge></div><p className="mt-1 text-xs text-muted-foreground">{str(row["evidence"] or "No supporting evidence provided.")}</p></div> }}</div><p className="text-xs text-muted-foreground">{"AI suitability is advisory only."}</p></CardContent></Card> }}
                </div>
            </div>
        }}
        {if len(message) > 0 { <p className="text-sm text-destructive">{message}</p> }}
    </HavenhireLayout>;
}
