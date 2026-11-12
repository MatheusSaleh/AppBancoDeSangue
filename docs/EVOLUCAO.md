# Evolução: de 2023 para 2026

Este documento separa o que foi construído em 2023, durante o Projeto de
Iniciação Científica (PIC), do que foi modernizado em 2026. O histórico
completo está no `git log`; os commits de abril a junho de 2023 são a versão
original.

## Versão original (2023)

Desenvolvida no 2º ano de Ciência da Computação, no Centro de Pesquisas em
Informática da FEMA, sem uso de ferramentas de IA.

**Proposta:** um app educativo para incentivar e orientar a doação de sangue.

**O que existia:**

- Login com e-mail e senha (Firebase Authentication).
- Notícias lidas da coleção `noticias` do Firestore.
- Registro de doação (nome e data) na coleção `doacoes`.
- Histórico de doações do usuário.
- Guia "antes, durante e depois" da doação.
- Quiz com 5 perguntas e mensagens de resultado.
- Tela "Sobre" com os autores.

**Stack:** Flutter (canal master, Dart 3.0 pré-lançamento), `firebase_core 2`,
`firebase_auth 4`, `cloud_firestore 4`, Android Gradle Plugin 7.3.

## Problemas encontrados no diagnóstico de 2026

| Área | Problema | Situação |
| --- | --- | --- |
| Fluxo | Não havia cadastro nem recuperação de senha; contas só podiam ser criadas no console do Firebase | Corrigido |
| Navegação | `StreamBuilder` de autenticação competindo com `pushReplacement` manual; após registrar uma doação, `push(HomeScreen)` empilhava telas | Corrigido (`go_router` com um único guard) |
| UX | Spinner inicial sem `Scaffold` (tela preta); ícone de "olho" não mostrava a senha; erros de login silenciosos | Corrigido |
| Validação | Regex de e-mail recusava TLDs com mais de 4 letras e aliases `+` | Corrigido |
| Arquitetura | Firebase acessado direto nos widgets; serviço de autenticação em `main.dart` | Camadas de domínio, dados e UI |
| Dados | Data gravada como `String`; nome digitado a cada doação; sem editar ou excluir | Datas de calendário (`AAAA-MM-DD`), perfil e CRUD na API própria; dados do Firestore não migrados |
| Robustez | Notícias quebravam se faltasse um campo; `currentUser!` forçado | Leitura tolerante e estados de erro |
| Conteúdo | Quiz marcava "Reduz o risco de anemia" como benefício de doar (incorreto); erros de digitação e frase duplicada no guia | Revisado com fonte oficial |
| Testes | Apenas o teste padrão do contador, que falhava | Testes de domínio, repositórios, widgets e API, incluindo isolamento entre usuários |
| Build | AGP 7.3, Gradle 7.5, Kotlin 1.7, Java 8, `minSdk 19`, incompatíveis com o Flutter atual | Plataformas regeneradas |
| Plataformas | Desktop sem configuração do Firebase (lançava exceção) | Removidas; mantidos Android, iOS e Web |

## O que mudou em 2026

### Engenharia

- Flutter 3.50 / Dart 3.14, dependências atuais e `material_ui` (substituto
  oficial de `package:flutter/material.dart`, deprecado desde a 3.47).
- Arquitetura MVVM seguindo o guia oficial: repositórios abstratos, view
  models com `ChangeNotifier`, injeção com `provider` e rotas com `go_router`.
- Monorepo: app Flutter em `apps/mobile` e API TypeScript em `apps/api`.
- Dois backends intercambiáveis: **demonstração** (local, sem credenciais) e
  **API própria**, com Fastify, validação Zod e SQLite via Drizzle ORM.
- Firebase removido das dependências e configurações do app. Os dados do
  Firestore original não foram migrados; isso exige acesso ao projeto antigo.
- Senhas com `scrypt`, sessões revogáveis com tokens armazenados como hash,
  rate limit, headers de segurança e consultas limitadas ao usuário autenticado.
- Cliente HTTP no app com token no armazenamento seguro do sistema e fluxo
  de redefinição de senha. O envio real de e-mail ainda exige um provedor.
- Análise estática em modo estrito e integração contínua no GitHub Actions.

### Produto

- **Próxima data apta para doar:** calculada pelo intervalo (60 ou 90 dias) e
  pelo limite anual (4 ou 3 doações), conforme o Ministério da Saúde.
- **Perfil:** nome, sexo (usado só para as regras) e tipo sanguíneo.
- **Compatibilidade sanguínea:** tabela ABO/Rh de concentrado de hemácias.
- **Quiz:** explicação após cada resposta e barra de progresso. As mensagens
  de resultado de 2023 foram mantidas, com a pontuação simplificada para o
  número de acertos (que é equivalente).
- **Histórico:** editar, excluir com "Desfazer" e aviso de data muito próxima
  de outra doação.
- Tema escuro, layout responsivo e rótulos de acessibilidade.

### Revisão de conteúdo

O conteúdo original foi preservado sempre que estava correto. As mudanças
seguiram a página "Doação de Sangue" e o FAQ do Ministério da Saúde
(gov.br/saude):

- **Idade:** "geralmente 18 anos" passou para 16 a 69 anos (menores com
  autorização; de 60 a 69 apenas quem já doou antes dos 60).
- **Sono e alimentação:** incluídos "dormir pelo menos 6 horas" e "evitar
  alimentos gordurosos nas 3 horas anteriores".
- **Quiz Q3:** reescrita, porque doar não reduz o risco de anemia.
- **Quiz Q2:** o distrator "2 meses", ambíguo (≈ 60 dias), foi substituído.

Nenhum resultado científico, métrica de uso ou dado de usuários foi criado.
As notícias do modo demonstração são fictícias e aparecem marcadas como tal.
