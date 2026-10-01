# Validação local — 1 de outubro de 2026

Hardware: MacBook Pro M1 Pro (`MacBookPro18,3`).
macOS: 27.0.1, build 26A434. Firmware: mBoot-20457.1.29.

## Confirmado

- Compilação de desenvolvimento e testes: passou.
- Quatro testes unitários: percentual por razão de capacidades, descarga negativa
  em inteiro unsigned, temperatura em Kelvin, saúde estimada, métricas ausentes,
  capacidade inválida e valores fora da faixa.
- Compilação release dos dois executáveis e empacotamento do app: passou.
- Leitura real: percentual de bateria, estado de alimentação, ciclos e potência.
- Serviço PowerUI respondeu sem root com limites 80/85/90/95/100%.
- Teste reversível: estado inicial 100% / desativado; aplicado 80% / ativado;
  restaurado 100% / desativado. A leitura posterior confirmou ambos os estados.
- Não houve escrita de chaves SMC, instalação de daemon ou alteração de SIP.

Relatórios locais ignorados pelo Git:

- `artifacts/diagnostic-local.json`
- `artifacts/control-verification.json`
- `artifacts/control-recovery.json`

## Limites da evidência

O Mac estava na bateria, sem carregador conectado. O teste comprova que o
serviço aceita e informa a alteração de configuração; não comprova a interrupção
física de carga ao atingir 80%, nem funcionamento durante repouso e reinício.

A temperatura não estava disponível nas propriedades lidas da bateria neste
Mac, e o painel a apresenta como indisponível. A saúde é uma estimativa de
capacidade, não uma leitura do diagnóstico de saúde da Apple.

As chaves CH0B, CH0C, CHTE e CH0I retornaram “não encontrada” nesta consulta;
bfF0, bfD0 e bfE0 retornaram “sem privilégio”. O processo não era root. Isso
não constitui prova independente de bloqueio dessas chaves também para root.

O controle temporário “carregar até 100% agora” foi implementado pelo método
nativo `temporarilyDisableMCL:`. Não foi executado no teste: duração e retomada
precisam ser observadas com carregador conectado antes de considerar a função
validada para uso contínuo.

O comando de abrir o app foi executado. A inspeção visual automática não pôde
ser concluída: o serviço de interação com o computador retornou timeout nas
duas tentativas. Compilação e teste do CLI não equivalem a validação visual.

## Validação após a renomeação para BatHold

- Recompilação de desenvolvimento: quatro testes passaram, sem falhas.
- Compilação release de BatHold e do CLI: passou.
- `dist/bathold --help` apresenta o novo nome e os comandos esperados.
- `dist/bathold charge-status` confirmou acesso ao serviço nativo sem root;
  o estado consultado era 100% / limite desativado. Não houve alteração de carga.
- Pacote `dist/BatHold.app`: plist válido e assinatura ad hoc verificada.
- Ícone `.icns` incluído nos recursos e declarado em `CFBundleIconFile`.
- Imagem mestre com alpha; versões do iconset incluem 1024 × 1024 com alpha.
- Links relativos do README, guia e documentos: verificados.

O nome de compilação do CLI é `bathold-cli`, para evitar colisão com `BatHold`
em volumes que ignoram maiúsculas. O empacotamento o disponibiliza como
`dist/bathold`, conforme o guia de uso.
