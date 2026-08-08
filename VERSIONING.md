# 版本管理规则

本仓库基于上游项目 [Wei-Shaw/sub2api](https://github.com/Wei-Shaw/sub2api) 维护自定义版本。

## 版本号格式

- 上游官方版本：`0.x.y`，例如 `0.1.172`。
- 本仓库自定义版本：`0.x.y.n`，其中 `n` 从 `1` 开始递增，表示基于该官方版本的第几次自定义发布。

示例：

- 基于官方 `0.1.172` 的第一个自定义版本：`0.1.172.1`
- 第二个自定义版本：`0.1.172.2`

## 同步上游

当上游发布新版本 `0.x.y` 时：

1. 拉取上游最新代码：`git fetch upstream && git pull --rebase upstream main`。
2. 将 `backend/cmd/server/VERSION` 更新为 `0.x.y.1`。
3. 提交并推送 `main`。
4. 创建并推送版本标签 `v0.x.y.1`，触发 GitHub Actions 自动构建镜像。

## 发布标签

- Git 标签使用 `v<版本号>` 格式，例如 `v0.1.172.1`。
- 镜像推送到 `ghcr.io/hebaiju/sub2api:<版本号>`。
- 不要直接使用上游版本号（如 `v0.1.172`）作为自定义发布标签，避免与上游冲突。

## 版本文件

`backend/cmd/server/VERSION` 是构建时嵌入二进制的版本号，发布前必须与本次标签一致。
