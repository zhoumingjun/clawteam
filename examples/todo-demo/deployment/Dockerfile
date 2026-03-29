# Todo Demo - Docker 构建文件
# 使用 Nginx 部署静态页面

FROM nginx:1.25-alpine

# 复制构建产物
COPY dist/ /usr/share/nginx/html/

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# 运行 Nginx
CMD ["nginx", "-g", "daemon off;"]
