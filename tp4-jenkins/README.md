# TP4 — Pipeline Jobs Jenkins

Trois pipelines correspondent aux deux parties du TP4 :

| Fichier | Job Jenkins | Objet |
|---|---|---|
| [Jenkinsfile.hello](Jenkinsfile.hello) | `simple-pipeline` | Partie I — affiche `Hello World!` |
| [Jenkinsfile.deploy-agent](Jenkinsfile.deploy-agent) | `deploy-job` | Partie II.1 — exécution sur **Agent Jenkins** distant |
| [Jenkinsfile.deploy-sshagent](Jenkinsfile.deploy-sshagent) | `deploy-job` | Partie II.2 — **SSH direct** depuis le master (Linux) |
| [Jenkinsfile.deploy-windows](Jenkinsfile.deploy-windows) | `deploy-job` | Partie II.2 — **SSH via plink.exe** (Jenkins Windows) |

Tous créent le dossier `~/deploy_in_remote` sur la VM Vagrant définie au niveau du projet (voir [../Vagrantfile](../Vagrantfile), IP `192.168.56.10`).

---

## Partie I — `simple-pipeline`

1. Jenkins → **New Item** → nom `simple-pipeline` → type **Pipeline** → **OK**
2. Section *Pipeline* → **Pipeline script** → coller le contenu de [Jenkinsfile.hello](Jenkinsfile.hello)
3. **Save** puis **Build Now**
4. Console Output doit afficher `Hello World!`

---

## Partie II — `deploy-job`

### Option A : Agent Jenkins distant (recommandée)

Sur la VM de recette :

```bash
sudo apt update && sudo apt install -y openjdk-11-jdk
```

Dans Jenkins → **Manage Jenkins → Nodes → New Node** :
- Name : `remote-agent`
- Type : **Permanent Agent**
- Remote root directory : `/home/vagrant`
- Labels : `remote`
- Launch method : **Launch agents via SSH**
- Host : `192.168.56.10`
- Credentials : `Vagrant_ssh` (clé privée SSH)

Créer le job `deploy-job` (type Pipeline) et coller [Jenkinsfile.deploy-agent](Jenkinsfile.deploy-agent).

### Option B : SSH direct (Jenkins Linux)

1. Sur le master Jenkins : `ssh-keygen -t rsa -b 2048 -f ~/.ssh/jenkins_recette -N ""`
2. `ssh-copy-id -i ~/.ssh/jenkins_recette.pub vagrant@192.168.56.10`
3. Jenkins → Credentials → **SSH Username with private key**, ID = `Vagrant_ssh`, user = `vagrant`, clé privée = contenu de `~/.ssh/jenkins_recette`
4. Job `deploy-job` → coller [Jenkinsfile.deploy-sshagent](Jenkinsfile.deploy-sshagent)

### Option C : Jenkins Windows + plink

1. Installer PuTTY (plink.exe doit être dans le PATH du service Jenkins)
2. Première connexion manuelle pour accepter la clé hôte :
   ```powershell
   plink.exe -ssh vagrant@192.168.56.10
   ```
3. Jenkins → Credentials → **Username with password**, ID = `vagrant-cred` (user=`vagrant`, pass=`vagrant`)
4. Job `deploy-job` → coller [Jenkinsfile.deploy-windows](Jenkinsfile.deploy-windows)

---

## Vérification (commune)

Après build vert :

```bash
vagrant ssh -c "ls -la ~/deploy_in_remote && cat ~/deploy_in_remote/hello_folder.txt"
```

Sortie attendue :

```
hello_folder.txt
Dossier cree depuis Jenkins
```

## Bonnes pratiques (rappel énoncé)

- Préférer **Agent Jenkins** au SSH direct (scalable, logs centralisés)
- **Jamais** de mot de passe en clair → toujours `withCredentials` / `sshagent`
- Ajouter des `echo` pour le debug en console
