# FURNITURE_ART_GUIDE

Guia de arte para criar moveis e objetos decorativos no visual de Mermaid/Ester.

Use este documento quando for gerar aparadores, mesas, camas, cadeiras, penteadeiras,
estantes, armarios, bancadas de loja, objetos de casa, decoracoes de sala ou props
grandes que precisam parecer parte do mesmo jogo das fases da sereia.

## Objetivo

Todo movel deve parecer um asset de jogo simples, quente e legivel:

- sprite 2D limpo
- formas grandes e arredondadas
- cores chapadas ou quase chapadas
- silhueta muito legivel
- tema de sereia sugerido por formas grandes, nao por muitos detalhes pequenos
- poucos detalhes pequenos
- fundo transparente no asset final

O movel deve funcionar em escala pequena dentro do jogo. Se um detalhe so aparece
quando a imagem esta grande, provavelmente e detalhe demais.

## Resultado De Referencia

O aparador de sala com tematica de sereia funcionou porque combinou estas escolhas:

- corpo principal coral/pessego, grande e arredondado
- leitura clara de "aparador" antes da decoracao tematica
- frente com portas e gavetas simples, em massas grandes
- gavetas inspiradas em conchas, mas sem linhas finas demais
- puxadores como perolas redondas
- topo com curva suave de onda
- pes curtos e arredondados, lembrando pequenas nadadeiras
- decoracao marinha integrada ao desenho do movel, nao espalhada como muitos props
- paleta pequena: coral/pessego, lavanda suave, branco perola e acento dourado
- sem textura de madeira, sem brilho realista, sem sombra no chao

O ponto principal: primeiro o asset precisa ler como movel; depois, a tematica de
sereia aparece em curvas, conchas, perolas, ondas e nadadeiras.

## Padrao Visual Do Jogo

Use como referencia principal as fases da sereia em `docs/storyboard/ref-teacher/`:

- `baby-siren.png`
- `child-siren.png`
- `young-siren.png`
- `adult-siren.png`

Nuances importantes para moveis:

- Sem contorno escuro pesado.
- Construa o objeto com massas simples: retangulos arredondados, ovais, gotas,
  arcos grossos, fitas largas e conchas simplificadas.
- Cores quentes e amigaveis: coral, pessego, rosa queimado, amarelo, laranja,
  lavanda suave, branco perola.
- Contraste vem de grandes areas de cor, nao de linha, textura ou sombreamento.
- A silhueta deve explicar a funcao do movel antes dos detalhes.
- Evite renderizacao realista, pixel art, pintura com textura, sombras complexas,
  highlights brilhantes e madeira com veios realistas.

## Como Traduzir Tema De Sereia Para Moveis

Tema de sereia deve entrar por linguagem de forma, nao por excesso de ornamento.

Bom:

- topo em curva de onda
- gaveta com forma simples de concha
- puxadores de perola grandes
- pernas como nadadeiras curtas e arredondadas
- porta com arco suave lembrando escama grande
- detalhe unico de coral, estrela-do-mar ou concha bem simplificado
- laterais levemente onduladas
- detalhes lavanda, perola ou dourado em areas pequenas

Ruim:

- muitas conchas pequenas
- muitas escamas desenhadas uma por uma
- arabescos finos
- veios de madeira realistas
- brilho metalico detalhado
- varias decoracoes soltas em cima do movel
- fundo de sala, parede, tapete ou outros moveis quando o pedido for asset isolado

## Checklist Antes De Gerar

Defina:

- Tipo de movel: aparador, mesa, cama, cadeira, armario, estante, bancada, bau.
- Funcao no jogo: casa, loja, decoracao, recompensa, evento, item interativo.
- Personalidade visual: gentil, elegante, magico, caseiro, antigo, brincalhao.
- Silhueta base: horizontal, vertical, baixa, alta, larga, estreita.
- Tema marinho principal: concha, onda, perola, coral, nadadeira, escama grande.
- Um detalhe de leitura rapida: puxador-perola, topo-onda, gaveta-concha,
  pe-nadadeira, broche-coral.
- Paleta dominante: 2 ou 3 cores principais.
- Nivel de detalhe: formas grandes, sem textura fina.
- Enquadramento: objeto inteiro, centralizado, sem corte.

## Anatomia De Um Bom Movel

Para o movel ficar legivel e bonito:

- comece por uma silhueta forte e simples
- use um corpo principal grande
- coloque poucos elementos secundarios
- mantenha os detalhes simetricos ou quase simetricos quando o objeto for frontal
- use linhas internas grossas e suaves apenas quando precisarem separar partes
- faca portas, gavetas e prateleiras em formas grandes
- deixe puxadores e enfeites em tamanho suficiente para lerem em escala pequena
- evite detalhes que dependam de textura

