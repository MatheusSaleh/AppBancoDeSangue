# API — Banco de Sangue

API REST em TypeScript que substitui o Firebase usado em 2023. Cobre
autenticação, perfil do doador, histórico de doações e notícias.

**Stack:** Node.js 22+, Fastify 5, Zod 4, SQLite (`better-sqlite3`) com
Drizzle ORM, Vitest. Documentação OpenAPI gerada a partir dos schemas.

## Executar

```sh
npm ci
cp .env.example .env     # opcional
npm run dev              # http://127.0.0.1:3000 — docs em /docs
npm run seed             # (opcional) notícias de exemplo, marcadas como fictícias
```

O banco é um arquivo SQLite (`./data/app.db`) criado e migrado
automaticamente na inicialização.

Com Docker:

```sh
docker build -t banco-de-sangue-api .
docker run -p 3000:3000 -v bds-data:/data banco-de-sangue-api
```

Para publicar notícias, promova uma conta existente a administradora:

```sh
npm run user:promote -- pessoa@example.com
```

## Endpoints

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| POST | `/auth/register` | público | Cria conta e devolve sessão |
| POST | `/auth/login` | público | Entra com e-mail e senha |
| POST | `/auth/logout` | autenticado | Revoga a sessão atual |
| GET | `/auth/me` | autenticado | Usuário da sessão |
| POST | `/auth/password-reset/request` | público | Envia código de redefinição (sempre 202) |
| POST | `/auth/password-reset/confirm` | público | Nova senha com o código |
| GET / PUT | `/profile` | autenticado | Nome, sexo e tipo sanguíneo |
| GET / POST | `/donations` | autenticado | Lista (mais recentes primeiro) / cria |
| PUT / DELETE | `/donations/:id` | dono | Edita / exclui |
| GET | `/news` | autenticado | Notícias |
| POST / DELETE | `/news`, `/news/:id` | administrador | Publica / remove |
| GET | `/health` | público | Verificação de saúde |
| POST | `/ai/quiz` | autenticado | Gera 5 questões educativas com alternativas e explicações |
| POST | `/ai/chat` | autenticado | Responde à conversa e devolve 2–3 próximas perguntas sugeridas |
| GET | `/ai/usage` | autenticado | Consulta somente a própria cota diária, sem consumir IA |

Erros seguem um formato único:
`{ "error": { "code": "...", "message": "mensagem em português" } }`.

## Segurança

| Medida | Implementação |
| --- | --- |
| Senhas | `scrypt` (N=2¹⁷, r=8, p=1, recomendação OWASP), do módulo `crypto` do Node; tamanho máximo de 128 caracteres para limitar abuso do hash |
| Sessões | Token aleatório de 256 bits; o banco guarda só o SHA-256. Expira em 30 dias e pode ser revogado (logout, troca de senha) |
| Enumeração de contas | Login responde igual para e-mail inexistente e senha errada, comparando com um hash fictício para igualar o tempo; redefinição sempre responde 202 |
| Redefinição de senha | Código de uso único, com hash, válido por 30 minutos; um código novo invalida o anterior; trocar a senha encerra todas as sessões |
| Autorização | Toda consulta filtra pelo usuário autenticado: o id de um registro de outra pessoa resulta em 404 (há teste para isso) |
| Validação | Zod em todas as entradas; corpo limitado a 16 KB; ids validados como UUID; datas no formato `AAAA-MM-DD` e não futuras |
| Saída | Schemas de resposta funcionam como lista de permissão: campos internos (como o hash da senha) nunca são serializados |
| Força bruta | Rate limit: 10 req/min por IP nas rotas de autenticação e 300 req/min no geral |
| HTTP | Helmet (headers de segurança); CORS só para origens configuradas, mais `localhost` em desenvolvimento; sem cookies, então sem CSRF |
| Logs | `Authorization`, senhas e códigos são redigidos |
| SQL | Consultas parametrizadas via Drizzle |
| Container | Imagem Alpine, usuário sem privilégios, dados em volume |
| Dependências | Scripts de instalação do npm negados (`allowScripts`); `better-sqlite3` já traz binários pré-compilados |

## Limitações

- **IA:** exige `VENICE_API_KEY` no `.env` da API e créditos no Venice.
  Veja a configuração e os limites abaixo. Pode gerar conteúdo incorreto;
  a validação de formato não garante a correção médica das respostas.

- **E-mail:** não há provedor configurado. O `LogMailer` grava o código de
  redefinição no log do servidor. Em produção, implemente a interface
  `Mailer` com um provedor de e-mail.
- **Custo do hash:** cada verificação de senha levou ≈ 0,7 s na máquina de
  desenvolvimento e ocupa uma das 4 threads padrão do libuv. Em produção,
  ajuste `UV_THREADPOOL_SIZE` e mantenha o rate limit.
- **SQLite:** atende uma única instância. Para escalar horizontalmente,
  troque por PostgreSQL (o Drizzle suporta os dois).
- **Auditoria:** `npm audit` não aponta nada nas dependências de produção.
  Há avisos moderados em ferramentas de desenvolvimento (ESLint e
  `drizzle-kit`), que não vão para a imagem.

