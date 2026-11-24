# Guia de defesa individual

O professor pode pedir qualquer trecho e uma pequena alteração. Este guia serve para estudar o código; a apresentação deve demonstrar o aplicativo real após a configuração e os testes.

## Apresentação sugerida — aproximadamente 8 a 10 minutos

1. **Objetivo e tema:** apresentar Entrelinhas como biblioteca pessoal com anotações, progresso e agenda de leitura. A busca da Open Library mantém a base do primeiro trabalho.
2. **Autenticação:** criar/entrar em uma conta, mostrar o nome, explicar validações e recuperação de senha. Mostrar que não é um login fictício.
3. **CRUD e calendário:** cadastrar um livro, selecionar uma data, visualizar o evento, abrir detalhes e editar. Demonstrar a atualização da interface.
4. **Integrações:** pesquisar um livro na API, preencher o formulário, obter coordenadas e escolher uma foto. Explicar a diferença entre capa por URL e foto local.
5. **Offline, parte principal:** criar uma alteração sem rede, fechar/abrir o app, editar e excluir. Mostrar a tabela SQLite com pendências e o tombstone.
6. **Reconexão:** restaurar a rede, mostrar a sincronização, o documento com ID único no Console e a limpeza no SQLite depois da confirmação.
7. **Código e segurança:** abrir os arquivos principais, explicar o UID, as regras e o `changeId`. Concluir mostrando o repositório e o APK testado.

## Perguntas e pontos do código

| Pergunta prevista | Onde olhar | Explicação a dominar |
| --- | --- | --- |
| Qual a estrutura do projeto? | Pastas `view`, `database`, `service`, `controller`, `widgets` | Interface não contém SQL nem a comunicação direta com Firestore. |
| O que `main.dart` faz? | `main`, `initializeServices`, `EntrelinhasApp`, `_BootstrapPage` | Inicializa bindings, idioma e Firebase, define tema/localização e só libera o app após inicialização e estado de autenticação. |
| Como Firebase é configurado? | `scripts/configurar_firebase.ps1`, `firebase_options.dart` gerado | FlutterFire CLI associa o aplicativo Android ao projeto real. O arquivo atual precisa ser gerado, não contém configuração pronta. |
| Como o login funciona? | `AuthService`, `LoginPage` | Firebase Auth verifica e-mail/senha; stream observa o usuário; nome é `displayName`; logout usa `signOut`. |
| Onde o registro é gravado primeiro? | `LibraryController.save`, `RecordHelper.save` | Primeiro SQLite, antes de iniciar um envio independente da interface. Se a rede falhar, a alteração permanece durável. |
| Como cria e atualiza no Firestore? | `FirestoreService.save` | `users/{uid}/registros/{uuid}.set(...)`; o UUID estável permite repetir a operação sem gerar outro documento. |
| Qual a diferença entre os bancos? | `RecordHelper`, `FirestoreService` | SQLite é uma fila local explícita de pendências; Firestore é o banco remoto e oferece seu próprio cache persistente para registros já sincronizados. |
| Como detecta falta de internet? | `ConnectivityService`, `LibraryController` | Rede disponível é só um sinal. Acesso real ao servidor é confirmado pelas operações; erro/timeout mantém a fila. |
| Quando sincroniza? | `LibraryController.start`, `synchronize`, lifecycle em Home | Ao iniciar, reconectar, retornar ao app, por timer quando há pendências e pelo botão manual. |
| Como impede perda de edição durante um envio? | `SyncService`, `RecordHelper.acknowledge` | O ACK só remove a linha se seu `changeId` ainda for o mesmo. Uma alteração mais nova continua e será enviada em seguida. |
| Como funciona a exclusão offline? | `RecordHelper.delete`, `deletedAt`, `SyncService` | Guarda tombstone no SQLite; a interface oculta o livro; quando online faz delete remoto e só depois limpa localmente. |
| Por que não manter todos os livros no SQLite? | `LibraryController.merge` | O PDF exige limpar os dados enviados do banco local. A fila é removida após ACK; o cache do SDK Firestore mantém a última consulta. |
| Como separa contas? | Queries por `userId`, caminho Firestore, regras e diretório de fotos | A interface troca o controller por UID e o servidor rejeita acesso de outro usuário; não é apenas um filtro visual. |
| Como funciona o GPS? | `LocationService.currentPosition`, formulário | Verifica serviço ativo, pede permissão, trata negação/bloqueio, lê posição e vincula as coordenadas ao registro. |
| Como o calendário recebe eventos? | `_events`, `eventLoader`, `onDaySelected` | Filtra `eventAt` pelo dia local; a mesma lista controla marcadores e os cartões da data selecionada. |
| Por que tipos diferentes de botão? | Formulário, conta, autenticação e FAB | Filled enfatiza salvar; Outlined é alternativa; Text é ação secundária; Icon é ação compacta; FAB inicia cadastro. |
| Como consome a API? | `OpenLibraryService.search`, `ExplorePage` | Monta URI HTTPS, aguarda HTTP, valida status, decodifica JSON, modela livros, trata falhas e apresenta resultados/paginação. |
| Como a foto persiste? | `PhotoService` | Copia o arquivo temporário para Documents, por UID/UUID. Existe uma por livro; não sincroniza arquivos nem envia caminhos locais para a nuvem. |
| Como datas são tratadas? | `ReadingRecord.toMap/fromMap`, `FirestoreService` | Persistência normalizada em UTC; Firestore usa Timestamp; a interface converte de volta à hora local para a agenda. |

## Exercícios para se preparar

1. Alterar uma cor em `AppTheme`, executar e explicar por que os componentes seguem o tema.
2. Alterar o rótulo de uma situação em `ReadingStatus` e localizar onde ele aparece.
3. Tornar o campo de anotações opcional. Explicar que também seria necessário ajustar a validação das regras, sem deixar app e servidor incompatíveis.
4. Mudar a quantidade de livros por página e ajustar coerentemente a paginação.
5. Explicar por que remover o `await` do envio remoto antes de limpar o SQLite causa perda de dados.
6. Explicar por que trocar o UUID estável por `collection.add` em cada tentativa pode duplicar registros.
7. Demonstrar no código a diferença entre excluir imediatamente a linha pendente e registrar uma exclusão que sobreviva ao reinício.
8. Explicar o que acontece quando uma conta sai com pendências e por que elas não devem ser enviadas usando a conta seguinte.

Não informe que testes, APK, configuração Firebase ou publicação foram concluídos enquanto estiverem pendentes no relatório de validação.
