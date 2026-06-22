# Regras do Mundo — Ester

> Documento vivo. Editar aqui quando uma regra for decidida, alterada ou descartada.

---

## Modelo Mental

- **Mapa** é a unidade principal de exploração.
- **Fase da sereia** controla quais mapas ela pode acessar.
- **Profundidade** é o eixo vertical dentro de cada mapa.
- **Scene** troca ao viajar entre mapas.

---

## Fases da Sereia

| Fase | Descrição |
|---|---|
| Ovo/Choco | Estado inicial — fora da lógica de mapas |
| Bebê | Primeira fase livre |
| Criança | Segunda fase |
| Adolescente | Terceira fase |
| Jovem | Quarta fase |
| Adulta | Fase final, acesso total |

---

## Mapas Por Fase

| Fase | Mapa 1 | Mapa 2 |
|---|---|---|
| Bebê | Águas de Nascimento | Jardim Calmo |
| Criança | Recife Esmeralda | Grande Delta |
| Adolescente | Mar Azul Aberto | Boca das Cavernas |
| Jovem | Campos de Cristal | Ruínas Antigas |
| Adulta | Abismo Vivo | Superfície Distante |

---

## Regras de Acesso a Mapas

- Cada fase dá **elegibilidade** cumulativa: **fase atual + todas as fases anteriores**.
- Elegibilidade de fase **não descobre mapa sozinha**.
- Apenas *Águas de Nascimento* começa conhecido por padrão.
- Todo outro mapa precisa passar pelo fluxo de pista → seguir pista → confirmar viagem.
- Mapas de fases futuras aparecem no menu como **bloqueados**, com mensagem: *"Disponível quando ela for [Fase]"*.
- Voltar para mapa de fase menor **sempre é permitido**.

---

## Profundidades

Camadas existentes em cada mapa:

1. Clara
2. Rasa
3. Média
4. Azul
5. Profunda
6. Abissal
7. Superfície *(acima da água)*

Todas as camadas existem em todos os mapas. O que muda é o **desbloqueio**.

Fase mínima por profundidade:

| Profundidade | Fase mínima |
|---|---|
| Rasa | Bebê |
| Média | Bebê |
| Azul | Criança |
| Profunda | Adolescente |
| Clara | Jovem |
| Abissal | Jovem |
| Superfície | Adulta |

---

## Regras de Desbloqueio de Profundidades

> **Decisão pendente:** desbloqueio é global ou por mapa? → Ver seção abaixo.

Critérios válidos para travar uma profundidade:

| Critério | Descrição |
|---|---|
| `Fase mínima` | Corpo precisa estar maduro o suficiente |
| `Adaptação` | Tempo/visitas acumuladas na camada anterior |
| `Descoberta` | Encontrar entrada ou evento específico no mapa |
| `Energia` | Tentativa exige energia mínima |
| `História` | Evento narrativo necessário |

---

## Coragem

**Decisão:** removida do sistema por enquanto. Não é critério de desbloqueio nem atributo ativo. Pode ser revisitada no futuro se houver necessidade narrativa.

---

## Desbloqueio Global vs Por Mapa

**Decisão:** híbrido.

| Tipo | Escopo |
|---|---|
| Fase mínima | Global |
| Adaptação por camada | Global |
| Descobertas especiais | Por mapa |

**Exemplo:** adulta nada fundo globalmente, mas a entrada para *"Abismo Vivo"* precisa ser descoberta dentro daquele mapa.

---

## Estrutura de Cada Mapa

```
mapId
nome
faseMínima
scene própria
paleta de água
fauna
comidas
eventos
desafios
profundidadesVisíveis      ← todas, sempre
profundidadesDesbloqueadas ← depende da sereia atual
```

---

## Viagem Entre Mapas

1. Jogador seleciona mapa no menu.
2. Sistema valida se fase atual permite acesso.
3. Se permitido: inicia transição de scene.
4. Salva mapa atual + posição local.
5. Carrega scene do destino.
6. Coloca sereia no ponto de entrada do novo mapa.

