# GOAT Hub

Estrutura modular para Roblox/Luau:

- `Main.lua`: LocalScript que primeiro valida o `gameId` e inicia somente os recursos permitidos no place atual.
- `UI.lua`: ModuleScript da janela, checkbox, seletores recolhíveis e arraste.
- `AutoBuy.lua`: ModuleScript da compra automática.
- `AutoGift.lua`: ModuleScript da coleta de gifts.
- `AutoOrbs.lua`, `AutoBreakables.lua` e `AutoEggs.lua`: recursos do place de farming.
- `Config.lua`: IDs do jogo e dos places permitidos.

No log analisado, a coleta usa `ReplicatedStorage.Network["Redeem Free Gift"]:InvokeServer(indice)` e o evento `Free Gift: Claimed` confirma uma coleta aceita. O módulo tenta os índices de 1 a 12 a cada 15 segundos; o servidor somente aceitará os gifts já disponíveis. Ajuste `GIFT_COUNT` em `AutoGift.lua` caso o jogo tenha uma quantidade diferente de presentes.

Para usar como ModuleScripts, mantenha todos os módulos e `Main` dentro da mesma pasta `GOATHub`; `Main` os carrega por `script.Parent`.

## Escopo

- O script encerra imediatamente se `game.GameId` não for `3317771874`.
- `Auto Collect Gift` aparece em qualquer place desse jogo.
- Auto-Buy, Eggs, Suprimentos e Traveling Merchant aparecem somente no place `119454325063278`.
- Auto Orbs/Moedas, Auto Quebrar Items e Auto Open Eggs aparecem somente no place `140403681187145`.

O Auto Open usa `Eggs_RequestPurchase(egg, 3)`, como registrado no log. Em executores que oferecem `getconnections`, a animação visual de abertura é suspensa temporariamente enquanto o Auto Open está ligado; fora deles, a abertura continua com a animação normal.
