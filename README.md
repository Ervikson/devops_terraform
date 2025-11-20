# Итоговый проект: Docker + Terraform + Yandex Cloud

Проект демонстрирует полный цикл: создаём инфраструктуру Terraform, собираем и отправляем образ приложения в Yandex Container Registry, разворачиваем контейнеры на виртуальных машинах и подключаемся к управляемой MySQL. Дополнительно пароль базы хранится в Yandex LockBox и автоматически используется через Terraform.

## Структура репозитория
- `app/` – простое Node.js-приложение, которое обращается к MySQL и отдаёт JSON.
- `Dockerfile` – мультистейдж сборка образа.
- `docker-compose.yml` – локальная проверка связки приложения и MySQL.
- `cloud-init/user-data.yaml` – установка Docker и Docker Compose на ВМ через user-data.
- `terraform/` – описание инфраструктуры (VPC, подсети, SG, ВМ, БД, LockBox, Container Registry, удалённый state).
- `docs/architecture.md` – краткое описание архитектуры и потоков.

## Задание 1. Инфраструктура в Yandex Cloud
1. Заполните переменные в файле `terraform/terraform.tfvars` (пример ниже):
   ```hcl
   yc_token      = "<OAuth token>"
   cloud_id      = "<cloud id>"
   folder_id     = "<folder id>"
   ssh_public_key = "ssh-ed25519 AAAA..."
   ```
2. Инициализация и проверка:
   ```bash
   cd /home/sergey/Documents/HW_projects/Final-1/terraform
   terraform init
   terraform plan -out plan.tfplan
   terraform apply plan.tfplan
   ```
3. В результате будут созданы:
   - `VPC final-vpc` и две подсети `/24`.
   - Группа безопасности с открытыми портами 22/80/443.
   - Registry `final-app-registry`.
   - Управляемый кластер MySQL `final-mysql` с БД `appdb` и пользователем `app`.
   - Секрет LockBox `final-mysql-secret` с паролем пользователя.
   - Одна или несколько ВМ (настраивается `var.vm_count`).
4. `terraform/outputs.tf` печатает публичные IP ВМ, FQDN БД и ID реестра.

## Задание 2. Установка Docker и Compose через cloud-init
- Файл `cloud-init/user-data.yaml` добавлен в метаданные ВМ в `terraform/main.tf`.
- Скрипт:
  - Обновляет пакеты, добавляет официальный репозиторий Docker.
  - Устанавливает Docker CE + CLI + containerd.
  - Скачивает бинарь Docker Compose v2.29.5.
  - Настраивает daemon и добавляет пользователя `yc-user` в группу `docker`.
- При создании ВМ docker готов к работе без ручных действий.

## Задание 3. Dockerfile и Container Registry
1. Локальная сборка и тест:
   ```bash
   docker compose up --build
   curl http://localhost:80
   ```
2. Авторизация и загрузка в YCR:
   ```bash
   yc iam create-token | docker login --username oauth --password-stdin cr.yandex
   export REG_ID=$(terraform -chdir=terraform output -raw registry_id)
   docker build -t cr.yandex/$CLOUD_ID/$REG_ID/final-app:$(git rev-parse --short HEAD) .
   docker push cr.yandex/$CLOUD_ID/$REG_ID/final-app:$(git rev-parse --short HEAD)
   docker tag ...:$(git rev-parse --short HEAD) ...:latest
   docker push ...:latest
   ```
3. После пуша образ доступен всем ВМ в папке.

## Задание 4. Привязка приложения к БД
- Приложение читает переменные `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` (см. `app/src/server.js`).
- На прод-вм переменные лучше хранить в `/etc/systemd/system/final-app.service` или `.env`. Пример запуска контейнера:
  ```bash
  docker run -d \
    --name final-app \
    -p 80:3000 \
    -e DB_HOST=$(terraform -chdir=terraform output -raw mysql_endpoint) \
    -e DB_PORT=3306 \
    -e DB_USER=app \
    -e DB_PASSWORD=$(yc lockbox payload get --id $(terraform -chdir=terraform output -raw lockbox_secret_id) --key db-password) \
    -e DB_NAME=appdb \
    cr.yandex/$CLOUD_ID/$REG_ID/final-app:latest
  ```
- Для автоматизации можно описать systemd unit или docker-compose файл с теми же переменными.

## Задание 5*. LockBox + Terraform
- `terraform/main.tf` создаёт `yandex_lockbox_secret` и версию с автоматически сгенерированным паролем (`random_password`).
- Тот же пароль передаётся ресурсу `yandex_mdb_mysql_user`.
- При необходимости обновить пароль достаточно выполнить `terraform taint yandex_lockbox_secret_version.mysql` + `terraform apply`.

## Чек-лист готовности
- [x] Инфраструктура описана через Terraform, переменные без хардкода, state в Object Storage, включён state locking.
- [x] Docker и Compose ставятся cloud-init.
- [x] Dockerfile использует мультистейдж и ориентирован на загрузку в Container Registry.
- [x] Приложение доступно по публичному IP ВМ (или через DNS, если прикрутить в YC DNS).
- [x] Репозиторий содержит оформленный MD-файл с инструкциями и ссылкой на архитектуру.

## Дальнейшие улучшения
- Добавить Application Load Balancer и сертификат из Yandex Certificate Manager.
- Автоматизировать деплой контейнера через Ansible или Terraform Cloud-init шаблон.
- Подключить мониторинг (Yandex Monitoring + log group).
