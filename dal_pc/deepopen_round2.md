# DeepOpen round 2 — firme vere: 00:04
firma predict : (state: Union[str, dict, list], questions: Dict[str, Any], model: Optional[str] = None, task: Optional[str] = None, lang: Optional[str] = None) -> Dict[str, Any]
firma route : (state: Union[str, dict, list, NoneType], questions: Optional[Dict[str, Any]] = None, model: Optional[str] = None, task: Optional[str] = None, lang: Optional[str] = None) -> deepopen.router.RouteDecision
firma system_one : (state: Union[str, dict, list], questions: Dict[str, Any], model: Optional[str] = None, task: Optional[str] = None, lang: Optional[str] = None) -> Dict[str, Any]
  predict domanda_opzioni → Router.predict() got an unexpected keyword argument 'options'
Fetching 5 files:   0%|          | 0/5 [00:00<?, ?it/s]Fetching 5 files:  20%|██        | 1/5 [00:00<00:00,  4.75it/s]Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
Fetching 5 files:  80%|████████  | 4/5 [00:25<00:06,  6.79s/it]Fetching 5 files: 100%|██████████| 5/5 [10:04<00:00, 166.22s/it]Fetching 5 files: 100%|██████████| 5/5 [10:04<00:00, 120.87s/it]
  predict solo_testo → 'list' object has no attribute 'keys'
  predict kw → Router.predict() got an unexpected keyword argument 'question'
  route domanda_opzioni → Router.route() got an unexpected keyword argument 'options'
FUNZIONA: route stile solo_testo → RouteDecision(model='multilingual', reason="Latin script but language looks like 'es', not English") (0 ms)
  ✗ [scrivi una funzione python che ordina ] atteso=code → RouteDecision(model='multilingual', reason="Latin script but language  (0ms)
  ✗ [ciao come stai oggi?] atteso=chat → RouteDecision(model='english', reason='English Latin text') (0ms)
  ✗ [analizza pro e contro di questi 3 prov] atteso=analisi → RouteDecision(model='english', reason='English Latin text') (0ms)
  ✗ [cerca informazioni aggiornate sul mete] atteso=ricerca → RouteDecision(model='english', reason='English Latin text') (0ms)
  ✗ [correggi questo errore: TypeError at l] atteso=code → RouteDecision(model='english', reason='English Latin text') (0ms)
  ✗ [raccontami una barzelletta] atteso=chat → RouteDecision(model='english', reason='English Latin text') (0ms)
  ✗ [confronta i costi di LiteLLM e Portkey] atteso=analisi → RouteDecision(model='english', reason='English Latin text') (0ms)
  ✗ [trova la documentazione ufficiale di F] atteso=ricerca → RouteDecision(model='english', reason='English Latin text') (0ms)

VERDETTO GREZZO: 0/8 corrette · mediana 0 ms · max 0 ms su CPU
