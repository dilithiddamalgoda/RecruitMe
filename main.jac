import from .frontend { app as ClientApp }
import from hr.Auth { register, login }

# Auth endpoints are registered from this entry module for REST callers.
def:pub app() -> JsxElement {
    return <ClientApp />;
}
