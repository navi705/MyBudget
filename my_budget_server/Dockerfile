# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# Install dart_frog_cli
RUN dart pub global activate dart_frog_cli

# Copy pubspec files for layer caching
COPY pubspec.* ./
RUN dart pub get

# Copy source code
COPY . .

# Generate the production build using dart_frog_cli
# This creates the 'build' directory with the generated entry point
RUN /root/.pub-cache/bin/dart_frog build

# Change directory to the generated build folder
WORKDIR /app/build

# Resolve dependencies for the generated project
RUN dart pub get --offline

# Compile the AOT executable
RUN dart compile exe bin/server.dart -o server

# Stage 2: Runtime
# Using scratch for the smallest possible surface area
FROM scratch

# Copy required runtime libraries from the build image
COPY --from=build /runtime/ /

# Copy the compiled binary
COPY --from=build /app/build/server /app/server

# Expose port and start
EXPOSE 8080
CMD ["/app/server"]
