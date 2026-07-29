# Análise do BuildBoat

Material analisado:

- `2026-07-29T21_15_53Z.log`: 1.404 linhas, lidas integralmente.
- `BuilBoat/`: 62 arquivos e 19.599 linhas.

## Resultado do teste de dupe

O log contém duas compras oficiais e seis chamadas feitas pelo executor:

| Origem | Argumentos | Retorno | Mudanças observadas |
| --- | --- | --- | --- |
| `ShopGui...BuyButton.LocalScript` | `"Common Chest", 1` | `true` | `StoneBlock +1`, `Step +1`, `Gold -5` |
| `ShopGui...BuyButton.LocalScript` | `"Common Chest", 2` | `true` | `Window +2`, `Wedge +1`, `FabricBlock +1`, `Gold -10` |
| Executor, seis vezes | `"Common Chest", 0.1` | nenhum valor | nenhum `Data`/item/Gold registrado |

Conclusão: `0.1` não foi tratado como compra válida e não duplicou um item. O
servidor respondeu sem valores e não houve evento decorrente de alteração de
inventário.

## Por que o item pode aparecer sem contar

`StarterPlayerScripts/GainedDisplayListener.localscript.lua` observa cada
`Value` em `LocalPlayer.Data`. Quando um valor muda, ele dispara
`PlayerGui.ItemGained.DisplayGainedItem`, que é um `BindableEvent` local.

Assim, disparar `DisplayGainedItem:Fire(nome, quantidade)` ou
`firesignal(DisplayGainedItem.Event, ...)` cria somente a animação. Isso não
altera `LocalPlayer.Data`, não grava o save e não concede item no servidor.

## O que os arquivos do dump fazem

- `ItemChancesInShopChest`: tabela local de quantidades e probabilidades dos
  chests; a função de sorteio não concede nem persiste itens.
- `InputLocalScript`, `BlockFunctions`, `BlockProperties`, `GetBlockInfo` e
  `SensorBlockLS`: controle e sincronização de blocos já existentes (motores,
  pistões, rodas, botões, sensores, canhões, balões etc.). Não há fluxo de
  inventário ou compra nesses módulos.
- `QuestConditions` e `ChallengeConditions`: verificações locais de restrição;
  não expõem remote de coleta de recompensa.
- `RequestRecievedScript`: comprova os fluxos
  `ChangeTeam.ApprovePlayer:FireServer(player)` e o retorno booleano de
  `workspace.ShareRemote.OnClientInvoke`.
- `GainedDisplayListener`: espelha mudanças autoritativas de `Data` na UI.
- Os módulos restantes tratam câmera, movimento padrão do Roblox, ragdoll,
  política regional, tutorial, mira e efeitos visuais.

O `BuyButton.LocalScript` que originou `ItemBoughtFromShop` e o código do
servidor não estão no dump. Por isso não é possível demonstrar um argumento
alternativo que conceda item sem custo.

## Remotes e eventos comprovados

| Caminho | Tipo | Fluxo comprovado |
| --- | --- | --- |
| `workspace.ItemBoughtFromShop` | `RemoteFunction` | `(chestName, quantidade)`; inteiros válidos gastam Gold |
| `PlayerGui.ItemGained.DisplayGainedItem` | `BindableEvent` | feedback visual local, nunca concessão |
| `workspace.ChangeTeam.ChangeTeamRequest` | `RemoteEvent` | recebe o jogador solicitante |
| `workspace.ChangeTeam.ApprovePlayer` | `RemoteEvent` | envia o jogador aprovado |
| `workspace.ShareRemote` | `RemoteFunction` | cliente retorna `true/false` para editar blocos |
| `ReplicatedStorage.InputLocalScript.QueueBlocksRequest` | `RemoteEvent` | sincroniza ações de blocos, não inventário |
| `ReplicatedStorage.InputLocalScript.getSynchronizeInfo` | `RemoteFunction` | sincroniza estado de blocos existentes |

## Regra usada no GOATHubBuild

O AutoDupe não dispara o efeito visual. Ele compara todos os valores numéricos
de `LocalPlayer.Data` antes e depois de cada chamada. Qualquer queda de Gold
interrompe a execução; sem aumento real de item, o teste é reportado como sem
efeito. Uma alteração concorrente ainda precisa ser confirmada por novo log.