---

## Mini-mapa de Expedição

### Como o Terraria faz (referência)

O minimap do Terraria é uma representação 2D do mundo em escala, exibido em canto da tela. As regras centrais são:

- **Fog of war**: área começa escondida. Só aparece no mapa quando o personagem passou por ali.
- **Luz obrigatória**: áreas exploradas sem fonte de luz **não são mapeadas**.
- **Brilho máximo**: área aparece com o brilho máximo que já foi vista — não regride.
- **Persistência**: área revelada fica revelada mesmo que volte ao escuro na tela.
- **Modos de exibição**: canto (portrait), overlay transparente, tela cheia, oculto.
- **Zoom**: pode dar zoom in/out no mapa.
- **Por personagem**: dados do mapa são salvos por personagem, não por mundo. Se outro personagem explorar o mesmo mundo, não vê o mapa do primeiro.
- **Camadas verticais**: Terraria tem 5 camadas (Espaço → Superfície → Underground → Caverna → Submundo) — o minimap mostra todas ao mesmo tempo numa visão lateral 2D.

### Adaptação para Ester

O mundo da Ester tem **dois eixos principais**:
- **Horizontal**: exploração lateral dentro do mapa atual.
- **Vertical**: profundidade (Clara → Rasa → Média → Azul → Profunda → Abissal → Superfície).

Isso é análogo às camadas do Terraria, mas rotacionado: no Terraria o eixo de profundidade é vertical e você desce; em Ester também é, mas a progressão tem nomes e regras de desbloqueio.

#### Regras propostas para o mini-mapa

| Regra | Decisão |
|---|---|
| Posição | Aparece **somente ao abrir o mapa de expedição** — não fica na HUD |
| Orientação | Vertical: eixo Y = profundidade, eixo X = horizontal dentro do mapa |
| Fog of war | Sim — área revelada somente ao passar por ali |
| Revelação por proximidade | À medida que a sereia passa por uma área, ela vai se clareando no mapa gradualmente |
| Persistência | Área revelada fica marcada mesmo saindo de lá |
| Revelação | **Gradiente** — área recém-visitada aparece parcialmente; quanto mais explorada, mais definida |
| Dados por save | Mapa salvo por save (equivalente ao per-character do Terraria) |
| Marcadores | Posição atual da sereia, pontos de interesse descobertos, entradas de profundidade |
| Profundidades bloqueadas | Aparecem no mapa como zonas escuras/cinzas com ícone de cadeado |
| Modos | Integrado ao menu de expedição (tela cheia do mapa) |

#### O que aparece no mini-mapa

- Silhueta da sereia (posição atual)
- Terreno/estruturas da área já revelada
- Profundidades desbloqueadas vs bloqueadas (distinção visual clara)
- Pontos de interesse já descobertos (comida, evento, entrada especial)
- Bordas do mapa atual
- Indicador de profundidade atual (ex: "Zona Azul")

#### O que NÃO aparece

- Conteúdo de áreas ainda não reveladas
- Detalhes de fauna/eventos em tempo real (não é radar)
- Outros mapas — o mini-mapa é sempre do mapa atual

#### Porcentagem de descoberta

- A porcentagem de descoberta do mapa combina **área revelada** e **POIs alcançáveis descobertos**.
- Um mapa só pode aparecer como **100% descoberto** quando a área alcançável foi revelada e todos os POIs alcançáveis daquele mapa foram descobertos.
- POIs em profundidades ainda bloqueadas não entram na porcentagem até a profundidade ser desbloqueada.

#### Raio de visão — decisão fechada

**Raio fixo por fase**: corpo mais maduro = maior percepção do ambiente = mais área revelada ao redor.

| Fase | Raio de revelação (referência) |
|---|---|
| Bebê | Pequeno — revela só o imediato |
| Criança | Um pouco maior |
| Adolescente | Médio |
| Jovem | Amplo |
| Adulta | Máximo |

