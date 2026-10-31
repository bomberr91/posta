import json
import os

def carica_profili(percorso):
    """
    Carica i profili da un file JSON, gestendo errori e assenze.
    Ritorna (profili, errore) dove errore è None se ok, altrimenti messaggio.
    """
    if not os.path.exists(percorso):
        return ({}, None)
    
    try:
        with open(percorso, 'r', encoding='utf-8') as f:
            dati = json.load(f)
        return (dati, None)
    except json.JSONDecodeError as e:
        return ({}, f"JSON corrotto: {str(e)}")
    except Exception as e:
        return ({}, f"Errore lettura file: {str(e)}")

def profilo_di(sessione, profili):
    """
    Trova il primo profilo il cui prefisso combacia con l'id sessione.
    """
    for prefisso, profilo in profili.items():
        if sessione.startswith(prefisso):
            return profilo
    return None

def applica_profilo(payload, profilo):
    """
    Applica il profilo al payload, rispettando le regole di override.
    Ritorna (nuovo_payload, note_modifiche).
    """
    nuovo = payload.copy()
    note = []
    
    # Gestione max_tokens: solo se profilo ha valore più basso
    if "max_tokens" in profilo and "max_tokens" in nuovo:
        if profilo["max_tokens"] < nuovo["max_tokens"]:
            nuovo["max_tokens"] = profilo["max_tokens"]
            note.append(f"max_tokens → {profilo['max_tokens']}")
    
    # Gestione temperature: solo se assente
    if "temperature" in profilo and "temperature" not in nuovo:
        nuovo["temperature"] = profilo["temperature"]
        note.append(f"temperature → {profilo['temperature']}")
    
    # Gestione model: solo se payload chiede "auto"
    if "model" in nuovo and nuovo["model"] == "auto" and "politica" in profilo:
        nuovo["model"] = profilo["politica"]
        note.append(f"model → {profilo['politica']}")
    
    return (nuovo, note)

if __name__ == "__main__":
    # Test carica_profili (simulazione file mancante/rotto)
    assert carica_profili("inesistente.json")[0] == {}, "File mancante non gestito"
    
    # Test profilo_di
    profili_test = {"goose-": {"politica": "veloce"}, "test-": {"max_tokens": 100}}
    assert profilo_di("goose-123", profili_test)["politica"] == "veloce", "Prefisso non trovato"
    assert profilo_di("altro-456", profili_test) is None, "Match non esistente"
    
    # Test applica_profilo (priorità payload esplicita)
    payload = {"max_tokens": 800, "model": "auto"}
    profilo = {"max_tokens": 900, "politica": "code"}
    nuovo, note = applica_profilo(payload, profilo)
    assert nuovo["max_tokens"] == 800, "Override non necessario di max_tokens"
    assert nuovo["model"] == "code", "Model non sostituito da politica"
    assert len(note) == 1, "Note non registrate correttamente"
