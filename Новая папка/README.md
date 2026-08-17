# Roadmap.sh: Simple System Monitoring with Netdata — Complete Study Notes

Этот конспект содержит теорию по мониторингу системных метрик, пошаговое руководство по установке и настройке **Netdata**, созданию алертов, а также готовые Bash-скрипты автоматизации (`setup.sh`, `test_dashboard.sh`, `cleanup.sh`).

---

## 1. Основы системного мониторинга

**Мониторинг** — это процесс непрерывного сбора, агрегации и анализа метрик работы операционной системы и приложений для обеспечения доступности и производительности.

### Ключевые метрики ресурсоемкости (USE Method):
* **CPU Usage**: Нагрузка на процессор (User, System, IOWait, Idle). Высокий IOWait указывает на узкое место в дисковой подсистеме.
* **Memory Usage**: Распределение ОЗУ (Used, Free, Buffers/Cached, Swap).
* **Disk I/O**: Скорость чтения/записи (IOPS, throughput) и утилизация диска (`%util`).
* **Network Traffic**: Входящий/исходящий трафик (Kbps/Mbps) и ошибки пакетов (errors/dropped).

---

## 2. Пошаговая ручная установка и настройка Netdata

Netdata — это lightweight агент реального времени (1-second granularity), собирающий метрики системы с минимальным потреблением ресурсов.

### Шаг 1. Установка агента Netdata (Ubuntu/Debian)

```bash
# Официальный скрипт автоматической установки Netdata
wget -O /tmp/netdata-kickstart.sh [https://get.netdata.cloud/kickstart.sh](https://get.netdata.cloud/kickstart.sh)
sh /tmp/netdata-kickstart.sh --non-interactive

# Проверка статуса службы
sudo systemctl status netdata
По умолчанию веб-интерфейс Netdata доступен по адресу: http://<SERVER_IP>:19999

Шаг 2. Настройка собственного алерта (Custom Alert)
Создадим пользовательский алерт для оповещения при высокой загрузке CPU (выше 80%).

Bash
# Редактирование файла пользовательских медицинских правил
sudo /etc/netdata/edit-config health.d/cpu.conf
Добавьте следующую конфигурацию правила:

Ini, TOML
 template: custom_cpu_high
       on: system.cpu
    lookup: average -1m unaligned of user,system,softirq,irq,guest
     every: 10s
      warn: $this > 70
     crit: $this > 80
     delay: up 30s down 1m peak 2m
      info: Average CPU utilization over the last minute is high
Перезапустите или обновите конфигурацию Health Engine:

Bash
# Перезагрузка правил алертов без полной перезагрузки агента
sudo netdata-cli reload-health
3. Скрипты автоматизации (DevOps Practices)
Для автоматизации процесса создадим три исполняемых скрипта.

3.1 setup.sh — Автоматическая установка и настройка
Bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/3] Updating system packages ==="
sudo apt-get update -y
sudo apt-get install -y curl wget stress-ng

echo "=== [2/3] Installing Netdata Agent ==="
if ! command -v netdata &> /dev/null; then
    wget -O /tmp/netdata-kickstart.sh [https://get.netdata.cloud/kickstart.sh](https://get.netdata.cloud/kickstart.sh)
    sh /tmp/netdata-kickstart.sh --non-interactive
else
    echo "Netdata is already installed."
fi

echo "=== [3/3] Configuring Custom CPU Alert ==="
NETDATA_CONF_DIR="/etc/netdata/health.d"
sudo mkdir -p "${NETDATA_CONF_DIR}"

cat << 'EOF' | sudo tee "${NETDATA_CONF_DIR}/custom_cpu.conf" > /dev/null
 template: custom_cpu_high
       on: system.cpu
    lookup: average -10s unaligned of user,system
     every: 5s
      warn: $this > 60
     crit: $this > 80
      info: High CPU load detected by automated test
EOF

echo "=== Restarting Netdata Service ==="
sudo systemctl restart netdata

echo "SUCCESS: Netdata setup complete! Access dashboard at http://$(hostname -I | awk '{print $1}'):19999"
3.2 test_dashboard.sh — Генерация нагрузки для проверки метрик и алертов
Скрипт генерирует искусственную нагрузку на CPU, память и диск с помощью утилиты stress-ng.

Bash
#!/usr/bin/env bash
set -euo pipefail

if ! command -v stress-ng &> /dev/null; then
    echo "Installing stress-ng..."
    sudo apt-get install -y stress-ng
fi

echo "=== Starting Load Test for Netdata Dashboard ==="
echo "Generating High CPU & RAM load for 60 seconds..."
echo "Watch your Netdata dashboard (http://<SERVER_IP>:19999) to observe spike and triggered alerts!"

# Нагрузка: 4 ядра CPU, 256M RAM, 2 потока Disk I/O на 60 секунд
stress-ng --cpu 4 --vm 2 --vm-bytes 256M --io 2 --timeout 60s --metrics-brief

echo "=== Load Test Completed ==="
echo "Check the Health Notifications tab in Netdata to verify if the CPU alert was triggered."
3.3 cleanup.sh — Очистка системы и удаление Netdata
Bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/2] Stopping and Uninstalling Netdata ==="
if [ -f /usr/libexec/netdata/netdata-uninstaller.sh ]; then
    sudo /usr/libexec/netdata/netdata-uninstaller.sh --yes --force
elif [ -f /usr/sbin/netdata-uninstaller.sh ]; then
    sudo /usr/sbin/netdata-uninstaller.sh --yes --force
else
    echo "Netdata uninstaller script not found. Purging via package manager..."
    sudo apt-get purge -y netdata || true
fi

echo "=== [2/2] Removing leftover configurations and tools ==="
sudo rm -rf /etc/netdata /var/lib/netdata /var/log/netdata /var/cache/netdata
sudo apt-get remove -y stress-ng || true
sudo apt-get autoremove -y

echo "SUCCESS: Cleanup complete. System restored to initial state."
4. Запуск и проверка работы
Bash
# 1. Сделать скрипты исполняемыми
chmod +x setup.sh test_dashboard.sh cleanup.sh

# 2. Запустить установку
./setup.sh

# 3. Запустить тест нагрузки и открыть дашборд в браузере
./test_dashboard.sh

# 4. После проверки выполнить очистку
./cleanup.sh
5. Диагностика и полезные команды
Bash
# Проверить статус службы Netdata
sudo systemctl status netdata

# Просмотр логов работы агента
sudo journalctl -u netdata --since "10 minutes ago" -f

# Проверить текущий статус алертов через CLI
sudo netdata-cli health