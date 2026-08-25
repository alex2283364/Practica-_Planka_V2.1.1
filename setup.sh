#!/bin/sh
# Скрипт автоматического развертывания Planka и загрузки тестовых данных
# Строго совместим с POSIX sh (dash, ash, sh)
set -e # Останавливать выполнение при любой ошибке
export COMPOSE_PROJECT_NAME=planka

# ==============================================================================
# БЛОК 1: ПЕРЕМЕННЫЕ И ФУНКЦИИ ЛОГИРОВАНИЯ
# ==============================================================================
LOG_FILE="setup.log"
ENV_FILE=".env"
CONTAINER_NAME="planka-postgres"

COLOR_GREEN='\033[0;32m'; COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'; COLOR_RED='\033[0;31m'; COLOR_NC='\033[0m'

log_info()    { printf "${COLOR_BLUE}[INFO]${COLOR_NC} %s\n" "$1" | tee -a "$LOG_FILE"; }
log_success() { printf "${COLOR_GREEN}[✓]${COLOR_NC} %s\n" "$1" | tee -a "$LOG_FILE"; }
log_warn()    { printf "${COLOR_YELLOW}[!]${COLOR_NC} %s\n" "$1" | tee -a "$LOG_FILE"; }
log_error()   { printf "${COLOR_RED}[ERROR]${COLOR_NC} %s\n" "$1" | tee -a "$LOG_FILE"; }
die() { log_error "$1"; exit 1; }

# ==============================================================================
# БЛОК 2: ФУНКЦИИ ДЛЯ РАБОТЫ С БД И ДАННЫМИ
# ==============================================================================
load_env() {
    [ -f "$ENV_FILE" ] || die ".env file not found"
    eval "$(grep -E '^POSTGRES_USER=' "$ENV_FILE" | head -n 1)"
    eval "$(grep -E '^POSTGRES_PASSWORD=' "$ENV_FILE" | head -n 1)"
    eval "$(grep -E '^POSTGRES_DB=' "$ENV_FILE" | head -n 1)"
    POSTGRES_USER="${POSTGRES_USER:-postgres}"
    POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
    POSTGRES_DB="${POSTGRES_DB:-planka}"
}

# SQL читается из stdin (heredoc) — shell не трогает ни кавычки, ни $, ни \
exec_sql() {
    sql_status=0
    sql_out=$(docker compose exec -T postgres psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" -d "$POSTGRES_DB" 2>&1) || sql_status=$?
    printf '%s\n' "$sql_out" | tee -a "$LOG_FILE"
    [ "$sql_status" -eq 0 ] || die "SQL query failed (exit code $sql_status)"
}

check_container() {
    docker compose ps | grep -q "$CONTAINER_NAME" || die "PostgreSQL container not running"
}

load_test_data() {
    log_info "Загрузка тестовых данных..."

    # ─── Очистка (CASCADE автоматически удалит зависимые записи) ─────
    exec_sql <<'SQL'
TRUNCATE TABLE notification CASCADE;
TRUNCATE TABLE action CASCADE;
TRUNCATE TABLE comment CASCADE;
TRUNCATE TABLE card_subscription CASCADE;
TRUNCATE TABLE card_membership CASCADE;
TRUNCATE TABLE card_label CASCADE;
TRUNCATE TABLE task CASCADE;
TRUNCATE TABLE task_list CASCADE;
TRUNCATE TABLE custom_field_value CASCADE;
TRUNCATE TABLE custom_field_group CASCADE;
TRUNCATE TABLE custom_field CASCADE;
TRUNCATE TABLE base_custom_field_group CASCADE;
TRUNCATE TABLE attachment CASCADE;
TRUNCATE TABLE uploaded_file CASCADE;
TRUNCATE TABLE background_image CASCADE;
TRUNCATE TABLE card CASCADE;
TRUNCATE TABLE board_subscription CASCADE;
TRUNCATE TABLE board_membership CASCADE;
TRUNCATE TABLE label CASCADE;
TRUNCATE TABLE list CASCADE;
TRUNCATE TABLE board CASCADE;
TRUNCATE TABLE project_favorite CASCADE;
TRUNCATE TABLE project_manager CASCADE;
TRUNCATE TABLE project CASCADE;
TRUNCATE TABLE user_account CASCADE;
TRUNCATE TABLE config CASCADE;
TRUNCATE TABLE internal_config CASCADE;
TRUNCATE TABLE storage_usage CASCADE;
SQL

    # ─── 1. Пользователи ───────────────────────────────────────────────
    exec_sql <<'SQL'
insert into public.user_account (id, email, "password", "role", "name", username, avatar, phone, organization, "language", subscribe_to_own_cards, subscribe_to_card_when_commenting, turn_off_recent_card_highlighting, enable_favorites_by_default, default_editor_mode, default_home_view, default_projects_order, is_sso_user, is_deactivated, created_at, updated_at, password_changed_at, terms_signature, terms_accepted_at, api_key_prefix, api_key_hash, api_key_created_at)
values(1839549968164062220, 'jane.smith@example.com', '$2b$10$E6eBY6/8ZYrJA76FgF7EK.dkEorI/.6YMnHJb7qdwPUnpCYClpVAK', 'projectOwner', 'jane', 'jane', null, null, null, 'en-US', false, true, false, true, 'wysiwyg', 'groupedProjects', 'byDefault', false, false, '2026-08-11 21:17:24.793', '2026-08-11 21:28:59.742', null, '03f07fa4887405919f0a569871c5bed69e5fc2e7045b186145dbd8ca09c2351a', '2026-08-11 21:28:59.739', null, null, null);
insert into public.user_account (id, email, "password", "role", "name", username, avatar, phone, organization, "language", subscribe_to_own_cards, subscribe_to_card_when_commenting, turn_off_recent_card_highlighting, enable_favorites_by_default, default_editor_mode, default_home_view, default_projects_order, is_sso_user, is_deactivated, created_at, updated_at, password_changed_at, terms_signature, terms_accepted_at, api_key_prefix, api_key_hash, api_key_created_at)
values(1839550084035904525, 'john.doe@example.com', '$2b$10$mUAXtwzVy0cyPe0ifoVZQOFmdm61xRM6EX35vEa5EcyHV3GbL2hmm', 'boardUser', 'john', 'john', null, null, null, 'en-US', false, true, false, true, 'wysiwyg', 'groupedProjects', 'byDefault', false, false, '2026-08-11 21:17:38.607', '2026-08-11 21:33:21.370', null, '03f07fa4887405919f0a569871c5bed69e5fc2e7045b186145dbd8ca09c2351a', '2026-08-11 21:33:21.367', null, null, null);
insert into public.user_account (id, email, "password", "role", "name", username, avatar, phone, organization, "language", subscribe_to_own_cards, subscribe_to_card_when_commenting, turn_off_recent_card_highlighting, enable_favorites_by_default, default_editor_mode, default_home_view, default_projects_order, is_sso_user, is_deactivated, created_at, updated_at, password_changed_at, terms_signature, terms_accepted_at, api_key_prefix, api_key_hash, api_key_created_at)
values(1839548131402843137, 'admin@example.com', '$2b$10$mHhHCcb0i9SXOZ2Fyfcn7eSkYHhOwW6gY8r.S/R5lQEdb5J4DMqF.', 'admin', 'Administrator', 'admin', null, null, null, 'en-US', false, true, false, true, 'wysiwyg', 'groupedProjects', 'byDefault', false, false, '2026-08-11 21:13:45.836', '2026-08-11 21:14:14.832', null, '03f07fa4887405919f0a569871c5bed69e5fc2e7045b186145dbd8ca09c2351a', '2026-08-11 21:14:14.821', null, null, null);
SQL

    # ─── 2. Глобальные конфигурации ────────────────────────────────────
    exec_sql <<'SQL'
insert into public.config (id, created_at, updated_at, smtp_host, smtp_port, smtp_name, smtp_secure, smtp_tls_reject_unauthorized, smtp_user, smtp_password, smtp_from)
values(1, '2026-08-11 21:13:45.715', null, null, null, null, false, true, null, null, null);
insert into public.internal_config (id, storage_limit, active_users_limit, is_initialized, created_at, updated_at)
values(1, null, null, true, '2026-08-11 21:13:45.775', '2026-08-11 21:14:14.844');
insert into public.storage_usage (id, total, user_avatars, background_images, attachments, created_at, updated_at)
values(1, 0, 0, 0, 0, '2026-08-11 21:13:45.450', null);
SQL

    # ─── 3. Проекты ────────────────────────────────────────────
    exec_sql <<'SQL'
insert into public.project (id, owner_project_manager_id, background_image_id, "name", description, background_type, background_gradient, is_hidden, created_at, updated_at)
values(1839548560673080323, null, null, 'Тестовый проект', 'Тестовый проект', null, null, false, '2026-08-11 21:14:37.008', null);
insert into public.project (id, owner_project_manager_id, background_image_id, "name", description, background_type, background_gradient, is_hidden, created_at, updated_at)
values(1839550519169778704, null, null, 'DevOps Practica Project', 'Учебный проект производственной практики', null, null, false, '2026-08-11 21:18:30.480', null);
insert into public.project (id, owner_project_manager_id, background_image_id, "name", description, background_type, background_gradient, is_hidden, created_at, updated_at)
values(1839551749325587492, null, null, 'QA & Testing', 'Проект для смоук-тестов и баг-репортов', null, null, false, '2026-08-11 21:20:57.124', null);
SQL

    # ─── 4. Менеджеры проектов ─────────────────────────────────────
    exec_sql <<'SQL'
insert into public.project_manager (id, project_id, user_id, created_at, updated_at)
values(1839548560706634756, 1839548560673080323, 1839548131402843137, '2026-08-11 21:14:37.014', null);
insert into public.project_manager (id, project_id, user_id, created_at, updated_at)
values(1839550519203333137, 1839550519169778704, 1839548131402843137, '2026-08-11 21:18:30.485', null);
insert into public.project_manager (id, project_id, user_id, created_at, updated_at)
values(1839551749350753317, 1839551749325587492, 1839548131402843137, '2026-08-11 21:20:57.131', null);
SQL

    # ─── 5. Доски ──────────────────────────────────────────────────────
    exec_sql <<'SQL'
insert into public.board (id, project_id, "position", "name", default_view, default_card_type, limit_card_types_to_default_one, always_display_card_creator, created_at, updated_at, expand_task_lists_by_default, display_card_ages)
values(1839548652117296133, 1839548560673080323, 65536.0, 'Test Board', 'kanban', 'project', false, false, '2026-08-11 21:14:47.910', '2026-08-11 21:15:53.287', true, true);
insert into public.board (id, project_id, "position", "name", default_view, default_card_type, limit_card_types_to_default_one, always_display_card_creator, created_at, updated_at, expand_task_lists_by_default, display_card_ages)
values(1839550594969240594, 1839550519169778704, 65536.0, 'Main Board', 'kanban', 'project', false, false, '2026-08-11 21:18:39.518', '2026-08-11 21:18:43.608', true, true);
insert into public.board (id, project_id, "position", "name", default_view, default_card_type, limit_card_types_to_default_one, always_display_card_creator, created_at, updated_at, expand_task_lists_by_default, display_card_ages)
values(1839550803149325334, 1839550519169778704, 131072.0, 'Infrastructure Board', 'kanban', 'project', false, false, '2026-08-11 21:19:04.332', '2026-08-11 21:19:07.156', true, true);
insert into public.board (id, project_id, "position", "name", default_view, default_card_type, limit_card_types_to_default_one, always_display_card_creator, created_at, updated_at, expand_task_lists_by_default, display_card_ages)
values(1839552744650703910, 1839551749325587492, 65536.0, 'QA Board', 'kanban', 'project', false, false, '2026-08-11 21:22:55.779', '2026-08-11 21:22:58.100', true, true);
SQL

    # ─── 6. Участники досок ────────────────────────────
    exec_sql <<'SQL'
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839548652176016390, 1839548560673080323, 1839548652117296133, 1839548131402843137, 'editor', null, '2026-08-11 21:14:47.917', null);
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839550199471539214, 1839548560673080323, 1839548652117296133, 1839550084035904525, 'editor', null, '2026-08-11 21:17:52.369', null);
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839550223848834063, 1839548560673080323, 1839548652117296133, 1839549968164062220, 'editor', null, '2026-08-11 21:17:55.277', null);
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839550595002795027, 1839550519169778704, 1839550594969240594, 1839548131402843137, 'editor', null, '2026-08-11 21:18:39.521', null);
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839550803166102551, 1839550519169778704, 1839550803149325334, 1839548131402843137, 'editor', null, '2026-08-11 21:19:04.337', null);
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839551501844874274, 1839550519169778704, 1839550594969240594, 1839549968164062220, 'editor', null, '2026-08-11 21:20:27.624', null);
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839551549735437347, 1839550519169778704, 1839550803149325334, 1839549968164062220, 'editor', null, '2026-08-11 21:20:33.333', null);
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839552744675869735, 1839551749325587492, 1839552744650703910, 1839548131402843137, 'editor', null, '2026-08-11 21:22:55.783', null);
insert into public.board_membership (id, project_id, board_id, user_id, "role", can_comment, created_at, updated_at)
values(1839552802615985194, 1839551749325587492, 1839552744650703910, 1839550084035904525, 'editor', null, '2026-08-11 21:23:02.690', null);
SQL

    # ─── 7. Списки ────────────────────────────────────────────────────
    exec_sql <<'SQL'
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839548652217959431, 1839548652117296133, 'archive', null, null, null, '2026-08-11 21:14:47.923', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839548652226348040, 1839548652117296133, 'trash', null, null, null, '2026-08-11 21:14:47.923', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839549630866523145, 1839548652117296133, 'active', 65536.0, 'To Do', null, '2026-08-11 21:16:44.584', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839549680199926794, 1839548652117296133, 'active', 131072.0, 'In Progress', null, '2026-08-11 21:16:50.469', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839549711673984011, 1839548652117296133, 'active', 196608.0, 'Done', null, '2026-08-11 21:16:54.221', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839550595044738068, 1839550594969240594, 'archive', null, null, null, '2026-08-11 21:18:39.526', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839550595069903893, 1839550594969240594, 'trash', null, null, null, '2026-08-11 21:18:39.526', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839550803191268376, 1839550803149325334, 'archive', null, null, null, '2026-08-11 21:19:04.340', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839550803191268377, 1839550803149325334, 'trash', null, null, null, '2026-08-11 21:19:04.340', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839550970502054938, 1839550594969240594, 'active', 65536.0, 'To Do', null, '2026-08-11 21:19:24.284', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839551035136279579, 1839550594969240594, 'active', 131072.0, 'In Progress', null, '2026-08-11 21:19:31.990', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839551078975144988, 1839550594969240594, 'active', 196608.0, 'Done', null, '2026-08-11 21:19:37.217', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839551355119731743, 1839550803149325334, 'active', 65536.0, 'To Do', null, '2026-08-11 21:20:10.133', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839551394051261472, 1839550803149325334, 'active', 131072.0, 'In Progress', null, '2026-08-11 21:20:14.776', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839551415425434657, 1839550803149325334, 'active', 196608.0, 'Done', null, '2026-08-11 21:20:17.324', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839552744692646952, 1839552744650703910, 'archive', null, null, null, '2026-08-11 21:22:55.785', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839552744701035561, 1839552744650703910, 'trash', null, null, null, '2026-08-11 21:22:55.785', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839552873885598763, 1839552744650703910, 'active', 65536.0, 'Backlog', null, '2026-08-11 21:23:11.186', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839552973005390892, 1839552744650703910, 'active', 131072.0, 'Testing', null, '2026-08-11 21:23:23.000', null);
insert into public.list (id, board_id, "type", "position", "name", color, created_at, updated_at)
values(1839553007373517869, 1839552744650703910, 'active', 196608.0, 'Done', null, '2026-08-11 21:23:27.097', null);
SQL

    # ─── 8. Метки ──────────────────────────────────────────────────────
    exec_sql <<'SQL'
