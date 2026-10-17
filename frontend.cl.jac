cl import ".styles.global.css";
cl import from ".components.ui.card" { Card, CardContent, CardHeader, CardTitle, CardDescription }

cl def:pub app() -> JsxElement {
    return <main className="min-h-screen bg-muted/40 px-5 py-10 text-foreground sm:px-8">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-8">
            <header className="flex items-center gap-3">
                <div className="flex size-10 items-center justify-center rounded-xl bg-primary text-primary-foreground font-semibold">{"H"}</div>
                <div>
                    <p className="text-sm font-semibold tracking-tight">{"Havenhire"}</p>
                    <p className="text-xs text-muted-foreground">{"Recruitment platform foundation"}</p>
                </div>
            </header>
            <section className="grid gap-8 rounded-2xl border bg-card p-6 shadow-sm sm:p-10 lg:grid-cols-[1.2fr_0.8fr] lg:items-center">
                <div className="flex flex-col gap-5">
                    <div className="flex w-fit items-center rounded-full border bg-muted px-3 py-1 text-xs font-medium text-muted-foreground">{"JAC + OBJECT-SPATIAL PROGRAMMING"}</div>
                    <h1 className="max-w-2xl text-3xl font-semibold tracking-tight sm:text-4xl">{"A stronger foundation for every hire."}</h1>
                    <p className="max-w-xl text-base leading-relaxed text-muted-foreground">{"Havenhire’s recruitment domain is modeled as a connected graph, with role-aware accounts, audit trails, and reusable access controls ready for the next product layer."}</p>
                    <div className="flex flex-wrap gap-2 pt-1">
                        <span className="rounded-md bg-primary px-3 py-2 text-sm font-medium text-primary-foreground">{"Graph-native domain"}</span>
                        <span className="rounded-md border bg-background px-3 py-2 text-sm font-medium">{"Role-based access"}</span>
                    </div>
                </div>
                <div className="grid gap-3 sm:grid-cols-2">
                    <Card className="shadow-sm">
                        <CardHeader><CardTitle>{"People"}</CardTitle><CardDescription>{"Applicant and agent profiles"}</CardDescription></CardHeader>
                        <CardContent><p className="text-sm leading-relaxed text-muted-foreground">{"User records connect to the right profile for each account role."}</p></CardContent>
                    </Card>
                    <Card className="shadow-sm">
                        <CardHeader><CardTitle>{"Hiring graph"}</CardTitle><CardDescription>{"Companies to interviews"}</CardDescription></CardHeader>
                        <CardContent><p className="text-sm leading-relaxed text-muted-foreground">{"Jobs, applications, availability, and outcomes have explicit relationships."}</p></CardContent>
                    </Card>
                    <Card className="shadow-sm sm:col-span-2">
                        <CardHeader><CardTitle>{"Security and accountability"}</CardTitle><CardDescription>{"A dependable base for future workflows"}</CardDescription></CardHeader>
                        <CardContent><p className="text-sm leading-relaxed text-muted-foreground">{"Registration validates inputs, access checks are reusable, and status changes have an audit record."}</p></CardContent>
                    </Card>
                </div>
            </section>
            <footer className="text-xs text-muted-foreground">{"Foundation only. Job, AI, and applicant-facing workflows are intentionally not included yet."}</footer>
        </div>
    </main>;
}
