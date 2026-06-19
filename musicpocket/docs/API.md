# MusicPocket API 接口文档

## 基础信息

- 基础路径：`/api/v1`
- 数据格式：JSON
- 认证方式：Bearer Token（可选，匿名可用）

---

## 认证接口

### POST /api/v1/auth/register-device

注册匿名设备，获取 JWT token。客户端首次启动时调用。

**请求**：无参数

**响应**：
```json
{
  "device_id": "550e8400-e29b-41d4-a716-446655440000",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "daily_quota": 10
}
```

### GET /api/v1/auth/me

查询当前设备信息和剩余额度。

**请求头**：`Authorization: Bearer <token>`（可选）

**响应**：
```json
{
  "device_id": "550e8400-e29b-41d4-a716-446655440000",
  "daily_quota": 10,
  "used_today": 3
}
```

---

## 转换接口

### POST /api/v1/convert

提交视频转音频任务。

**请求体**：
```json
{
  "url": "https://v.douyin.com/iRNBho5e/",
  "audio_format": "mp3",
  "audio_bitrate": "192k"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| url | string | 是 | 视频链接或包含链接的分享文本 |
| audio_format | string | 否 | mp3 / m4a / aac / opus，默认 mp3 |
| audio_bitrate | string | 否 | 128k / 192k / 320k，默认 192k |

**响应**：
```json
{
  "task_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "pending",
  "message": "已识别为 douyin 链接，开始处理"
}
```

**错误码**：
| 状态码 | 说明 |
|--------|------|
| 400 | 不支持的链接或未找到有效URL |
| 429 | 请求频率超限 |

### POST /api/v1/detect

仅检测链接是否支持，不创建任务。用于客户端粘贴时实时预览。

**请求体**：同 `/convert`

**响应**：
```json
{
  "supported": true,
  "url": "https://v.douyin.com/iRNBho5e/",
  "platform": "douyin",
  "video_id": "7234567890123456789"
}
```

---

## 任务接口

### GET /api/v1/tasks/{task_id}

查询任务状态和进度。客户端每 2 秒轮询。

**响应**：
```json
{
  "task_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "transcoding",
  "progress": 70,
  "title": "Sunset Drive",
  "author": "创作者名称",
  "cover_url": "https://...",
  "duration_seconds": 204,
  "audio_format": "mp3",
  "download_url": null,
  "file_size": null,
  "error_message": null,
  "expires_at": null
}
```

**状态流转**：
```
pending → parsing → downloading → transcoding → completed
                                              → failed
```

| status | progress 范围 | 说明 |
|--------|--------------|------|
| pending | 0 | 等待处理 |
| parsing | 10-30 | 解析视频信息 |
| downloading | 30-70 | 下载媒体文件 |
| transcoding | 70-90 | FFmpeg 音频转码 |
| completed | 100 | 完成，可下载 |
| failed | - | 失败，见 error_message |

### GET /api/v1/tasks/{task_id}/download

下载转换完成的音频文件。

**响应**：音频文件流（application/octet-stream）

**错误码**：
| 状态码 | 说明 |
|--------|------|
| 400 | 任务未完成 |
| 404 | 任务不存在 |
| 410 | 文件已过期（超过 6 小时） |

---

## 健康检查

### GET /health

```json
{
  "status": "ok",
  "supported_platforms": ["douyin", "tiktok", "bilibili", "xiaohongshu"]
}
```

---

## 限流规则

| 用户类型 | 限制 | 说明 |
|---------|------|------|
| 匿名 | 5 次/分钟 | 无 token 请求 |
| 设备认证 | 30 次/分钟 | 携带有效 token |

仅对 `/api/v1/convert` 接口限流。

## 客户端集成流程

```
1. 首次启动 → POST /auth/register-device → 保存 token
2. 用户粘贴文本 → POST /detect → 显示平台和预览
3. 用户点击转换 → POST /convert → 获取 task_id
4. 每 2 秒轮询 → GET /tasks/{task_id} → 更新进度条
5. status=completed → GET /tasks/{task_id}/download → 保存到本地
6. 本地 SQLite 记录 → 音频库列表 → 离线播放
```
