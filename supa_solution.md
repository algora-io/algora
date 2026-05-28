**Livrable complet : Support request**

**Titre :** Manuelle attribution de PR pour @PTHAICAP

**Plateforme :** Algora

**Valeur :** 250 USDC

**Description :**

Bonjour Équipe Algora,

Je vous écris pour demander votre aide dans la manuelle attribution de 4 requêtes de paiement (PR) bloquées sur GitHub. Malgré mes tentatives pour commenter ces bounties, elles ont été cachées par l'anti-spam de GitHub et ne sont pas plus visibles que si elles n'existaient pas.

Pour résoudre ce problème, je demande que vous attribuiez manuellement ces PRs à mon compte Algora @PTHAICAP.

**Informations sur les bounties bloquées :**

| Numéro de l'issue | Lien du PR | Montant |
| --- | --- | --- |
| #59 | https://github.com/outerbase/starbasedb/pull/249 | 250 USDC |
| #72 | https://github.com/outerbase/starbasedb/pull/250 | 250 USDC |
| #5756 | https://github.com/calcom/cal.diy/pull/5756 | 250 USDC |

**Méthode de résolution :**

Pour résoudre ce problème, je vous demande de suivre les étapes suivantes :

1. Se connecter à votre compte Algora.
2. Sélectionner le token d'accès pour l'application "GitHub".
3. Se rendre sur la page des bounties bloquées et sélectionner les 4 requêtes mentionnées ci-dessus.
4. Cliquez sur l'option "Attribuer manuellement" et entrez mon nom (@PTHAICAP) dans le champ de commentaire.
5. Confirmez la modification pour attribuer correctement les PRs à mon compte.

**Conclusion :**

Je vous remercie d'avance pour votre aide et votre rapidité dans résoudre ce problème. Si vous avez besoin d'informations supplémentaires ou si vous avez des questions, n'hésitez pas à me contacter.

Cordialement,

[Votre nom]

**Script de réclamation :**

```bash
# Réclamer l'attribution manuelle de PR sur GitHub pour @PTHAICAP

curl -X POST \
  https://api.github.com/repos/outerbase/starbasedb/pulls/249/comments \
  -H 'Authorization: Bearer <TOKEN_DE_GITHUB>' \
  -H 'Content-Type: application/json' \
  -d '{"body": " Attribution manuelle pour @PTHAICAP", "user": {"login": "@PTHAICAP"}}'

curl -X POST \
  https://api.github.com/repos/outerbase/starbasedb/pulls/250/comments \
  -H 'Authorization: Bearer <TOKEN_DE_GITHUB>' \
  -H 'Content-Type: application/json' \
  -d '{"body": " Attribution manuelle pour @PTHAICAP", "user": {"login": "@PTHAICAP"}}'

curl -X POST \
  https://api.github.com/repos/calcom/cal.diy/pulls/5756/comments \
  -H 'Authorization: Bearer <TOKEN_DE_GITHUB>' \
  -H 'Content-Type: application/json' \
  -d '{"body": " Attribution manuelle pour @PTHAICAP", "user": {"login": "@PTHAICAP"}}'
```

Remplacez `<TOKEN_DE_GITHUB>` par votre token d'accès pour l'application "GitHub".