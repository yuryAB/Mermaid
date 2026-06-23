# MapEditor

Editor macOS para desenhar terreno do Mermaid usando autotile.

## Abrir

Abra o workspace:

```sh
open Mermaid.xcworkspace
```

Depois selecione o scheme `MapEditor`.

## Uso

- `Brush`: pinta terreno.
- `Eraser`: apaga terreno.
- `Size`: muda tamanho do pincel.
- `Zoom`: aproxima ou afasta o canvas.
- `Shuffle`: troca a variacao deterministica dos tiles compativeis.
- `Save`: salva o mapa da profundidade atual em `SharedGameData/Maps/<depth>.json`.
- `Load`: salva alteracoes pendentes e recarrega o mapa salvo.
- `Clear`: limpa o terreno atual.
- `Unsaved`: aparece quando ha pintura ainda nao salva.

Ao trocar de profundidade, o editor salva automaticamente a profundidade anterior quando houver alteracoes pendentes.

Atalhos:

- `Command-Z`: desfazer stroke.
- `Command-Shift-Z`: refazer stroke.
- `Command-S`: salvar.
- `Command-O`: carregar.

## Autotile

O editor salva terreno como celulas ocupadas. Ele nao salva cada tile visual escolhido.

Ao renderizar, o MapEditor calcula:

- `connectionMask`: vizinhos cardinais (`N=1`, `E=2`, `S=4`, `W=8`).
- `innerCornerMask`: cantos internos quando ha vizinhos cardinais mas a diagonal esta vazia.
- `variationSeed`: variacao deterministica para escolher entre tiles compativeis.

Assim, quando uma celula e pintada ou apagada, os tiles ao redor se ajustam automaticamente.

## Dados

- Tiles: `../SharedGameData/Tiles/Mossy/terrain-256/`
- Mapas: `../SharedGameData/Maps/`
- Mapa inicial: `../SharedGameData/Maps/recife_tropical.json`

## Verificacao Leve

Sem rodar build, estes comandos verificam a estrutura:

```sh
python3 Tools/verify_mossy_autotile.py
xcrun swiftc -typecheck -target arm64-apple-macosx14.0 MapEditor/MapEditor/*.swift
git diff --check MapEditor SharedGameData Mermaid.xcworkspace Tools
```