> Valores exatos a definir durante implementação.

---

## Pontos de Interesse (POIs)

### Conceito

Cada combinação **mapa + profundidade** tem seus próprios POIs. Exemplo: *Águas de Nascimento × Camada Média* tem POIs distintos de *Águas de Nascimento × Camada Rasa*.

### Tipos de POI (exemplos)

- Barcos naufragados
- NPCs com recompensas especiais
- Minigames exclusivos da área
- *(lista expandida conforme o jogo cresce — sistema deve ser escalável, ver nota do desenvolvedor)*

### Coordenadas

- POIs são **colocados em coordenadas aleatórias** a cada mapa+profundidade gerado.
- Ponto de entrada no mapa também é **dinâmico** — a sereia não começa sempre no mesmo lugar.

### Visibilidade no Menu de Expedição

- POIs não descobertos aparecem como **silhuetas** no mapa — o jogador sabe que existe algo, mas não o quê.
- POIs descobertos aparecem completos, com nome e tipo.
- Silhuetas somem/aparecem dependendo do gradiente de revelação daquela área.

### Descoberta

- A sereia descobre POIs **explorando organicamente** — ao passar perto, o ponto é revelado.
- Se o **usuário der comando de exploração**, a sereia tem **chance levemente maior** de encontrar POIs próximos.
- Se o usuário **continuar pedindo** para explorar, a sereia vai sendo guiada gradualmente em direção aos POIs ainda não descobertos da área atual.

### Retorno a POIs Descobertos

- POI descoberto fica **clicável no menu de mapa** para sempre.
- Usuário pode clicar e pedir para a sereia voltar àquela coordenada.
- **A sereia pode aceitar ou recusar** — comportamento segue a lógica de aceitação/recusa já implementada no jogo. Desenvolvedor deve consultar o sistema existente e manter consistência.

### Sistema de Recompensas

Recompensas são obtidas em POIs e em eventos aleatórios. Os tipos possíveis são:

| Tipo | Exemplos |
|---|---|
| **Conchas** | Moeda do jogo — quantidade variável |
| **Pets temporários** | Animal de companhia por tempo limitado |
| **Efeitos temporários** | Sem fome por 1h, sem recusar pedidos por 1h, nado mais rápido, etc. |
| **Itens** | Objetos colecionáveis, decoração do refúgio, etc. |
| **Storytelling** | Revelação narrativa — sem item, só história |

> 📝 **Nota para o desenvolvedor — Recompensas**
>
> O sistema de recompensas deve ser **independente da fonte** (POI, evento aleatório, NPC, minigame). Toda recompensa passa pelo mesmo `RewardSystem`. Isso permite que qualquer fonte futura entregue qualquer tipo de recompensa sem código novo. Efeitos temporários devem usar um sistema de buffs com timer — não implementar caso a caso.

---

### Eventos Aleatórios — Upgrade

Os eventos aleatórios já existentes no jogo continuam, mas precisam ser aprimorados:

- **Antes:** eventos só davam conchas.
- **Agora:** eventos podem entregar qualquer tipo de recompensa do sistema acima.
- Desenvolvedor deve **reaproveitar o sistema de eventos existente** e conectá-lo ao `RewardSystem` novo — não reescrever do zero.

---

### Versão 1 — Escopo dos Mapas

Na primeira versão do jogo:

- Mapas serão gerados com toda a estrutura (cenas, profundidades, fauna, paleta).
- **POIs ainda não serão implementados** nos mapas da v1.
- A arquitetura de POIs deve estar preparada para receber os pontos de interesse em versão futura sem refatoração.

---

### POIs da Fase Bebê

#### Águas de Nascimento × Rasa
| POI | Tipo | Descrição |
|---|---|---|
| Ninho de ovos abandonados | Narrativo | Ela reconhece algo familiar — momento de conexão com a própria origem |
| Cardume de peixinhos bebês | Interação | Seguem a sereia; possível mini-interação de guiar o cardume |
| Concha gigante com música | Minigame | Minigame de ritmo simples ao se aproximar |