## Venice AI

```dotenv
# Em apps/api/.env (nunca no Flutter, no Git ou nas capturas de tela)
VENICE_API_KEY=sua_chave
# Opcional; vazio descobre o modelo padrão compatível pelo catálogo atual.
VENICE_MODEL=
AI_DAILY_LIMIT=20
```

A integração usa `https://api.venice.ai/api/v1/chat/completions`, autenticação
Bearer e JSON Schema estrito. Os modelos são descobertos em `/models?type=text`
e precisam oferecer `supportsResponseSchema=true`; o catálogo é consultado
novamente após 10 minutos. Um modelo configurado que não esteja disponível ou
não suporte esse formato produz um erro explícito, sem trocar silenciosamente.
Referência: [Venice — respostas estruturadas](https://docs.venice.ai/guides/features/structured-responses).

`POST /ai/quiz` recebe `{}`. `POST /ai/chat` recebe, por exemplo:

```json
{"messages":[{"role":"user","content":"Como me preparar para doar?"}]}
```

O chat devolve `{ "reply": "...", "suggestions": ["...", "..."] }`.
Somente `user` e `assistant` são aceitos, alternados, começando e terminando
com `user`. Limites: 11 mensagens, 1800 caracteres por mensagem, 9000 no total;
o app limita a entrada do usuário a 1000 caracteres e envia as últimas 5
trocas. A API não armazena conversas nem as associa ao perfil. O texto digitado
é enviado ao Venice; não há envio automático de dados do doador.

Proteções: autenticação obrigatória, 6 chamadas/minuto por conta por endpoint,
uma cota diária persistente compartilhada entre chat e quiz (veja abaixo),
até 2 chamadas simultâneas por instância, timeout total de 60 segundos e limite
de 3000 tokens por resposta. O aplicativo aguarda até 75 segundos. Nenhum retry
automático é feito para evitar custos duplicados. Respostas e históricos são
validados; erros do provedor são substituídos por mensagens seguras, e a chave
e os prompts não são gravados nos logs. As respostas usam `Cache-Control: no-store`.
Sem configuração, a API continua atendendo os demais recursos e retorna 503
apenas para as rotas de IA. Em Docker, passe a chave com `--env-file .env`.

Os prompts restringem o tema à doação e hemoterapia, incluem uma referência
educativa do Ministério da Saúde revisada em 12/11/2026 e orientam a não dar
diagnóstico, prescrição ou liberação individual para doar. Não há consulta
atualizada a estoques, localização de hemocentros ou pesquisa na web.

### Cota diária de IA

`AI_DAILY_LIMIT` aceita um inteiro de 0 a 1000 (padrão: **20**). `0` desativa
novas gerações. Reinicie a API ao mudar a configuração. A migração
`0001_ai_daily_usage.sql` cria o contador automaticamente no SQLite existente.

- Uma chamada de chat ou geração de questionário usa uma unidade; ambas as
  rotas compartilham a cota. Uma sugestão enviada conta como mensagem.
- A chave do contador é `(usuário autenticado, dia em America/Sao_Paulo)`.
  A API usa seu relógio e as regras IANA para definir a meia-noite, inclusive
  possíveis mudanças de fuso. Não confia em datas, IDs ou limites do cliente.
- Uma instrução SQL `INSERT … ON CONFLICT … DO UPDATE … WHERE` reserva a
  unidade antes de chamar o Venice. O banco serializa as escritas; chamadas
  simultâneas ou instâncias ligadas ao mesmo arquivo não ultrapassam a cota.
- O contador persiste em reinícios e é compartilhado entre sessões e
  dispositivos da mesma conta. A implantação deve preservar o volume do banco;
  cópias independentes do SQLite não compartilham limites.
- Pedidos sem autenticação, inválidos ou barrados pelo rate limit por minuto
  não reservam unidades. Uma reserva admitida não é estornada em erros, falta
  de configuração, serviço ocupado, timeout ou resposta inválida: falhas do
  provedor podem gerar cobranças, e estornar indiscriminadamente permitiria
  repetir tentativas cobradas sem limite.
- Não há exceção para administradores. O limite é por conta, não por pessoa:
  combater múltiplos cadastros exige políticas adicionais de verificação.

`GET /ai/usage` continua disponível mesmo após esgotar a cota:

```json
{
  "limit": 20,
  "used": 3,
  "remaining": 17,
  "day": "2026-11-12",
  "timeZone": "America/Sao_Paulo",
  "resetsAt": "2026-11-13T03:00:00.000Z"
}
```

As respostas autenticadas das rotas de IA incluem `X-AI-Daily-Limit`,
`X-AI-Daily-Remaining` e `X-AI-Reset-At`, expostos via CORS às origens permitidas.
Ao exceder a cota, a API responde **429** com código `ai_daily_limit_exceeded`,
mensagem de renovação para o app e `Retry-After` em segundos. O usuário segue
autenticado e pode usar normalmente as funcionalidades que não dependem de IA.
