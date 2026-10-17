import from "@jac/runtime" { Link, useLocation }
cl import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
cl import from .ui.button { Button }

cl def:pub HavenhireLayout(title: str, subtitle: str, children: any = None) -> JsxElement {
    path = useLocation().pathname;
    jobs_class = "rounded-lg px-3 py-2 hover:bg-muted " + ("text-foreground font-medium" if path.startswith("/jobs") else "text-muted-foreground");
    applicant_class = "rounded-lg px-3 py-2 hover:bg-muted " + ("text-foreground font-medium" if path == "/applicant" else "text-muted-foreground");
    agent_class = "rounded-lg px-3 py-2 hover:bg-muted " + ("text-foreground font-medium" if path == "/agent" else "text-muted-foreground");
    company_class = "rounded-lg px-3 py-2 hover:bg-muted " + ("text-foreground font-medium" if path == "/company" else "text-muted-foreground");
    return <div className="min-h-screen bg-muted/40 text-foreground">
        <header className="border-b bg-background">
            <div className="mx-auto flex w-full max-w-7xl flex-wrap items-center justify-between gap-4 px-5 py-4 sm:px-8">
                <Link to="/jobs" className="flex items-center gap-3 no-underline">
                    <span className="flex size-10 items-center justify-center rounded-xl bg-primary font-semibold text-primary-foreground">{"H"}</span>
                    <span><strong className="block text-sm tracking-tight">{"Havenhire"}</strong><span className="text-xs text-muted-foreground">{"Recruitment workspace"}</span></span>
                </Link>
                <nav className="flex flex-wrap items-center gap-2 text-sm">
                    <Link to="/jobs" className={jobs_class}>{"Find jobs"}</Link>
                    <Link to="/applicant" className={applicant_class}>{"Applicant"}</Link>
                    <Link to="/agent" className={agent_class}>{"Agent"}</Link>
                    <Link to="/company" className={company_class}>{"Company"}</Link>
                    <Link to="/auth" className="rounded-lg border px-3 py-2 font-medium hover:bg-muted">{"Sign in"}</Link>
                </nav>
            </div>
        </header>
        <main className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-5 py-8 sm:px-8">
            <div><h1 className="text-2xl font-semibold tracking-tight">{title}</h1><p className="mt-1 text-sm text-muted-foreground">{subtitle}</p></div>
            {children}
            <footer className="border-t pt-4 text-xs text-muted-foreground">{"Havenhire · A clear, human-centered recruitment process"}</footer>
        </main>
    </div>;
}

cl def:pub SectionCard(title: str, description: str, children: any = None) -> JsxElement {
    return <Card className="shadow-sm"><CardHeader><CardTitle>{title}</CardTitle><CardDescription>{description}</CardDescription></CardHeader><CardContent>{children}</CardContent></Card>;
}
