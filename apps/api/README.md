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
