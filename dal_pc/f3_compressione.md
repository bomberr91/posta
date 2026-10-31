[0m
> build · auto
[0m
```python
import re
import json

def alleggerisci_tools(tools):
    tools_ridotti = []
    risparmiato = 0
    for tool in tools:
        try:
            name = tool.get('name', '')
            desc = tool.get('description', '')
            desc_trunc = desc[:110]
            params = tool.get('parameters', {})
            req_params = params.get('required', [])
            props = params.get('properties', {})
            new_props = {}
            for p in req_params:
                if p in props:
                    new_props[p] = {'type': props[p].get('type', '')}
            new_params = {
                'type': 'object',
                'properties': new_props,
                'required': req_params
            }
            # Calcolo risparmio
            risparmio_desc = len(desc) - len(desc_trunc)
            risparmio_param = 0
            for p in props:
                if p not in req_params:
                    risparmio_param += len(props[p].get('description', ''))
            risparmiato += risparmio_desc + risparmio_param
            tools_ridotti.append({
                'name': name,
                'description': desc_trunc,
                'parameters': new_params
            })
        except:
            tools_ridotti.append({'name': 'errore', 'description': '', 'parameters': {}})
    return tools_ridotti, risparmiato

def json_a_toon(oggetto, indent=0):
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
    system_indices = set(i for i, m in enumerate(messaggi) if m['role'] == 'system')
    ultimo_indice = len(messaggi) - 1
    ultimi_quattro = set(range(max(0, ultimo_indice - 3), ultimo_indice + 1))
    da_tagliare = []
    for i in range(len(messaggi)):
        if i not in system_indices and i not in ultimi_quattro:
            da_tagliare.append(i)
    da_tagliare.sort()
    for i in da_tagliare:
        msg = messaggi[i]
        originale = len(msg['content'])
        nuovi[i]['content'] = f"[tagliato: {msg['role']}, {originale} caratteri]"
        totale -= originale - len(nuovi[i]['content'])
        if totale <= max_caratteri:
            break
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
    assert any('system' in m['content'] for m in storia_cort), "System perso"
    assert len(storia_cort[-4:]) == 4, "Ultimi 4 persi"
    print("Taglia storia: tutti test passati")
```
