package main

import (
        "fmt"
        "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Welcome to MyApps !\n")
        fmt.Fprintf(w, "If you're lost, please check with your administrator")
}

func main() {
        http.HandleFunc("/", handler)
        fmt.Println("Server running...")
        http.ListenAndServe(":8080", nil)
}
