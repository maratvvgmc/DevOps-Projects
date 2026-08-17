# Roadmap.sh: SSH Remote Server Setup & Security Hardening

Полный конспект по настройке SSH-подключения на удаленный сервер по ключам, настройке alias-конфига, изменению стандартных портов и защите сервера через UFW и Fail2ban.

---

## 1. Подготовка удаленного сервера

Перед настройкой ключей убедитесь, что на сервере установлен и запущен OpenSSH.

```bash
# Обновление списков пакетов
sudo apt update

# Установка пакета OpenSSH Server
sudo apt install openssh-server -y

# Проверка статуса службы SSH
sudo systemctl status ssh
2. Генерация двух пар SSH-ключей (Хостовая машина)
Создайте две разные пары ключей на вашей локальной машине (PowerShell на Windows или Терминал на Linux/macOS).

2.1 Генерация ключей
Перейдите в директорию ~/.ssh/ и выполните команды:

Bash
# Генерация первой пары ключей
ssh-keygen -t ed25519 -C "devserver_primary_key" -f ~/.ssh/devserver_key1

# Генерация второй пары ключей
ssh-keygen -t ed25519 -C "devserver_secondary_key" -f ~/.ssh/devserver_key2
Флаги:

-t ed25519 — современный и безопасный алгоритм шифрования.

-C "comment" — комментарий для идентификации ключа.

-f <path> — путь и имя файла для сохранения.

В результате создаются файлы:

devserver_key1 / devserver_key2 — закрытые (приватные) ключи. Никогда никому не передавайте!

devserver_key1.pub / devserver_key2.pub — открытые (публичные) ключи.

3. Добавление публичных ключей на сервер
3.1 Просмотр публичных ключей
Выведите содержимое публичных ключей на хостовой машине:

Bash
cat ~/.ssh/devserver_key1.pub
cat ~/.ssh/devserver_key2.pub
3.2 Настройка прав и файла authorized_keys на сервере
Зайдите на сервер и выполните подготовку:

Bash
# Создание папки .ssh, если она не существует
mkdir -p ~/.ssh

# Установка прав доступа только для владельца
chmod 700 ~/.ssh

# Открытие файла authorized_keys для редактирования
nano ~/.ssh/authorized_keys
Вставьте оба публичных ключа с новой строки:

Plaintext
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... devserver_primary_key
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... devserver_secondary_key
Сохраните файл (Ctrl+O, Enter, Ctrl+X) и установите строго ограниченные права:

Bash
chmod 600 ~/.ssh/authorized_keys
4. Настройка быстрых подключений через ~/.ssh/config
Чтобы не вводить каждый раз IP-адреса, порты и пути к ключам, настройте файл конфигурации на локальном ПК.

Создайте или отредактируйте файл ~/.ssh/config (или C:\Users\<username>\.ssh\config на Windows):

Ini, TOML
Host devserver-key1
    HostName 192.168.X.X
    User username
    Port 2222
    IdentityFile ~/.ssh/devserver_key1

Host devserver-key2
    HostName 192.168.X.X
    User username
    Port 2222
    IdentityFile ~/.ssh/devserver_key2
Использование:
Теперь подключение выполняется короткой командой:

Bash
ssh devserver-key1
# или
ssh devserver-key2
5. Базовая безопасность SSH (Hardening)
Изменение стандартных настроек OpenSSH daemon для защиты от сканеров и подбора паролей.

5.1 Создание отдельного файла конфигурации
Рекомендуется добавлять свои правила в отдельный файл в папке /etc/ssh/sshd_config.d/:

Bash
sudo nano /etc/ssh/sshd_config.d/hardened.conf
Вставьте следующие параметры:

Ini, TOML
# Смена стандартного порта 22 на нестандартный 2222
Port 2222

# Запрет прямого входа под пользователем root
PermitRootLogin no

# Запрет авторизации по паролю (только по SSH-ключам)
PasswordAuthentication no

# Разрешение авторизации по публичным ключам
PubkeyAuthentication yes

# Максимальное количество попыток аутентификации за сессию
MaxAuthTries 3

# Путь к файлу с авторизованными ключами
AuthorizedKeysFile .ssh/authorized_keys
5.2 Проверка и перезапуск службы
Bash
# Проверка конфигурационного файла на синтаксические ошибки
sudo sshd -t

# Перезапуск службы SSH для применения настроек
sudo systemctl restart sshd
6. Настройка файрвола (UFW)
Настройка межсетевого экрана для закрытия всех портов, кроме используемого SSH.

Bash
# Разрешить подключение по новому порту SSH
sudo ufw allow 2222/tcp

# Запретить все входящие подключения по умолчанию
sudo ufw default deny incoming

# Разрешить все исходящие подключения
sudo ufw default allow outgoing

# Включить UFW
sudo ufw enable

# Проверить статус файрвола
sudo ufw status verbose
7. Защита от подбора паролей (Fail2ban)
Fail2ban отслеживает логи авторизации и автоматически блокирует IP-адреса, предпринимающие попытки брутфорса.

7.1 Установка Fail2ban
Bash
sudo apt update && sudo apt install fail2ban -y
7.2 Создание локальной конфигурации
Создайте файл /etc/fail2ban/jail.local:

Bash
sudo nano /etc/fail2ban/jail.local
Вставьте следующие настройки:

Ini, TOML
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
banaction = ufw

[sshd]
enabled = true
port = 2222
filter = sshd-aggressive
logpath = /var/log/auth.log
maxretry = 3
Разбор параметров:

bantime = 1h — время блокировки IP-адреса (1 час).

findtime = 10m — окно времени (10 минут), в течение которого считаются неудачные попытки.

maxretry = 3 — максимальное число неудачных попыток перед баном.

banaction = ufw — использование UFW для блокировки забаненных IP.

filter = sshd-aggressive — строгий фильтр анализа логов SSH.

logpath = /var/log/auth.log — путь к логу аутентификации.

7.3 Запуск и проверка службы
Bash
# Включение службы в автозагрузку
sudo systemctl enable fail2ban

# Запуск службы Fail2ban
sudo systemctl start fail2ban

# Проверка статуса джейла sshd
sudo fail2ban-client status sshd
8. Полезные команды для диагностики
Управление Fail2ban
Разблокировать конкретный IP:

Bash
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>
Просмотр логов Fail2ban:

Bash
sudo tail -f /var/log/fail2ban.log
Диагностика SSH
Просмотр логов подключения SSH в реальном времени:

Bash
sudo journalctl -u ssh --since "5 minutes ago" -f
Подключение с выводом подробных отладочных логов:

Bash
ssh -v devserver-key1