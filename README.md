# STM32 Template

Template de projet pour microcontrôleurs **STM32** avec une approche **sans STM32CubeIDE** : Dev Container Docker, STM32CubeMX, CMake + Ninja, VS Code.

Cible par défaut : **STM32G431KB** (Nucleo-G431KB) — facilement adaptable à d'autres MCU.

## Démarrage rapide

```bash
# 1. Cloner le dépôt
git clone <URL_DU_DEPOT> && cd stm32template

# 2. Ouvrir dans VS Code → "Reopen in Container"

# 3. Compiler
cmake --preset template_g431
cmake --build build/template_g431
```

## Documentation

La documentation complète se trouve dans le dossier [`docs/`](docs/README.md) :

1. [Installation](docs/01-installation.md) — WSL, Docker, VS Code, extensions, USB
2. [Utilisation](docs/02-utilisation.md) — Compiler, flasher, débugger
3. [Architecture](docs/03-architecture.md) — Structure du projet, CMake, CubeMX
4. [Ajouter une cible](docs/04-ajouter-une-cible.md) — Supporter un nouveau MCU
5. [FAQ & Dépannage](docs/05-faq.md) — Problèmes courants

## Licence

[MIT](LICENSE) — Cyprien Ménard, 2026
