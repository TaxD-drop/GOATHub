# GOAT Hub

Estrutura modular para Roblox/Luau:

- `Main.lua`: LocalScript que primeiro valida o `gameId` e inicia somente os recursos permitidos no place atual.
- `AutoBuy.lua`: ModuleScript da compra automática.
- `AutoGift.lua`: ModuleScript da coleta de gifts.
- `AutoDailyRewards.lua`: coleta os pads/recompensas diárias cujo cooldown terminou.
- `AutoRanks.lua`: coleta as recompensas de rank já liberadas pelas estrelas.
- `AutoVendingMachines.lua`: compra automaticamente nas Vending Machines que têm estoque e saldo suficiente.
- `AutoOrbs.lua`, `AutoBreakables.lua` e `AutoEggs.lua`: recursos do place de farming.
- `Config.lua`: IDs do jogo e dos places permitidos.

Os componentes da interface ficam na pasta irmã `GOATHubGUI`; veja o README dela para conectá-los a novas funcionalidades.

No log analisado, a coleta usa `ReplicatedStorage.Network["Redeem Free Gift"]:InvokeServer(indice)` e o evento `Free Gift: Claimed` confirma uma coleta aceita. O módulo tenta os índices de 1 a 12 a cada 15 segundos; o servidor somente aceitará os gifts já disponíveis. Ajuste `GIFT_COUNT` em `AutoGift.lua` caso o jogo tenha uma quantidade diferente de presentes.

O Main é compatível com execução por `loadstring`: seus módulos são baixados de `https://raw.githubusercontent.com/TaxD-drop/GOATHub/refs/heads/main/`. Há arquivos de entrada com esses nomes na raiz do projeto; eles encaminham para as implementações dentro das pastas e preservam essa organização.

## Escopo

- O script encerra imediatamente se `game.GameId` não for `3317771874`.
- `Auto Collect Gift` aparece em qualquer place desse jogo.
- Daily Rewards, Ranks e Vending Machines aparecem somente nos places de farming. A compra prepara e lê o estoque de cada Vending Machine antes de comprar. Ela respeita o limite normal de 3 unidades por máquina; com o perk oficial de estoque completo, compra todo o estoque, exatamente como o menu do jogo.
- Auto-Buy, Eggs, Suprimentos e Traveling Merchant aparecem somente no place `119454325063278`.
- Auto Orbs/Moedas, Auto Quebrar Items e Auto Eggs aparecem nos places `140403681187145` e `8737899170`.

O Auto Quebrar fixa o item mais próximo durante uma sequência de golpes. Assim os seus cliques normais na tela não trocam o alvo da automação.

Auto Eggs mostra os eggs na ordem oficial (`eggNumber`), usando o formato `Ovo N — Nome`, e usa `Eggs_RequestPurchase` com o máximo de eggs que o jogador pode pagar/abrir. O servidor continua validando moeda e desbloqueio do egg; a posição física do modelo do egg não é enviada no remote.
