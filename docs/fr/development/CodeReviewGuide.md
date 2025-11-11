# Guide de Code Review

> Ceci fait partie des choses que j'ai apprise durant mon expérience. En voulant cherchant à comprendre que chaque humain est différent et donc la review devait prendre en compte ce détail. Ce cheminement a été construit via des feedbacks constructifs et collaboratifs venant des Developpeurs, de CTO, de Managers, des personnes de l'équipe produit et articles.

## Table des matières

- [Philosophie](#philosophie)
- [Rôles et responsabilités](#rôles-et-responsabilités)
- [Avant de soumettre une PR](#avant-de-soumettre-une-pr)
- [Checklist du reviewer](#checklist-du-reviewer)
- [Comment commenter](#comment-commenter)
- [Répondre aux commentaires](#répondre-aux-commentaires)
- [Les différents types de commentaires](#les-différents-types-de-commentaires)
- [Red flags](#red-flags)
- [Best practices](#best-practices)
- [Ressources](#ressources)

## Philosophie

### Objectifs d'une code review

1. 🎯 **Qualité** : Détecter les bugs et améliorer la maintenabilité
2. 📚 **Partage de connaissance** : Diffuser les bonnes pratiques
3. 🤝 **Cohérence** : Maintenir un standard commun dans la codebase
4. 🧠 **Apprentissage** : Grandir collectivement en tant qu'équipe

### Principes fondamentaux

> **Critiquer le code, pas le développeur**

- Restez bienveillant et constructif
- Posez des questions plutôt que d'imposer
- Expliquez le "pourquoi" de vos suggestions
- Reconnaissez le bon travail

## Rôles et responsabilités

### 👨‍💻 L'auteur (développeur)

**Avant la PR :**

- Tester localement son code
- Exécuter les linters et tests
- Faire une auto-review de son code
- Rédiger une description claire

**Pendant la review :**

- Répondre aux questions rapidement
- Être ouvert aux suggestions
- Expliquer les choix techniques
- Ne pas prendre les critiques personnellement

### 👀 Le reviewer

**Pendant la review :**

- Comprendre le contexte avant de commenter
- Être constructif et proposer des solutions
- Distinguer les bloquants des suggestions
- Approuver rapidement si tout est OK

**Après la review :**

- Re-vérifier les modifications demandées
- Valider ou continuer la discussion

## Avant de soumettre une PR

### ✅ Auto-checklist

```bash
# 1. Vérifier que les tests passent
php bin/phpunit

# 2. Vérifier PHPStan
vendor/bin/phpstan analyse

# 3. Formater le code
vendor/bin/php-cs-fixer fix

# 4. Vérifier qu'il n'y a pas de code debug
grep -r "dump\|dd\|var_dump" src/

# 5. Vérifier les migrations
php bin/console doctrine:schema:validate
```

### 📝 Description de la PR

**Template recommandé :**

```markdown
## 🎯 Objectif

Implémenter le système de notifications par email pour les commandes.

## 🔧 Changements

- Ajout d'un `OrderPlacedEvent` et son listener
- Création du service `OrderNotificationService`
- Templates email Twig pour confirmation de commande
- Tests unitaires et fonctionnels

## 🧪 Comment tester

1. Créer une commande via l'API : `POST /api/orders`
2. Vérifier la réception de l'email de confirmation
3. Vérifier les logs : `tail -f var/log/dev.log`

## 📸 Screenshots (si applicable)

[Image de l'email reçu]

## ⚠️ Breaking changes

Aucun

## 📚 Documentation

- [ ] README mis à jour
- [ ] Documentation API mise à jour
- [x] Docblocks ajoutés

## ✅ Checklist

- [x] Tests ajoutés
- [x] PHPStan niveau 8 passe
- [x] Code formaté
- [x] Auto-review effectuée
```

### 🔍 Auto-review

Avant de soumettre, faites votre propre review :

1. Lisez chaque ligne comme si c'était du code d'un collègue
2. Vérifiez les noms de variables/méthodes
3. Cherchez la duplication de code
4. Vérifiez la cohérence avec l'existant
5. Assurez-vous que les commentaires sont utiles

## Checklist du reviewer

### 1️⃣ Vue d'ensemble (5 min)

- [ ] La PR a-t-elle une description claire ?
- [ ] La taille est-elle raisonnable ? (< 400 lignes idéalement)
- [ ] Le titre de la PR est-il explicite ?
- [ ] Les tests sont-ils inclus ?

### 2️⃣ Architecture & Design (10-15 min)

- [ ] Le code respecte-t-il les principes SOLID ?
- [ ] Y a-t-il de la duplication ?
- [ ] Les abstractions sont-elles appropriées ?
- [ ] Les responsabilités sont-elles bien séparées ?
- [ ] Le code suit-il les patterns existants ?

### 3️⃣ Code Quality (15-20 min)

- [ ] Les noms sont-ils explicites et cohérents ?
- [ ] Les méthodes sont-elles courtes et focalisées ?
- [ ] Y a-t-il des "code smells" évidents ?
- [ ] Les commentaires sont-ils utiles ou redondants ?
- [ ] Le code gère-t-il les cas d'erreur ?

### 4️⃣ Tests (10 min)

- [ ] Les tests couvrent-ils les cas importants ?
- [ ] Les tests sont-ils lisibles ?
- [ ] Y a-t-il des tests pour les cas d'erreur ?
- [ ] Les tests sont-ils indépendants ?

### 5️⃣ Sécurité (5-10 min)

- [ ] Les entrées utilisateur sont-elles validées ?
- [ ] Les données sensibles sont-elles protégées ?
- [ ] Y a-t-il des risques d'injection SQL ?
- [ ] Les autorisations sont-elles vérifiées ?

### 6️⃣ Performance (5 min)

- [ ] Y a-t-il des requêtes N+1 ?
- [ ] Les boucles sont-elles optimisées ?
- [ ] Le cache est-il utilisé quand approprié ?
- [ ] Les requêtes DB sont-elles indexées ?

## Comment commenter

### ✅ Bon commentaire

```
❓ Question : Pourquoi utiliser un tableau ici plutôt qu'un objet Collection ?
Je me demande si ça ne poserait pas de problèmes de performance avec beaucoup d'éléments.

💡 Suggestion : On pourrait utiliser `ArrayCollection` de Doctrine pour avoir
les méthodes de filtrage out-of-the-box.

Qu'en penses-tu ?
```

**Pourquoi c'est bon :**

- Commence par une question
- Explique le raisonnement
- Propose une alternative concrète
- Invite à la discussion

### ❌ Mauvais commentaire

```
C'est faux, il faut utiliser ArrayCollection.
```

**Pourquoi c'est mauvais :**

- Ton autoritaire
- Pas d'explication
- Pas d'alternative
- Pas constructif

### Types de préfixes recommandés

```
🔴 BLOQUANT : [explication du problème critique]
⚠️  IMPORTANT : [problème à corriger avant merge]
💡 SUGGESTION : [amélioration possible mais pas obligatoire]
❓ QUESTION : [demande de clarification]
🎓 APPRENTISSAGE : [partage de connaissance]
✨ COMPLIMENT : [ce qui est bien fait]
🔍 NITPICK : [détail mineur, style, typo]
```

## Répondre aux commentaires

### ✅ Bonnes réponses

```markdown
# Accepter une suggestion

✅ Bonne idée ! J'ai appliqué ta suggestion dans le commit abc123

# Désaccord constructif

🤔 Je comprends ton point, mais j'ai choisi cette approche car [raison].
Qu'en penses-tu si on fait [alternative] ?

# Demander de l'aide

🆘 Je ne suis pas sûr de comprendre. Tu peux me donner un exemple ?

# Clarification

💬 L'objectif ici était de [explication]. J'ai ajouté un commentaire
pour clarifier.
```

### ❌ Mauvaises réponses

```markdown
# Défensif

Non, c'est correct comme ça.

# Passif-agressif

Ok, je change même si je pense que c'était mieux avant.

# Ignorer

[Pas de réponse]
```

## Les différents types de commentaires

### 1. Bloquants 🔴

Problèmes qui **doivent** être résolus avant le merge.

```
🔴 BLOQUANT : Cette méthode peut exposer des données sensibles.
Le mot de passe de l'utilisateur est retourné dans la réponse JSON.

Il faut utiliser un DTO ou des groupes de sérialisation pour exclure
le champ `password`.
```

### 2. Importants ⚠️

Problèmes sérieux mais qui peuvent être discutés.

```
⚠️ IMPORTANT : Cette requête va créer un problème N+1.
Avec 1000 commandes, ça va générer 1001 requêtes SQL.

Suggestion : Utiliser un JOIN ou eager loading :
$qb->leftJoin('o.customer', 'c')->addSelect('c')
```

### 3. Suggestions 💡

Améliorations possibles mais pas obligatoires.

```
💡 SUGGESTION : On pourrait extraire cette logique dans une méthode
dédiée pour améliorer la lisibilité :

private function isEligibleForDiscount(Order $order): bool
{
    return $order->getTotal() > 100
        && $order->getCustomer()->isPremium();
}
```

### 4. Questions ❓

Demandes de clarification.

```
❓ QUESTION : Pourquoi utiliser un flush() dans une boucle ?
Est-ce qu'on ne pourrait pas flusher une seule fois à la fin ?
```

### 5. Apprentissage 🎓

Partage de connaissance.

```
🎓 APPRENTISSAGE : Petite astuce, depuis Symfony 6.3 on peut utiliser
le `MapRequestPayload` qui fait la validation automatiquement :

public function create(
    #[MapRequestPayload] CreateOrderDTO $dto
): Response { }
```

### 6. Compliments ✨

Reconnaître le bon travail.

```
✨ COMPLIMENT : Super clean cette séparation de responsabilités !
L'utilisation du pattern Strategy ici est vraiment appropriée.
```

### 7. Nitpick 🔍

Détails mineurs, style, typos.

```
🔍 NITPICK : Petite typo dans le nom de la variable :
`$cutsomer` → `$customer`
```

## Red flags

### 🚨 Alertes critiques

1. **Données sensibles exposées**

   ```php
   // ❌ Danger
   return $this->json($user); // Retourne le mot de passe !
   ```

2. **Injections SQL**

   ```php
   // ❌ Danger
   $sql = "SELECT * FROM users WHERE id = " . $id;
   ```

3. **Credentials en dur**

   ```php
   // ❌ Danger
   $apiKey = "sk_live_123456789";
   ```

4. **Pas de validation d'autorisation**

   ```php
   // ❌ Danger
   public function delete(int $id): Response
   {
       $order = $this->orderRepository->find($id);
       $this->em->remove($order); // N'importe qui peut supprimer !
   }
   ```

5. **Tests qui passent toujours**
   ```php
   // ❌ Inutile
   public function testSomething(): void
   {
       $this->assertTrue(true);
   }
   ```

### ⚠️ Code smells sérieux

1. **Méthodes > 50 lignes**
2. **Classes > 500 lignes**
3. **Duplication évidente**
4. **Magic numbers partout**
5. **Pas de gestion d'erreurs**
6. **Tests manquants pour logique critique**

## Best practices

### Pour l'auteur

#### ✅ Faire

- **PR de taille raisonnable** : < 400 lignes si possible
- **Un seul objectif par PR** : Ne pas mélanger refactoring et feature
- **Commits atomiques** : Chaque commit compile et les tests passent
- **Messages de commit clairs** : `feat: add email notifications for orders`
- **Répondre rapidement** : < 24h idéalement
- **Être ouvert** : Accepter les critiques constructivement

#### ❌ Éviter

- PR de 2000+ lignes
- Mélanger 5 fonctionnalités différentes
- Ne pas tester avant de submit
- Ignorer les commentaires
- Se vexer des critiques

### Pour le reviewer

#### ✅ Faire

- **Review dans les 24h** : Ne pas bloquer l'équipe
- **Commencer par le positif** : Souligner ce qui est bien
- **Être spécifique** : Donner des exemples concrets
- **Proposer des solutions** : Ne pas juste critiquer
- **Apprendre aussi** : C'est une opportunité d'apprentissage
- **Approuver rapidement** : Si tout est OK, ne pas tarder

#### ❌ Éviter

- Laisser traîner les reviews pendant des jours
- Commentaires vagues : "C'est pas bien"
- Imposer son style personnel
- Chercher la perfection absolue
- Être condescendant

### Durée recommandée

- **Petite PR (< 200 lignes)** : 15-30 min
- **Moyenne PR (200-400 lignes)** : 30-60 min
- **Grande PR (> 400 lignes)** : Demander de split

Si ça prend plus d'1h, c'est que la PR est trop grosse.

## Exemple de review complète

````markdown
## Vue d'ensemble

✨ Bon travail sur cette feature ! L'architecture générale est solide
et les tests sont bien présents.

J'ai quelques suggestions pour améliorer la maintenabilité.

---

### src/Service/OrderService.php:42

💡 SUGGESTION : Cette méthode fait beaucoup de choses. On pourrait
extraire la logique de calcul :

```php
public function placeOrder(PlaceOrderCommand $command): Order
{
    $order = $this->createOrder($command);
    $this->applyDiscounts($order);
    $this->persistOrder($order);
    $this->notifyCustomer($order);

    return $order;
}

private function applyDiscounts(Order $order): void
{
    // Logique de discount
}
```
````

Qu'en penses-tu ?

---

### src/Repository/OrderRepository.php:28

⚠️ IMPORTANT : Cette requête va créer un N+1 problem.

```php
// Actuel
public function findWithItems(): array
{
    return $this->findAll(); // Items chargés ensuite
}

// Suggestion
public function findWithItems(): array
{
    return $this->createQueryBuilder('o')
        ->leftJoin('o.items', 'i')
        ->addSelect('i')
        ->getQuery()
        ->getResult();
}
```

---

### tests/Service/OrderServiceTest.php:15

❓ QUESTION : Pourquoi mocker le repository ici plutôt que d'utiliser
le vrai repository avec une base de test ?

Ça rendrait le test plus proche de la réalité.

---

### src/Entity/Order.php:89

🎓 APPRENTISSAGE : Depuis Doctrine 2.15, on peut utiliser les typed
properties directement :

```php
#[ORM\Column]
private \DateTimeImmutable $createdAt;
```

Plus besoin de `type: 'datetime_immutable'`

---

### src/Controller/OrderController.php:34

✨ COMPLIMENT : Super utilisation du DTO pattern ici ! C'est exactement
ce qu'il faut faire.

---

### README.md:12

🔍 NITPICK : Petite typo "commande" → "commandes"

---

## Verdict

Une fois les points ⚠️ IMPORTANT corrigés, je pourrai approuver.
Les 💡 SUGGESTIONS sont optionnelles mais amélioreraient le code.

Bon boulot ! 👍

```

## Ressources
- 📚 [Google Engineering Practices - Code Review](https://google.github.io/eng-practices/review/)
- 📚 [Conventional Comments](https://conventionalcomments.org/)
- 📚 [How to Make Your Code Reviewer Fall in Love with You](https://mtlynch.io/code-review-love/)
```
