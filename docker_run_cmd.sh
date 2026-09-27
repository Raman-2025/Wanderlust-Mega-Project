docker network create app-nw \

docker run -d \
  --name redis-service \
  --network app-nw \
  -p "6379:6379" \
  --restart unless-stopped \
  redis:7-alpine


docker run -d \
  --name mongo-service \
  --network app-nw \
  -p "27017:27017" \
  --restart unless-stopped \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  -e MONGO_INITDB_DATABASE=wanderlust \
  mongo:7


docker run -d \
  --name backend \
  --network app-nw \
  -p "8080:8080" \
  -e MONGODB_URI="mongodb://admin:secret@mongo-service:27017/wanderlust?authSource=admin" \
  -e REDIS_URL="redis://redis-service:6379" \
  -e FRONTEND_URL="http://3.94.38.126:5173" \
  -e PORT=8080 \
  -e ACCESS_COOKIE_MAXAGE=120000 \
  -e ACCESS_TOKEN_EXPIRES_IN="120s" \
  -e REFRESH_COOKIE_MAXAGE=120000 \
  -e REFRESH_TOKEN_EXPIRES_IN="120s" \
  -e JWT_SECRET="70dd8b38486eee723ce2505f6db06f1ee503fde5eb06fc04687191a0ed665f3f98776902d2c89f6b993b1c579a87fedaf584c693a106f7cbf16e8b4e67e9d6df" \
  -e NODE_ENV=Development \
  backend-3:latest
  

docker run -d \
  --name frontend \
  --network app-nw \
  -p "5173:5173" \
  -e VITE_API_PATH="http://3.94.38.126:8080" \
  frontend-3:latest  