# Stack Jenkins (controller + agent SSH) avec Docker CLI

Setup complet pour exécuter les pipelines Docker du projet sans le bug `docker: not found`.

## Contenu

| Fichier | Rôle |
|---|---|
| [docker-compose.yml](docker-compose.yml) | Orchestre le controller (port 8081) + l'agent SSH (port 2223) |
| [Dockerfile.controller](Dockerfile.controller) | Jenkins LTS + Docker CLI |
| [Dockerfile.agent](Dockerfile.agent) | Jenkins SSH-agent + Docker CLI |
| [.env.example](.env.example) | Modèle pour la clé publique SSH (à copier en `.env`) |

Particularités :
- Le **socket Docker de l'hôte** (`/var/run/docker.sock`) est monté dans les deux containers → les pipelines `docker build / push` utilisent le démon Docker de Docker Desktop, pas un démon imbriqué.
- Le user `jenkins` est ajouté au groupe `docker` (GID 999).

## Démarrage

```powershell
cd tp4-jenkins\jenkins-stack
copy .env.example .env       # on remplira la cle a l'etape 3
docker compose up -d --build
```

Vérification :

```powershell
docker compose ps
docker exec tp4-jenkins-controller docker --version
docker exec tp4-jenkins-controller docker ps
```

`docker ps` depuis l'intérieur doit lister les containers de l'hôte.

## Étape 1 — Setup wizard Jenkins

1. Ouvrir <http://localhost:8081>
2. Récupérer le mot de passe initial :
   ```powershell
   docker exec tp4-jenkins-controller cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Installer les plugins suggérés
4. Créer le user admin

## Étape 2 — Installer les plugins nécessaires

Manage Jenkins → Plugins → Available :
- **SSH Build Agents**
- **SSH Agent**
- **Credentials Binding**
- **Git**
- **Pipeline** (déjà installé via suggested)

## Étape 3 — Connecter l'agent au controller

3.1. Générer une paire de clés SSH **dans le controller** :

```powershell
docker exec -u jenkins tp4-jenkins-controller ssh-keygen -t rsa -b 2048 -f /var/jenkins_home/.ssh/agent_key -N ""
```

3.2. Récupérer la **publique** et la coller dans le `.env` :

```powershell
docker exec tp4-jenkins-controller cat /var/jenkins_home/.ssh/agent_key.pub
```

Édite `.env` :

```
JENKINS_AGENT_SSH_PUBKEY=ssh-rsa AAAA... jenkins@<hostname>
```

Puis recrée l'agent pour qu'il prenne la clé :

```powershell
docker compose up -d --force-recreate jenkins-agent
```

3.3. Ajouter un **credential SSH** dans Jenkins :
- Manage Jenkins → Credentials → System → Global → Add Credentials
- Kind : **SSH Username with private key**
- ID : `jenkins-agent-key`
- Username : `jenkins`
- Private Key : **Enter directly** → coller le contenu de `agent_key` (privée) :
  ```powershell
  docker exec tp4-jenkins-controller cat /var/jenkins_home/.ssh/agent_key
  ```

3.4. Déclarer l'agent comme Node :
- Manage Jenkins → Nodes → New Node
- Name : `agent1`
- Type : **Permanent Agent**
- Remote root directory : `/home/jenkins/agent`
- Labels : `docker-agent`
- Launch method : **Launch agents via SSH**
- Host : `jenkins-agent` (nom du service docker-compose → résolu sur le réseau interne)
- Credentials : `jenkins-agent-key`
- Host Key Verification Strategy : **Non verifying Verification Strategy** (lab uniquement)
- Save → l'agent doit passer **online** en quelques secondes.

## Étape 4 — Adapter le Jenkinsfile (optionnel)

Pour faire tourner le build sur l'agent :

```groovy
pipeline {
    agent { label 'docker-agent' }
    ...
}
```

Sinon, garde `agent any` : Jenkins choisira soit le controller (built-in) soit l'agent.

## Étape 5 — Credentials pour le pipeline Angular

Toujours dans Manage Jenkins → Credentials → Add :

| ID | Type | Contenu |
|---|---|---|
| `dockerhub-credentials` | Username with password | login + token Docker Hub |
| `Vagrant_ssh` | SSH Username with private key | user `vagrant` + clé privée de l'hôte vers la VM Vagrant |

## Commandes utiles

```powershell
docker compose ps                          # statut
docker compose logs -f jenkins-controller  # logs
docker compose restart jenkins-controller  # redemarrer
docker compose down                        # arret (volumes conserves)
docker compose down -v                     # arret + suppression jenkins_home (RESET COMPLET)
```

## Dépannage

| Symptôme | Cause | Fix |
|---|---|---|
| `docker: not found` dans un pipeline | Container reconstruit sans le Dockerfile custom | `docker compose build --no-cache && docker compose up -d` |
| `permission denied /var/run/docker.sock` | GID hôte ≠ 999 | `docker exec -u root tp4-jenkins-controller chmod 666 /var/run/docker.sock` |
| Agent reste offline | Clé publique pas dans `authorized_keys` | Re-vérifier le `.env`, `docker compose up -d --force-recreate jenkins-agent` |
| Port 8081 occupé | Autre Jenkins déjà lancé | Adapter `ports:` ou arrêter l'autre stack |