insert into public."label" (id, board_id, "position", "name", color, created_at, updated_at)
values(1839553591799448622, 1839550594969240594, 65536.0, 'инфраструктура', 'morning-sky', '2026-08-11 21:24:36.765', null);
insert into public."label" (id, board_id, "position", "name", color, created_at, updated_at)
values(1839553681993761839, 1839550594969240594, 131072.0, 'важно', 'berry-red', '2026-08-11 21:24:47.519', null);
insert into public."label" (id, board_id, "position", "name", color, created_at, updated_at)
values(1839553795936224304, 1839550594969240594, 196608.0, 'скрипты', 'orange-peel', '2026-08-11 21:25:01.101', null);
insert into public."label" (id, board_id, "position", "name", color, created_at, updated_at)
values(1839553951494571057, 1839550594969240594, 262144.0, 'мониторинг', 'tank-green', '2026-08-11 21:25:19.645', null);
insert into public."label" (id, board_id, "position", "name", color, created_at, updated_at)
values(1839554104217568306, 1839550803149325334, 65536.0, 'сеть', 'navy-blue', '2026-08-11 21:25:37.852', null);
insert into public."label" (id, board_id, "position", "name", color, created_at, updated_at)
values(1839554262351217715, 1839550803149325334, 131072.0, 'бэкапы', 'dark-granite', '2026-08-11 21:25:56.702', null);
insert into public."label" (id, board_id, "position", "name", color, created_at, updated_at)
values(1839554563024094261, 1839552744650703910, 65536.0, 'баг', 'red-burgundy', '2026-08-11 21:26:32.545', null);
insert into public."label" (id, board_id, "position", "name", color, created_at, updated_at)
values(1839554621106816054, 1839552744650703910, 131072.0, 'тест', 'desert-sand', '2026-08-11 21:26:39.471', null);
SQL

    # ─── 9. Карточки ───────────────────────────
    exec_sql <<'SQL'
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839551203923461149, 1839550594969240594, 1839550595044738068, 1839548131402843137, null, null, 'project', null, 'Archive', null, null, null, '2026-08-11 21:19:52.108', null, '2026-08-11 21:19:52.108', 0, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839555150822245431, 1839548652117296133, 1839549630866523145, 1839548131402843137, null, null, 'project', 65536.0, 'Тестовая карточка', 'Описание карточки', null, null, '2026-08-11 21:27:42.617', '2026-08-11 21:28:15.220', '2026-08-11 21:27:42.616', 0, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839556525052396606, 1839550594969240594, 1839551035136279579, 1839549968164062220, null, null, 'project', 65536.0, 'Настроить CI/CD', 'GitHub Actions: сборка, smoke\_test.sh, красный прогон', null, null, '2026-08-11 21:30:26.437', '2026-08-11 21:30:39.949', '2026-08-11 21:30:26.437', 0, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839557332690797635, 1839550803149325334, 1839551355119731743, 1839548131402843137, null, null, 'project', 65536.0, 'Настроить сеть и порты', 'Вынести порты и хосты в .env, проверить healthcheck', null, null, '2026-08-11 21:32:02.714', '2026-08-11 21:32:30.828', '2026-08-11 21:32:02.713', 0, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839557745838130245, 1839550803149325334, 1839551355119731743, 1839548131402843137, null, null, 'project', 131072.0, 'Резервное копирование БД', 'pg\_dump по расписанию, проверка восстановления', null, null, '2026-08-11 21:32:51.966', '2026-08-11 21:33:01.532', '2026-08-11 21:32:51.965', 0, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839558611919963210, 1839552744650703910, 1839552873885598763, 1839550084035904525, null, null, 'project', 65536.0, 'Задокументировать баг авторизации', 'Воспроизвести и описать шаги, приложить скриншот', null, null, '2026-08-11 21:34:35.210', '2026-08-11 21:34:45.924', '2026-08-11 21:34:35.209', 0, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839558415416820808, 1839552744650703910, 1839552973005390892, 1839550084035904525, null, null, 'project', 65536.0, 'Прогнать смоук-тесты', 'smoke\_test.sh: не менее 3 эндпоинтов, коды 200', null, null, '2026-08-11 21:34:11.786', '2026-08-11 21:48:04.801', '2026-08-11 21:34:11.785', 1, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839556054451487802, 1839550594969240594, 1839550970502054938, 1839549968164062220, null, null, 'project', 65536.0, 'Настроить Docker Compose', 'Создать docker-compose.yml с БД, приложением и кэшем', null, null, '2026-08-11 21:29:30.338', '2026-08-11 21:50:12.339', '2026-08-11 21:29:30.337', 2, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839556285876405308, 1839550594969240594, 1839550970502054938, 1839549968164062220, null, null, 'project', 131072.0, 'Написать setup.sh', 'Автоматизировать развертывание с нуля, совместимость с sh', null, null, '2026-08-11 21:29:57.926', '2026-08-11 21:50:57.398', '2026-08-11 21:29:57.925', 2, false, null);
insert into public.card (id, board_id, list_id, creator_user_id, prev_list_id, cover_attachment_id, "type", "position", "name", description, due_date, stopwatch, created_at, updated_at, list_changed_at, comments_total, is_closed, is_due_completed)
values(1839556721194828864, 1839550594969240594, 1839551078975144988, 1839549968164062220, null, null, 'project', 65536.0, 'Настроить мониторинг', 'Prometheus \+ Grafana \+ Loki, дашборды в репозитории', null, null, '2026-08-11 21:30:49.820', '2026-08-11 21:51:39.386', '2026-08-11 21:30:49.818', 1, false, null);
SQL

    # ─── 10. Метки на карточках ────────────────────────────────────────
    exec_sql <<'SQL'
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839560563672220749, 1839556054451487802, 1839553591799448622, '2026-08-11 21:38:27.878', null);
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839560743331038286, 1839556054451487802, 1839553681993761839, '2026-08-11 21:38:49.293', null);
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839560821521253455, 1839556285876405308, 1839553795936224304, '2026-08-11 21:38:58.618', null);
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839560968850375760, 1839556525052396606, 1839553591799448622, '2026-08-11 21:39:16.178', null);
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839561040069657681, 1839556721194828864, 1839553951494571057, '2026-08-11 21:39:24.671', null);
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839561552546497618, 1839557332690797635, 1839554104217568306, '2026-08-11 21:40:25.761', null);
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839561604983686227, 1839557745838130245, 1839554262351217715, '2026-08-11 21:40:32.014', null);
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839561693391225940, 1839558611919963210, 1839554563024094261, '2026-08-11 21:40:42.550', null);
insert into public.card_label (id, card_id, label_id, created_at, updated_at)
values(1839561725108552789, 1839558415416820808, 1839554621106816054, '2026-08-11 21:40:46.334', null);
SQL

    # ─── 11. Чек-листы и задачи ────────────────────────────────────────
    exec_sql <<'SQL'
