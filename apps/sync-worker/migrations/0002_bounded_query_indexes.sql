CREATE INDEX sync_operations_entity_cursor ON sync_operations(entity_id, server_cursor);
CREATE INDEX sync_operations_device_sequence ON sync_operations(device_id, device_sequence);
CREATE INDEX auth_one_time_expiry ON auth_one_time(kind, expires_at);
CREATE INDEX auth_sessions_device ON auth_sessions(device_id, revoked_at);
CREATE INDEX auth_sessions_family ON auth_sessions(family_id, revoked_at);
INSERT INTO sync_schema_migrations(version, name, applied_at) VALUES (2, 'bounded_query_indexes', CURRENT_TIMESTAMP);
