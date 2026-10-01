# Ícone do BatHold

`AppIcon.png` é o arquivo mestre com transparência. O ícone combina uma bateria
verde com um símbolo de pausa, representando a manutenção do limite de carga.
Foi criado para o BatHold com a ferramenta integrada de geração de imagens;
não usa imagens ou recursos visuais do BatFi.

O script `scripts/build-icon.sh` gera os tamanhos exigidos pelo macOS e monta
`dist/BatHold.icns`. O ícone é incluído no aplicativo por `build-app.sh`.
Os arquivos convertidos ficam em `dist/` e não entram no Git. A imagem mestre
acompanha a licença MIT do projeto.

## Prompt de criação

```text
Use case: logo-brand. Asset type: original native macOS application icon for BatHold, an open source battery charge controller. Create a single polished square 1024x1024 app icon: a softly beveled rounded-square tile in deep charcoal with subtle dimensional shading, centered horizontal battery shape in luminous mint green filled about 80 percent, its remaining unfilled segment subtly visible. A small elegant pause symbol integrated into the battery's center suggests holding charge. Simple bold silhouette, refined restrained macOS icon design, crisp readable at small sizes, front view with very subtle depth, generous safe margins. Transparent background outside the rounded-square tile, preserve real alpha corners. No text, no letters, no watermark, no mockup, no extra icons, no photographic scene. This is a distinct original mark; do not reproduce BatFi's logo. Deliver only the isolated app icon.
```