insert into public.task_list (id, card_id, "position", "name", show_on_front_of_card, created_at, updated_at, hide_completed_tasks)
values(1839562916643210326, 1839556054451487802, 65536.0, 'Чек-лист', true, '2026-08-11 21:43:08.374', null, false);
insert into public.task_list (id, card_id, "position", "name", show_on_front_of_card, created_at, updated_at, hide_completed_tasks)
values(1839563015494566999, 1839556525052396606, 65536.0, 'Чек-лист', true, '2026-08-11 21:43:20.161', null, false);
insert into public.task_list (id, card_id, "position", "name", show_on_front_of_card, created_at, updated_at, hide_completed_tasks)
values(1839563180095833176, 1839558415416820808, 65536.0, 'Чек-лист', true, '2026-08-11 21:43:39.781', null, false);
insert into public.task (id, task_list_id, assignee_user_id, "position", "name", is_completed, created_at, updated_at, linked_card_id)
values(1839564188733670491, 1839562916643210326, null, 196608.0, 'Задать mem_limit и cpus', false, '2026-08-11 21:45:40.019', null, null);
insert into public.task (id, task_list_id, assignee_user_id, "position", "name", is_completed, created_at, updated_at, linked_card_id)
values(1839564003202827353, 1839562916643210326, null, 65536.0, 'Описать сервисы app + postgres + redis', true, '2026-08-11 21:45:17.902', '2026-08-11 21:45:45.714', null);
insert into public.task (id, task_list_id, assignee_user_id, "position", "name", is_completed, created_at, updated_at, linked_card_id)
values(1839564088582079578, 1839562916643210326, null, 131072.0, 'Настроить healthcheck для всех сервисов', true, '2026-08-11 21:45:28.079', '2026-08-11 21:45:46.166', null);
insert into public.task (id, task_list_id, assignee_user_id, "position", "name", is_completed, created_at, updated_at, linked_card_id)
values(1839564538882557023, 1839563015494566999, null, 65536.0, 'Проверка наличия docker и git', false, '2026-08-11 21:46:21.762', null, null);
insert into public.task (id, task_list_id, assignee_user_id, "position", "name", is_completed, created_at, updated_at, linked_card_id)
values(1839564614203868256, 1839563015494566999, null, 131072.0, 'Генерация .env через openssl', false, '2026-08-11 21:46:30.742', null, null);
insert into public.task (id, task_list_id, assignee_user_id, "position", "name", is_completed, created_at, updated_at, linked_card_id)
values(1839564664451630177, 1839563015494566999, null, 196608.0, 'Генерация .env через openssl', false, '2026-08-11 21:46:36.731', null, null);
insert into public.task (id, task_list_id, assignee_user_id, "position", "name", is_completed, created_at, updated_at, linked_card_id)
values(1839564874468820067, 1839563180095833176, null, 65536.0, 'sh setup.sh на чистой машине', false, '2026-08-11 21:47:01.765', null, null);
insert into public.task (id, task_list_id, assignee_user_id, "position", "name", is_completed, created_at, updated_at, linked_card_id)
values(1839564928667616356, 1839563180095833176, null, 131072.0, 'smoke_test.sh: 3 эндпоинта', false, '2026-08-11 21:47:08.228', null, null);
SQL

    # ─── 12. Комментарии ───────────────────────────────────────────────
    exec_sql <<'SQL'