Para aparadores especificamente:

- proporcao horizontal, mais largo do que alto
- tampo claro e levemente curvo
- duas portas ou gavetas grandes
- pes curtos visiveis
- uma decoracao marinha principal integrada ao movel
- frente limpa, sem muitas divisorias

## Prompt Base

Use este template e preencha os campos entre colchetes.

```text
Use case: stylized-concept
Asset type: final 2D game furniture prop sprite, transparent-background workflow source

Primary request:
Create ONLY one complete [tipo de movel] inspired by a mermaid theme for a cozy mermaid game.
It should feel [3 palavras de personalidade].

Style/medium:
Ultra-simple flat 2D game art, matching a minimalist mermaid sprite style.
Use solid flat color shapes only, clean rounded forms, no texture, no gradients,
no soft airbrush, no painterly shading, no drop shadow, no cast shadow, no dark outline.
Make it look like a simple cutout sprite made from flat vector-like shapes.

Reference style to match:
Simple mermaid game sprites with large rounded parts, warm peach/coral colors,
soft lavender, pearl white and gold accents, minimal features, no outlines,
no lighting effects, no detailed rendering. The silhouette must be readable at small game scale.

Subject details:
One [tipo de movel], centered, full object visible.
Use [paleta].
Include only these readable mermaid/furniture cues: [1 a 3 elementos grandes].
Keep details large and readable at small game scale.

Composition/framing:
Straight front view or gentle 3/4 front view, centered, generous padding, no cropping.
No room scene, no floor, no wall, no extra furniture.

Background:
Perfectly flat solid #00ff00 chroma-key background for removal.
Absolutely uniform green fill from edge to edge, no gradient, no vignette,
no shadow, no texture.

Constraints:
Do not use #00ff00 anywhere in the furniture.
No text, no watermark, no other objects, no scenery, no UI frame.
Avoid realistic wood grain, avoid tiny decorative carvings, avoid complex shell detail,
avoid shiny highlights, avoid ornate furniture realism.
The final result should be simpler and flatter than a children's book illustration.
```

## Prompt Exemplo: Aparador De Sala Sereia

```text
Use case: stylized-concept
Asset type: final 2D game furniture prop sprite, transparent-background workflow source

Primary request:
Create ONLY one complete living-room sideboard cabinet inspired by a mermaid theme,
for a cozy mermaid game. It should feel gentle, warm, handmade, and magical.

Style/medium:
Ultra-simple flat 2D game art, matching a minimalist mermaid sprite style.
Use solid flat color shapes only, clean rounded forms, no texture, no gradients,
no soft airbrush, no painterly shading, no drop shadow, no cast shadow, no dark outline.
Make it look like a simple cutout sprite made from flat vector-like shapes.

Reference style to match:
Simple mermaid game sprites with large rounded parts, warm peach/coral colors,
soft lavender, pearl white and gold accents, minimal features, no outlines,
no lighting effects, no detailed rendering. The silhouette must be readable at small game scale.

Subject details:
One sideboard cabinet / aparador for a living room, centered, full object visible.
Rounded coral-peach wooden body, soft scallop-shell drawer fronts, pearl-like round knobs,
gentle wave-shaped top edge, two rounded cabinet doors, short curved legs like little fins,
one large readable shell ornament or small coral motif integrated into the furniture design.
Use 2 to 3 dominant colors: coral-peach, soft lavender, pearl white, with tiny warm gold accents.
Keep details large and readable.

Composition/framing:
Straight front view or gentle 3/4 front view, centered, generous padding, no cropping.
No room scene, no floor, no wall, no extra furniture.

Background:
Perfectly flat solid #00ff00 chroma-key background for later removal.
Absolutely uniform green fill from edge to edge, no gradient, no vignette,
no shadow, no texture.

Constraints:
Do not use #00ff00 anywhere in the furniture.
No text, no watermark, no other objects, no scenery, no UI frame.
Avoid realistic wood grain, avoid tiny decorative carvings, avoid complex shell detail,
avoid shiny highlights, avoid ornate furniture realism.
The final result should be simpler and flatter than a children's book illustration.
```

## Paleta Recomendada

Use poucas cores por movel.

Boas bases:

- coral/pessego para corpo principal
- rosa queimado para detalhe quente
- lavanda suave para portas, gavetas ou acabamento magico
- amarelo/dourado para puxadores, broches ou pequenos acentos
- branco perola para conchas, perolas, detalhes de puxador ou tampo
- azul claro/turquesa apenas como detalhe pequeno, nao como fundo do asset

