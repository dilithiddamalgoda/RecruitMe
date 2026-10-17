import from datetime { datetime }
import from hr.domain { AuditLog }

def:pub log_status_change(actor_id: str, entity: str, entity_id: str, from_status: str, to_status: str, reason: str) -> AuditLog {
    record = root ++> AuditLog(
        actor_id=actor_id,
        entity=entity,
        entity_id=entity_id,
        from_status=from_status,
        to_status=to_status,
        reason=reason,
        created_at=str(datetime.now().isoformat())
    );
    return record;
}

def:pub record_audit(actor_id: str, entity: str, entity_id: str, reason: str) -> AuditLog {
    return log_status_change(actor_id, entity, entity_id, "", "", reason);
}