insert into public."comment" (id, card_id, user_id, "text", created_at, updated_at)
values(1839565403211170917, 1839558415416820808, 1839550084035904525, 'Прогон на чистой VM — все проверки зелёные.', '2026-08-11 21:48:04.794', null);
insert into public."comment" (id, card_id, user_id, "text", created_at, updated_at)
values(1839566266029835369, 1839556054451487802, 1839548131402843137, 'Взял за основу официальный пример compose-файла.', '2026-08-11 21:49:47.648', null);
insert into public."comment" (id, card_id, user_id, "text", created_at, updated_at)
values(1839566473085846636, 1839556054451487802, 1839549968164062220, 'Добавь healthcheck для postgres и лимиты ресурсов.', '2026-08-11 21:50:12.330', null);
insert into public."comment" (id, card_id, user_id, "text", created_at, updated_at)
values(1839566751386305647, 1839556285876405308, 1839549968164062220, 'Скрипт обязан работать в sh — проверил через sh -n', '2026-08-11 21:50:45.511', null);
insert into public."comment" (id, card_id, user_id, "text", created_at, updated_at)
values(1839566851059745905, 1839556285876405308, 1839549968164062220, 'Повторный запуск не ломает данные, идемпотентность ок.', '2026-08-11 21:50:57.393', null);
insert into public."comment" (id, card_id, user_id, "text", created_at, updated_at)
values(1839567203289007219, 1839556721194828864, 1839549968164062220, 'Prometheus + Grafana + Loki, дашборды лежат в репозитории.', '2026-08-11 21:51:39.383', null);
SQL

    # ─── 13. Синхронизация счётчика комментариев ───────────────────────
    exec_sql <<'SQL'
