#!/bin/sh
set -eu
cd /var/www/html
if ! wp core is-installed; then
  wp core install --url="$BLOG_URL" --title='Campus Journal | DTC245200499' --admin_user=thuong_admin --admin_password="$(cat /run/secrets/wp_admin_password)" --admin_email=thuong@example.invalid --skip-email
fi
wp theme activate campus-journal
wp option update blogdescription 'Ghi chép công nghệ, chia sẻ kiến thức và hành trình học tập'
wp option update permalink_structure '/%postname%/'
wp rewrite flush --hard
if ! wp user get bien_tap >/dev/null 2>&1; then
  wp user create bien_tap editor@example.invalid --role=editor --user_pass="$(cat /run/secrets/wp_editor_password)" --display_name='Ban biên tập'
fi
for category in 'Công nghệ' 'Docker & DevOps' 'Góc học tập'; do
  if ! wp term list category --field=name | grep -Fx "$category" >/dev/null; then wp term create category "$category"; fi
done
if [ "$(wp option get de7_seeded 2>/dev/null || true)" != 'yes' ]; then
  category_id="$(wp term list category --name='Docker & DevOps' --field=term_id)"
  wp post create --post_type=post --post_status=publish --post_title='Từ mã nguồn đến hệ thống: hành trình cùng Docker Compose' --post_name='hanh-trinh-docker-compose' --post_category="$category_id" --post_content='<p>Một website hoàn chỉnh cần nhiều hơn mã nguồn: cần cơ sở dữ liệu, reverse proxy và công cụ vận hành.</p><h2>Vì sao chọn Docker Compose?</h2><p>Compose mô tả dịch vụ, mạng và volume trong một cấu hình có thể quản lý bằng Git. Mỗi thành phần có trách nhiệm rõ ràng.</p><h2>Quan sát và bảo vệ</h2><p>Prometheus thu thập chỉ số, Grafana trực quan hóa, Loki lưu nhật ký để tìm sự cố. Mật khẩu mạnh và mạng nội bộ giúp giảm bề mặt tấn công.</p>'
  wp post create --post_type=post --post_status=publish --post_title='Đọc hiểu dashboard: CPU, RAM và kết nối MySQL' --post_name='doc-hieu-dashboard' --post_content='<p>CPU đo mức sử dụng xử lý, RAM working set thể hiện bộ nhớ hoạt động và kết nối MySQL phản ánh nhu cầu truy cập dữ liệu. Hãy so sánh biểu đồ với hành vi truy cập theo thời gian.</p>'
  wp post create --post_type=post --post_status=publish --post_title='LogQL: bắt đầu từ một request bị từ chối' --post_name='logql-request-bi-tu-choi' --post_content='<p>Truy cập /xmlrpc.php tạo mã 403 theo chính sách Nginx. Dùng Grafana Explore, chọn Loki và lọc status = 403 để tìm request tương ứng.</p>'
  wp post create --post_type=post --post_status=draft --post_title='Bản nháp: kế hoạch học tập tuần tới' --post_content='<p>Bài này chỉ xuất hiện trong trang quản trị cho đến khi được xuất bản.</p>'
  wp option update de7_seeded yes
fi
echo 'Seed complete. Admin: thuong_admin; editor: bien_tap. Passwords are in local secrets files.'
