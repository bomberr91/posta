#!/bin/bash
D="[CHIAVE-RIMOSSA]"
sed -i 's/^WEB_SEARCH_ENGINE=.*/WEB_SEARCH_ENGINE=both/' "$D/.env"
echo "WEB_SEARCH_ENGINE ora: $(grep ^WEB_SEARCH_ENGINE "$D/.env")"
echo "🐕 DeepDog in doppia-ricerca (Exa + Tavily). Riavviare il bat per leggere il .env."
