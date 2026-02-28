# Documentation – STM32 Template

Bienvenue dans la documentation du **STM32 Template**, un gabarit de projet pour microcontrôleurs STM32 **sans STM32CubeIDE**.

Le projet s'appuie sur une chaîne d'outils ouverte et reproductible :

| Brique                     | Rôle                                                                |
| -------------------------- | ------------------------------------------------------------------- |
| **Docker + Dev Container** | Environnement de développement identique pour tout le monde         |
| **STM32CubeMX**            | Génération du code d'initialisation (HAL, horloges, linker script…) |
| **CMake + Ninja**          | Système de build cross-compilé (`arm-none-eabi-gcc`)                |
| **VS Code**                | Éditeur avec extensions C/C++, Clangd, Cortex-Debug, PlantUML…      |
| **J-Link / ST-Link**       | Flash et debug sur cible                                            |

> **Cible par défaut** : STM32G431KB (carte Nucleo-G431KB), mais le système de *variants* permet de supporter d'autres MCU facilement.

---

## Sommaire de la documentation

| #   | Document                                     | Description                                                         |
| --- | -------------------------------------------- | ------------------------------------------------------------------- |
| 1   | [Installation](01-installation.md)           | Installer WSL, Docker, VS Code, les extensions, et ouvrir le projet |
| 2   | [Utilisation](02-utilisation.md)             | Compiler, flasher, débugger, modifier la config CubeMX              |
| 3   | [Architecture](03-architecture.md)           | Structure du projet, flux CMake, intégration CubeMX                 |
| 4   | [Ajouter une cible](04-ajouter-une-cible.md) | Supporter un nouveau MCU / une nouvelle carte                       |
| 5   | [FAQ & Dépannage](05-faq.md)                 | Problèmes courants et solutions                                     |

---

## Pré-requis en un coup d'œil

- **Système hôte** : Windows 10/11, macOS ou Linux
- **RAM** : 8 Go minimum (16 Go recommandé)
- **Espace disque** : ~10 Go (image Docker ≈ 6 Go)
- **Connexion Internet** : Nécessaire pour le premier `docker pull`

---

## Liens rapides

- [STM32CubeMX](https://www.st.com/en/development-tools/stm32cubemx.html)
- [arm-none-eabi-gcc](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain)
- [CMake](https://cmake.org/documentation/)
- [Ninja](https://ninja-build.org/)
- [VS Code](https://code.visualstudio.com/)
- [Dev Containers](https://containers.dev/)
- [Docker](https://docs.docker.com/)

---

*Dernière mise à jour : février 2026*