UPDATE card cd
SET comments_total = (SELECT count(*) FROM comment cm WHERE cm.card_id = cd.id),
updated_at = NOW()
WHERE cd.comments_total <> (SELECT count(*) FROM comment cm WHERE cm.card_id = cd.id);
SQL

    # ─── 15. Подписки на карточки ──────────────────────────────────────
    exec_sql <<'SQL'
insert into public.card_subscription (id, card_id, user_id, is_permanent, created_at, updated_at)
values(1839565403370554470, 1839558415416820808, 1839550084035904525, true, '2026-08-11 21:48:04.817', null);
insert into public.card_subscription (id, card_id, user_id, is_permanent, created_at, updated_at)
values(1839566266155664490, 1839556054451487802, 1839548131402843137, true, '2026-08-11 21:49:47.669', null);
insert into public.card_subscription (id, card_id, user_id, is_permanent, created_at, updated_at)
values(1839566473387836526, 1839556054451487802, 1839549968164062220, true, '2026-08-11 21:50:12.370', null);
insert into public.card_subscription (id, card_id, user_id, is_permanent, created_at, updated_at)
values(1839566751537300592, 1839556285876405308, 1839549968164062220, true, '2026-08-11 21:50:45.531', null);
insert into public.card_subscription (id, card_id, user_id, is_permanent, created_at, updated_at)
values(1839567203448390772, 1839556721194828864, 1839549968164062220, true, '2026-08-11 21:51:39.403', null);
SQL

    # ─── 18. Лента действий (с ::jsonb!) ──────────────────────────────
    exec_sql <<'SQL'
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839551203982181406, 1839551203923461149, 1839548131402843137, 'createCard', '{"card": {"name": "Archive"}, "list": {"id": "1839550595044738068", "name": null, "type": "archive"}}'::jsonb, '2026-08-11 21:19:52.118', null, 1839550594969240594);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839555150872577080, 1839555150822245431, 1839548131402843137, 'createCard', '{"card": {"name": "Тестовая карточка"}, "list": {"id": "1839549630866523145", "name": "To Do", "type": "active"}}'::jsonb, '2026-08-11 21:27:42.624', null, 1839548652117296133);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839556054493430843, 1839556054451487802, 1839549968164062220, 'createCard', '{"card": {"name": "Описание карточки"}, "list": {"id": "1839550970502054938", "name": "To Do", "type": "active"}}'::jsonb, '2026-08-11 21:29:30.345', null, 1839550594969240594);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839556285926736957, 1839556285876405308, 1839549968164062220, 'createCard', '{"card": {"name": "Написать setup.sh"}, "list": {"id": "1839550970502054938", "name": "To Do", "type": "active"}}'::jsonb, '2026-08-11 21:29:57.933', null, 1839550594969240594);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839556525102728255, 1839556525052396606, 1839549968164062220, 'createCard', '{"card": {"name": "Настроить CI/CD"}, "list": {"id": "1839551035136279579", "name": "In Progress", "type": "active"}}'::jsonb, '2026-08-11 21:30:26.445', null, 1839550594969240594);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839556721253549121, 1839556721194828864, 1839549968164062220, 'createCard', '{"card": {"name": "Настроить мониторинг"}, "list": {"id": "1839551078975144988", "name": "Done", "type": "active"}}'::jsonb, '2026-08-11 21:30:49.827', null, 1839550594969240594);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839557332741129284, 1839557332690797635, 1839548131402843137, 'createCard', '{"card": {"name": "Настроить сеть и порты"}, "list": {"id": "1839551355119731743", "name": "To Do", "type": "active"}}'::jsonb, '2026-08-11 21:32:02.723', null, 1839550803149325334);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839557745888461894, 1839557745838130245, 1839548131402843137, 'createCard', '{"card": {"name": "Резервное копирование БД"}, "list": {"id": "1839551355119731743", "name": "To Do", "type": "active"}}'::jsonb, '2026-08-11 21:32:51.974', null, 1839550803149325334);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839558415475541065, 1839558415416820808, 1839550084035904525, 'createCard', '{"card": {"name": "Прогнать смоук-тесты"}, "list": {"id": "1839552973005390892", "name": "Testing", "type": "active"}}'::jsonb, '2026-08-11 21:34:11.795', null, 1839552744650703910);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839558611970294859, 1839558611919963210, 1839550084035904525, 'createCard', '{"card": {"name": "Задокументировать баг авторизации"}, "list": {"id": "1839552873885598763", "name": "Backlog", "type": "active"}}'::jsonb, '2026-08-11 21:34:35.219', null, 1839552744650703910);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839564236523570268, 1839556054451487802, 1839548131402843137, 'completeTask', '{"card": {"name": "Настроить Docker Compose"}, "task": {"id": "1839564003202827353", "name": "Описать сервисы app + postgres + redis"}}'::jsonb, '2026-08-11 21:45:45.718', null, 1839550594969240594);
insert into public."action" (id, card_id, user_id, "type", "data", created_at, updated_at, board_id)
values(1839564240306832477, 1839556054451487802, 1839548131402843137, 'completeTask', '{"card": {"name": "Настроить Docker Compose"}, "task": {"id": "1839564088582079578", "name": "Настроить healthcheck для всех сервисов"}}'::jsonb, '2026-08-11 21:45:46.170', null, 1839550594969240594);
SQL
    log_success "Тестовые данные успешно загружены!"
}

