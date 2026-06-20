# SharedGameData

Pasta de dados compartilhados entre `MapEditor` e `Ester`.

- `Tiles/`: PNGs recortados, organizados por ID estavel.
- `Maps/`: mapas exportados pelo editor em JSON.
- `Licenses/`: licencas, creditos e URLs dos pacotes externos.

O editor deve escrever aqui durante desenvolvimento. O jogo deve ler/copiar estes dados como fonte de verdade.

`Maps/birth_waters.json` e um mapa inicial pequeno para abrir o editor ja com terreno desenhado.

## Verificacao

Rode:

```sh
python3 Tools/verify_mossy_autotile.py
```

Esse script valida se o manifest Mossy aponta para PNGs `256x256`, se todas as 16 mascaras de vizinhanca tem pelo menos um tile unico usavel, se mascaras finas/isoladas usam tiles compostos, e se existem cantos internos para curvas.

Ele tambem simula cenarios comuns de pintura do MapEditor: bloco solido, plataforma fina, coluna fina, bloco isolado e buracos com cantos internos. Isso garante que topo, miolo, laterais, fundo, pontas e curvas tenham candidatos compativeis.

## Tilesets

- `Tiles/Mossy/terrain-256/`: terreno fatiado em tiles `256x256` a partir de `Mossy - TileSet.png`.
  - `manifest.json`: indice lido pelo MapEditor.
  - `contact-sheet.png`: previa visual dos tiles usaveis.
  - `autotile-preview.png`: previa do encaixe automatico por vizinhanca.
  - `connectionMask`: lados que conectam com terreno vizinho (`N=1`, `E=2`, `S=4`, `W=8`).
  - `innerCornerMask`: cantos internos usados quando uma diagonal esta vazia.
  - `mossy-terrain-auto-*`: tiles compostos para mascaras que nao existiam no pacote original, como bloco isolado, ponta fina, plataforma fina `E+W` e coluna fina `N+S`. Os blocos isolados usam recortes de `Mossy - FloatingPlatforms.png`.
