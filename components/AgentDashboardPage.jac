sv import from hr.Interviews { add_availability, get_my_availability, schedule_interview, reschedule_interview, cancel_interview, complete_interview }
sv import from hr.Notifications { get_my_notifications, mark_read }
sv import from hr.Applications { evaluate_application, check_suitability, update_application_status }
cl import from .RecruitmentShell { RecruitMeLayout }
cl import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
cl import from .ui.button { Button }
cl import from .ui.input { Input }
cl import from .ui.textarea { Textarea }
cl import from .ui.badge { Badge }
cl import from .ui.empty { Empty, EmptyHeader, EmptyTitle, EmptyDescription }

cl def:pub AgentDashboardPage() -> JsxPage {
    has availability: list[any] = [];
    has notifications: list[any] = [];
    has start_time: str = "";
    has end_time: str = "";
    has timezone: str = "UTC";
    has loading: bool = True;
    has message: str = "";
    def on_start(e: ChangeEvent) { start_time = e.target.value; }
    def on_end(e: ChangeEvent) { end_time = e.target.value; }
    def on_timezone(e: ChangeEvent) { timezone = e.target.value; }
    async def load_agent {
        loading = True;
        try {
            slot_response: any = await get_my_availability();
            if slot_response["reports"] { availability = slot_response["reports"] as list[any]; }
            note_response: any = await get_my_notifications();
            if note_response["reports"] { notifications = note_response["reports"] as list[any]; }
        } except Exception { message = "Sign in as an assigned agent to use this workspace."; }
        loading = False;
    }
    async def add_slot { try { _ = await add_availability(start_time, end_time, timezone); message = "Availability saved."; await load_agent(); } except Exception { message = "Slot could not be saved. Use a future, non-overlapping interval."; } }
    async def mark_notice(notification_id: str) { _ = await mark_read(notification_id); await load_agent(); }
    async can with entry { await load_agent(); }
    return <RecruitMeLayout title="Agent workspace" subtitle="Coordinate active requisitions, suitability reviews, and interviews.">
        {if message { <p className="rounded-lg border bg-card px-4 py-3 text-sm">{message}</p> }}
        <div className="grid gap-5 xl:grid-cols-[1.1fr_0.9fr]">
            <div className="flex flex-col gap-5">
                <Card className="shadow-sm"><CardHeader><CardTitle>{"Assigned requisitions"}</CardTitle><CardDescription>{"Review roles assigned to your recruitment team."}</CardDescription></CardHeader><CardContent><Empty><EmptyHeader><EmptyTitle>{"No requisitions loaded"}</EmptyTitle><EmptyDescription>{"Assigned jobs will appear here as soon as a company adds you to a requisition."}</EmptyDescription></EmptyHeader></Empty></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>{"Application reviews"}</CardTitle><CardDescription>{"Suitability evidence is advisory; hiring decisions remain with your team."}</CardDescription></CardHeader><CardContent><Empty><EmptyHeader><EmptyTitle>{"No applications to review"}</EmptyTitle><EmptyDescription>{"Applications for your assigned jobs will appear here with evidence and status actions."}</EmptyDescription></EmptyHeader></Empty></CardContent></Card>
            </div>
            <div className="flex flex-col gap-5">
                <Card className="shadow-sm"><CardHeader><CardTitle>{"Interview availability"}</CardTitle><CardDescription>{"Add future slots using ISO local or timezone-offset timestamps."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><label className="flex flex-col gap-1 text-sm font-medium">{"Starts at"}<Input value={start_time} onChange={on_start} placeholder="2035-04-12T09:00:00-04:00" /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Ends at"}<Input value={end_time} onChange={on_end} placeholder="2035-04-12T10:00:00-04:00" /></label><label className="flex flex-col gap-1 text-sm font-medium">{"Timezone"}<Input value={timezone} onChange={on_timezone} placeholder="America/Toronto" /></label><Button onClick={add_slot}>{"Add availability"}</Button><div className="flex flex-col gap-2 border-t pt-3"><h3 className="text-sm font-semibold">{"Your slots"}</h3>{if len(availability) == 0 { <p className="text-sm text-muted-foreground">{"No interview slots added yet."}</p> }}{for slot in availability { <div key={str(slot["_jac_id"])} className="flex items-center justify-between gap-2 rounded-lg border p-3 text-sm"><span>{str(slot["start"]) + " – " + str(slot["end"])}</span><Badge variant="outline">{"Booked" if slot["is_booked"] else "Available"}</Badge></div> }}</div></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>{"Interview calendar"}</CardTitle><CardDescription>{"Scheduled, completed, and rescheduled meetings."}</CardDescription></CardHeader><CardContent><p className="text-sm text-muted-foreground">{"Scheduled interviews for assigned applications will appear here."}</p></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>{"Notifications"}</CardTitle><CardDescription>{"Application and interview activity."}</CardDescription></CardHeader><CardContent className="flex flex-col gap-2">{if len(notifications) == 0 { <p className="text-sm text-muted-foreground">{"You’re all caught up."}</p> }}{for notification in notifications { <div key={str(notification["_jac_id"])} className="flex items-center justify-between gap-2 rounded-lg border p-3"><span className="text-sm">{str(notification["message"])}</span>{if not notification["read"] { <Button size="sm" variant="outline" onClick={lambda { mark_notice(str(notification["_jac_id"])); }}>{"Read"}</Button> }}</div> }}</CardContent></Card>
            </div>
        </div>
    </RecruitMeLayout>;
}
