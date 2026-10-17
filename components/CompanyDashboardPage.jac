sv import from hr.CompanyJobs { create_company, create_job, close_job, add_agent_to_company, assign_agent_to_job }
cl import from .RecruitmentShell { HavenhireLayout }
import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.badge { Badge }
import from .ui.empty { Empty, EmptyHeader, EmptyTitle, EmptyDescription }

cl def:pub CompanyDashboardPage() -> JsxPage {
    has company_name: str = "";
    has job_title: str = "";
    has job_description: str = "";
    has spots: str = "1";
    has salary_min: str = "";
    has salary_max: str = "";
    has deadline: str = "";
    has company_id: str = "";
    has message: str = "";
    def on_company(e: ChangeEvent) { company_name = e.target.value; }
    def on_title(e: ChangeEvent) { job_title = e.target.value; }
    def on_description(e: ChangeEvent) { job_description = e.target.value; }
    def on_spots(e: ChangeEvent) { spots = e.target.value; }
    def on_salary_min(e: ChangeEvent) { salary_min = e.target.value; }
    def on_salary_max(e: ChangeEvent) { salary_max = e.target.value; }
    def on_deadline(e: ChangeEvent) { deadline = e.target.value; }
    def on_company_id(e: ChangeEvent) { company_id = e.target.value; }
    async def add_company { try { company: any = await create_company(company_name); company_id = str(company["_jac_id"]); message = "Company created. An administrator must verify it before jobs can be posted."; } except Exception { message = "Company could not be created. Sign in with a company administrator account."; } }
    async def post_job { try { _ = await create_job(company_id, job_title, int(spots), float(salary_min), float(salary_max), deadline, job_description, "Technology", job_title, "USD", "year", "hybrid", "Toronto", "full-time", "mid-level", ["Communication"], ["Recruiting"]); message = "Job posted."; } except Exception { message = "Job could not be posted. Verify the company, deadline, salary range, and available spots."; } }
    return <HavenhireLayout title="Company workspace" subtitle="Manage your hiring team and publish roles once your company is verified.">
        {if message { <p className="rounded-lg border bg-card px-4 py-3 text-sm">{message}</p> }}
        <div className="grid gap-5 lg:grid-cols-2">
            <Card className="shadow-sm"><CardHeader><CardTitle>{"Company profile"}</CardTitle><CardDescription>{"Create your company profile or check its verification state."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><label className="flex flex-col gap-1 text-sm font-medium">{"Company name"}<Input value={company_name} onChange={on_company} placeholder="Your registered company" /></label><Button onClick={add_company}>{"Create company profile"}</Button><label className="mt-2 flex flex-col gap-1 text-sm font-medium">{"Company ID for job posting"}<Input value={company_id} onChange={on_company_id} placeholder="Paste your company identifier" /></label><div className="flex items-center gap-2"><span className="text-sm text-muted-foreground">{"Verification status"}</span><Badge variant="outline">{"Pending review"}</Badge></div><p className="text-xs text-muted-foreground">{"Unverified companies cannot publish job listings."}</p></CardContent></Card>
            <Card className="shadow-sm"><CardHeader><CardTitle>{"Create a job"}</CardTitle><CardDescription>{"Publish a new opening for your verified company."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><label className="flex flex-col gap-1 text-sm font-medium">{"Job title"}<Input value={job_title} onChange={on_title} placeholder="Senior Data Engineer" /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Description"}<Textarea value={job_description} onChange={on_description} placeholder="Describe the role and team" /></label><div className="grid gap-3 sm:grid-cols-2"><label className="flex flex-col gap-1 text-sm font-medium">{"Openings"}<Input type="number" value={spots} onChange={on_spots} /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Apply by"}<Input type="datetime-local" value={deadline} onChange={on_deadline} /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Minimum salary"}<Input type="number" value={salary_min} onChange={on_salary_min} /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Maximum salary"}<Input type="number" value={salary_max} onChange={on_salary_max} /></label></div><Button onClick={post_job}>{"Publish job"}</Button></CardContent></Card>
        </div>
        <div className="grid gap-5 lg:grid-cols-2"><Card className="shadow-sm"><CardHeader><CardTitle>{"Hiring team"}</CardTitle><CardDescription>{"Add recruitment agents and assign them to open jobs."}</CardDescription></CardHeader><CardContent><Empty><EmptyHeader><EmptyTitle>{"No agents listed"}</EmptyTitle><EmptyDescription>{"Your team memberships and assigned roles will appear here."}</EmptyDescription></EmptyHeader></Empty></CardContent></Card><Card className="shadow-sm"><CardHeader><CardTitle>{"Applications"}</CardTitle><CardDescription>{"Review candidates and their advisory suitability evidence."}</CardDescription></CardHeader><CardContent><Empty><EmptyHeader><EmptyTitle>{"No applications yet"}</EmptyTitle><EmptyDescription>{"Applications to your posted roles will appear here."}</EmptyDescription></EmptyHeader></Empty></CardContent></Card></div>
    </HavenhireLayout>;
}
