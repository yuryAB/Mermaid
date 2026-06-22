# Balanceamento de Minigames

Este criterio define quanto a pontuacao de cada minigame vale em conchas. A regra central: pontuacao bruta nao vira concha direto. Cada minigame passa por um perfil economico que considera dificuldade e volume natural de pontos.

## Formula

```text
pontosEconomicos = round(pontosBrutos * taxaDoMinigame)
bonusMeta = round(bonusDaFase * multiplicadorDeMeta) quando a meta foi atingida
conchasBase = pontosEconomicos + bonusMeta
conchasBase *= 3 em desafio especial
conchasBase = min(conchasBase, pontosBrutos)
conchasFinais = min(round(conchasBase * multiplicadorDeGanhoDeConchas), pontosBrutos)
```

`pontosBrutos` seguem visiveis na tela e continuam valendo para recordes. `pontosEconomicos` existem so para converter recompensa.
Regra dura: conchas finais nunca podem ser maiores que pontos brutos.

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

| Minigame | Volume de pontos | Dificuldade | Taxa ponto -> concha | Multiplicador de meta | Racional |
|---|---:|---:|---:|---:|---|
| Subida | Muito baixo | 4 | 0.75 | 0.50 | Cada bolha vale so 1 ponto; maior taxa, mas sempre abaixo do score. |
| Trama | Baixo | 2 | 0.62 | 0.50 | Score cresce devagar, mas jogo e simples e perdoa bastante. |
| Lembrancas | Medio-alto | 4 | 0.50 | 0.65 | Exige memoria e pune erro; bonus de meta paga execucao boa. |
| Banquete | Medio-alto | 3 | 0.46 | 0.55 | Movimento e risco elevam dificuldade, mas pontuacao sobe em blocos grandes. |
| Estalo | Alto | 2 | 0.36 | 0.35 | Pontua muito rapido em grupos e combos; concha por ponto deve ser menor. |
| Ruptura | Muito alto | 5 | 0.16 | 0.75 | Score bruto e enorme; taxa baixa compensa volume, bonus paga risco. |

## Regra de Ajuste

Depois de playtest, comparar conchas por minuto, nao so conchas por run. Meta saudavel:

- Minigame facil: menor concha/minuto, mais consistente.
- Minigame medio: concha/minuto base da economia.
- Minigame dificil: maior teto, mas media so deve superar os faceis quando jogador joga bem.

Se um minigame facil estiver dominando farm, diminuir `taxaDoMinigame`. Se um minigame dificil estiver pagando pouco apesar de boa execucao, aumentar `multiplicadorDeMeta` primeiro; isso premia vencer sem inflar tentativas ruins.
