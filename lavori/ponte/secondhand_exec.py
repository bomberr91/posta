#!/usr/bin/env python3
# secondhand_exec.py — driver Python per Open Interpreter: bypassa l'interfaccia terminale.
# Perché: la CLI 0.4.3 fa input() a fine giro (feedback) e nel loop (cli_input) → EOFError senza TTY.
# Qui: interpreter.chat() diretto + interpreter.offline=True (spegne feedback/telemetry alla radice).
import os, sys

def main():
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("compito mancante", file=sys.stderr)
        return 2
    task = sys.argv[1]

    from interpreter import interpreter

    api_base = os.environ.get("OPENAI_BASE_URL", "http://127.0.0.1:20129/v1")
    api_key = os.environ.get("OPENAI_API_KEY", "sk-cervello")
    model = os.environ.get("MODEL", "auto")
    if "/" not in model:
        model = "openai/" + model      # litellm esige provider/model; il portiere accetta "auto"
    for attr, valore in (("api_base", api_base), ("api_key", api_key), ("model", model)):
        try:
            setattr(interpreter.llm, attr, valore)
        except Exception as e:
            print(f"config llm.{attr}: {e}", file=sys.stderr)
    try:
        interpreter.offline = True          # la radice: niente feedback, niente telemetry prompt
    except Exception as e:
        print(f"flag offline: {e}", file=sys.stderr)

    try:
        out = interpreter.chat(task)
        if isinstance(out, str):
            testo = out
        else:
            testo = "\n".join(
                str(m.get("content", "")) for m in (out or []) if isinstance(m, dict) and m.get("role") == "assistant"
            )
        print(testo or "(nessun output)")
        return 0
    finally:
        try:
            interpreter.computer.terminate()
        except Exception:
            pass

if __name__ == "__main__":
    sys.exit(main())