Evite:

- verdes proximos de `#00ff00`, porque atrapalham remover fundo
- preto puro em areas grandes
- muitas cores saturadas competindo
- marrom realista dominante
- sombras azuladas realistas

## Composicao

Para moveis de jogo:

- objeto inteiro
- objeto centralizado
- margem generosa em volta
- base ou pes visiveis
- sem cenario
- sem sombra no chao
- sem bolhas, texto, moldura ou UI
- vista frontal ou 3/4 leve

Para moveis de casa:

- leitura de conforto e escala domestica
- formas macias e arredondadas
- decoracao marinha integrada ao objeto
- poucos elementos sobrepostos

Para moveis de loja ou evento:

- silhueta mais marcante
- um detalhe grande que indique funcao
- area frontal limpa para leitura rapida
- cor de destaque usada com moderacao

## Nivel De Detalhe

Bom:

- puxadores redondos como perolas
- uma concha grande simplificada
- topo em onda unica
- pernas como nadadeiras simples
- duas ou tres divisorias grandes
- um detalhe de coral em forma grande
- uma estrela-do-mar simples se for o detalhe principal

Ruim:

- muitas escamas pequenas
- muitas conchas pequenas
- madeira com textura e veios
- detalhes metalicos brilhantes
- vidro realista
- sombras complexas
- varios objetos decorativos em cima
- linhas internas muito finas

## Negativos Uteis

Inclua quando o gerador insistir em detalhar demais:

```text
Avoid realistic rendering, avoid painterly texture, avoid grain, avoid heavy outlines,
avoid complex shadows, avoid glossy highlights, avoid tiny details, avoid extra props,
avoid background scenery, avoid text, avoid watermark, avoid UI frame.
```

Inclua quando o movel ficar fora do estilo:

```text
Make the furniture simpler, flatter, more rounded, and closer to a minimal 2D mobile game sprite.
Use larger color shapes and fewer details.
The furniture must read clearly at small game scale.
```

Inclua quando a tematica de sereia virar excesso:

```text
Use only one to three large mermaid-themed cues.
Integrate the shell, pearl, wave, coral, fin, or scale motif into the furniture shape.
Do not add many small ocean decorations.
```

## Fundo Transparente

Fluxo recomendado:

1. Gerar com fundo chroma-key `#00ff00`.
2. Garantir que o movel nao usa verde semelhante.
3. Remover o chroma-key localmente.
4. Validar que o PNG final tem alpha real.
5. Recortar o canvas transparente sobrando antes de colocar em `Assets.xcassets`.
6. Conferir especialmente a base do movel: o limite inferior do PNG deve encostar
   no ultimo pixel visivel da ilustracao, sem faixa transparente abaixo dos pes.

O asset final deve ser PNG RGBA com fundo transparente.

## Pos-processamento Do Asset

A imagem final nao deve manter a area verde nem a sobra transparente do canvas
original. Depois de remover o chroma-key, faca um recorte pelo limite real da
ilustracao, usando o bounding box dos pixels com alpha visivel.

Use sempre o helper local quando o asset vier de geracao com chroma-key:

```bash
node Tools/process-furniture-asset.cjs \
  --input tmp/furniture-chroma.png \
  --out Ester/Assets.xcassets/MermaidSideboard.imageset/mermaid-sideboard.png
```

Esse script faz os dois passos obrigatorios:

- remove o chroma-key plano, com key automatica pelas bordas da imagem
- recorta o PNG final pelo bounding box dos pixels com alpha visivel

Regras:

- corte esquerda, direita, topo e base ate os limites da ilustracao
- nao deixe faixa transparente abaixo do movel
- preserve a proporcao da arte; nao estique nem redesenhe para caber
- valide que os cantos estao transparentes e que a base visual esta no limite
  inferior do PNG
- para moveis de chao, esse recorte e essencial porque o jogo usa o bottom do
  asset como referencia de apoio no piso

Se a imagem ficar com sombra, poeira de chroma-key ou pixels soltos longe do
movel, limpe esses pixels antes de calcular o recorte. O objetivo e que o canvas
descreva a ilustracao, nao o espaco vazio onde ela foi gerada.

## Integracao No Jogo

Quando o movel for para o jogo:

- coloque em `Ester/Assets.xcassets/[NomeDoMovel].imageset/`
- use nome de asset claro, exemplo: `MermaidSideboard`
- recorte a area transparente sobrando antes de importar, principalmente abaixo
  dos pes/base
- preserve a paleta e o nivel de detalhe do restante dos assets
- valide em escala pequena dentro da tela onde o movel aparece
