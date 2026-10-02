# Economie: <Nom du jeu>

## Monnaies

| Monnaie | Type | Source principale | Sink principal | Robux ? |
|---------|------|-------------------|----------------|---------|
| Coins | soft | boucle core | boutique | non |
| Gems | hard | Developer Product | accelerations | oui |

## Sources et sinks (chaque source a un sink)

| Flux | Montant / min de jeu | Evenement AnalyticsService | SKU |
|------|----------------------|----------------------------|-----|

## Game Passes (achat unique, permanent)

| Nom | Prix Robux | Effet | Verification serveur |
|-----|------------|-------|----------------------|

## Developer Products (consommables)

| Nom | Prix Robux | Effet | Idempotence ProcessReceipt |
|-----|------------|-------|----------------------------|

## Courbes

Formules explicites, tracees dans un tableur ou un script, jamais "a l'oeil".

## Garde-fous

- Aucun objet aleatoire payant sans verification `PolicyService` et alternative deterministe.
- Prix lus cote serveur uniquement (`src/shared/Config/Economy.luau` est un miroir d'affichage).
- Pas de dark pattern: pas de fausse rarete, pas d'odds caches.

## Sante economique (lue par 10-analyste-liveops)

Ratio sink/source cible, inflation toleree, concentration des depenses.
