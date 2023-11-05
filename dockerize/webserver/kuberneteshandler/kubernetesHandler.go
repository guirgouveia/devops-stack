package kuberneteshandler

import (
	"bytes"
	"dockerize/webserver/articlehandler"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

func TerminateGracefully(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
	os.Exit(0)
}

func PreStopHook(w http.ResponseWriter, r *http.Request) {
	// Prepare an empty JSON payload
	payload := []byte("{}")

	// Create a new request using http
	req, err := http.NewRequest("POST", "https://localhost:8080/terminate-gracefully", bytes.NewBuffer(payload))
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

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal Server Error"))
	} else if string(body) == "Hello, World!" {
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
	err := articlehandler.GetDatabase()

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprint(w, "Application not ready")
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "Application ready")
}
