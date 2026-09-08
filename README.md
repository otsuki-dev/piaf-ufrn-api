# PIAF API

API REST do **PIAF – Programa Institucional de Atividade Física** (COESPE/UFRN). Faz a
gestão de usuários (alunos, instrutores e administradores), turmas, matrículas (com
fila de espera), presenças, renovações e relatórios, com autenticação por JWT e e-mails
transacionais.

## Stack

- **Ruby** 4.0.6 · **Rails** 8.1.3 (API)
- **PostgreSQL** com `pg`
- **Devise 5 + devise-jwt** (autenticação e JWT com revogação via denylist)
- **Pundit** (autorização), **Blueprinter** (serialização), **Pagy 9** (paginação)
- **Delayed Job** (job de fila) + **Whenever** (agendamento de cron)
- **paper_trail** (auditoria), **Rack::Attack** (rate limiting), **CORS** (rack-cors)
- Dados pessoais sensíveis (CPF, RG, endereço, telefone) **criptografados em
  repouso** com `ActiveRecord::Encryption` (LGPD); o CPF é criptografado de forma
  **determinística** para permitir busca e unicidade.

## Pré-requisitos

- Ruby ≥ 3.4 (o projeto usa a trilha `ruby-4.0.6`, ver `.ruby-version`)
- PostgreSQL (local ou via `docker compose`)
- Bundler

## Configuração

```bash
git clone <repo-url> piaf_api
cd piaf_api
bundle install
bin/rails db:prepare            # cria e migra os bancos (dev + test)
```

### Credenciais e variáveis de ambiente

Segredos (JWT, SMTP, chaves de criptografia) ficam em credenciais Rails
(`bin/rails credentials:edit`) e/ou variáveis de ambiente. A leitura segue a ordem
**env var → credencial Rails**:

| Variável | Uso | Padrão |
|---|---|---|
| `JWT_SECRET` | Segredo de assinatura do JWT (`credentials.jwt.secret`) | credencial `jwt.secret` |
| `JWT_EXPIRATION_SECONDS` | Validade do token | `86400` (1 dia) |
| `PIAF_MAILER_SENDER` | Remetente (remetente externo Devise) | `PIAF COESPE/UFRN <piaf@coespe.ufrn.br>` |
| `PIAF_MAILER_FROM` | Remetente (ApplicationMailer) | idem acima |
| `SMTP_ADDRESS/PORT/USERNAME/PASSWORD/AUTHENTICATION` | SMTP de produção | credenciais `smtp.*` |
| `PIAF_ALLOWED_ORIGINS` | Origens CORS permitidas (vírgula; precedência sobre credenciais) | credencial `allowed_origins` ou `http://localhost:3001,http://localhost:5173` |
| `PIAF_RAISE_DELIVERY_ERRORS` | Eleva erros de envio de e-mail (`"true"`) | `false` |

> **JWT_SECRET obrigatório fora do desenvolvimento**: `devise.rb` usa
> `Rails.application.credentials.dig(:jwt, :secret)`. Sem ele, a autenticação falha —
> defina no deploy.

## Rodando localmente

```bash
bin/rails server              # API em http://localhost:3000
```

O frontend em desenvolvimento pode apontar para a origem padrão do CORS
(`http://localhost:3001` / `http://localhost:5173`) ou configurar `PIAF_ALLOWED_ORIGINS`.

### Background jobs (e-mails)

Emails confirmam a conta, a matrícula, a promoção da fila de espera, reset de senha,
notificações etc. e são processados de forma assíncrona via Delayed Job:

```bash
bin/delayed_job start         # worker em segundo plano
# ou, em foreground (útil em dev):
bin/delayed_job run
```

### E-mails em desenvolvimento

Com a gem **letter_opener**, os e-mails são abertos no navegador em vez de enviados.
Consulte `config/environments/development.rb`; sem worker rodando, os e-mails ficam
enfileirados na tabela `delayed_jobs`.

## Tarefas agendadas (Whenever)

Definidas em `config/schedule.rb` e `lib/tasks/scheduled.rake` (instale o cron com
`whenever --update-crontab` em produção):

| Horário | Tarefa | Ação |
|---|---|---|
| diário 02:00 | `scheduled:expire_pending_enrollments` | Expira matrículas `pending` com > 7 dias (promove fila se abrir vaga) |
| diário 03:00 | `scheduled:deactivate_inactive_students` | Desativa alunos confirmados sem presença nos últimos 14 dias (promove fila) |
| diário 04:00 | `scheduled:maintenance` | Limpa a denylist de JWTs expirados |

Também podem ser executadas manualmente: `bin/rails scheduled:expire_pending_enrollments`.

## Testes e qualidade

