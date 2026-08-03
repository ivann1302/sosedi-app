# Production network и access boundary

Production использует deny-by-default security groups/provider firewall. Compose
overlay дополнительно разделяет `edge` и internal `data` networks. PostgreSQL и
Redis не публикуют host ports; backend видит data services, но data services не
подключены к edge.

## Разрешённые потоки

| Source | Destination | Port | Условие |
| --- | --- | --- | --- |
| Internet | RF load balancer/reverse proxy | 443 | TLS; 80 только redirect |
| Reverse proxy | backend `edge` | 3000 | Только proxy identity/network |
| backend | PostgreSQL `data` | 5432 | Runtime DB role без DDL/role admin |
| backend | Redis `data` | 6379 | `sosedi_runtime` ACL; опасные admin/flush commands запрещены |
| backend | S3/SMS/push/approved providers | 443 egress | Allowlist после выбора provider; test/live раздельно |
| Prometheus | metrics through private proxy | 443 | Отдельный bearer token |
| short-lived migration job | PostgreSQL `data` | 5432 | Отдельная DDL identity только на migration window |
| operator device | operator UI и `/api/v1/admin/*` | 443 | VPN/IP allowlist или provider private access + MFA admin session |

Любой другой inbound к compute, PostgreSQL, Redis, exporters или operator UI
запрещён. SSH, если provider без agent/API его требует, разрешён только через
MFA/bastion с named human identity и audit; password/root login запрещён.

## Credential boundary

- PostgreSQL bootstrap password и Redis ACL password монтируются как protected
  files, не literal environment/command arguments.
- Backend `DATABASE_URL` использует отдельного `sosedi_runtime`; migration URL
  никогда не передаётся runtime process.
- Redis запускается с выключенным `default` user. Runtime ACL запрещает
  `ACL`, `CONFIG`, `DEBUG`, `FLUSH*`, replication/module, `MIGRATE`, `RESTORE`
  и `SHUTDOWN`.
- Backend container работает non-root, read-only, без Linux capabilities и с
  `no-new-privileges`.
- Admin API остаётся защищён приложением: MFA step-up, opaque short session,
  CSRF, capability checks и append-only audit. Network allowlist — второй слой,
  а не замена этих проверок.

## Проверка и evidence

```bash
make production-boundary
```

Verifier строит merged Compose и отклоняет опубликованные DB/Redis ports,
подключение data services к edge, открытый Redis, literal PostgreSQL password и
ослабление backend container. Перед release provider security-group export
сверяется с таблицей выше; staged port scan с отдельного external host должен
видеть только `443`. Из private migration/monitoring networks проверяются только
разрешённые направления.

Реальные role grants, secret references, firewall IDs, VPN/bastion и scan
evidence находятся в закрытом access register. Без них production gate не
закрыт.
