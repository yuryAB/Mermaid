# CHARACTER_ART_GUIDE

Guia de arte para criar personagens novos no visual de Mermaid/Ester.

Use este documento quando for gerar NPCs, criaturas, personagens de loja, personagens de evento, acompanhantes ou variações de personagens existentes.

## Objetivo

Todo personagem deve parecer parte do mesmo jogo das fases da sereia:

- sprite 2D limpo
- formas grandes e arredondadas
- cores chapadas ou quase chapadas
- silhueta muito legivel
- rosto simples e gentil
- poucos detalhes pequenos
- fundo transparente no asset final

O personagem deve funcionar em escala pequena dentro do jogo. Se o detalhe so funciona em imagem grande, provavelmente e detalhe demais.

## Padrao Visual Do Jogo

Use como referencia principal as fases da sereia em `docs/storyboard/ref-teacher/`:

- `baby-siren.png`
- `child-siren.png`
- `young-siren.png`
- `adult-siren.png`

Nuances importantes:

- Sem contorno escuro pesado.
- Anatomia feita por massas simples: circulos, ovais, gotas, fitas grossas.
- Rosto minimo: olhos ovais escuros, boca curva pequena, sobrancelhas simples quando necessario.
- Cores quentes e amigaveis: coral, pessego, rosa queimado, amarelo, laranja, lavanda suave.
- Contraste vem de grandes areas de cor, nao de linha ou textura.
- A silhueta deve explicar o personagem antes dos detalhes.
- A pose deve ser calma, frontal ou 3/4 leve, com leitura clara.
- Evite renderizacao realista, pixel art, pintura com textura, sombras complexas e highlights brilhantes.

## Como Usar Concept Arts

Concept arts servem para ideia, nao para acabamento.

Ao usar uma referencia conceitual:

- Pegue somente personalidade, gesto, acessorio principal ou silhueta.
- Traduza tudo para o flat simples do jogo.
- Reduza props para 1 item grande e claro, no maximo.
- Troque detalhes pequenos por formas grandes.
- Remova textura, granulado, hachura, brilho realista e contorno escuro.

Exemplo da professora-polvo:

- A ideia veio de concepts de polvo professor/simpatico.
- O acabamento veio das sereias.
- Resultado: senhora polvo gentil, oculos, cabelo claro, livro simples, xale lavanda, tentaculos grandes e limpos.

## Checklist Antes De Gerar

Defina:

- Funcao no jogo: loja, professor, desafio, evento, companhia, criatura, morador.
- Personalidade principal: gentil, curioso, timido, serio, brincalhao, misterioso.
- Especie ou forma base: polvo, peixe, tartaruga, cavalo-marinho, coral vivo, sereia, molusco.
- Um acessorio de leitura rapida: livro, bolsa, concha, lupa, broche, flor, ferramenta.
- Paleta dominante: 2 ou 3 cores principais.
- Proporcao: cabeca/corpo grandes, membros simples, sem detalhe fino.
- Pose: centrada, corpo inteiro, sem corte.

## Prompt Base

Use este template e preencha os campos entre colchetes.

```text
Use case: stylized-concept
Asset type: final 2D game NPC character sprite, transparent-background workflow source

Primary request:
Create ONLY one complete character for a mermaid game: [descricao curta do personagem].
The character should feel [3 palavras de personalidade].

Style/medium:
Ultra-simple flat 2D game art, matching a minimalist mermaid sprite style.
Use solid flat color shapes only, clean rounded forms, no texture, no gradients,
no soft airbrush, no painterly shading, no drop shadow, no cast shadow, no dark outline.
Make it look like a simple cutout sprite made from flat vector-like shapes.

Reference style to match:
Simple mermaid sprites with large rounded body parts, warm peach/coral colors,
tiny dark oval eyes, simple curved smile, minimal features, no outlines,
no lighting effects, no detailed rendering.

Subject details:
[Especie/forma base], full body, centered.
Use [paleta].
Include only these readable character cues: [1 a 3 elementos grandes].
Keep details large and readable at small game scale.

Composition/framing:
Vertical full-body sprite, centered, generous padding, no cropping.
Readable at small size.

Background:
Perfectly flat solid #00ff00 chroma-key background for removal.
Absolutely uniform green fill from edge to edge, no gradient, no vignette,
no shadow, no texture.

Constraints:
Do not use #00ff00 anywhere in the character.
No text, no watermark, no other characters, no scenery, no UI frame.
Avoid realistic details, avoid complex texture, avoid tiny props,
avoid scary expression unless specifically requested.
The final result should be simpler and flatter than a children's book illustration.
```

## Prompt Exemplo

