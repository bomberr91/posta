# Secondhand — profilo Windows reso "controllato" (4/11)

- backup: `/tmp/secondhand_win_20261104-155337`
- YAML Windows: `auto_run` True->False, `safe_mode` "off"->"ask"
- TOML Windows: `sandbox_mode` danger-full-access->workspace-write,
  `approval_policy` never->on-request
- profilo WSL del ponte: **NON toccato** (auto_run True / safe_mode off:
  lì l'auto-run serve, altrimenti la CLI chiede (y/n) e va in EOFError)

## Esito delle sostituzioni
```
/mnt/c/Users/giopi/.config/open-interpreter/profiles/default.yaml: aggiornato
/mnt/c/Users/giopi/.openinterpreter/config.toml: aggiornato
patch finita
```

## Dopo — YAML Windows
```
# OPEN INTERPRETER CONFIGURATION FILE
# 4/11: Secondhand parla col CERVELLO LOCALE (20129) con la chiave fissa del
# portone: nessuna chiave provider in giro.

llm:
  model: "auto"
  temperature: 0
  api_key: "sk-cervello"
  api_base: "http://127.0.0.1:20129/v1"

computer:
  import_computer_api: True

auto_run: False
safe_mode: "ask"
version: 0.2.5  # Profile version (do not modify)
```

## Dopo — TOML Windows
```
model = "auto"
model_provider = "cervello"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
[model_providers.cervello]
name = "Cervello"
base_url = "http://127.0.0.1:20129/v1"
env_key = "OPENAI_API_KEY"
wire_api = "chat"

[tui]
screen_reader_detection_done = true

[projects.'c:\users\giopi\documents\agentworkspace']
trust_level = "trusted"

[windows]
sandbox = "elevated"
```

## Profilo WSL del ponte (solo lettura, invariato)
```
# OPEN INTERPRETER CONFIGURATION FILE
# 4/11: Secondhand parla col CERVELLO LOCALE (20129) con la chiave fissa del
# portone: nessuna chiave provider in giro.

llm:
  model: "auto"
  temperature: 0
  api_key: "sk-cervello"
  api_base: "http://127.0.0.1:20129/v1"

computer:
  import_computer_api: True

auto_run: True
safe_mode: "off"

version: 0.2.5  # Profile version (do not modify)
```
