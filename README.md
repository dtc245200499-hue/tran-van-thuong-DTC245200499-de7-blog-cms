# Đề 7 - Hệ thống Blog / CMS
**Sinh viên: Trần Văn Thưởng - MSSV: DTC245200499 - Khóa: K23**  
Lớp, trường/khoa và giảng viên: chờ bổ sung theo thông tin chính thức.

Repository: https://github.com/dtc245200499-hue/tran-van-thuong-DTC245200499-de7-blog-cms

Website WordPress với giao diện Campus Journal tự xây dựng, quản lý bài viết, danh mục,
người dùng, tìm kiếm và phân quyền Administrator/Editor. Tất cả dịch vụ triển khai qua Docker Compose.

## Chạy nhanh trên Windows
Yêu cầu Docker Desktop chạy **Linux containers**, Docker Compose v2+ và PowerShell.
Gợi ý cấp 4 CPU, RAM 6-8 GB, 10 GB đĩa trống; lần đầu cần Internet để tải image.
Từ thư mục repository:
~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/start.ps1
~~~
Script tạo 6 mật khẩu ngẫu nhiên 48 ký tự hex, chạy stack, chờ MySQL/WordPress và khởi tạo
website, 3 danh mục, 3 bài công khai, 1 bản nháp và 2 tài khoản. WordPress có thể còn bài
mặc định Hello world. Chạy seed lại không nhân bản dữ liệu sau khi lần đầu hoàn tất.

| Thành phần | Địa chỉ | Tài khoản | Mật khẩu cục bộ |
|---|---|---|---|
| Website | http://localhost:8080 | Không cần | - |
| WordPress Admin | http://localhost:8080/wp-admin/ | thuong_admin | secrets/wp_admin_password.txt |
| Editor | http://localhost:8080/wp-admin/ | bien_tap | secrets/wp_editor_password.txt |
| phpMyAdmin | http://localhost:8081 | blog | secrets/db_password.txt |
| Grafana | http://localhost:3000 | admin | secrets/grafana_password.txt |
| Prometheus | http://localhost:9090/targets | Chỉ localhost | - |

Đọc đúng tệp mật khẩu trên máy, không đưa mật khẩu vào ảnh chụp hoặc GitHub.
phpMyAdmin dùng cookie login, không tự đăng nhập root.
MySQL, Loki, exporters, cAdvisor, WordPress backend không publish port.

## Kiến trúc
~~~mermaid
flowchart LR
  Browser -->|localhost:8080| Nginx
  Nginx --> WordPress
  WordPress --> MySQL
  phpMyAdmin --> MySQL
  Nginx -->|access/error files| Promtail
  Promtail --> Loki
  NginxExporter --> Nginx
  MySQLExporter --> MySQL
  Prometheus --> NginxExporter
  Prometheus --> MySQLExporter
  Prometheus --> cAdvisor
  Prometheus --> Loki
  Prometheus --> Promtail
  Grafana --> Prometheus
  Grafana --> Loki
~~~

Có 11 dịch vụ thường trực, init-logs chuẩn bị quyền volume rồi thoát, và seed (profile tools, chỉ chạy khi gọi).
Frontend: Nginx/WordPress. Database: MySQL/WordPress/phpMyAdmin/mysql-exporter, internal.
Monitoring: Prometheus/Grafana/Loki/Promtail/exporters/cAdvisor/Nginx, internal.
phpMyAdmin có thêm mạng admin để publish localhost. WordPress có mạng frontend cho kết nối
ra ngoài; database internal không thay thế cho firewall hoặc cơ chế phân quyền SQL.

## Giám sát và log
Grafana tự nạp 2 datasource và dashboard **De 7 - Blog CMS Operations** gồm CPU/RAM container,
request/giây, kết nối Nginx, MySQL up, queries/giây, kết nối DB và log.
Truy cập http://localhost:3000/d/de7-blog sau đăng nhập.
Chờ 1-2 phút cho biểu thức rate có đủ dữ liệu. Prometheus có 6 target.
Kiểm tra thêm mysql_up = 1, nginx_up = 1; target UP chỉ chứng minh scrape endpoint trả lời.

Trong Grafana Explore chọn **Loki**, thời gian Last 15 minutes:
~~~logql
{job="nginx", stream="access"}
{job="nginx", stream="access"} | json | status >= 400
{job="nginx", stream="access"} | json | status = 403
sum(count_over_time({job="nginx", stream="access"} | json | status >= 400 [5m]))
{job="nginx", stream="error"} |= "error"
~~~
Tạo log 403 bằng http://localhost:8080/xmlrpc.php. Không cần lỗi 500 giả.
Loki tập trung **access/error log Nginx** (không tuyên bố thu toàn bộ stdout của mọi container).
LogQL phân tích JSON lúc truy vấn, tránh gắn URI/status thành label gây nhiều stream.

