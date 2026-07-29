# GOAT Hub Build

Hub separado para o jogo BuildBoat analisado. Ele não compartilha `Config` nem
branches de place com o GOATHub existente.

## Antes de publicar

Edite `Config.lua` e substitua os dois zeros:

```lua
GAME_ID = 0,
PLACES = {
    MAIN = 0,
},
```

Com qualquer ID em zero, ou fora do jogo/place configurado, `Main.lua` encerra
antes de criar a UI, carregar features ou procurar remotes.

## Funcionalidades

- Monitor do inventário real em `LocalPlayer.Data`.
- AutoDupe experimental limitado a seis tentativas com
  `ItemBoughtFromShop:InvokeServer("Common Chest", 0.1)`.
- Parada de segurança se houver redução de Gold.
- Auto aceitar entrada na equipe.
- Auto permitir edição de blocos, com restauração do callback original ao
  desligar/fechar o hub.

O AutoDupe é um verificador experimental, não uma duplicação confirmada. No log
fornecido, todas as seis chamadas `0.1` foram rejeitadas sem gasto e sem item.
Consulte `ANALISE.md` para a reconstrução completa.

A parada por redução de Gold ocorre depois da primeira resposta. O log indica
que `0.1` custa zero, mas uma mudança futura do servidor pode alterar esse
comportamento; nenhum script cliente consegue garantir isso antecipadamente.

Não foram adicionados Auto Gold, Auto Quest, Auto Launch ou Save/Load porque os
logs e fontes fornecidos não registram os remotes/argumentos desses fluxos.

## Arquivos para deploy

Mantenha estes caminhos no branch `main` do repositório configurado em
`HUB_URL`:

```text
GOATHubBuild/Main.lua
GOATHubBuild/Config.lua
GOATHubBuild/AutoDupe.lua
GOATHubBuild/InventoryMonitor.lua
GOATHubBuild/AutoRequests.lua
GOATHubGUI/UI.lua
```

Execute o entrypoint:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/TaxD-drop/GOATHub/refs/heads/main/GOATHubBuild/Main.lua"
))()
```

Depois do primeiro teste no jogo, gere outro log contendo
`ItemBoughtFromShop` e confira se houve alguma mudança real em
`LocalPlayer.Data`. A animação `DisplayGainedItem` isolada não é confirmação.