#### Águas de Nascimento × Média
| POI | Tipo | Descrição |
|---|---|---|
| Barquinho de brinquedo naufragado | Exploração/Coleta | Brinquedo humano perdido, pequeno o bastante para a bebê explorar por dentro |
| Tartaruga velha | NPC | Dá dica sobre o mundo; recompensa por conversar |
| Corrente quente | Evento | Leva a sereia brevemente a uma área secreta |

#### Jardim Calmo × Rasa
| POI | Tipo | Descrição |
|---|---|---|
| Planta que reage ao toque | Minigame | Interação leve de toque/ritmo com a planta |
| Peixe colorido | NPC | Troca comida por item/recompensa |
| Nuvem de bolhas subindo | Evento visual | Bônus pequeno + efeito visual agradável |

#### Jardim Calmo × Média
| POI | Tipo | Descrição |
|---|---|---|
| Ruína coberta de algas | Narrativo/Teaser | Mistério visual — teaser de conteúdo de fases futuras |
| Polvo bebê escondido | Interação de paciência | Se revela devagar; requer que a sereia fique parada/calma |
| Sereia anciã dormindo | NPC especial | Pode acordar ou não dependendo da interação; recompensa rara se acordar |

---

> 📝 **Nota para o desenvolvedor**
>
> Ao implementar POIs e eventos de interação, priorize arquitetura **orientada a dados e escalável**:
>
> - Cada POI deve ser definido em um arquivo de configuração/dados separado do código (JSON, plist, ScriptableObject, ou equivalente), não hardcoded em cena ou classe.
> - Crie um `POIType` enum ou protocolo base que todos os tipos de POI implementam: narrativo, minigame, npc, evento, coleta. Novos tipos devem ser adicionados sem modificar o código existente.
> - O sistema de spawn dos POIs deve ler a lista de POIs disponíveis para aquele `mapId + profundidade` e colocar nas coordenadas aleatórias — nunca instanciar POIs específicos diretamente na cena.
> - Minigames devem ser módulos independentes chamados pelo sistema de POI, não acoplados à cena do mapa.
> - NPCs devem usar um sistema de diálogo/recompensa configurável em dados — adicionar um novo NPC deve ser só criar um novo registro de dados, não novo código.
> - O estado de cada POI (descoberto, visitado, recompensa coletada) deve ser salvo por `save` em estrutura separada, fácil de versionar e migrar.
>
> O objetivo é: adicionar um novo POI no futuro = criar um arquivo de dados. Não mexer em código existente.

### Estrutura de Dados

```
poi {
  poiId
  mapId
  profundidade
  tipo           ← narrativo | minigame | npc | evento | coleta
  coordenadas    ← geradas aleatoriamente no spawn
  descoberto     ← bool, por save
  visitado       ← bool, por save
  recompensaColetada ← bool, por save
  silhuetaVisível ← calculado pelo gradiente de revelação da área
  config         ← referência ao arquivo de dados do POI (diálogo, recompensa, etc.)
}
```

---

## Desbloqueio de Novos Mapas

### Como um novo mapa é descoberto

O acesso a um novo mapa (da próxima fase) **não é dado automaticamente** — ele precisa ser descoberto pela sereia dentro do jogo.

O gatilho de descoberta é **aleatório** e pode vir de duas fontes:
- Um **evento aleatório** durante a exploração, ou
- Um **POI específico** que contém a pista do novo mapa.

Qual das duas fontes dispara é definido pelo acaso — o jogador não sabe de onde vai vir.
O destino da pista segue a ordem de progressão dos mapas elegíveis ainda desconhecidos; a aleatoriedade decide **quando e de qual fonte** a pista aparece, não pula para qualquer mapa distante da lista.

### Fluxo de desbloqueio