## Kiểm tra và demo
~~~powershell
docker compose ps
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1
~~~
verify kiểm tra website, permalink, security header, 403, DB tool HTTP, Grafana health,
6 target, mysql_up/nginx_up, container metrics và log 403. CRUD và phân quyền cần demo
thủ công theo [docs/DEMO.md](docs/DEMO.md).
Xem [docs/VALIDATION.md](docs/VALIDATION.md) để phân biệt kiểm tra tĩnh với kiểm tra runtime.
Báo cáo PDF và bản Markdown trong docs/. Cần chèn screenshot thật trước khi nộp.

## Hardening
- Mật khẩu ngẫu nhiên riêng biệt; secrets file bị Git ignore, sử dụng *_FILE.
- Ứng dụng dùng user SQL blog chỉ có quyền trong DB blog; exporter có SELECT/PROCESS/REPLICATION CLIENT, tối đa 3 kết nối.
- Nginx, Grafana, Loki, Prometheus và exporters chạy UID non-root.
- Bỏ toàn bộ Linux capabilities, root filesystem read-only cho nhóm dịch vụ hỗ trợ.
- no-new-privileges; network database và monitoring internal; chỉ bind port 127.0.0.1.
- Security headers, giấu phiên bản Nginx/PHP, chặn XML-RPC và dotfile.
- Tắt chỉnh sửa/cài theme-plugin qua giao diện; theme bind mount read-only.
- Log Docker xoay vòng 10 MB x 3; metric và Loki giữ 7 ngày.

**Ngoại lệ có chủ đích:** WordPress/phpMyAdmin official Apache cần root entrypoint/master,
worker phục vụ HTTP hạ quyền. MySQL official entrypoint khởi tạo quyền rồi chạy mysqld
bằng mysql. Không tuyên bố toàn bộ container là non-root. Promtail UID 0 để đọc log
và ghi positions nhưng cap_drop ALL, read_only, không mount socket/host.
cAdvisor privileged, có quyền quan sát host và mount /var/run, là ngoại lệ nhạy cảm;
chỉ dùng máy lab, không publish port. Mount socket :ro không biến Docker API thành
read-only; không xem cấu hình cAdvisor là ranh giới bảo mật production.

Promtail đã EOL 02/03/2026, giữ để đúng đề; hệ thống thực tế nên chuyển sang Grafana Alloy.
Các image gắn phiên bản để tái lập bài lab, **chưa quét CVE**, không coi là cấu hình production.
Đề cho phép HTTPS **hoặc** security headers; bản này dùng HTTP localhost và security headers.
Muốn public phải bổ sung TLS hợp lệ, firewall/VPN cho admin, cập nhật và quét image.

## Vận hành
~~~powershell
docker compose logs --tail=100 nginx wordpress mysql
docker compose restart nginx
docker compose down
docker compose up -d
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/backup.ps1
~~~
down không xóa named volume. Không dùng down -v nếu cần giữ dữ liệu.
Giữ thư mục secrets an toàn; tạo lại secret không tự đổi mật khẩu DB đã nằm trong volume.
Đổi host/port: sửa seed.BLOG_URL, mapping Nginx và cập nhật siteurl/home bằng WP-CLI:
~~~powershell
docker compose --profile tools run --rm --entrypoint wp seed option update home http://localhost:8080
docker compose --profile tools run --rm --entrypoint wp seed option update siteurl http://localhost:8080
~~~
Backup gồm dump DB và uploads; lưu cùng Git revision và secrets ở nơi riêng.
Hướng dẫn restore và xử lý lỗi: [docs/OPERATIONS.md](docs/OPERATIONS.md).

## Tài liệu gốc và tham khảo
- Đề tài thực hành TKQT HTPM K23, trang 1-4: đề 7, yêu cầu chung và tiêu chí.
- https://hub.docker.com/_/wordpress
- https://github.com/prometheus/mysqld_exporter
- https://github.com/google/cadvisor/blob/master/docs/running.md
- https://grafana.com/docs/loki/latest/send-data/promtail/
- https://grafana.com/docs/loki/latest/query/

Thông tin tác giả, tài khoản và dữ liệu mẫu phục vụ bài thực hành; không có mật khẩu trong source.
