# Contribuir

Abra `Package.swift` no Xcode ou use `swift test` e
`zsh scripts/build-app.sh`. Não são necessárias dependências de terceiros.

Para problemas de compatibilidade, inclua modelo, versão de macOS, firmware,
mensagem de erro e diagnóstico obtido por `dist/bathold diagnose`.
Confira o conteúdo antes de compartilhar; os relatórios deste projeto não
incluem número de série nem UUID.

Novos backends devem detectar suporte no próprio hardware, validar entradas,
verificar o estado após alteração e documentar recuperação. Testes que alteram
a carga devem ser explícitos e restaurar o estado anterior.

Preserve os avisos de terceiros e documente qualquer código ou dependência
incorporada com sua licença.

Para propor uma mudança, faça um fork de `ferreiralisson/bathold`, crie uma branch,
prepare a alteração e abra um pull request com o problema resolvido, o comportamento
resultante e os testes executados. Recursos que dependem de hardware devem indicar
o modelo, macOS e firmware usados na validação, sem números de série ou UUIDs.

O ícone mestre está em `Assets/AppIcon.png`. O empacotamento gera o `.icns`
automaticamente; não versione binários, caches ou arquivos gerados em `dist/`.