```text
Use case: stylized-concept
Asset type: final 2D game NPC character sprite, transparent-background workflow source

Primary request:
Create ONLY one complete NPC character: an elderly lady octopus professor who sells upgrades to a mermaid.
She is kind, gentle, wise, and friendly.

Style/medium:
Ultra-simple flat 2D game art, matching a minimalist mermaid sprite style.
Use solid flat color shapes only, clean rounded forms, no texture, no gradients,
no soft airbrush, no painterly shading, no drop shadow, no cast shadow, no dark outline.
Make it look like a simple cutout sprite made from flat vector-like shapes.

Reference style to match:
Simple mermaid sprites with large rounded body parts, warm peach/coral colors,
tiny dark oval eyes, simple curved smile, minimal features, no outlines,
no lighting effects, no detailed rendering.

Subject details:
Elderly female octopus professor, full body, centered.
Rounded peach-coral octopus head/body, simple pale pink hair bun or soft hair cap shape,
small round glasses, simple white eyebrows, tiny dark oval eyes, small curved smile.
A simple lavender shawl shape can suggest professor/grandma.
Tentacles are thick simple rounded ribbons, arranged clearly around the body, with very few details.
One tentacle may hold a very simple closed book or shell-shaped upgrade token made of 2-3 flat shapes.

Composition/framing:
Vertical full-body sprite, centered, generous padding, no cropping.
Readable at small size.

Background:
Perfectly flat solid #00ff00 chroma-key background for removal.
Absolutely uniform green fill from edge to edge, no gradient, no vignette,
no shadow, no texture.

Constraints:
Do not use #00ff00 anywhere in the character.
No text, no watermark, no other characters, no scenery, no UI frame.
Avoid realistic suction cups, avoid highlights, avoid detailed book pages,
avoid props from concept art like hats, guns, tea, food, sheriff/cowboy elements.
The final result should be simpler and flatter than a children's book illustration.
```

## Paleta Recomendada

Use poucas cores por personagem.

Boas bases:

- coral/pessego para pele, corpo ou criaturas amigaveis
- rosa queimado para cabelo ou detalhe quente
- lavanda suave para roupa, xale, magia ou professor
- amarelo/dourado para concha, broche, item especial ou brilho simbolico
- azul claro/turquesa apenas como detalhe, nao como fundo do asset
- branco perola para cabelo, perolas, sobrancelhas ou pequenos acentos

Evite:

- verdes proximos de `#00ff00`, porque atrapalham remover fundo
- preto puro em areas grandes
- muitas cores saturadas competindo
- sombras azuladas realistas

## Composicao

Para personagens de jogo:

- corpo inteiro
- personagem centralizado
- proporcao vertical
- margem generosa em volta
- pes/base visivel
- sem cenario
- sem sombra no chao
- sem bolhas, texto, moldura ou UI

Para NPCs de loja ou dialogo:

- pose calma
- rosto virado para frente ou 3/4 leve
- acessorio grande que indique funcao
- expressao acolhedora
- leitura clara quando reduzido

## Nivel De Detalhe

Bom:

- oculos redondos simples
- um livro fechado simples
- uma concha grande
- um broche claro
- tentaculos grossos em poucas curvas
- cabelo como massa grande

Ruim:

- muitas ventosas
- textura de pele
- paginas detalhadas
- varias ferramentas pequenas
- olhos com iris complexa
- roupas cheias de costura
- sombras e brilhos em excesso

## Negativos Uteis

Inclua quando o gerador insistir em detalhar demais:

```text
Avoid realistic rendering, avoid painterly texture, avoid grain, avoid heavy outlines,
avoid complex shadows, avoid glossy highlights, avoid tiny details, avoid extra props,
avoid background scenery, avoid text, avoid watermark, avoid UI frame.
```

Inclua quando o personagem ficar fora do estilo:

```text
Make the character simpler, flatter, more rounded, and closer to a minimal 2D mobile game sprite.
Use larger color shapes and fewer details.
```

## Fundo Transparente

Fluxo recomendado:

1. Gerar com fundo chroma-key `#00ff00`.
2. Garantir que o personagem nao usa verde semelhante.
3. Remover o chroma-key localmente.
4. Validar que o PNG final tem alpha real.
5. Recortar o canvas transparente sobrando antes de colocar em `Assets.xcassets`.

O asset final deve ser PNG RGBA com fundo transparente.

## Integracao No Jogo

Quando o personagem for para o jogo:

- coloque em `Ester/Assets.xcassets/[NomeDoPersonagem].imageset/`
- use nome de asset claro, exemplo: `ProfessorOctopus`
- recorte a area transparente sobrando antes de importar
- use `SKSpriteNode(imageNamed:)` para sprite unico
- escala deve ser definida pelo contexto onde aparece
- idle simples pode usar `moveBy`, `scaleX` e `scaleY`

Idle improvisado recomendado:

```swift
sprite.run(.repeatForever(.sequence([
    .group([
        .scaleX(to: 1.025, duration: 1.15),
        .scaleY(to: 0.985, duration: 1.15)
    ]),
    .group([
        .scaleX(to: 0.985, duration: 1.15),
        .scaleY(to: 1.018, duration: 1.15)
    ]),
    .group([
        .scaleX(to: 1, duration: 0.65),
        .scaleY(to: 1, duration: 0.65)
    ])
]))
```

Use distorcao leve. Se o sprite parecer borrachudo demais, reduza os valores para `1.012` e `0.992`.

## Regra Final

Personagem bom para Mermaid/Ester parece um brinquedo de papel recortado: simples, redondo, quente, gentil, legivel e pronto para viver embaixo d'agua sem precisar de muitos detalhes.
