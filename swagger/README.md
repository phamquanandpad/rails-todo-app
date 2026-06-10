# Hướng dẫn thêm API endpoint mới

## 1. Tạo file path YAML

Tạo file trong `swagger/paths/v1/<resource>/` theo tên action.

| Action | Tên file |
|--------|----------|
| `index` + `create` | `index.yaml` |
| `show` + `update` + `destroy` | `show.yaml` |
| Custom action (e.g. `complete`) | `complete.yaml` |

**Ví dụ** — thêm `PATCH /api/v1/todos/:id/complete`:

```yaml
# swagger/paths/v1/todos/complete.yaml
patch:
  summary: Mark todo as completed
  operationId: patch-todo-complete
  tags: [todo]
  security:
    - bearerAuth: []
  responses:
    '200':
      description: Todo marked as completed
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Todo'
    '404':
      $ref: '#/components/responses/NotFound'
    '401':
      $ref: '#/components/responses/Unauthorized'
```

> `operationId` phải **duy nhất** trong toàn bộ spec. Dùng pattern: `{method}-{resource}-{action}`.

---

## 2. Đăng ký path vào root spec

Mở `swagger/reference/v1.yaml`, thêm vào section `paths:`:

```yaml
paths:
  # ... các path hiện có ...
  /api/v1/todos/{id}/complete:
    $ref: '../paths/v1/todos/complete.yaml'
```

---

## 3. Thêm schema mới (nếu cần)

Chỉ làm bước này nếu response trả về schema **chưa có**.

**Thêm vào file component phù hợp:**

```yaml
# swagger/components/schemas/<tên>.yaml
components:
  schemas:
    NewSchema:
      type: object
      properties:
        id:
          type: integer
        # ...
      required: [id]
```

**Rồi đăng ký vào `swagger/reference/v1.yaml` → section `components.schemas`:**

```yaml
components:
  schemas:
    NewSchema:
      $ref: '../components/schemas/<tên>.yaml#/components/schemas/NewSchema'
```

---

## 4. Merge YAML → sinh `merged/v1.yaml`

```bash
cd swagger && npm run merge && cd ..
```

> File `swagger/merged/v1.yaml` là file được dùng bởi Redoc UI và committee contract tests. **Không sửa tay file này.**

---

## 5. Viết request spec với contract test

Trong file spec tương ứng (`spec/requests/api/v1/<resource>_spec.rb`), thêm describe block mới. Với mọi test trả về 2xx, thêm `assert_schema_conform(status_code)` ở **cuối** block `it`.

```ruby
describe "PATCH /api/v1/todos/:id/complete" do
  let!(:todo) { create(:todo, user: user) }

  it "marks todo as completed" do
    patch "/api/v1/todos/#{todo.id}/complete",
      headers: user_headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("completed")
    assert_schema_conform(200)   # ← bắt buộc
  end

  it "returns 404 for another user's todo" do
    patch "/api/v1/todos/#{other_todo.id}/complete",
      headers: user_headers, as: :json

    expect(response).to have_http_status(:not_found)
    # không cần assert_schema_conform cho error cases (validate_success_only: true)
  end
end
```

---

## 6. Chạy tests

```bash
bundle exec rspec spec/requests/api/v1/<resource>_spec.rb
```

Nếu response không khớp schema → test đỏ với lỗi dạng:

```
Committee::InvalidResponse:
  #/paths/~1api~1v1~1todos~1{id}~1complete/patch/responses/200
  missing required field: status
```

→ Sửa YAML hoặc code cho khớp, merge lại rồi chạy lại test.

---

## 7. Xem UI (tùy chọn)

```bash
docker compose up swagger-merger swagger
```

Mở `http://localhost:8031` → endpoint mới sẽ xuất hiện.

---

## Tóm tắt checklist

```
[ ] Tạo swagger/paths/v1/<resource>/<action>.yaml
[ ] Thêm $ref vào swagger/reference/v1.yaml → paths
[ ] (nếu cần) Tạo swagger/components/schemas/<tên>.yaml + đăng ký vào reference
[ ] cd swagger && npm run merge && cd ..
[ ] Viết request spec + assert_schema_conform cho 2xx responses
[ ] bundle exec rspec spec/requests/api/v1/<resource>_spec.rb → xanh
```

---

## Quy tắc YAML cần nhớ

| Quy tắc | Ví dụ |
|---------|-------|
| JSON keys dùng `camelCase` | `userId`, `createdAt`, `totalPages` |
| Request params (query/body) **nên** dùng `camelCase` (server sẽ tự convert sang `snake_case`) | `refreshToken`, `passwordConfirmation` |
| `operationId` duy nhất, kebab-case | `get-todos`, `patch-todo-complete` |
| `tags` theo resource (lowercase) | `[todo]`, `[user]`, `[auth]` |
| Ref local (`#/components/...`) hợp lệ sau merge | Dùng thoải mái trong path files |
| **Không sửa** `swagger/merged/v1.yaml` | Luôn edit source rồi merge |
