# Avaliação técnica — 1 de outubro de 2026

## Resultado

É viável produzir um app nativo open source para monitoramento, limite de carga
e automações. Equivalência total ao BatFi depende de hardware, firmware e APIs
privadas. O resultado do teste local está em `validation.md`.

## Base pública avaliada

O [BatFi público](https://github.com/rurza/BatFi) tem licença MIT. O snapshot
consultado aponta para um commit de fevereiro de 2025. Ele usa Swift/SwiftUI,
um helper com privilégios, XPC e o cliente AppleSMC de SMCKit, além de diversas
dependências. O produto comercial atual anuncia automação por local e horário;
não assumimos que essas funções estão cobertas por esse snapshot.

Decisão: aproveitar o cliente SMC MIT para diagnóstico, preservar os avisos e
criar um núcleo menor, sem importar dependências de UI, telemetria ou licença
comercial. Não usar marca nem recursos visuais do BatFi.

## Controle de carga

A [Apple](https://support.apple.com/en-ie/102338) documenta limite nativo de 80%
a 100% a partir do macOS 26.4 com Apple Silicon. O sistema pode ocasionalmente
carregar completamente para ajustar a estimativa de carga.

O [batt](https://github.com/charlie0129/batt) documenta restrições em firmwares
20457.0.125.0.2 e posteriores às chaves CH0B/CH0C/CHTE e bfF0/bfD0/bfE0,
controladas por entitlement privado. Um helper root não resolve automaticamente
esse bloqueio. Alternar a entrada de energia pode criar ciclos de descarga e
carga e afetar o uso com tampa fechada.

No Mac alvo, foi descoberta e consultada a classe `PowerUISmartChargeClient`
do framework privado PowerUI. Ela permite consultar limites e solicitar alterações
ao serviço da Apple. Isso elimina a necessidade de daemon próprio para esse
primeiro backend, mas continua dependente de uma interface privada.

A implementação verifica seletores e assinaturas antes de chamar o framework,
valida o percentual pela lista do próprio serviço e verifica o estado após
alterar o limite. Não há alteração de SIP ou acesso a chaves arbitrárias.

## Arquitetura atual

```text
App SwiftUI / CLI
        ↓
BatteryCore
  ├─ AppleSmartBattery: monitoramento por IOKit
  ├─ SMCKit adaptado: diagnóstico somente de leitura
  └─ NativeCharge: adaptador Objective-C original
        ↓
PowerUI / serviço de carga da Apple
```

As chamadas são serializadas. O app executa consultas e alterações fora da
thread principal, atualiza a cada 30 segundos e consulta novamente ao despertar.
O CLI permite exportar diagnósticos e testar/restaurar a configuração.

## Evolução

Antes de implementar um serviço próprio com privilégios, comprovar a necessidade
e a permissão do backend desejado. Se necessário, usar
[SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
e XPC com verificação do cliente, operações restritas e desinstalação que restaure
a carga. Nunca assumir que permissão de leitura garante permissão de escrita.