1. Evento ou POI revela a existência de um novo mapa.
2. A sereia recebe um "mapa" (fragmento de direção) para aquele local.
3. O **jogador precisa clicar para ela seguir o mapa** — não acontece sozinho.
4. Ela traça caminho até o ponto de descoberta dentro do mapa atual.
5. Ao chegar, a área sofre uma **leve alteração visual** que remete ao próximo mapa — paleta, luz, fauna diferente aparecendo.
6. A sereia demonstra **curiosidade** — reação narrativa/visual de querer explorar o novo lugar.
7. Aparece um **botão para o jogador confirmar** que ela vai seguir para o novo mapa.
8. Ao confirmar, a tela carrega o novo mapa.

### Arquitetura — GameScene por mapa

> 📝 **Nota crítica para o desenvolvedor**
>
> Cada mapa é uma **GameScene separada e independente**. Não existe um mundo contínuo onde todos os mapas existem ao mesmo tempo carregados em memória — cada viagem entre mapas é um **carregamento de nova scene**.
>
> Isso é uma decisão arquitetural central. Benefícios:
> - Memória controlada — só a scene atual está carregada.
> - Cada mapa tem sua própria paleta, fauna, física de água, eventos — sem conflito.
> - Adicionar novos mapas no futuro = criar nova scene, sem mexer nas existentes.
>
> O sistema de viagem deve salvar o estado atual (posição, POIs, gradiente de mapa revelado) **antes** de descarregar a scene, e carregar o estado salvo do destino ao iniciar a nova scene.

---

## Energia e Exploração

- Sistema de energia já implementado — **não alterar**.
- Única influência no contexto de mapas: **distância máxima que a sereia consegue percorrer antes de cansar**.
- Energia não trava acesso a mapas nem profundidades além disso.

---

## Chegada em Mapa Novo

Quando a sereia entra em um mapa pela primeira vez (ou em uma profundidade nova dentro de um mapa):

- Exibir **textos flutuantes de storytelling** — frases curtas que ambientam aquele lugar.
- Sem cutscene obrigatória; o texto é leve, não bloqueia a jogadora.
- Conteúdo dos textos varia por mapa + profundidade.

> 📝 Desenvolvedor: criar um sistema simples de `entryText` por `mapId + profundidade`, disparado uma única vez na primeira visita. Salvar flag `primeiraVisita` por save.

---

## Progressão de Fase

Segue o sistema já implementado no jogo — **não alterar**.

---

## Refúgio

Por enquanto simples — recompensas de exploração **não afetam o refúgio**.

Pets temporários (ex: peixe seguindo a sereia por um tempo) são efeitos temporários na cena de exploração, não itens do refúgio.

---

## Persistência e Movimento Offline

- O jogo já tem sistema de **movimento offline**: a sereia continua explorando sozinha quando o app está fechado — **manter**.
- Ao abrir o jogo, o sistema deve:
  1. Identificar a posição que a sereia estava ao fechar o app.
  2. Identificar a posição atual (onde ela chegou offline).
  3. **Traçar um caminho orgânico** entre as duas posições e aplicar o desbloqueio de mapa ao longo desse trajeto.
- Se durante o caminho offline ela passou por um POI, o jogador **poderá ver e clicar nele** no mapa.
- **Recompensas de POI só ocorrem quando o jogador está vendo** e pede para a sereia interagir — não acontecem automaticamente offline.

---

## Conchas (Moeda)

Balanceamento base implementado em `GameBalance`.

- Minigames nao convertem pontuacao bruta direto em conchas.
- Cada minigame tem perfil economico por dificuldade e volume natural de pontos.
- Criterio atual documentado em [`docs/BALANCEAMENTO_MINIGAMES.md`](BALANCEAMENTO_MINIGAMES.md).

---

## Decisões Abertas

*(nenhuma no momento)*

---

*Última atualização: 2026-06-14 — porcentagem de descoberta passa a combinar área revelada + POIs alcançáveis; fase agora é elegibilidade, não descoberta automática de mapa; pistas seguem ordem de progressão dos mapas elegíveis*
