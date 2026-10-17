import os;

obj AIConfig {
    has api_key: str = "";
    has model: str = "";
    has enabled: bool = False;
}

def:pub load_ai_config() -> AIConfig {
    key = os.environ.get("OPENAI_API_KEY", "");
    model = os.environ.get("LLM_MODEL", "gpt-4o-mini");
    return AIConfig(api_key=key, model=model, enabled=(len(key) > 0));
}
