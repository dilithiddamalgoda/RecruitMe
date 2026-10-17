import from hr.domain { SharedDirectory, Company, Job, DirectoryHasCompany, DirectoryHasJob }

def:pub shared_directory() -> SharedDirectory {
    for directory in [root.shared -->][?:SharedDirectory] {
        if directory.namespace == "recruitme-global" { return directory; }
    }
    dir = SharedDirectory(namespace="recruitme-global");
    root.shared ++> dir;
    return dir;
}

def:pub shared_companies() -> list[Company] {
    directory = shared_directory();
    return [directory ->:DirectoryHasCompany:->];
}

def:pub shared_jobs() -> list[Job] {
    directory = shared_directory();
    return [directory ->:DirectoryHasJob:->];
}

def:pub publish_company(company: Company) -> Company {
    directory = shared_directory();
    connected = False;
    for existing in [directory ->:DirectoryHasCompany:->] { if jid(existing) == jid(company) { connected = True; } }
    if not connected { directory +>:DirectoryHasCompany:+> company; }
    return company;
}

def:pub publish_job(job: Job) -> Job {
    directory = shared_directory();
    connected = False;
    for existing in [directory ->:DirectoryHasJob:->] { if jid(existing) == jid(job) { connected = True; } }
    if not connected { directory +>:DirectoryHasJob:+> job; }
    return job;
}
