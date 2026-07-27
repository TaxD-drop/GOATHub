# GOAT Hub

Estrutura modular para Roblox/Luau:

- `Main.lua`: LocalScript que inicia a interface.
- `UI.lua`: ModuleScript da janela, checkbox, seletores recolhíveis e arraste.
- `AutoBuy.lua`: ModuleScript da compra automática.
- `AutoGift.lua`: ModuleScript da coleta de gifts.

No log analisado, a coleta usa `ReplicatedStorage.Network["Redeem Free Gift"]:InvokeServer(indice)` e o evento `Free Gift: Claimed` confirma uma coleta aceita. O módulo tenta os índices de 1 a 12 a cada 15 segundos; o servidor somente aceitará os gifts já disponíveis. Ajuste `GIFT_COUNT` em `AutoGift.lua` caso o jogo tenha uma quantidade diferente de presentes.

Para usar como ModuleScripts, mantenha os três módulos e `Main` dentro da mesma pasta `GOATHub`; `Main` os carrega por `script.Parent`.
