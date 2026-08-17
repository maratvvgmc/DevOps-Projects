Markdown
# Полное руководство: Настройка DNS и веб-сервера на Linux (Nginx)

Конспект по концепциям DNS, настройке DNS-записей, связыванию домена с сервером и конфигурации виртуальных хостов в Nginx.

---

## 1. Как работает DNS (Domain Name System)

**DNS** — распределенная система, которая сопоставляет доменные имена (например, `mysite.com`) с физическими IP-адресами серверов (`203.0.113.195`).

### Базовые типы DNS-записей

* **`A` (IPv4 Address)**: Указывает домен или поддомен на конкретный IPv4-адрес сервера.
* **`AAAA` (IPv6 Address)**: Указывает домен на IPv6-адрес.
* **`CNAME` (Canonical Name)**: Создает псевдоним одного домена на другой (например, `www.mysite.com` -> `mysite.com`). Нельзя использовать для корневого домена (`@`).
* **`MX` (Mail Exchange)**: Определяет почтовые серверы, обслуживающие почту вашего домена.
* **`TXT` (Text)**: Произвольные текстовые данные. Используется для верификации владения сайтом, а также для защиты почты (SPF, DKIM, DMARC).
* **`NS` (Name Server)**: Указывает, какие DNS-серверы хранят авторитетные записи для данного домена.

---

## 2. Связывание домена с сервером (DNS-провайдер)

Существует два основных подхода к управлению DNS-записями:

### Способ А: Управление через панель регистратора (или Cloudflare)
Вы оставляете NS-серверы регистратора (или переводите домен на Cloudflare) и в их панели создаете следующие записи:

| Тип | Имя / Хост (Host) | Значение (Value / Target) | TTL | Назначение |
| :--- | :--- | :--- | :--- | :--- |
| **A** | `@` | `203.0.113.195` | Auto / 300 | Направляет основной домен на ваш IP |
| **A** | `www` | `203.0.113.195` | Auto / 300 | Направляет www-поддомен на ваш IP |
| **A** | `subdomain` | `203.0.113.195` | Auto / 300 | (Опционально) Отдельный поддомен |

---

### Способ Б: Делегирование NS-серверов хостинг-провайдеру (например, DigitalOcean)
1. В панели регистратора меняете NS-записи домена на серверы провайдера (например, `ns1.digitalocean.com`, `ns2.digitalocean.com`).
2. Управляете всеми `A`, `CNAME` и `MX` записями прямо из панели управления провайдера.

---

## 3. Настройка веб-сервера (Nginx) под домен

После того как DNS-записи указывают на ваш IP, веб-сервер на сервере должен понимать, какой сайт отдавать при запросе конкретного домена.

### Step 1. Создание каталога сайта
```bash
# Создаем директорию для файлов сайта
sudo mkdir -p /var/www/[mysite.com/html](https://mysite.com/html)

# Назначаем владельцем текущего пользователя
sudo chown -R $USER:$USER /var/var/www/[mysite.com/html](https://mysite.com/html)

# Права на чтение для всех
sudo chmod -R 755 /var/www/mysite.com
Step 2. Создание тестового файла index.html
Bash
echo "<h1>Welcome to mysite.com!</h1>" > /var/www/[mysite.com/html/index.html](https://mysite.com/html/index.html)
Step 3. Создание конфигурации виртуального хоста (Server Block)
Создайте файл конфигурации в директории sites-available:

Bash
sudo nano /etc/nginx/sites-available/mysite.com
Вставьте следующий блок конфигурации:

Nginx
server {
    listen 80;
    listen [::]:80;

    # Доменные имена, которые обрабатывает этот блок
    server_name mysite.com [www.mysite.com](https://www.mysite.com);

    # Корневая папка с файлами сайта
    root /var/www/[mysite.com/html](https://mysite.com/html);
    index index.html index.htm;

    # Обработка запросов
    location / {
        try_files $uri$uri/ =404;
    }

    # Логи доступа и ошибок для этого домена
    access_log /var/log/nginx/mysite.com.access.log;
    error_log /var/log/nginx/mysite.com.error.log;
}
Step 4. Активация конфигурации и перезапуск Nginx
Bash
# Создание символической ссылки для активации сайта
sudo ln -s /etc/nginx/sites-available/mysite.com /etc/nginx/sites-enabled/

# Проверка синтаксиса конфигурации Nginx
sudo nginx -t

# Перезапуск Nginx для применения изменений
sudo systemctl reload nginx
4. Выпуск бесплатного SSL-сертификата (HTTPS) через Certbot
Для защиты трафика и работы по протоколу HTTPS используется Let's Encrypt.

Bash
# Установка Certbot и плагина для Nginx
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

# Получение и автоматическая установка сертификата
sudo certbot --nginx -d mysite.com -d [www.mysite.com](https://www.mysite.com)
Certbot автоматически изменит ваш файл конфигурации Nginx, добавив настройки SSL на порт 443 и настроив автоматический редирект с HTTP на HTTPS.

5. Диагностика и отладка (Troubleshooting)
Инструменты проверки DNS на клиенте / сервере:
Bash
# 1. Проверка A-записи домена через dig
dig mysite.com A +short

# 2. Проверка запрашиваемых NS-серверов
dig mysite.com NS +short

# 3. Кроссплатформенная проверка IP через nslookup
nslookup mysite.com

# 4. Проверка ответа веб-сервера через curl с заголовком Host
curl -I [http://mysite.com](http://mysite.com)
Полезные логи на сервере:
Bash
# Лог ошибок Nginx для конкретного сайта
sudo tail -f /var/log/nginx/mysite.com.error.log

# Главный системный лог Nginx
sudo journalctl -u nginx --since "10 minutes ago"