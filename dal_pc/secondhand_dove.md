# Risposta a «secondhand_dove»

_04/11/2026 14:04 · FilippoPC_

### 1. DOVE NASCE IL MODELO DI DEFAULT
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/browser/browser.py:145:        # self.computer.interpreter.llm.model = "gpt-4o-mini"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/browser/browser.py:150:        self.computer.interpreter.llm.model = "gpt-4o-mini"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/llm/llm.py:54:        self.model = "gpt-4o"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/defaults/assistant.py:11:interpreter.llm.model = "gpt-4o"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/defaults/os.py:8:interpreter.llm.model = "gpt-4o"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/defaults/the01.py:12:# interpreter.llm.model = "gpt-4o-mini"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py:173:                        text = text.replace("gpt-4", "gpt-4o")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py:174:                        profile["llm"]["model"] = "gpt-4o"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py:176:                        text = text.replace("gpt-4-turbo-preview", "gpt-4o")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py:177:                        profile["llm"]["model"] = "gpt-4o"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/start_terminal_interface.py:200:            "help_text": "runs `interpreter --model gpt-4o-mini` and asks OI to be extremely concise (shortcut for `interpreter --profile fast`)",
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/validate_llm_settings.py:39:                "gpt-4o",

### 2. QUALI FILE TOML / CONFIG IL PACCHETTO LEGGE

### 3. COME COSTRUISCE IL PERCORSO DELLA CONFIG
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/display/point/point.py:76:    debug_path = os.path.join(os.path.expanduser("~"), "Desktop", "oi-debug")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/display/point/point.py:424:        desktop = os.path.join(os.path.join(os.path.expanduser("~")), "Desktop")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/display/point/point.py:552:    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/mail/mail.py:139:                os.path.getsize(os.path.expanduser(att)) for att in attachments
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/sms/sms.py:21:                home_directory = os.path.expanduser(f"~{os.environ.get('SUDO_USER')}")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/sms/sms.py:23:                home_directory = os.path.expanduser("~")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/computer/sms/sms.py:26:            home_directory = os.path.expanduser("~")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/core/utils/telemetry.py:25:            os.path.expanduser("~"), ".cache", "open-interpreter", "telemetry_user_id"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/contributing_conversations.py:15:    os.path.expanduser("~"), ".cache", "open-interpreter", "contribute.json"
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/magic_commands.py:221:        downloads = os.path.join(os.path.expanduser("~"), "Downloads")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py:684:    old_dir_pre_020 = platformdirs.user_config_dir("Open Interpreter")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py:686:    old_dir_020 = platformdirs.user_config_dir("Open Interpreter Terminal")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py:760:        old_dir = platformdirs.user_config_dir("Open Interpreter")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/profiles/profiles.py:764:        old_dir = platformdirs.user_config_dir("Open Interpreter Terminal")
/home/agenti/.local/lib/python3.12/site-packages/interpreter/terminal_interface/utils/local_storage_path.py:6:config_dir = platformdirs.user_config_dir("open-interpreter")

### 4. DOVE SETTA IL MODELO (core)

### 5. IL MODELLO CHE ARRIVA AL CERVELLO (ultimo tentativo con -c e con --model PRIMA di exec)
--- interpreter exec -c model="auto" --skip-git-repo-check
  File "/home/agenti/.local/lib/python3.12/site-packages/litellm/litellm_core_utils/exception_mapping_utils.py", line 624, in exception_type
    raise APIError(
litellm.exceptions.APIError: litellm.APIError: APIError: OpenAIException - Guardia solo-gratis: 'gpt-4o' sembra un modello a pagamento. Usa 'auto', 'gratis', 'veloce' o 'migliore' (regola: costo zero).
--- senza 'exec': (la CLI e' solo TUI ora)
                        (we don't recommend changing this) base prompt for the
  -y, --auto_run        automatically run generated code
  -m MODEL, --model MODEL
  -f, --fast            runs `interpreter --model gpt-4o-mini` and asks OI to
FINE

<!-- fine secondhand_dove -->
