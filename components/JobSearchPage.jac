import from "@jac/runtime" { Link }
sv import from hr.CompanyJobs { Job, search_jobs }
cl import from .RecruitmentShell { HavenhireLayout, SectionCard }
cl import from .ui.input { Input }
cl import from .ui.button { Button }
cl import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
cl import from .ui.badge { Badge }
cl import from .ui.empty { Empty, EmptyHeader, EmptyTitle, EmptyDescription }

cl def:pub JobSearchPage() -> JsxPage {
    has keyword: str = "";
    has category: str = "";
    has location: str = "";
    has employment_type: str = "";
    has page: int = 1;
    has jobs: list[Job] = [];
    has total: int = 0;
    has loading: bool = False;
    has error: str = "";
    def change_keyword(e: ChangeEvent) { keyword = e.target.value; }
    def change_category(e: ChangeEvent) { category = e.target.value; }
    def change_location(e: ChangeEvent) { location = e.target.value; }
    def change_employment(e: ChangeEvent) { employment_type = e.target.value; }
    async def run_search {
        loading = True;
        error = "";
        try {
            response = root spawn search_jobs(keyword=keyword, category=category, location=location, salary_min=0.0, salary_max=0.0, employment_type=employment_type, page=page, page_size=12);
            if response.reports and len(response.reports) > 0 {
                result: any = response.reports[0];
                jobs = result["items"] as list[Job];
                total = result["total"] as int;
            } else { error = "No search response was returned."; }
        } except Exception { error = "Sign in as an applicant to search jobs."; }
        loading = False;
    }
    async can with entry { await run_search(); }
    safe_jobs: list[Job] = jobs or [];
    return <HavenhireLayout title="Find your next role" subtitle="Explore open opportunities and filter for what matters to you.">
        <Card className="shadow-sm"><CardContent className="grid gap-3 pt-6 sm:grid-cols-2 lg:grid-cols-5">
            <label className="flex flex-col gap-1 text-sm font-medium">{"Keyword"}<Input value={keyword} onChange={change_keyword} placeholder="Role, skill, or company" /></label>
            <label className="flex flex-col gap-1 text-sm font-medium">{"Category"}<Input value={category} onChange={change_category} placeholder="Technology" /></label>
            <label className="flex flex-col gap-1 text-sm font-medium">{"Location"}<Input value={location} onChange={change_location} placeholder="City or remote" /></label>
            <label className="flex flex-col gap-1 text-sm font-medium">{"Employment"}<Input value={employment_type} onChange={change_employment} placeholder="Full-time" /></label>
            <Button onClick={run_search} disabled={loading} className="self-end">{"Search roles"}</Button>
        </CardContent></Card>
        {if error and len(error) > 0 { <p className="rounded-lg border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">{error}</p> }}
        <div className="flex flex-wrap items-center justify-between gap-2"><h2 className="text-lg font-semibold">{"Open opportunities"}</h2><span className="text-sm text-muted-foreground tabular-nums">{str(total or 0) + " roles"}</span></div>
        {if loading { <div className="rounded-xl border bg-card p-6 text-sm text-muted-foreground">{"Loading jobs…"}</div> }}
        {if not loading and len(safe_jobs) == 0 { <Empty className="rounded-xl border bg-card py-10"><EmptyHeader><EmptyTitle>{"No matching jobs"}</EmptyTitle><EmptyDescription>{"Try a broader search or clear one of your filters."}</EmptyDescription></EmptyHeader></Empty> }}
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {for job in safe_jobs {
                title = str(job["title"]);
                slug = title.lower().replace(" ", "-");
                <Card key={str(job["_jac_id"])} className="shadow-sm transition-shadow hover:shadow-md">
                    <CardHeader><div className="flex items-start justify-between gap-3"><div><CardTitle>{title}</CardTitle><CardDescription>{str(job["category"]) + " · " + str(job["working_location"]["city"])}</CardDescription></div><Badge variant="secondary">{str(job["employment_type"])}</Badge></div></CardHeader>
                    <CardContent className="flex flex-col gap-4"><p className="line-clamp-3 text-sm leading-relaxed text-muted-foreground">{str(job["description"])}</p><div className="flex items-center justify-between border-t pt-3 text-xs text-muted-foreground"><span>{str(job["available_spots"]) + " openings"}</span><span>{str(job["experience_level"])}</span></div><Link to={"/jobs/" + slug} className="inline-flex h-9 items-center justify-center rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground">{"View job"}</Link></CardContent>
                </Card>
            }}
        </div>
        <div className="flex justify-end gap-2"><Button variant="outline" disabled={page <= 1} onClick={lambda { page = page - 1; run_search(); }}>{"Previous"}</Button><span className="self-center px-2 text-sm text-muted-foreground">{"Page " + str(page)}</span><Button variant="outline" disabled={len(safe_jobs) < 12} onClick={lambda { page = page + 1; run_search(); }}>{"Next"}</Button></div>
    </HavenhireLayout>;
}