```bash
bundle exec rspec              # 205 exemplos (spec/), inclui request specs de ponta a ponta
bundle exec rubocop -a         # linter Ruby (RuboCop omakase)
bundle exec brakeman -q        # análise de segurança estática
bundle exec bundler-audit      # vulns de gems
```

## Autenticação (JWT)

1. **Cadastro** → `POST /api/v1/auth` (corpo em `user`). A conta nasce **não confirmada**
   (`confirmable`) e um e-mail com link de confirmação é enfileirado.
2. **Confirmação** → o link do e-mail aponta para
   `GET /api/v1/auth/confirmation?confirmation_token=...` (ou `POST
   /api/v1/auth/confirmation` com `user.email` para reenviar as instruções).
   O token é de uso único e armazenado de forma hashada no banco (prazo de
   validade configurável via `confirm_within`, desativado por padrão).
3. **Login** → `POST /api/v1/auth/sign_in` com `{ "user": { "email", "password" } }`.
   Retorna o usuário em `data` e o JWT em `meta.token` e também no header
   `Authorization: Bearer <jwt>`.
4. **Requisições autenticadas** → enviar o header
   `Authorization: Bearer <jwt>` (o token expira conforme `JWT_EXPIRATION_SECONDS`).
5. **Logout** → `DELETE /api/v1/auth/sign_out` com o token no header; o JWT é
   adicionado à denylist (`jwt_denylist`) e revogado na hora.

Emails (instruções de confirmação/reset) usam `PiafDeviseMailer` e layout próprio
em `app/views/devise/mailer`.

## Endpoints

