# 5 – FAQ & Dépannage

Problèmes courants et solutions.

---

## Table des matières

1. [Installation](#installation)
2. [Compilation](#compilation)
3. [Flash & Debug](#flash--debug)
4. [CubeMX](#cubemx)
5. [Dev Container](#dev-container)
6. [USB / WSL](#usb--wsl)

---

## Installation

### « Docker daemon is not running »

**Cause** : Docker Desktop n'est pas lancé.

**Solution** :
- Windows / macOS : lancez Docker Desktop depuis le menu Démarrer
- Linux : `sudo systemctl start docker`

---

### « Permission denied » avec Docker (Linux)

**Cause** : l'utilisateur n'est pas dans le groupe `docker`.

**Solution** :

```bash
sudo usermod -aG docker $USER
# Déconnectez-vous puis reconnectez-vous (ou redémarrez)
```

---

### WSL : « WslRegisterDistribution failed with error 0x80370102 »

**Cause** : la virtualisation n'est pas activée dans le BIOS.

**Solution** :
1. Redémarrez et entrez dans le BIOS (touche F2, DEL, ou F10 selon le PC)
2. Activez **Intel VT-x** ou **AMD-V** (souvent dans les options CPU/Advanced)
3. Sauvegardez et redémarrez

---

## Compilation

### « arm-none-eabi-gcc: command not found »

**Cause** : vous n'êtes pas dans le Dev Container.

**Solution** : ouvrez le projet dans le conteneur (`Ctrl+Shift+P` → « Dev Containers: Reopen in Container »).

---

### « CubeMX generation failed » / Timeout

**Cause** : CubeMX tente de se connecter à Internet pour mettre à jour (bloqué dans le conteneur).

**Solution** :

```bash
# Nettoyer le build et reconfigurer
rm -rf build/template_g431
cmake --preset template_g431
```

Si le problème persiste, vérifiez que CubeMX est fonctionnel :

```bash
echo "exit" > /tmp/test.txt
xvfb-run -a STM32CubeMX -q /tmp/test.txt
```

---

### « No linker script found »

**Cause** : CubeMX n'a pas généré le fichier `.ld`.

**Solution** :
1. Vérifiez que le fichier `.ioc` est correct : `cat src/bsp/template_g431/template_g431.ioc | head`
2. Nettoyez et régénérez :
   ```bash
   rm -rf build/template_g431
   cmake --preset template_g431
   ```

---

### Les warnings « -Wconversion » sont trop stricts

**Cause** : le projet utilise des warnings stricts par défaut (c'est voulu !).

**Solution** : corrigez votre code avec des casts explicites :

```c
// ❌ Warning: implicit conversion
uint8_t x = some_uint32;

// ✅ Correct
uint8_t x = (uint8_t)some_uint32;
```

> Les warnings stricts forment de bonnes habitudes. Ne les désactivez pas !

---

## Flash & Debug

### « No ST-Link detected » / « Target not found »

**Vérifications** :
1. La sonde est bien branchée physiquement
2. Windows : avez-vous fait `usbipd attach` ? (voir [guide USB](01-installation.md#8-usb-passthrough-windows--usbipd))
3. Vérifiez la détection : `lsusb | grep -i st` (doit afficher le ST-Link)
4. Le conteneur a accès à `/dev` : vérifiez dans `devcontainer.json`

---

### « Error connecting to target » en debug

**Causes possibles** :
- La carte n'est pas alimentée
- Le câble USB est un câble de charge uniquement (pas de données)
- Un autre processus utilise déjà le debug (fermez d'autres sessions GDB)

---

## CubeMX

### Comment ouvrir l'interface graphique de CubeMX ?

CubeMX est un outil Java avec interface graphique. Dans le conteneur, Xvfb est installé pour l'exécution headless. Pour l'interface graphique, vous avez deux options :

1. **Depuis votre machine hôte** : installez CubeMX localement, modifiez le `.ioc`, puis copiez-le dans `src/bsp/`
2. **X11 forwarding** : configurez X11 forwarding dans votre conteneur (avancé)

---

### Puis-je utiliser STM32CubeIDE pour créer le .ioc ?

Oui ! Vous pouvez créer le `.ioc` avec n'importe quel outil (CubeMX standalone, CubeIDE, etc.). Assurez-vous juste de :
- Régler le toolchain sur **Makefile**
- Copier uniquement le `.ioc` dans `src/bsp/`

---

## Dev Container

### Le conteneur met longtemps à démarrer la première fois

**Normal** : l'image Docker fait ~6 Go et doit être téléchargée. Les démarrages suivants seront rapides.

---

### Comment mettre à jour l'image Docker ?

```bash
docker pull ghcr.io/cmenard001/stm32template:dev
```

Puis rouvrez le conteneur dans VS Code.

---

### Puis-je ajouter mes propres outils au conteneur ?

Oui, deux options :

1. **Temporaire** : installez via `sudo apt install ...` dans le terminal du conteneur (perdu au redémarrage)
2. **Permanent** : modifiez le `Dockerfile`, rebuilder l'image, et mettez à jour le `devcontainer.json`

---

## USB / WSL

### « usbipd: command not found » (Windows)

**Cause** : usbipd-win n'est pas installé.

**Solution** :

```powershell
winget install usbipd
```

Ou téléchargez depuis <https://github.com/dorssel/usbipd-win/releases>.

---

### Le périphérique USB n'apparaît plus après débranchement

**Normal** : la commande `usbipd attach` doit être relancée à chaque branchement :

```powershell
usbipd attach --wsl --busid <BUSID>
```

> 💡 Vous pouvez automatiser cela avec `usbipd attach --auto-attach --wsl --busid <BUSID>`.

---

### « /dev/ttyACM0: Permission denied »

**Solution** :

```bash
sudo chmod 666 /dev/ttyACM0
# Ou ajoutez votre utilisateur au groupe dialout
sudo usermod -aG dialout $USER
```

---

## Toujours bloqué ?

1. Lisez les logs du conteneur : `Ctrl+Shift+P` → « Dev Containers: Show Container Log »
2. Vérifiez les erreurs CMake : relancez avec `cmake --preset template_g431 --log-level=VERBOSE`
3. Demandez à votre prof (c'est pour ça qu'ils sont là !)

---

⬅️ **Retour** : [Sommaire de la documentation](README.md)
