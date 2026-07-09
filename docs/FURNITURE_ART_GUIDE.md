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

Assets aprovados como referencia direta:

- `Ester/Assets.xcassets/MermaidSideboard.imageset/mermaid-sideboard.png`
- `Ester/Assets.xcassets/MermaidDresser.imageset/mermaid-dresser.png`

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

A comoda funcionou quando manteve o topo livre. Para moveis que podem receber
outros objetos no futuro, a superficie superior deve ficar limpa e usavel. A
tematica de sereia deve aparecer nas gavetas, puxadores, pes, bordas e frente,
nao como props soltos apoiados no tampo.

O ponto principal: primeiro o asset precisa ler como movel funcional; depois, a
tematica de sereia aparece em curvas, conchas, perolas, ondas e nadadeiras.
Ornamento nunca deve atrapalhar a funcao do objeto.

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
- Evite aspecto 3D. O asset pode ter leves variacoes internas de cor, mas nao
  deve parecer iluminado por uma luz real nem modelado em volume.
- Se a imagem gerada ja parece pertencer ao jogo, preserve essa saida. Nao tente
  deixar o asset "mais flat" com filtros depois da geracao.

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
- tampo vazio quando o movel puder servir de apoio para outros objetos

Ruim:

- muitas conchas pequenas
- muitas escamas desenhadas uma por uma
- arabescos finos
- veios de madeira realistas
- brilho metalico detalhado
- concha, coral, vaso, perola, estatua ou qualquer prop solto em cima de moveis
  que devem ter tampo usavel
- fundo de sala, parede, tapete ou outros moveis quando o pedido for asset isolado

## Funcao Antes Do Ornamento

Antes de gerar, decida se o movel tem uma superficie que pode receber outros
objetos no jogo.

Moveis que geralmente precisam de topo livre:

- aparador
- comoda
- criado-mudo
- mesa de centro
- estante baixa
- banco
- bau
- bancada

Para esses moveis:

- nao coloque objetos em cima do tampo
- nao use conchas, vasos, corais, livros ou perolas como props apoiados no topo
- use o tema marinho integrado a estrutura: gaveta-concha, puxador-perola,
  pe-nadadeira, borda em onda, painel frontal com coral simples
- o topo pode ter curva ou acabamento de onda, mas deve continuar vazio e
  visualmente disponivel para receber itens depois

Para objetos que sao decorativos por natureza, como vaso, escultura, globo,
cesta ou instrumento, o proprio objeto pode ter ornamento. Mesmo assim, evite
varios props soltos competindo com a silhueta principal.

## Checklist Antes De Gerar

Defina:

- Tipo de movel: aparador, mesa, cama, cadeira, armario, estante, bancada, bau.
- Funcao no jogo: casa, loja, decoracao, recompensa, evento, item interativo.
- Personalidade visual: gentil, elegante, magico, caseiro, antigo, brincalhao.
- Silhueta base: horizontal, vertical, baixa, alta, larga, estreita.
- Tema marinho principal: concha, onda, perola, coral, nadadeira, escama grande.
- Um detalhe de leitura rapida: puxador-perola, topo-onda, gaveta-concha,
  pe-nadadeira, broche-coral.
- Superficie util: o topo precisa ficar livre ou o objeto e decorativo por si so?
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
- tampo livre, sem props colocados em cima
- duas portas ou gavetas grandes
- pes curtos visiveis
- uma decoracao marinha principal integrada ao movel
- frente limpa, sem muitas divisorias

Para comodas especificamente:

