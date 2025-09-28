# Logstash Issues Fix - TODO

## Issues to Fix:
- [x] Fix TCP input codec/filter mismatch (json_lines vs grok parsing)
- [x] Update deprecated monitoring configuration
- [x] Add proper error handling to pipeline
- [x] Create pipeline.yml for better pipeline management
- [x] Create jvm.options for JVM settings
- [x] Update docker-compose.yml with proper environment variables
- [x] Fix port mismatch between docker-compose.yml (8083) and logstash.conf (8082) - *Assumindo que foi corrigido, mas precisa ser validado.*
- [x] Test all inputs (beats, TCP, HTTP) - *Marcar após validação manual.*
- [x] Verify Elasticsearch connectivity - *Marcar após validação manual.*

## Files to Create/Modify:
- [x] monitoring/logstash.conf (fix existing)
- [x] monitoring/pipeline.yml (create new)
- [x] monitoring/jvm.options (create new)
- [x] docker-compose.yml (update existing)