show_status() {
    log_info "Статистика загруженных записей:"
    exec_sql <<'SQL'
SELECT 'user_account' as tbl, COUNT(*) as rows FROM user_account
UNION ALL SELECT 'project', COUNT(*) FROM project
UNION ALL SELECT 'project_manager', COUNT(*) FROM project_manager
UNION ALL SELECT 'board', COUNT(*) FROM board
UNION ALL SELECT 'board_membership', COUNT(*) FROM board_membership
UNION ALL SELECT 'list', COUNT(*) FROM list
UNION ALL SELECT 'label', COUNT(*) FROM label
UNION ALL SELECT 'card', COUNT(*) FROM card
UNION ALL SELECT 'card_label', COUNT(*) FROM card_label
UNION ALL SELECT 'card_membership', COUNT(*) FROM card_membership
UNION ALL SELECT 'task_list', COUNT(*) FROM task_list
UNION ALL SELECT 'task', COUNT(*) FROM task
UNION ALL SELECT 'comment', COUNT(*) FROM comment
UNION ALL SELECT 'action', COUNT(*) FROM action
UNION ALL SELECT 'config', COUNT(*) FROM config
UNION ALL SELECT 'internal_config', COUNT(*) FROM internal_config
UNION ALL SELECT 'storage_usage', COUNT(*) FROM storage_usage
ORDER BY tbl;
SQL
}