- proporcao vertical moderada, mais alta que aparador mas ainda larga e estavel
- tampo livre, limpo e usavel
- duas ou tres gavetas horizontais grandes
- gavetas podem ter frente inspirada em concha, mas como parte da gaveta
- puxadores como perolas grandes
- pes curtos arredondados ou em forma de nadadeira
- ornamento principal na frente inferior ou nas gavetas, nunca apoiado no topo

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
If this furniture has a usable top surface, keep the top empty with no props on it.
Integrate mermaid cues into the drawers, doors, legs, edges, handles, or front panel.

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
No loose props sitting on top of furniture that should have a usable surface.
Avoid realistic wood grain, avoid tiny decorative carvings, avoid complex shell detail,
avoid shiny highlights, avoid ornate furniture realism, avoid 3D volume,
avoid realistic lighting.
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
Keep the top surface empty; do not place loose objects on top of the sideboard.
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
No loose props sitting on top of the furniture.
Avoid realistic wood grain, avoid tiny decorative carvings, avoid complex shell detail,
avoid shiny highlights, avoid ornate furniture realism, avoid 3D volume,
avoid realistic lighting.
The final result should be simpler and flatter than a children's book illustration.
```

## Prompt Exemplo: Comoda Sereia Com Topo Livre

```text
Use case: stylized-concept
Asset type: final 2D game furniture prop sprite, transparent-background workflow source

Primary request:
Create ONLY one complete mermaid-themed dresser / comoda for a cozy mermaid game.
It should feel gentle, warm, handmade, and magical.

Critical functional requirement:
This is a dresser with a usable top surface. Do not put any shell, coral, pearl,
vase, statue, ornament, object, prop, or decoration sitting on top of the dresser.
The top must stay clean and empty so future game objects can be placed there.

Style/medium:
Ultra-simple flat 2D game art, matching the approved MermaidSideboard style.
Use clean rounded forms, broad color areas, minimal internal lines, no cast shadow,
no contact shadow, no realistic lighting, no 3D volume, no glossy highlights.

Reference style to match:
Coral-peach body, soft lavender shell-shaped drawer fronts, pearl white knobs,
warm gold accents, short fin-like legs, simple mobile game sprite readability.

Subject details:
One compact dresser, centered, full object visible. Rounded coral-peach body.
Two or three large horizontal drawers. Drawer fronts may use simple lavender
scallop-shell curves integrated into the drawers. Use large pearl knobs.
Use a gentle wave-shaped empty top edge and short rounded fin-like legs.
Any shell or coral motif must be integrated into the drawer/front design, never
placed as a loose object on top.

Composition/framing:
Straight front view or very gentle 3/4 front view, centered, generous padding,
no cropping. No room scene, no floor, no wall, no extra furniture.

Background:
Perfectly flat solid #00ff00 chroma-key background for later removal.
Absolutely uniform green fill from edge to edge, no gradient, no vignette,
no shadow, no texture.

Constraints:
Do not use #00ff00 anywhere in the furniture.
No text, no watermark, no other objects, no scenery, no UI frame.
No loose props on top. Avoid realistic wood grain, tiny decorative carvings,
complex shell detail, shiny highlights, ornate furniture realism, 3D volume,
realistic lighting, texture, grain, speckles, and painterly shading.
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
- ornamento que prejudica a funcao do movel, como uma concha grande ocupando o
  topo de uma comoda ou mesa

## Negativos Uteis

Inclua quando o gerador insistir em detalhar demais:

```text
Avoid realistic rendering, avoid painterly texture, avoid grain, avoid heavy outlines,
avoid complex shadows, avoid glossy highlights, avoid tiny details, avoid extra props,
avoid background scenery, avoid text, avoid watermark, avoid UI frame, avoid 3D volume,
avoid realistic lighting.
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
Do not place loose decorative objects on top of furniture with a usable surface.
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

Nao use pos-processamento para alterar o estilo da arte gerada. Nao aplique
quantizacao de paleta, filtro de textura, blur, mode filter, posterizacao,
sharpen, recolor automatico ou qualquer transformacao estetica. Se a imagem
gerada esta boa no chroma-key, o pos-processamento deve fazer somente:

- remocao do fundo verde
- limpeza de pixels soltos de chroma-key quando necessario
- recorte do canvas transparente

Se a arte estiver com estilo errado, gere novamente com prompt melhor. Nao tente
"consertar" estilo ruim com filtro.

Importante: "flat" e uma direcao para o prompt de geracao, nao uma autorizacao
para achatar a imagem depois. Filtros de paleta ou textura podem criar manchas,
ruido e artefatos que quebram o estilo mesmo quando a fonte chroma-key estava boa.

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
