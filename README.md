----- TP – Docker Networks (Flask + MariaDB + Nginx Reverse Proxy)

- Ce TP consiste à mettre en place une infrastructure Docker organisée autour de trois services :

db : une base MariaDB
app : Flask qui interroge la base via PyMySQL
proxy : un serveur Nginx jouant le rôle de reverse proxy

L’infrastructure doit être répartie sur deux réseaux Docker différents et respecter plusieurs contraintes de sécurité réseau.

1. Récupération des sources et compréhension du projet
J’ai commencé par cloner le dépôt fourni

Ensuite, j’ai regardé l’arborescence du projet pour comprendre ce qui était déjà présent, soit un dossier app/ contenant app.py et un dossier proxy/ contenant le fichier nginx.conf

J'ai ensuite ouvert chacun des deux fichiers pour comprendre les besoins

Dans app/app.py, l’app écoute sur le port 5000

l’app récupère les variables d’environnement : DB_HOST, DB_USER, DB_PASS, DB_NAME

l’app doit être connectée au réseau où se trouve la base (précisé dans le README fournit)

Dans nginx.conf
proxy_pass http://app:5000;


J’ai compris que :

le proxy doit atteindre le conteneur app donc Nginx doit partager un réseau avec l'app


2. Analyse des contraintes de l’énoncé

L’énoncé impose :

- app et db dans backend_net, donc ils communiquent uniquement entre eux et db doit être isolée du monde extérieur (aucun port exposé).

- proxy dans frontend_net et backend_net, pour faire le lien entre l'hote et le réseau de la db

- db ne doit pas être accessible depuis l’hôte directement, donc pas de port directement joignable sur le service db (uniquement expose pour que app la voie)

- tout doit passer par le reverse proxy nginx, donc seul le proxy expose le port vers l’extérieur


3. Dockerfile

FROM python:3.11-slim
WORKDIR /app

RUN pip install Flask pymysql

COPY app.py .

CMD ["python", "app.py"]


Je me base sur :

la doc Docker (RUN pip install…)

la doc Flask (déploiement minimal)

la doc Python slim (image légère car quasiment plus de place sur le pc)

4. compose.yml

J'ai commencé par noté qu'il fallait 3 services : app, proxy et db.

Facilement, on sait que les 3 sont dans le reseau backend et seulement proxy et aussi dans front. J'ai donc commencer par ca.

Pour proxy et maria db on va chercher l'image sur le docker hub donc onn met "image :", par contre comme le flask est defini avec le Dockerfile, on met "build :".

Pour definir la partie environnement, il fallait regarder dans le app.py les variables necessaire, puis la doc web nous guide pour la facon de rediger.
meme si pas claire dutout > [‌](https://www.youtube.com/watch?v=dQw4w9WgXcQ)


Pour les aprties expose, 5000 pour flask car c'est spécifié dans le docker file, et 3306 pour mariadb parce que c'est le port ar défaut.

pour la partie port du proxy, il est exposé sur le port 80 et on le veut (arbitrairement) sur le port 8080. Pour ca on écrit 8080:80


Le volume ./proxy/nginx.conf:/etc/nginx/conf.d/default.conf sert à remplacer la configuration par défaut du conteneur nginx par le fichier nginx.conf
Ce fichier contient proxy_pass qui redirige les requêtes vers Flask

Sans ca le proxy ne redirigerait pas vers Flask



BONUS : 

Pour rendre la base inaccesible, on test d'abord de supprimer la parti port du compose, en gardant simplement les expose pour l'interconnexion avec le proxy. En effet, docker se sert de expose pour exposer les services en interne et de ports pour exposer vers l'hote. Sans les parties ports, cela devrait nous empecher d'y acceer depuis l'hote. test de joindre localhost port 3306 et c'est bien bloqué cf: BONUS


tests : 

localhost:8080 affiche bien Hello from app cf:image
ocalhost:8080/health affiche bien db reachable status ok cf:image1

Dans tout ca, la commande docker compose up -d --build a été utiliser 
