# Balanceamento de Minigames

Este criterio define quanto a pontuacao de cada minigame vale em conchas. A regra central: pontuacao bruta nao vira concha direto. Cada minigame passa por um perfil economico que considera dificuldade e volume natural de pontos.

## Formula

```text
pontosEconomicos = round(pontosBrutos * taxaDoMinigame)
bonusVitoria = round(pontosEconomicos * 0.50) apenas se o premio da vitoria for conchas
conchasBase = pontosEconomicos + bonusVitoria
conchasBase *= 3 em desafio especial
conchasBase = min(conchasBase, pontosBrutos)
conchasFinais = min(round(conchasBase * multiplicadorDeGanhoDeConchas), pontosBrutos)
```

`pontosBrutos` seguem visiveis na tela e continuam valendo para recordes. `pontosEconomicos` existem so para converter recompensa.
Regra dura: conchas finais nunca podem ser maiores que pontos brutos.
O multiplicador global de ganho de conchas comeca em 0.45x, sobe +0.02 por nivel do aprimoramento "Ganho de conchas" e trava em 1.8x.

Ao vencer um desafio comum, a vitoria sorteia um premio: ou +50% nas conchas convertidas, ou 1 recurso elegivel. Os dois premios nao acumulam. Recursos de crescimento acelerado ficam fora desse sorteio. Desafios especiais nao usam esse premio comum porque ja tem regra propria de dificuldade e recompensa.

Metas nao aparecem como valor fixo na lista de desafios. Quando um peixe ou POI oferece um desafio, a oferta sorteia uma meta dentro de uma faixa. Desafios comuns usam `commonChallengeGoalMultiplierRange` (1.18x...1.35x). Desafios especiais/POI usam `specialChallengeGoalMultiplierRange` (1.38x...1.62x), mantendo pontos de interesse acima dos desafios comuns.

## Criterio de Dificuldade

Use nota de 1 a 5:

| Nota | Criterio |
|---|---|
| 1 | Quase sem risco, sem pressao real, pontuacao facil de repetir. |
| 2 | Regras simples, pouca penalidade, exige atencao leve. |
| 3 | Pressao de tempo ou movimento constante, erro atrapalha a run. |
| 4 | Exige memoria, precisao ou controle sob pressao; falhas custam bastante. |
| 5 | Alta execucao, alta variancia, high score dificil e risco constante. |

Para escolher a nota, avaliar:

- Pressao de tempo.
- Penalidade por erro.
- Precisao motora.
- Carga de memoria/planejamento.
- Variancia ou aleatoriedade.
- Pontos por minuto de uma run mediana.

## Perfis Atuais

| Minigame | Volume de pontos | Dificuldade | Taxa ponto -> concha | Racional |
|---|---:|---:|---:|---|
| Subida | Muito baixo | 4 | 0.58 | Cada bolha vale so 1 ponto; taxa ainda maior, mas sem acelerar demais o inicio. |
| Trama | Baixo | 2 | 0.38 | Score cresce devagar, mas jogo e simples e perdoa bastante. |
| Lembrancas | Medio-alto | 4 | 0.32 | Exige memoria e pune erro; taxa maior compensa execucao boa sem inflar tentativas ruins. |
| Banquete | Medio-alto | 3 | 0.28 | Movimento e risco elevam dificuldade, mas pontuacao sobe em blocos grandes. |
| Estalo | Alto | 2 | 0.20 | Pontua muito rapido em grupos e combos; concha por ponto deve ser bem menor. |
| Ruptura | Muito alto | 5 | 0.09 | Score bruto e enorme; taxa baixa compensa volume e risco. |

## Regra de Ajuste

Depois de playtest, comparar conchas por minuto, nao so conchas por run. Meta saudavel:

- Minigame facil: menor concha/minuto, mais consistente.
- Minigame medio: concha/minuto base da economia.
- Minigame dificil: maior teto, mas media so deve superar os faceis quando jogador joga bem.

Se um minigame facil estiver dominando farm, diminuir `taxaDoMinigame`. Se um minigame dificil estiver pagando pouco apesar de boa execucao, ajustar `taxaDoMinigame` ou a chance do premio de recurso sem inflar tentativas ruins.
