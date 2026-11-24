# Roteiro para emulador Android e apresentação

Pré-requisitos: Firebase real configurado, E-mail/senha habilitado, Firestore criado, regras publicadas, dependências instaladas e aplicativo compilado. Execute no Android e anote o resultado observado; esta lista preparada não é um registro de testes já aprovados.

## Sequência do professor

| Passo | Ação | Resultado esperado |
| --- | --- | --- |
| 1 | Abrir o aplicativo | Ícone próprio, splash e tela de login. |
| 2 | Cadastre-se, preencha nome completo, e-mail, senha e confirmação | Campos inválidos impedem envio; conta é criada no Firebase Auth; nome aparece na biblioteca/conta. |
| 3 | Encerrar completamente o aplicativo | Processo fechado, sem apagar dados do app. |
| 4 | Abrir novamente; para demonstrar login manual, sair pela Conta e entrar de novo | A sessão é persistida; login aceita credenciais corretas e rejeita as inválidas. |
| 5 | Novo livro; preencher título, autor, notas, data e situação; salvar | Mensagem de salvamento; alteração passa primeiro pelo SQLite. |
| 6 | Consultar na Biblioteca e abrir o cartão | Título, notas, data, autor, situação e progresso correspondem ao cadastro. |
| 7 | Abrir Agenda e selecionar a data do livro | Data selecionada identificada visualmente. |
| 8 | Conferir a lista e o marcador no calendário | Livro aparece somente na data correta; navegar meses preserva os dados. |
| 9 | Editar o livro; Obter localização atual; enviar posição nos controles do emulador | Explicação, permissão e coordenadas visíveis. |
| 10 | Salvar e abrir detalhes | Coordenadas e nome do local vinculados ao livro; conferir latitude/longitude no Console. |
| 11 | Alterar notas, progresso e data | Biblioteca e calendário se atualizam sem reiniciar; documento remoto mantém o mesmo ID. |
| 12 | Excluir e confirmar | Livro sai da lista e do calendário; registro remoto é excluído quando confirmado. |
| 13 | Abrir Firebase Console | Usuário em Authentication e documentos em `users/{UID}/registros`; IDs não duplicados; dados corretos. |
| 14 | Desligar as conexões Wi-Fi/dados do emulador | App informa offline; não existe limpeza indevida de pendências. |
| 15 | Cadastrar livro offline; editar uma anotação antes de sincronizar | Registro e alteração disponíveis localmente, com envio pendente. |
| 16 | Forçar encerramento e abrir ainda sem rede | Sessão e dados pendentes recuperados. Não desinstalar nem limpar armazenamento. |
| 17 | Consultar o registro local | Última edição permanece; sem duplicações e sem exigir nova autenticação online. |
| 18 | Restaurar a conexão | Sincronização automática inicia; opção manual disponível na Conta. |
| 19 | Conferir o Firestore e o SQLite | Registro remoto existe uma única vez; tabela `pending_records` desse usuário fica vazia após ACK. |

## Casos adicionais obrigatórios ou importantes

- **Recuperação:** sair, abrir Recuperar senha, informar e-mail válido, conferir mensagem e recebimento real no e-mail. Nunca gravar senha em captura ou vídeo.
- **Exclusão offline de registro remoto:** sincronizar um livro, ficar offline, excluir, reiniciar, confirmar que continua ausente, reconectar e conferir exclusão no Console.
- **Criar e excluir offline:** cadastrar sem rede e excluir antes de enviá-lo. Reconectar: o documento não pode reaparecer.
- **Editar registro já sincronizado offline:** alterar título/data sem conexão, reiniciar e reconectar; mesmo ID remoto deve receber a edição.
- **Wi-Fi sem internet:** manter interface de rede ativa sem acesso externo. Deve haver erro/pendência, sem perda e sem rótulo falso de confirmação.
- **Duas contas:** A cria um livro; sair; B entra e não enxerga A. Criar pendência de A e entrar em B não pode enviar/apagar a pendência de A. Voltar a A permite sincronizar.
- **Segurança Firestore:** com os emuladores de Firebase ou cliente autenticado de teste, tentar acessar `users/{OUTRO_UID}/registros`. Esperado: `permission-denied`. Não confundir filtro visual com proteção no servidor.
- **API real:** em Explorar, pesquisar `Dom Casmurro` ou `The Lord of the Rings`, carregar mais resultados e adicionar um à biblioteca; completar as notas e salvar. Testar vazio, sem resultados e sem rede.
- **Foto:** escolher uma foto pequena da galeria, salvar, fechar e abrir. Editar trocando a foto e remover. Capturar outra pela câmera virtual. Conferir que não surge caminho local no Firestore.
- **GPS:** testar serviço desligado, permissão negada e permissão bloqueada; oferecer caminhos para configurações e permitir salvar sem GPS. Com GPS ativo, salvar coordenadas reais/simuladas.
- **Calendário:** cadastro pelo botão da data selecionada usa essa data; edição move o marcador; exclusão remove o evento; meses anterior e seguinte navegam.
- **Botões:** mostrar FilledButton ao salvar, OutlinedButton ao cancelar, TextButton na recuperação, IconButton ao editar/excluir e FAB ao adicionar; explicar a diferença.
- **Layout:** aparelho pequeno, teclado aberto, rotação e fonte ampliada; conferir scroll do formulário, rótulos e calendário.

## Como observar o SQLite sem alterar a aplicação

Use o Database Inspector do Android Studio com o app debug em execução. Abra o arquivo `entrelinhas.db` e consulte:

```sql
SELECT id, userId, title, synced, changeId, deletedAt FROM pending_records;
```

Offline: deve mostrar as alterações e as exclusões pendentes. Depois de ACK: não deve manter linhas confirmadas. Outra conta pode ter pendências; filtre pelo UID que está sendo demonstrado. Não conclua que a fila inteira deve estar vazia se outra conta tem alterações offline.

## Antes de enviar ao professor

- Executar `scripts/verificar_e_compilar.ps1` e registrar o resultado real.
- Instalar o APK de saída no emulador, repetir os passos principais e confirmar que permissões e internet funcionam também no release.
- Incluir capturas reais de login, biblioteca, formulário, calendário e busca em `docs/screenshots/` e adicioná-las ao README.
- Disponibilizar os commits em um repositório Git e conferir acesso do professor.
- Entregar APK, fonte, configuração pública necessária e documentação; não entregar tokens, senhas, cache de ferramentas nem contas de serviço.
- Estudar `DEFESA.md` e localizar cada método sem depender de decorar texto.
