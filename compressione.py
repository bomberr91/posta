import re
import json

def alleggerisci_tools(tools):
    """Riduce i tools: name + description (110 char) + SOLO parametri required.
    Capisce sia il formato OpenAI standard {type, function:{...}} sia quello
    piatto {name, description, parameters}. Mai distruttivo: se la forma e'
    strana, il tool passa intatto."""
    tools_ridotti = []
    risparmiato = 0
    for tool in tools or []:
        try:
            annidato = isinstance(tool.get('function'), dict)
            corpo = tool['function'] if annidato else tool
            name = corpo.get('name', '')
            if not name:
                tools_ridotti.append(tool)        # forma ignota: non si tocca
                continue
            desc = corpo.get('description', '') or ''
            desc_trunc = desc[:110]
            params = corpo.get('parameters', {}) or {}
            req = params.get('required', []) or []
            props = params.get('properties', {}) or {}
            new_props = {p: {'type': (props.get(p) or {}).get('type', '')}
                         for p in req if p in props}
            nuovo_corpo = {'name': name, 'description': desc_trunc,
                           'parameters': {'type': 'object',
                                          'properties': new_props,
                                          'required': req}}
            nuovo_tool = {'type': 'function', 'function': nuovo_corpo} if annidato else nuovo_corpo
            import json as _j
            risparmiato += max(0, len(_j.dumps(tool)) - len(_j.dumps(nuovo_tool)))
            tools_ridotti.append(nuovo_tool)
        except Exception:
            tools_ridotti.append(tool)            # mai rompere: passa intatto
    return tools_ridotti, risparmiato

def json_a_toon(oggetto, indent=0):
    if isinstance(oggetto, list) and not oggetto:
        return "(vuoto)"  # revisore: tabella senza righe = incoerente
    if isinstance(oggetto, dict):
        righe = []
        for chiave in sorted(oggetto.keys()):
            valore = oggetto[chiave]
            if isinstance(valore, (dict, list)):
                sub = json_a_toon(valore, indent + 1)
                righe.append(f"{'  ' * indent}{chiave}: {sub}")
            else:
                if isinstance(valore, str) and (':' in valore or '|' in valore or ' ' in valore):
                    valore_str = f"'{valore}'"
                else:
                    valore_str = str(valore)
                righe.append(f"{'  ' * indent}{chiave}: {valore_str}")
        return '\n'.join(righe)
    elif isinstance(oggetto, list):
        if all(isinstance(x, dict) for x in oggetto):
            chiavi = set().union(*[x.keys() for x in oggetto])
            if chiavi:
                intestazione = '|'.join(chiavi)
                righe = [f"{'  ' * indent}{intestazione}"]
                for item in oggetto:
                    riga = '|'.join(str(item.get(k, '')) for k in chiavi)
                    righe.append(f"{'  ' * indent}{riga}")
                return '\n'.join(righe)
        righe = []
        for idx, elem in enumerate(oggetto):
            elem_str = json_a_toon(elem, indent + 1)
            righe.append(f"{'  ' * indent}- {elem_str}")
        return '\n'.join(righe)
    else:
        return str(oggetto)

def comprimi_system(testo):
    def sostituisci_json(match):
        json_str = match.group(1) or match.group(2)
        if not json_str:
            return match.group(0)
        try:
            obj = json.loads(json_str)
            convertito = json_a_toon(obj)
            if match.group(1):
                return f'```\n{convertito}\n```'
            else:
                return f'{{{convertito}}}'
        except:
            return match.group(0)
    pattern = re.compile(r'```(?:json)?\s*(.*?)\s*```|{\s*(.*?)\s*}', re.DOTALL)
    nuovo_testo = pattern.sub(sostituisci_json, testo)
    risparmiato = len(testo) - len(nuovo_testo)
    return nuovo_testo, risparmiato

def taglia_storia(messaggi, max_caratteri):
    nuovi = [{'role': m['role'], 'content': m['content']} for m in messaggi]
    totale = sum(len(m['content']) for m in nuovi)
    if totale <= max_caratteri:
        return nuovi
    
    # Trova indici protetti: system, ultimi 4, ULTIMO USER
    system_indices = {i for i, m in enumerate(messaggi) if m['role'] == 'system'}
    ultimi_quattro = set(range(max(0, len(messaggi)-4), len(messaggi)))
    
    ultimo_utente = None
    for i in reversed(range(len(messaggi))):
        if messaggi[i]['role'] == 'user':
            ultimo_utente = i
            break
    protetti = system_indices.copy()
    if ultimo_utente is not None:
        protetti.add(ultimo_utente)
    protetti.update(ultimi_quattro)
    
    da_tagliare = [i for i in range(len(messaggi)) if i not in protetti]
    da_tagliare.sort()
    
    for i in da_tagliare:
        msg = messaggi[i]
        if totale <= max_caratteri:
            break
        originale = len(msg['content'])
        nuovi[i]['content'] = f"[tagliato: {msg['role']}, {originale} caratteri]"
        totale -= originale - len(nuovi[i]['content'])
    
    return nuovi


if __name__ == "__main__":
    # Test alleggerisci_tools
    tool_vero = {
        'name': 'test',
        'description': 'a' * 200,
        'parameters': {
            'type': 'object',
            'properties': {
                'p1': {'type': 'string', 'description': 'desc1'},
                'p2': {'type': 'int', 'description': 'desc2'}
            },
            'required': ['p1']
        }
    }
    tools_fake = [tool_vero] * 3
    ridotti, saved = alleggerisci_tools(tools_fake)
    assert saved > 40, f"Risparmiato {saved} < 40"
    print(f"Alleggerisci tools: risparmiato {saved} caratteri")

    # Test json_a_toon
    dati = [{'id': i, 'val': f'val_{i}'} for i in range(20)]
    json_str = json.dumps(dati, indent=2)
    convertito = json_a_toon(dati)
    assert len(convertito) < 0.5 * len(json_str), "Risparmio <50%"
    print("JSON a toon: risparmio >50% verificato")

    # Test taglia_storia
    storia_lunga = [{'role': 'user', 'content': 'a' * 200} for _ in range(30)]
    storia_lunga[0] = {'role': 'system', 'content': 'keep'}
    storia_cort = taglia_storia(storia_lunga, 4000)
    totale = sum(len(m['content']) for m in storia_cort)
    assert totale < 4000, f"Totale {totale} >=4000"
    assert storia_cort[0]['content'] == 'keep', 'System modificato'
    assert len(storia_cort[-4:]) == 4, "Ultimi 4 persi"
    print("Taglia storia: tutti test passati")
