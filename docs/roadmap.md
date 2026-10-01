# Roteiro

## Fase 1 — prova de conceito atual

- [x] Avaliar a base pública MIT do BatFi e preservar atribuições.
- [x] Núcleo Swift com monitoramento real por IOKit.
- [x] App nativo na barra de menus e CLI.
- [x] Diagnóstico de chaves SMC somente para leitura.
- [x] Backend nativo experimental com detecção da interface e verificação do limite.
- [x] Teste de controle e recuperação da configuração anterior.
- [ ] Observação de carga física ao atingir o limite.
- [ ] Testes de repouso, despertar, reinício, MagSafe e USB-C.
- [ ] Verificação da retomada após “carregar até 100% agora”.

## Fase 2 — MVP para uso contínuo

- Início automático usando SMAppService no app empacotado.
- Notificações de alteração de modo, com autorização do usuário.
- Histórico local com retenção limitada e gráfico de carga/consumo.
- Testes em outros modelos/firmwares e classificação clara de compatibilidade.
- Assinatura e notarização das versões públicas.
- Documentação de recuperação e tratamento de falhas do backend privado.

## Fase 3 — automações

- Regras por horário e dia da semana, incluindo horários que cruzam meia-noite.
- Prioridade entre regras, identificação da regra ativa e overrides manuais.
- Persistência das regras e recomputação após despertar e mudanças de fuso.
- Localização opcional por Core Location, com autorização e processamento local.
- Atalhos globais e modos de energia, conforme suporte do modelo.

## Fase 4 — outros backends

Limites abaixo de 80% e descarga forçada exigem investigação própria em hardware
compatível. Detectar capacidades reais e não oferecer ações incompatíveis.
Evitar descarregar/recarregar continuamente como substituição silenciosa de um
limite de carga. Um daemon privilegiado só deve ser implementado quando houver
um backend validado que o exija.