# ==============================================================================
# БЛОК 3: ОСНОВНОЙ ПРОЦЕСС РАЗВЕРТЫВАНИЯ
# ==============================================================================
echo "=========================================="
echo "Начало развертывания Planka"
echo "=========================================="

# -----------------------------------------------------------------------------
# 1. Проверка наличия необходимых утилит
# -----------------------------------------------------------------------------
echo "[1/7] Проверка зависимостей..."
command -v docker >/dev/null 2>&1 || { echo >&2 "ОШИБКА: docker не установлен."; exit 1; }
command -v git >/dev/null 2>&1 || { echo >&2 "ОШИБКА: git не установлен."; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo >&2 "ОШИБКА: openssl не установлен."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "ОШИБКА: curl не установлен."; exit 1; }
echo "Все зависимости найдены."

# -----------------------------------------------------------------------------
# 2. Генерация .env файла (Идемпотентно)
# -----------------------------------------------------------------------------
if [ ! -f "$ENV_FILE" ]; then
    echo "[2/7] Генерация файла .env со случайными паролями..."
    SECRET_KEY=$(openssl rand -hex 32)
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    REDIS_PASSWORD=$(openssl rand -hex 16)
    cat <<EOF > "$ENV_FILE"
PLANKA_PORT=3000
BASE_URL=http://localhost:3000
SECRET_KEY=$SECRET_KEY
LOG_LEVEL=info
TRUST_PROXY=false
POSTGRES_IMAGE=postgres:16-alpine
POSTGRES_DB=planka
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_INITDB_ARGS=-c shared_buffers=256MB -c max_connections=200
REDIS_IMAGE=redis:7-alpine
REDIS_PASSWORD=$REDIS_PASSWORD
PLANKA_CPU_LIMIT=1
PLANKA_MEMORY_LIMIT=1G
PLANKA_CPU_RESERVATION=0.5
PLANKA_MEMORY_RESERVATION=512M
POSTGRES_CPU_LIMIT=0.5
POSTGRES_MEMORY_LIMIT=512M
POSTGRES_CPU_RESERVATION=0.25
POSTGRES_MEMORY_RESERVATION=256M
REDIS_CPU_LIMIT=0.25
REDIS_MEMORY_LIMIT=256M
REDIS_CPU_RESERVATION=0.1
REDIS_MEMORY_RESERVATION=128M
PLANKA_DATA_PATH=./data
DEFAULT_ADMIN_EMAIL=admin@example.com
DEFAULT_ADMIN_PASSWORD=admin-password-change-me
DEFAULT_ADMIN_NAME=Administrator
DEFAULT_ADMIN_USERNAME=admin
EOF
    echo "Файл .env успешно создан."
