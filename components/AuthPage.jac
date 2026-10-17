import from "@jac/runtime" { jacLogin, useNavigate }
sv import from hr.Auth { register }
cl import from .RecruitmentShell { HavenhireLayout }
cl import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
cl import from .ui.input { Input }
cl import from .ui.button { Button }
cl import from .ui.select { Select, SelectTrigger, SelectValue, SelectContent, SelectItem }
cl import from .ui.field { Field, FieldLabel, FieldGroup }

cl def:pub AuthPage() -> JsxPage {
    has email: str = "";
    has password: str = "";
    has display_name: str = "";
    has role: str = "applicant";
    has mode: str = "login";
    has message: str = "";
    has busy: bool = False;
    nav = useNavigate();
    def change_email(e: ChangeEvent) { email = e.target.value; }
    def change_password(e: ChangeEvent) { password = e.target.value; }
    def change_name(e: ChangeEvent) { display_name = e.target.value; }
    async def submit_auth {
        busy = True;
        message = "";
        if mode == "register" {
            registration: any = await register(email, password, role, display_name);
            login_ok: bool = False;
            if registration["error"] { message = str(registration["message"]); busy = False; return; }
            login_ok = await jacLogin(email, password);
            if not login_ok { message = "Registration succeeded but sign in did not. Try signing in."; busy = False; return; }
        } else {
            login_ok = await jacLogin(email, password);
            if not login_ok { message = "Email or password is incorrect."; busy = False; return; }
        }
        busy = False;
        if role == "applicant" { nav("/applicant"); }
        elif role == "agent" { nav("/agent"); }
        else { nav("/company"); }
    }
    login_variant = "default" if mode == "login" else "outline";
    register_variant = "default" if mode == "register" else "outline";
    return <HavenhireLayout title="Welcome to Havenhire" subtitle="Sign in or create a recruitment account to continue.">
        <div className="grid gap-6 lg:grid-cols-[1fr_0.9fr]">
            <section className="flex flex-col justify-center gap-5 rounded-2xl bg-primary p-8 text-primary-foreground shadow-sm sm:p-10">
                <p className="text-sm font-medium text-primary-foreground/75">{"A clearer conversation for every hire"}</p>
                <h2 className="text-balance text-3xl font-semibold tracking-tight sm:text-4xl">{"Good hiring starts with a stronger connection."}</h2>
                <p className="max-w-xl leading-relaxed text-primary-foreground/80">{"Discover roles, coordinate thoughtful interviews, and keep every decision accountable."}</p>
                <div className="grid gap-3 sm:grid-cols-3">
                    <div className="rounded-xl bg-primary-foreground/10 p-4"><strong className="block text-sm">{"Find your next role"}</strong><span className="text-xs text-primary-foreground/75">{"Search open opportunities"}</span></div>
                    <div className="rounded-xl bg-primary-foreground/10 p-4"><strong className="block text-sm">{"Coordinate hiring"}</strong><span className="text-xs text-primary-foreground/75">{"Manage your talent pipeline"}</span></div>
                    <div className="rounded-xl bg-primary-foreground/10 p-4"><strong className="block text-sm">{"Meet with purpose"}</strong><span className="text-xs text-primary-foreground/75">{"Schedule across time zones"}</span></div>
                </div>
            </section>
            <Card className="shadow-sm">
                <CardHeader><CardTitle>{"Your account"}</CardTitle><CardDescription>{"Use an existing account or create a new one."}</CardDescription></CardHeader>
                <CardContent className="flex flex-col gap-4">
                    <div className="flex gap-2"><Button variant={login_variant} onClick={lambda { mode = "login"; message = ""; }}>{"Sign in"}</Button><Button variant={register_variant} onClick={lambda { mode = "register"; message = ""; }}>{"Create account"}</Button></div>
                    <FieldGroup>
                        {if mode == "register" { <Field><FieldLabel htmlFor="full-name">{"Full name"}</FieldLabel><Input id="full-name" value={display_name} onChange={change_name} placeholder="Your full name" /></Field> }}
                        <Field><FieldLabel htmlFor="account-email">{"Email address"}</FieldLabel><Input id="account-email" type="email" value={email} onChange={change_email} placeholder="you@example.com" /></Field>
                        <Field><FieldLabel htmlFor="account-password">{"Password"}</FieldLabel><Input id="account-password" type="password" value={password} onChange={change_password} placeholder="At least 8 characters" /></Field>
                        {if mode == "register" { <Field><FieldLabel htmlFor="account-role">{"Account type"}</FieldLabel><Select value={role} onValueChange={lambda (v: str) { role = v; }}><SelectTrigger id="account-role"><SelectValue placeholder="Choose an account type" /></SelectTrigger><SelectContent><SelectItem value="applicant">{"Applicant"}</SelectItem><SelectItem value="agent">{"Recruitment agent"}</SelectItem><SelectItem value="company_admin">{"Company administrator"}</SelectItem></SelectContent></Select></Field> }}
                    </FieldGroup>
                    {if len(message) > 0 { <p className="text-sm text-destructive">{message}</p> }}
                    <Button disabled={busy} onClick={submit_auth} className="w-full">{"Continue"}</Button>
                    <p className="text-xs text-muted-foreground">{"Company and agent access requires approved account provisioning."}</p>
                </CardContent>
            </Card>
        </div>
    </HavenhireLayout>;
}
