# Use a newer Flutter image with Dart 3.3+
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /workspace/apps/habiter

# Copy pubspec files first for better caching
COPY apps/habiter/pubspec.yaml apps/habiter/pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application
COPY apps/habiter/ .

# Build the web application
RUN flutter build web --release

# Production stage - serve with nginx
FROM nginx:alpine

# Copy the built web app to nginx
COPY --from=build /workspace/apps/habiter/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