else
    echo "[2/7] Файл .env уже существует. Пропускаем генерацию (идемпотентность)."
fi

echo "[2.5/7] Клонирование репозитория."
PLANKA_TAG="2.1.1"
PLANKA_REPO="https://github.com/plankanban/planka.git"

if [ ! -d "client" ] || [ ! -d "server" ]; then
    echo "Клонирование исходников Planka $PLANKA_TAG..."
    TEMP_DIR=$(mktemp -d)
    git clone --branch "$PLANKA_TAG" --depth 1 "$PLANKA_REPO" "$TEMP_DIR/planka-src"

    # Копируем всё, кроме .git, docker-compose.yml, Dockerfile
    rsync -av --exclude='.git' --exclude='docker-compose.yml' --exclude='README.md' --exclude='.gitignore' --exclude='.github' --exclude='Dockerfile' "$TEMP_DIR/planka-src/" ./

    rm -rf "$TEMP_DIR"
    echo "Исходный код Planka $PLANKA_TAG успешно скопирован."
else
    echo "Исходный код Planka уже присутствует. Пропуск клонирования (идемпотентность)."
fi
# -----------------------------------------------------------------------------
# 3. Сборка образов
# -----------------------------------------------------------------------------
echo "[3/7] Сборка образов (docker compose build)..."

docker compose build

# -----------------------------------------------------------------------------
# 4. Запуск СУБД и кэша
# -----------------------------------------------------------------------------
echo "[4/7] Запуск контейнеров..."
docker compose up -d
sleep 30

# -----------------------------------------------------------------------------
# 5. Ожидание готовности СУБД
# -----------------------------------------------------------------------------
echo "[5/7] Ожидание готовности базы данных..."
MAX_RETRIES=30
RETRY_COUNT=0
HEALTH_STATUS="starting"
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' planka-postgres 2>/dev/null || echo "not_found")
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        echo "База данных успешно прошла проверку готовности!"
        break
    fi
    echo "  Ожидание... (попытка $((RETRY_COUNT + 1))/$MAX_RETRIES, статус: $HEALTH_STATUS)"
    sleep 3
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ "$HEALTH_STATUS" != "healthy" ]; then
    echo "ОШИБКА: База данных не стала доступной за отведенное время."
    docker compose logs postgres
    exit 1
fi

# -----------------------------------------------------------------------------
# 6. ИНТЕГРАЦИЯ: Загрузка тестовых данных (вызов функций из load-data.sh)
# -----------------------------------------------------------------------------
echo "[6/7] Загрузка тестовых данных в БД..."
load_env
check_container
load_test_data
show_status

echo ""
echo "Тестовые пользователи (пароль для всех: admin-password-change-me):"
echo "  - admin@example.com (Администратор)"
echo "  - john.doe@example.com"
echo "  - jane.smith@example.com"
echo ""

# -----------------------------------------------------------------------------
# 7. Итоговый статус и проверка доступности
# -----------------------------------------------------------------------------
echo "[7/7] Финальная проверка доступности приложения..."
APP_PORT=$(grep '^PLANKA_PORT=' "$ENV_FILE" | cut -d '=' -f2-)
APP_PORT=${APP_PORT:-3000}

sleep 3
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$APP_PORT" || echo "000")

echo "=========================================="
echo "РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО!"
echo "=========================================="
echo "Адрес приложения: http://localhost:$APP_PORT"
echo "Статус проверки (HTTP): $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "401" ]; then
    echo "Результат: УСПЕШНО. Приложение отвечает."
else
    echo "Результат: ВНИМАНИЕ. Неожиданный код ответа."
    echo "Рекомендуется проверить логи: docker compose logs planka"
fi
echo "=========================================="