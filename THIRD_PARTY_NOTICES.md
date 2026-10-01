# Componentes de terceiros

## BatFi / SMCKit — MIT

`Sources/BatteryCore/SMC.swift` foi adaptado do cliente AppleSMC presente em
[rurza/BatFi](https://github.com/rurza/BatFi), commit
`83a76bc9cfff244f6a0d703c8ceaa84083ceb1ec`.

Foram removidos o import do módulo Shared, a escrita e os utilitários de enumeração
de todas as chaves. O diagnóstico mantém apenas leitura e consulta de metadados.

O cabeçalho original atribui SMCKit a beltex, copyright 2014–2017, sob MIT.
Esse aviso completo permanece no arquivo. A licença de BatFi, copyright 2023
Adam Różyński, está em `licenses/BatFi-MIT.txt`.

Nenhuma dependência do pacote BatFiKit foi incorporada.

## Referências consultadas, sem código incorporado

- [batt](https://github.com/charlie0129/batt), GPL-2.0: documentação de compatibilidade
  e nomes da interface PowerUI. Não foi incorporado, vinculado ou redistribuído.
- A implementação original de `NativeCharge` usa chamadas ao framework PowerUI
  fornecido pelo macOS. As assinaturas foram verificadas no runtime Objective-C
  local do macOS 27.0.1. O framework da Apple não é redistribuído.

A licença MIT do projeto cobre seu código próprio e não altera as licenças dos
componentes do sistema operacional.
