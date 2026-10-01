# Guia de uso do BatHold

Este guia descreve a versão 0.1.0, ainda experimental.

## Preparar e abrir

Você precisa de um Mac com Apple Silicon, macOS 14 ou posterior e Xcode ou Command Line Tools com Swift 5.9+. O controle depende do serviço nativo de carga compatível; o painel pode funcionar mesmo quando o controle não está disponível.

```sh
git clone https://github.com/ferreiralisson/bathold.git
cd bathold
swift test
zsh scripts/build-app.sh
open dist/BatHold.app
```

Para editar o código, abra `Package.swift` no Xcode. Para usar o app fora da pasta do projeto, copie `dist/BatHold.app` para Aplicativos pelo Finder. O app local não tem notarização Apple; ainda não há instalador publicado.

## Encontrar o painel

O BatHold funciona na **barra de menus**, sem uma janela principal permanente. Clique no ícone de bateria com o percentual para abrir o painel.

Se o ícone não aparecer, confira se há espaço na barra de menus e se algum gerenciador de ícones está ocultando o app. Abra `BatHold.app` novamente caso ele tenha sido encerrado. Use **Atualizar** para solicitar uma leitura imediata.

## Entender as informações

| Informação | Significado |
| --- | --- |
| Percentual | Carga atual informada pela bateria |
| Na tomada / Na bateria | Conexão à alimentação externa |
| Saúde estimada | Capacidade nominal em relação à capacidade de projeto, limitada a 100% |
| Ciclos | Contagem informada pelo sistema |
| Temperatura | Temperatura disponível na leitura; pode aparecer como `—` |
| Carga / Descarga em W | Potência estimada pela corrente e tensão |
| Limite ativo | Percentual e ativação confirmados pelo serviço nativo |

Os dados são atualizados a cada 30 segundos e após despertar. A saúde é uma estimativa; consulte também os Ajustes de Bateria da Apple. `—` indica informação indisponível, não zero.

## Definir um limite

1. Abra o painel na barra de menus.
2. Escolha um dos percentuais disponíveis, como **80%**.
3. Aguarde a confirmação do macOS no painel.

A escolha altera a configuração real do sistema. No Mac validado, as opções são 80%, 85%, 90%, 95% e 100%. O app usa a lista devolvida pelo serviço e não oferece limites abaixo dela.

O macOS pode realizar cargas ocasionais até 100% para ajustar sua estimativa. Se a bateria já estiver acima do percentual escolhido, o BatHold não força descarga. O limite controla o carregamento futuro conforme o comportamento do sistema.

## Solicitar carga completa

Clique em **Carregar até 100% agora** para solicitar a suspensão temporária do limite ao macOS. O sistema gerencia a retomada; o BatHold não usa um temporizador próprio.

A função está implementada, mas duração e retomada ainda precisam de validação com carregador conectado. A configuração exibida pelo serviço pode continuar indicando o limite habitual durante a solicitação temporária.

## Desativar o limite e sair

**Desativar limite** remove a limitação pelo serviço do sistema. Depois da operação, o app consulta novamente o estado para confirmar a desativação.

**Sair** fecha o BatHold. Fechar o app não desfaz a configuração de limite do macOS. Você também pode usar **Ajustes de Bateria** para configurar a carga diretamente pelo sistema.

Início automático e notificações ainda não estão implementados.

## Usar o CLI

Execute os comandos a partir da pasta do projeto, depois de gerar o app:

| Comando | Resultado |
| --- | --- |
| `dist/bathold status` | Dados da bateria em JSON |
| `dist/bathold diagnose` | Compatibilidade, bateria, serviço nativo e leitura de chaves SMC |
| `dist/bathold charge-status` | Percentuais disponíveis, limite salvo e ativação |
| `dist/bathold limit 80` | Aplica e verifica 80% |
| `dist/bathold charge-full` | Solicita carga completa temporária |
| `dist/bathold disable` | Desativa e verifica o limite |
| `dist/bathold --help` | Lista de comandos |

Os três primeiros são somente de leitura. `limit`, `charge-full` e `disable` alteram o controle de carga. Não é necessário `sudo` no Mac validado.

## Testar e restaurar o controle

Este teste é opcional e modifica a configuração por instantes. Verifica a aceitação de outro limite pelo serviço e restaura o percentual e a ativação anteriores. Faça o teste sem uma carga completa temporária já em andamento.

```sh
mkdir -p artifacts
dist/bathold verify-control artifacts/recovery.json
```

O arquivo é salvo antes da alteração e não é sobrescrito; para repetir o teste, escolha outro nome. O resultado informa os estados `original`, `applied` e `restored`.

Se o processo for interrompido, recupere a configuração:

```sh
dist/bathold restore artifacts/recovery.json
dist/bathold charge-status
```

Se a recuperação falhar, use os Ajustes de Bateria. O arquivo captura percentual e ativação, sem capturar um override temporário preexistente. O teste não comprova comportamento físico de carga, repouso ou reinício.

## Resolver problemas

### Controle de carga indisponível

Use **Ajustes de Bateria** e rode `dist/bathold diagnose`. O serviço privado pode não estar disponível nessa versão ou nesse hardware. Alterações de API podem exigir atualização do BatHold; não há necessidade de desativar SIP.

### Couldn't communicate with a helper application

Um sandbox pode impedir comunicação com PowerUIAgent. Tente abrir o `.app` pelo Finder ou executar o CLI pelo Terminal. Uma falha dentro de um sandbox não prova incompatibilidade do Mac.

### Temperatura ou outras métricas aparecem como `—`

O sistema não forneceu uma leitura utilizável. Isso é esperado em algumas combinações de modelo e firmware. O Mac inicialmente validado não forneceu temperatura nas propriedades consultadas.

### O limite foi aceito, mas a bateria passou dele

Confira `dist/bathold charge-status` e os Ajustes de Bateria. O macOS pode ocasionalmente carregar até 100%. Esta versão ainda precisa de testes físicos durante carga, repouso e reinício; registre o comportamento com modelo, macOS e firmware.

## Compartilhar um diagnóstico

```sh
mkdir -p artifacts
dist/bathold diagnose > artifacts/diagnostic.json
```

Revise o arquivo e inclua as partes relevantes em uma [issue](https://github.com/ferreiralisson/bathold/issues). O BatHold não coleta número de série, UUID ou localização; não há envio automático. Relatórios locais não entram nos commits.

## Remover o aplicativo

Se quiser remover também o limite, desative-o pelo painel ou pelos Ajustes de Bateria. Depois, use **Sair** e mova o app para a Lixeira pelo Finder. O projeto não instala serviço próprio com privilégios nem componentes de sistema.
