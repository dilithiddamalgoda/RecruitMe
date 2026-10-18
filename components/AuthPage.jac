import from "@jac/runtime" { useNavigate as authPageNavigate, Link }
cl import from .RecruitmentShell { HavenhireLayout as AuthPageLayout }
cl import from .ui.card { Card as AuthCard, CardHeader as AuthCardHeader, CardTitle as AuthCardTitle, CardDescription as AuthCardDescription, CardContent as AuthCardContent }
cl import from .ui.input { Input as AuthInput }
cl import from .ui.button { Button as AuthButton }
cl import from .ui.select { Select as AuthSelect, SelectTrigger as AuthSelectTrigger, SelectValue as AuthSelectValue, SelectContent as AuthSelectContent, SelectItem as AuthSelectItem }
cl import from .ui.field { Field as AuthField, FieldLabel as AuthFieldLabel }

cl def:pub RecruitMeAuthScreen() -> JsxPage {
    has email: str = "";
    has display_name: str = "";
    has role: str = "applicant";
    has message: str = "";
    nav = authPageNavigate();
    def change_email(e: ChangeEvent) { email = e.target.value; }
    def change_name(e: ChangeEvent) { display_name = e.target.value; }
    def go_applicant { nav("/applicant"); }
    def go_agent { nav("/agent"); }
    def go_company { nav("/company"); }
    return <AuthPageLayout title="Sign in to RecruitMe" subtitle="RecruitMe uses built-in Jac account authentication for secure sign-in and registration.">
        <div className="grid gap-6 lg:grid-cols-[1fr_0.9fr]">
            <section className="flex flex-col justify-center gap-5 rounded-2xl bg-primary p-8 text-primary-foreground shadow-sm sm:p-10">
                <p className="text-sm font-medium text-primary-foreground/75">{"A clearer conversation for every hire"}</p>
                <h2 className="text-balance text-3xl font-semibold tracking-tight sm:text-4xl">{"Good hiring starts with a stronger connection."}</h2>
                <p className="max-w-xl leading-relaxed text-primary-foreground/80">{"Discover roles, coordinate thoughtful interviews, and keep every decision accountable."}</p>
                <div className="grid gap-3 sm:grid-cols-3"><div className="rounded-xl bg-primary-foreground/10 p-4"><strong className="block text-sm">{"Find your next role"}</strong><span className="text-xs text-primary-foreground/75">{"Search open opportunities"}</span></div><div className="rounded-xl bg-primary-foreground/10 p-4"><strong className="block text-sm">{"Coordinate hiring"}</strong><span className="text-xs text-primary-foreground/75">{"Manage your talent pipeline"}</span></div><div className="rounded-xl bg-primary-foreground/10 p-4"><strong className="block text-sm">{"Meet with purpose"}</strong><span className="text-xs text-primary-foreground/75">{"Schedule across time zones"}</span></div></div>
            </section>
            <AuthCard className="shadow-sm"><AuthCardHeader><AuthCardTitle>{"Your RecruitMe profile"}</AuthCardTitle><AuthCardDescription>{"Sign in with Jac authentication, then initialize your application role."}</AuthCardDescription></AuthCardHeader><AuthCardContent className="flex flex-col gap-4">
                <p className="text-sm leading-relaxed text-muted-foreground">{"Registration and sign-in are handled by the host’s built-in Jac account forms. After sign-in, choose your RecruitMe workspace role to create its profile."}</p>
                <AuthField><AuthFieldLabel htmlFor="account-email">{"Account email"}</AuthFieldLabel><AuthInput id="account-email" type="email" value={email} onChange={change_email} placeholder="you@example.com" /></AuthField>
                <AuthField><AuthFieldLabel htmlFor="account-name">{"Display name"}</AuthFieldLabel><AuthInput id="account-name" value={display_name} onChange={change_name} placeholder="Your name" /></AuthField>
                <AuthField><AuthFieldLabel htmlFor="account-role">{"RecruitMe role"}</AuthFieldLabel><AuthSelect value={role} onValueChange={lambda (v: str) { role = v; }}><AuthSelectTrigger id="account-role"><AuthSelectValue placeholder="Choose your workspace" /></AuthSelectTrigger><AuthSelectContent><AuthSelectItem value="applicant">{"Applicant"}</AuthSelectItem><AuthSelectItem value="agent">{"Recruitment agent"}</AuthSelectItem><AuthSelectItem value="company_admin">{"Company administrator"}</AuthSelectItem></AuthSelectContent></AuthSelect></AuthField>
                {if len(message) > 0 { <p className="text-sm text-destructive">{message}</p> }}
                <div className="grid gap-2 sm:grid-cols-3"><AuthButton variant="outline" onClick={go_applicant}>{"Applicant workspace"}</AuthButton><AuthButton variant="outline" onClick={go_agent}>{"Agent workspace"}</AuthButton><AuthButton variant="outline" onClick={go_company}>{"Company workspace"}</AuthButton></div>
                <Link to="/jobs" className="text-sm font-medium text-primary">{"Browse open jobs"}</Link>
                <p className="text-xs text-muted-foreground">{"Initial admin access is bootstrapped only for ADMIN_EMAIL configured in the server environment."}</p>
            </AuthCardContent></AuthCard>
        </div>
    </AuthPageLayout>;
}