Base URL: `/api/v1`. Todas as rotas protegidas exigem `Authorization: Bearer <jwt>`
(marcação 🔒). Cada item de lista retorna paginação (ver [Paginação](#paginação)).

### Autenticação e conta

| Verbo | Rota | Acesso | Descrição |
|---|---|---|---|
| POST | `/auth` | público | Cadastro (body em `user`, ver campos abaixo) → `201`; se `confirmed?`, devolve JWT em `meta.token`, senão `confirmation_required: true` |
| PATCH/PUT | `/auth` | 🔒 autenticado | Atualização da própria conta (`account_update_params`) |
| DELETE | `/auth` | 🔒 autenticado | Exclusão da própria conta |
| POST | `/auth/sign_in` | público | Login → `200` com `data` + `meta.token` |
| DELETE | `/auth/sign_out` | 🔒 autenticado | Logout (revoga o JWT) → `204` |
| GET | `/auth/confirmation?confirmation_token=...` | por token | Confirma a conta → `200` |
| POST | `/auth/confirmation` | público | Reenvia as instruções de confirmação (`user.email`) |
| POST | `/auth/password` | público | Solicita reset de senha (`user.email`) → e-mail com link |
| PATCH/PUT | `/auth/password` | por token | Troca a senha (`user.reset_password_token`, `user.password`, `user.password_confirmation`) |
| GET | `/me` | 🔒 autenticado | Perfil do usuário atual (CPF mascarado) |

**Campos de cadastro** (`user`): `username`, `email`, `password`,
`password_confirmation`, `cpf`, `birthdate`, `phone_number`, `ufrn_student`,
`ufrn_registration_number`, `rg_user`, `address`, `cep`, `district` (campos
alfanuméricos de contato são normalizados para só dígitos).

### Turmas

Roles de acesso: **aluno** (somente leitura) · **instrutor** (próprias turmas ou
sem instrutor) · **admin** (tudo).

| Verbo | Rota | Acesso | Descrição |
|---|---|---|---|
| GET | `/courses?modality=x` | público | Lista turmas (`status` = `open`/`full`/`closed`, `available_slots`) |
| GET | `/courses/:id` | público | Detalhe da turma |
| POST | `/courses` | 🔒 instrutor/admin | Cria turma (`start_date`, `end_date`, `slots`, `modality`, `class_time`, `custom_modality`, `user_id`). Sem `user_id`, assume `current_user` |
| PATCH/PUT | `/courses/:id` | 🔒 instrutor (dono)/admin | Atualiza |
| DELETE | `/courses/:id` | 🔒 instrutor (dono)/admin | Remove (bloqueado com `409` se houver matrículas) |

`modality` é uma das: `musculacao natacao hidroginastica corrida
treinamento_funcional futebol futsal volei basketball handebol judo jiu_jitsu
kung_fu yoga pilates ritmos danca outro`. Se `other`, `custom_modality` é
obrigatório.

### Matrículas (enrollments)

| Verbo | Rota | Acesso | Descrição |
|---|---|---|---|
| POST | `/enrollments` | 🔒 autenticado | Matricula o `current_user` em `course_id`. Com vaga → `confirmed`; turf cheia → `waitlisted`. Aceita `terms_accepted` (obrigatório `true`) e anamnese |
| GET | `/enrollments?course_id=&status=` | 🔒 scoped | Lista (admin: todas; instrutor: da própria turma; aluno: as suas) |
| GET | `/enrollments/:id` | 🔒 dono/admin/instrutor | Detalhe com presenças e taxa de frequência |
| POST | `/enrollments/:id/renew` | 🔒 dono | Renova a matrícula para `course_id` (opcional; default mesma turma). Se for a mesma turma, a anterior vira `cancelled` e abre vaga para a fila |
| POST | `/enrollments/:id/attendance` | 🔒 instrutor da turma/admin | Registra presença: `{ "date": "2026-11-05", "present": true }` |
| DELETE | `/enrollments/:id` | 🔒 dono/admin/instrutor | Cancela a matrícula (`status: cancelled` — mantém histórico) e **promove automaticamente** o 1º da fila de espera |

**Anamnese** (top-level no body do `create`/`renew`): `heart_problem`,
`chest_pain`, `recent_chest_pain`, `dizziness`, `bone_problem`,
`blood_pressure_meds`, `other_reasons`, `physical_activity_responsibility`,
`terms_accepted`.

**Status possíveis:** `pending` · `confirmed` · `waitlisted` · `cancelled` ·
`inactive`.

### Admin

| Verbo | Rota | Acesso | Descrição |
|---|---|---|---|
| GET | `/admin/stats` | 🔒 admin | Totais de usuários (por papel), turmas (por modalidade) e matrículas (por status) + presenças de hoje/semana |
| GET | `/admin/reports` | 🔒 admin | Relatório por turma (taxa de ocupação, evasão, frequência) + resumo |
| POST | `/admin/notifications` | 🔒 admin | Enfileira e-mails. Body: `{ "subject", "body", "audience": {...} }` → `202` com `recipients_count` |
| POST | `/admin/students/:id/deactivate` | 🔒 admin | Desativa as matrículas `confirmed` do aluno (promove a fila) |

**Formato do `audience`** (uma das formas):
- `{ "user_ids": [1,2] }` — usuários específicos (confirmados)
- `{ "role": "students" | "instructors" | "admins" }`
- `{ "enrollment_status": "waitlisted" }` — alunos com matrícula naquele status
- `{ "all": true }` — todos os confirmados

## Formato de resposta

Sucesso individual:
```json
{ "data": { ... }, "meta": { "token": "..." } }
```

Lista:
```json
{ "data": [ ... ], "meta": { "pagination": { "page": 1, "per_page": 25, "count": 1,
  "pages": 1, "prev_page": null, "next_page": null }, "headers": { "X-Page": "1", ... } } }
```

Erro (JSON:API-like):
```json
{ "errors": [ { "status": 422, "code": "validation_failed",
  "title": "Validação falhou: ...", "source": { "pointer": "/data/attributes/terms_accepted" } } ] }
```

Códigos de erro comuns: `validation_failed` (422), `not_found` (404), `forbidden`
(403), `token_expired`/`token_invalid` (401), `missing_parameter` (400),
`record_not_unique` (422), `unpermitted_parameters` (422), `rate_limited` (429),
`internal_error` (500).

> Mensagens em português (locale padrão `pt-BR`, `config/locales/pt-BR.yml`).

## Paginação

Listas suportam `?page=` e `?per_page=` (padrão 25, máximo 100). A contagem/total
também é exposta via headers `X-Page`, `X-Per-Page`, `X-Total`, `X-Total-Pages`
(expostos pelo CORS).

## Segurança

- **JWT** com assinatura `HS256`, expiração configurável e **revogação por denylist**
  no logout (`JwtDenylist`); a denylist é limpa diariamente pela manutenção agendada.
- **Rate limiting** (Rack::Attack): login 10/min/IP, cadastro 5/hora, confirmações e
  resets 10/hora, API geral 900/min — respostas `429` com `Retry-After`.
- **Criptografia em repouso** dos dados pessoais (LGPD).
- **Pundit**: regras de autorização por papel; alunos não alcançam rotas de admin
  (403).
- Auditoria de mudanças via **paper_trail** (`whodunnit` = id do usuário atual).

## Estrutura relevante

```
app/controllers/api/v1/          # rotas da API (incl. users/, admin/)
app/controllers/concerns/api/v1/ # Renderable, ErrorHandling, Paginatable, Authenticatable
app/models/                      # User, Course, Enrollment, Attendance, JwtDenylist
app/policies/                    # Pundit (CoursePolicy, EnrollmentPolicy)
app/serializers/                 # Blueprinter
app/mailers/ + app/views/*mailer/ # EnrollmentMailer, NotificationMailer, PiafDeviseMailer
lib/tasks/scheduled.rake         # tarefas agendadas (Whenever)
config/schedule.rb               # cron (Whenever)
```

## Health check

`GET /up` responde `200` (página verde) quando a app sobe sem exceção — adequado
para load balancers e monitores de uptime.