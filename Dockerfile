# Build image
FROM golang
COPY ./server.go /go/
WORKDIR /go/
RUN CGO_ENABLED=0 GOOS=linux go build ./server.go

# Final image
FROM scratch
COPY --from=0 /go/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
CMD []
