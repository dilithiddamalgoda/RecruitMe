obj AppError {
    has ok: bool = False;
    has code: str = "";
    has message: str = "";
    has field: str | None = None;
}

def:pub make_error(code: str, message: str, field: str | None = None) -> AppError {
    return AppError(ok=False, code=code, message=message, field=field);
}
