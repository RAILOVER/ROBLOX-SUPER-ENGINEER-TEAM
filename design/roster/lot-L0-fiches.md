# Lot L0 : fiches (generees)

Genere par `python3 tools/gen_roster.py` depuis le brief §7.2. Les textes de competence et d'apparence servent au
Game Designer (fiche detaillee), a la DA (references) et au Tech artist (traits signature). Ne pas editer a la main.

| # | Slug | Nom | Rarete | Famille(s) | Classe | skillId | Competence | Apparence |
|---|---|---|---|---|---|---|---|---|
| 1 | `tralalero-tralala` | Tralalero Tralala | Champion | Mare | Sprinteur | `SprintTralala` | *Sprint Tralala* : 3 charges sur des cibles aléatoires en ignorant la ligne avant ; chaque coup lui donne +10 VIT jusqu'à la fin du combat | Requin gris-bleu à 3 pattes, baskets bleues sans logo |
| 2 | `tung-tung-tung-sahur` | Tung Tung Tung Sahur | Champion | Sahur | Guerrier | `TungTungTung` | *Tung ! Tung ! Tung !* : 3 coups de batte sur la même cible, le 3e étourdit 1 tour | Bûche de bois anthropomorphe tenant une batte en bois |
| 3 | `bombardiro-crocodilo` | Bombardiro Crocodilo | Champion | Cielo, Macchina | Artilleur | `TapisDeBombes` | *Tapis de bombes* : bombes cartoon sur toute une ligne ennemie (choisie en manuel ; la plus remplie en auto) | Tête de crocodile sur un corps de bombardier bimoteur à hélices |
| 4 | `ballerina-cappuccina` | Ballerina Cappuccina | Champion | Caffe | Mage | `PirouetteCappuccino` | *Pirouette Cappuccino* : tourbillon qui étourdit la colonne ennemie en face 1 tour et soigne les alliés Caffè de 15 % de leurs PV max | Ballerine en tutu rose et chaussons de pointe, tête = tasse de cappuccino |
| 5 | `poirita` | Poirita | Champion | Tentafruit (Presentatrice) | Mage | `CeremonieDElimination` | *Cérémonie d'élimination* : l'ennemi à la plus haute ATQ ou MAG quitte le combat 2 tours, puis revient avec −20 % de stats | Poire présentatrice avec micro et fiches |
| 6 | `cappuccino-assassino` | Cappuccino Assassino | Legendaire | Caffe | Assassin | `EspressoFatal` | *Espresso fatal* : se téléporte en ligne arrière et frappe la cible la plus faible (critique garanti) ; s'il met K.O., il devient Invisible 1 tour | Tasse de café ninja, deux katanas, bandeau |
| 7 | `brr-brr-patapim` | Brr Brr Patapim | Legendaire | Giungla | Colosse | `RacinesPatapim` | *Racines Patapim* : Provocation 2 tours + enracine la ligne avant ennemie (−50 % VIT) | Créature-arbre de la forêt au visage de singe à long nez, grands pieds |
| 8 | `lirili-larila` | Lirilì Larilà | Legendaire | Giungla, Cosmo | Mage | `ArretDuTemps` | *Arrêt du temps* : repousse tous les ennemis de 30 % dans la timeline. Passif : ses épines renvoient 20 % des dégâts de mêlée | Éléphant au corps de cactus, en sandales, associé à une horloge |
| 9 | `la-vacca-saturno-saturnita` | La Vacca Saturno Saturnita | Legendaire | Cosmo | Colosse | `AnneauxDeSaturne` | *Anneaux de Saturne* : bouclier de 20 % de ses PV max à tous les alliés + gravité (ennemis −15 % VIT 2 tours) | Vache dont le corps est la planète Saturne avec ses anneaux |
| 10 | `bombombini-gusini` | Bombombini Gusini | Legendaire | Cielo | Sprinteur | `PiqueSupersonique` | *Piqué supersonique* : frappe la ligne arrière ; rejoue immédiatement en cas de critique (1 fois par tour) | Oie avec des ailes d'avion de chasse |
| 11 | `girafa-celestre` | Girafa Celestre | Legendaire | Cosmo, Frutta | Artilleur | `PluieDeMeteores` | *Pluie de météores* : 5 météores sur des cibles aléatoires | Girafe au torse de pastèque, 3 pattes en bottes de cuir, casque d'astronaute |
| 12 | `cocofanto-elefanto` | Cocofanto Elefanto | Legendaire | Frutta, Giungla | Colosse | `ChargeDeCoco` | *Charge de coco* : charge la ligne avant, étourdit 1 cible, gagne un bouclier de 25 % de ses PV max | Bébé éléphant fusionné avec une noix de coco poilue |
| 13 | `chimpanzini-bananini` | Chimpanzini Bananini | Epique | Frutta, Giungla | Guerrier | `PeauDeBanane` | *Peau de banane* : coup + la cible a 50 % de chances de perdre son prochain tour. Passif *Indestructible* : survit une fois par combat à un coup fatal avec 1 PV | Chimpanzé qui sort d'une banane |
| 14 | `espressona-signora` | Espressona Signora | Epique | Caffe | Soigneur | `ShotDEspresso` | *Shot d'espresso* : soigne l'allié le plus blessé de 30 % et avance son tour de 25 % dans la timeline | Dame-espresso, sœur de Ballerina Cappuccina |
| 15 | `frigo-camelo` | Frigo Camelo | Epique | Macchina | Colosse | `SouffleGlace` | *Souffle glacé* : Ralenti sur la ligne avant ennemie 2 tours, +30 % DEF pour lui 2 tours | Chameau-réfrigérateur en bottes |
| 16 | `svinino-bombondino` | Svinino Bombondino | Epique | Macchina | Artilleur | `Kaboom` | *Kaboom !* : explose (gros dégâts de zone), tombe K.O., puis se reconstitue à 30 % de PV 2 tours plus tard (1 fois par combat) | Cochon-bombe |
| 17 | `talpa-di-ferro` | Talpa di Ferro | Epique | Macchina | Assassin | `Forage` | *Forage* : disparaît sous terre 1 tour (intouchable), puis ressort sous la ligne arrière avec un coup puissant | Taupe mécanique en fer avec foreuse |
| 18 | `bombardiere-lucertola` | Bombardiere Lucertola | Epique | Cielo, Macchina | Artilleur | `RaidEclair` | *Raid éclair* : 3 petites bombes, chacune applique Brûlure | Lézard-avion bombardier |
| 19 | `fraisita` | Fraisita | Epique | Tentafruit (Couple) | Mage | `Confessionnal` | *Confessionnal* : la cible devient Exposée (+25 % de dégâts reçus) pendant 2 tours | Fraise anthropomorphe |
| 20 | `cerisa` | Cerisa | Epique | Tentafruit (Tentation) | Assassin | `ClinDIl` | *Clin d'œil* : Charme 1 tour (la cible attaque son propre camp) | Cerise anthropomorphe |
| 21 | `citronello` | Citronello | Epique | Tentafruit (Tentation) | Mage | `Acidite` | *Acidité* : −30 % DEF et RES sur la ligne ciblée pendant 2 tours | Citron anthropomorphe |
| 22 | `bobrito-bandito` | Bobrito Bandito | Rare | Giungla | Artilleur | `RafaleDeBandit` | *Rafale de bandit* : 6 tirs sur des cibles aléatoires (projectiles stylisés cartoon) | Castor bandit, chapeau, mitraillette cartoon |
| 23 | `glorbo-fruttodrillo` | Glorbo Fruttodrillo | Rare | Mare, Frutta | Colosse | `MachoireJuteuse` | *Mâchoire juteuse* : Provocation 1 tour + morsure avec 30 % de vol de vie | Crocodile fusionné avec un fruit |
| 24 | `orangutini-ananasini` | Orangutini Ananasini | Rare | Giungla, Frutta | Guerrier | `AnanasPiquant` | *Ananas piquant* : coup + gagne Épines (renvoie 15 %) 2 tours | Orang-outan dans un ananas |
| 25 | `tigrrullini-watermellini` | Tigrrullini Watermellini | Rare | Frutta | Guerrier | `GriffesJuteuses` | *Griffes juteuses* : 2 coups, chacun applique Saignement | Tigre-pastèque |
| 26 | `bananita-dolfinita` | Bananita Dolfinita | Rare | Mare, Frutta | Soigneur | `Eclaboussure` | *Éclaboussure* : soigne toute une ligne alliée de 15 % | Dauphin dans une banane |
| 27 | `boneca-ambalabu` | Boneca Ambalabu | Rare | Mare, Macchina | Colosse | `RebondDePneu` | *Rebond de pneu* : rebondit sur 3 ennemis + Provocation 1 tour | Pneu de voiture surmonté d'une tête de ouaouaron, sur deux jambes humaines |
| 28 | `chef-crabracadabra` | Chef Crabracadabra | Rare | Mare | Mage | `RecetteMagique` | *Recette magique* : la cible est Ralentie et Exposée 2 tours | Crabe chef cuisinier magicien |
| 29 | `fraisio` | Fraisio | Rare | Tentafruit (Couple) | Guerrier | `CoupDeCur` | *Coup de cœur* : coup puissant, +25 % de dégâts si Fraisita est vivante dans son équipe | Fraise anthropomorphe |
| 30 | `litchita` | Litchita | Rare | Tentafruit (Tentation) | Mage | `ParfumDeLitchi` | *Parfum de litchi* : Endort 1 cible pendant 1 tour | Litchi anthropomorphe |
| 31 | `pasteco` | Pasteco | Rare | Tentafruit (Tentation) | Colosse | `VideurDeLaVilla` | *Videur de la villa* : Provocation 2 tours + bouclier de 20 % de ses PV max | Pastèque anthropomorphe |
| 32 | `tim-cheese` | Tim Cheese | Commune | Giungla | Sprinteur | `Grignotage` | *Grignotage* : 2 attaques rapides | Petit personnage-fromage |
| 33 | `trippi-troppi` | Trippi Troppi | Commune | Mare | Assassin | `BondDeCrevette` | *Bond de crevette* : saute en ligne arrière et frappe | Chat au corps de crevette |
| 34 | `burbaloni-luliloli` | Burbaloni Luliloli | Commune | Mare, Frutta | Soigneur | `ZenCapybara` | *Zen capybara* : retire les statuts négatifs d'un allié + petit soin | Capybara dans une noix de coco |
| 35 | `ta-ta-ta-ta-sahur` | Ta Ta Ta Ta Sahur | Commune | Sahur | Mage | `TaTaTaTa` | *Ta-ta-ta-ta !* : réveille les alliés Endormis ; 50 % de chances d'Endormir 1 ennemi 1 tour | Variante Sahur (référence obligatoire avant modélisation) |
| 36 | `banano` | Banano | Commune | Tentafruit (Couple) | Colosse | `MusclesDeLaVilla` | *Muscles de la villa* : Provocation 1 tour + bouclier léger | Banane anthropomorphe |
| 37 | `bananella` | Bananella | Commune | Tentafruit (Couple) | Artilleur | `LancerDePeau` | *Lancer de peau* : dégâts + 25 % de chances de faire glisser la cible (perd son tour) | Banane anthropomorphe |
| 38 | `pomito` | Pomito | Commune | Tentafruit (Couple) | Guerrier | `CroquePomme` | *Croque-pomme* : dégâts + se soigne de 50 % des dégâts infligés | Pomme anthropomorphe |
| 39 | `pomita` | Pomita | Commune | Tentafruit (Couple) | Soigneur | `CompoteReconfortante` | *Compote réconfortante* : soin de 25 % sur l'allié le plus blessé | Pomme anthropomorphe |
| 40 | `myrtilo` | Myrtilo | Commune | Tentafruit (Couple) | Artilleur | `GreleDeMyrtilles` | *Grêle de myrtilles* : petits dégâts sur tous les ennemis | Myrtille anthropomorphe |
| 41 | `myrtila` | Myrtila | Commune | Tentafruit (Couple) | Soigneur | `Smoothie` | *Smoothie* : petit soin + 20 Énergie à un allié | Myrtille anthropomorphe |
| 42 | `kiwina` | Kiwina | Commune | Tentafruit (Tentation) | Sprinteur | `KiwiExpress` | *Kiwi express* : joue 2 fois à son premier tour | Kiwi anthropomorphe |
