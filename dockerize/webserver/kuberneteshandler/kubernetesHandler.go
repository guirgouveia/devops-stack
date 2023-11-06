package kuberneteshandler

import (
	"bytes"
	"context"
	"database/sql"
	"dockerize/webserver/articlehandler"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

var sqldb *sql.DB

// PassDataBase passes the database to the articleHandlers.
func PassDataBase(db *sql.DB) {
	sqldb = db
}

func GetDatabase() *sql.DB {
	return sqldb
}

func TerminateGracefully(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
	os.Exit(0)
}

// PreStopHookWrapper is used to adapt the PreStopHook function to the http.HandlerFunc signature.
func PreStopHookWrapper(httpServer *http.Server) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		PreStopHook(w, r, httpServer)
	}
}

func PreStopHook(w http.ResponseWriter, r *http.Request, httpServer *http.Server) {
	// Create a channel to receive the SIGTERM signal
	gracefulStop := make(chan os.Signal, 1)

	// Notify the channel when a SIGTERM signal is received
	signal.Notify(gracefulStop, syscall.SIGTERM)

	// Block the execution until a SIGTERM signal is received
	<-gracefulStop

	// Create a deadline to wait for.
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	log.Println("Shutdown signal received, commencing graceful shutdown...")

	// Try to gracefully shutdown the http server and handle the error, if any
	if err := httpServer.Shutdown(ctx); err != nil {
		log.Println("Pre-Stop Hook failed to gracefully shutdown the server.")
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Pre-Stop Hook failed to gracefully shutdown the server."))
	} else {
		log.Println("Server gracefully stopped")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Server gracefully stopped."))
	}
}

func SendRequest(w http.ResponseWriter, r *http.Request) {
	// Prepare an empty JSON payload
	payload := []byte("{}")

	// Create a new request using http to shutdown the database
	req, err := http.NewRequest("POST", "https://mysql.mysql:8080/terminate-gracefully", bytes.NewBuffer(payload))
	if err != nil {
		log.Fatalf("Failed to create request: %v", err)
	}

	// Set the request header for content type to application/json
	req.Header.Set("Content-Type", "application/json")

	// Send the request using the http Client
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatalf("Failed to send request: %v", err)
	}
	defer resp.Body.Close()

	// Read and print the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatalf("Failed to read response body: %v", err)
	}
	fmt.Println(string(body))
}

// Created for testing the Kubernetes post start hook
func PostStartHook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)

	// Check if the request body is "Hello, World!"
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Internal Server Error"))
	} else if string(body) == "Hello, World!" {
		// Check if the database is ready
		err := articlehandler.GetDatabase().Ping()
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("Database not ready!"))
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Hello World"))
	} else {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Bad Request"))
	}
}

func HealthCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func ReadinessCheck(w http.ResponseWriter, r *http.Request) {
	// Check if the database connection is ready
	if err := articlehandler.GetDatabase().Ping(); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprint(w, "Database not ready")
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "Application ready")
}
